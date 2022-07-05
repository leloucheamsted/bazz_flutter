import 'dart:async';
import 'dart:convert';
import 'dart:isolate';

import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/services_address.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/socket_request.dart';
import 'package:bazz_flutter/services/data_connection_checker.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/websocket.dart';
import 'package:eventify/eventify.dart' as evf;
import 'package:random_string/random_string.dart';
import 'package:rxdart/subjects.dart';
import 'package:uuid/uuid.dart';

class Signaling extends evf.EventEmitter {
  static final Signaling _singleton = Signaling._();

  factory Signaling() => _singleton;

  Signaling._();

  late SimpleWebSocket _socket;
  late String peerId;
  late String _userId;
  late String _positionId;
  late BehaviorSubject<bool> connected;
  late Map<int, SocketRequest> _requestQueue;
  static bool? isBackgroundService;
  late Timer _heartbeatTimer;
  late bool _isConnecting;
  late bool startRecoverySupport;
  bool isOnline = false;
  bool disposing = false;
  late StreamSubscription _isOnlineListener;
  late evf.Listener locationUpdateSub;

  void init() {
    TelloLogger().i('Signaling init started...');
    _userId = Session.user!.id;
    _positionId = Session.shift!.positionId!;
    startRecoverySupport = true;
    _isConnecting = false;
    isBackgroundService = false;
    _requestQueue = {};
    connected = BehaviorSubject();

    _isOnlineListener = DataConnectionChecker().onStatusChange.listen((status) {
      switch (status) {
        case DataConnectionStatus.connected:
          isOnline = true;
          TelloLogger().i('[Media Signaling]Data connection is available.');
          connect();
          break;
        case DataConnectionStatus.disconnected:
          isOnline = false;
          TelloLogger()
              .i('[Media  Signaling]You are disconnected from the internet.');
          if (!_isConnecting) disconnect(closeSocket: true);
          break;
      }
    });

    _heartbeatTimer = Timer.periodic(
        Duration(seconds: AppSettings().heartbeatPeriod), (timer) async {
      final int isolateId = Isolate.current.hashCode;
      if (_userId != null) {
        if (connected.value == true) {
          TelloLogger().i(
              '[Signalling $peerId $processLabel $isolateId] < -- Heartbeat --- >');
          final DateTime sendTime = DateTime.now();
          final dynamic response =
              await sendWithTimeout('heartbeat', {}, withConnect: true);
          emit('signalingHeartbeatResponse', this, response);
        } else {
          TelloLogger().i('[Signaling $peerId $processLabel] Reconnecting...');
          connect();
        }
      }
    });
    TelloLogger().i('Signaling init ended.');
  }

  Future<void> dispose() async {
    TelloLogger().i('[Signaling IS DISPOSING START]');
    disposing = true;
    startRecoverySupport = false;
    _heartbeatTimer.cancel();
    _isOnlineListener.cancel();
    await disconnect(closeSocket: true);
    _socket.onMessage = null as Function(String);
    _socket.onOpen = null as Function();
    _socket.onClose = null as Function(int, String);
    _socket = null as SimpleWebSocket;
    connected.close();
    peerId = null as String;
    _userId = null as String;
    _positionId = null as String;
    _requestQueue = null as Map<int, SocketRequest>;
    locationUpdateSub = null as evf.Listener;
    isBackgroundService = false;
    _isConnecting = false;
    super.clear();
    disposing = false;
    TelloLogger().i('[Signaling IS DISPOSING DONE]');
  }

  String get processLabel => isBackgroundService! ? 'background' : 'foreground';

  Future<void> connect() async {
    if (_userId == null)
      return TelloLogger().i('Signaling: _userId is null, returning...');

    final _schema = ServiceAddress().webSocketSchema;
    final _host = ServiceAddress().webSocketAddress;
    final _port = ServiceAddress().wwsPort;

    try {
      TelloLogger().i('[Signalling  connect request $_isConnecting');
      if (_isConnecting) return;
      _isConnecting = true;

      TelloLogger().i(
          '[Signalling $peerId $processLabel] connect request $_userId [$processLabel]');
      if (connected.value == true) {
        TelloLogger().i(
            '[Signalling $peerId $processLabel] already connected $_userId [$processLabel]');
        _isConnecting = false;
        return;
      }
      // var url = 'http://$_host:$_port';
      peerId = Uuid().v1();
      if (_socket != null) {
        await _socket.close();
        _socket = null as SimpleWebSocket;
      }
      TelloLogger().i('[Signaling $peerId $processLabel] connecting $_userId');

      _socket = SimpleWebSocket(
        _schema,
        _host,
        _port,
        peerId: peerId,
        userId: _userId,
        positionId: _positionId,
        isBackgroundService: isBackgroundService,
        onTimeout: () {
          TelloLogger().i('[Signaling timeout connecting $_userId');
          disconnect();
        },
        roomId: '',
      );

      _socket.onOpen = () async {
        TelloLogger().i('[Media Soap Signaling $peerId $processLabel] onOpen');
        connected.add(true);
        _isConnecting = false;
      };
      TelloLogger().i('[Signaling ====> 0000000] connecting $_userId');
      _socket.onMessage = (message) {
        const JsonDecoder decoder = JsonDecoder();
        if (onMessage != null) {
          onMessage(decoder.convert(message) as Map<String, dynamic>);
        }
      };

      _socket.onClose = (int code, String reason) async {
        TelloLogger().i(
            '[Media Soap Signaling ${connected.value} ${connected.isClosed} $peerId $processLabel] Closed by server [$code => $reason]!');
        if (isOnline && !disposing) await AppSettings().tryUpdate();
        disconnect();
      };
      TelloLogger().i('[Signaling ====> 111111111] connecting $_userId');
      await _socket.connect();
    } catch (e, s) {
      if (isOnline && !disposing) await AppSettings().tryUpdate();
      TelloLogger().e("Media Soap  Connection error $e", stackTrace: s);
      disconnect();
    }
  }

  Future<void> disconnect({bool closeSocket = false}) async {
    if (closeSocket && _socket != null) {
      TelloLogger().i("[Signaling $peerId $processLabel] disconnecting...");
      await _socket.close();
    }
    if (!connected.isClosed) connected.add(false);
    _isConnecting = false;
  }

  Future<void> onMessage(Map<String, dynamic> message) async {
    final data = message['data'] as Map<String, dynamic>;
    final requestId = message['id'] as int;
    final method = message['method'] as String;

    if (_requestQueue.containsKey(requestId)) {
      _requestQueue[requestId]!.completer.complete(data);
    }

    /*switch (method) {
      case 'logout':
        {
          disconnect(notifyServer: false);
          break;
        }
    }*/

    if (method != null) {
      emit(method, this, message);
      TelloLogger().i(
          'onMessage() peerId: $peerId, processLabel: $processLabel',
          data: message,
          caller: 'Signaling');
    }

    _requestQueue.remove(requestId);
  }

  Future<dynamic> sendWithTimeout(String method, Map<String, dynamic> data,
      {bool withConnect = false}) async {
    return _send(method, data).timeout(
      Duration(seconds: AppSettings().socketTimeout),
      onTimeout: () {
        TelloLogger().w(
          '[Signalling timeout => $peerId $processLabel] $method ${AppSettings().socketTimeout}',
          data: data,
        );
        // disconnect();
        if (withConnect) {
          connected.add(false);
          connect();
        }
      },
    );
  }

  Future<dynamic> acceptWithTimeout(Map<String, dynamic> message,
      {Map<String, dynamic> data = const {}}) async {
    await _accept(message, data: data).timeout(
      Duration(seconds: AppSettings().socketTimeout),
      onTimeout: () {
        TelloLogger().w('[Accept timeout!', data: data);
      },
    );
  }

  Future<void> _accept(Map<String, dynamic> message,
      {Map<String, dynamic> data = const {}}) async {
    const JsonEncoder encoder = JsonEncoder();
    _socket.send(encoder.convert({
      "response": true,
      "id": message["id"],
      "ok": true,
      "data": data,
    }));
  }

  Future<dynamic> _send(String method, Map<String, dynamic> data) async {
    if (_socket == null) {
      return null;
    }

    final payload = <String, dynamic>{};
    int requestId;
    do {
      requestId = int.parse(randomNumeric(8));
    } while (_requestQueue.containsKey(requestId));

    payload['method'] = method;
    payload['request'] = true;
    payload['id'] = requestId;
    payload['data'] = data;
    TelloLogger().i("Signaling is sending request $method id: $requestId");
    _requestQueue[requestId] = SocketRequest(payload);
    const JsonEncoder encoder = JsonEncoder();
    _socket.send(encoder.convert(payload));

    return _requestQueue[requestId]!.completer.future;
  }
}
