import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/device_state.dart';
import 'package:bazz_flutter/models/location_details_model.dart';
import 'package:bazz_flutter/models/services_address.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/socket_request.dart';
import 'package:bazz_flutter/modules/location_tracking/location_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/power_management_service.dart';
import 'package:eventify/eventify.dart' as evf;
import 'package:geolocator/geolocator.dart';
import 'package:random_string/random_string.dart';
import 'package:rxdart/subjects.dart';

import 'data_connection_checker.dart';

class SystemEventsSignaling extends evf.EventEmitter {
  static final SystemEventsSignaling _singleton = SystemEventsSignaling._();

  late factory SystemEventsSignaling() => _singleton;

  SystemEventsSignaling._();

  // ignore: prefer_typing_uninitialized_variables
  late WebSocket _socket;
 late  String peerId;
 late  LocationService locationService;
 late  BehaviorSubject<bool> connected;
 late  BehaviorSubject<dynamic> errorOnSocket;
 late  Map<int, SocketRequest> _requestQueue;
   static bool ? isBackgroundService;
  late Timer _heartbeatTimer;

  //ConnectivityStatus _prevConnectivityStatus;
  bool ? _isConnecting;
  DeviceState ? prevDeviceState;
  bool ? isDisposed;
  bool? disposing;
  bool  _skipConnectionRecovery = false;
  bool isOnline = false;
  StreamSubscription ?_isOnlineListener;
  StreamSubscription ?_socketSub;
  evf.Listener ? locationUpdateSub;

  Future<void> init() async {
    TelloLogger().i("START init() SYSTEM EVENTS SIGNALING");
    isDisposed = false;
    _isConnecting = false;
    isBackgroundService = false;
    locationService = LocationService()..init();
    TelloLogger().i("START init() SYSTEM EVENTS SIGNALING 0000000");
    _requestQueue = {};
    connected = BehaviorSubject();
    errorOnSocket = BehaviorSubject();
    prevDeviceState = DeviceState.createEmpty();

    locationUpdateSub = locationService.on('locationUpdate', this, (evf.Event  ev, Object ?context) async {
      final Position  position = ev.eventData as Position;
      if (connected.value == true) {
        sendUpdatedLocation(position);
      }
    });

    TelloLogger().i("START init() SYSTEM EVENTS SIGNALING 1111111111111");

    _isOnlineListener = DataConnectionChecker().onStatusChange.listen((status) {
      switch (status) {
        case DataConnectionStatus.connected:
          isOnline = true;
          break;
        case DataConnectionStatus.disconnected:
          isOnline = false;
          TelloLogger().i('[System Events]You are disconnected from the internet.');
          if (_isConnecting!) disconnect();
          break;
      }
    });

    TelloLogger().i("START init() SYSTEM EVENTS SIGNALING22222222222222222");
    _heartbeatTimer = Timer.periodic(Duration(seconds: AppSettings().heartbeatPeriod), (timer) async {
      TelloLogger().i("connected.value ${connected.value}");
      final deviceState = await DeviceState.createDeviceState();
      if (deviceState != null) {
        PowerManagementService().managePowerConsumptionService(deviceState.batteryPercentage!,
            isDeviceCharging: deviceState.isDeviceCharging!);
      }
      TelloLogger().i('prevDeviceState == deviceState: ${deviceState.batteryPercentage}');
      if (connected.value == true) {
        TelloLogger().i('##### SystemEventsSignaling  Heartbeat #######');
        final DateTime sendTime = DateTime.now();
        final dynamic response = await sendWithTimeout(
          'heartbeat',
          {"device": !(prevDeviceState == deviceState) ? deviceState.toMap() : null},
        ).timeout(
          Duration(seconds: AppSettings().socketTimeout),
          onTimeout: () {
            TelloLogger().i('[SystemEventsSignaling $peerId $processLabel] heartbeat timeout!');
            // disconnect();
          },
        );
        TelloLogger()
            .i('[SystemEventsSignaling $peerId $processLabel] heartbeat with device info ==> ${deviceState.toMap()}');
        final DateTime responseTime = DateTime.now();
        TelloLogger().i('[SystemEventsSignaling $peerId $processLabel] heartbeat response: ${response.toString()}.'
            ' Duration: ${responseTime.difference(sendTime).inMilliseconds}');
        emit('systemEventsSignalingHeartbeatResponse', this, response);
      } else {
        TelloLogger().i('[SystemEventsSignaling $peerId $processLabel] Reconnecting...');
        if (!(prevDeviceState == deviceState) && deviceState != null) {
          deviceState.save();
        }
        startConnectionRecovery();
      }
      prevDeviceState = deviceState;
    });

    TelloLogger().i("COMPLETE init() SYSTEM EVENTS SIGNALING");
  }

  Future<void> dispose() async {
    TelloLogger().i('[EVENT Signaling IS DISPOSING START]');
    disposing = true;
    _heartbeatTimer.cancel();
    _isOnlineListener?.cancel();
    locationService.dispose();
    locationUpdateSub?.cancel();
    await disconnect(closeSocket: true);
    _socketSub!.cancel();
    _socket = null as WebSocket;
    connected.close();
    errorOnSocket.close();
    peerId = null as String;
    locationService = null as LocationService;
    connected = null as BehaviorSubject<bool>;
    _requestQueue = null as Map<int,SocketRequest>;
    locationUpdateSub = null as evf.Listener;
    _heartbeatTimer = null as Timer;
    prevDeviceState = null as DeviceState;
    isBackgroundService = false;
    _isConnecting = false;
    super.clear();
    isDisposed = true;
    disposing = false;
    TelloLogger().i('[Signaling IS DISPOSING DONE $isDisposed]');
  }

  Future<void> sendUpdatedLocation(Position position) async {
    final locationDetails = position != null ? LocationDetails.fromPosition(position) : null;
    final speed = locationDetails?.speed != null ? locationDetails!.speed : null;
    TelloLogger().i("sendUpdatedLocation speed km/h ===> $speed");
    TelloLogger().i("location details ===> ${locationDetails?.toMap()}");
    sendWithTimeout('locationUpdate', {
      'latitude': position.latitude,
      'longitude': position.longitude,
      "locationDetails": locationDetails?.toMap()
    });
  }

   String get processLabel => isBackgroundService! ? 'background' : 'foreground';

  // ignore: unnecessary_getters_setters
  bool get skipConnectionRecovery => _skipConnectionRecovery;

  // ignore: unnecessary_getters_setters
  set skipConnectionRecovery(bool skip) => _skipConnectionRecovery = skip;

  Future<void> startConnectionRecovery() async {
    if (isDisposed! || skipConnectionRecovery) return;
    TelloLogger().i("WAIT FOR SIGNALING System Events CONNECTION RECOVERY ===> $disposing");
    await Future.delayed(Duration(seconds: AppSettings().signalingSocketRecoveryPeriod));
    connect();
  }

  Future<void> connect() async {
    final _schema = ServiceAddress().webSystemEventsSocketSchema;
    final _host = ServiceAddress().webSystemEventsSocketAddress;
    final _port = ServiceAddress().wwsSystemEventsPort;

    try {
      TelloLogger().i("SYSTEM EVENTS START TO CONNECT $_isConnecting");
      if (_isConnecting! || connected == null) return;
      _isConnecting = true;

      if (connected.value == true) {
        _isConnecting = false;
        return;
      }
      final String urlToConnect = "$_schema://$_host:$_port/?token=${Session.authToken}";
      TelloLogger().i("SYSTEM EVENTS CONNECTING SYSTEM EVENT TO URL $urlToConnect");
      if (_socket != null) {
        await _socket.close();
        _socket = null as WebSocket;
      }
      _socket = await WebSocket.connect(urlToConnect)
        ..timeout(
          const Duration(seconds: 10),
          onTimeout: (_) {
            TelloLogger().i('[Signalling $peerId $processLabel] heartbeat timeout!');
            startConnectionRecovery();
          },
        );
      //_socket = await _connectForSelfSignedCert(_host, _port);

      TelloLogger().i('[SYSTEM EVENTS SOCKET IS OPENED Signaling System Events] onOpen');
      connected.add(true);
      _isConnecting = false;

      _socketSub = _socket.listen((data) {
        const JsonDecoder decoder = JsonDecoder();
        if (onMessage != null) {
          onMessage(decoder.convert(data.toString()) as Map<String, dynamic>);
        }
      }, onDone: () async {
        if (connected != null) {
          TelloLogger()
              .i('SystemEventsSignaling socket closed by server [${_socket.closeCode} => ${_socket.closeReason}]!');
          if (isOnline && disposing!) await AppSettings().tryUpdate();
          disconnect();
        }
      }, onError: (e) async {
        if (connected != null) {
          TelloLogger().e('SystemEventsSignaling socket error: $e');
          if (isOnline && disposing!) await AppSettings().tryUpdate();
          disconnect();
          errorOnSocket.add(e);
        }
      });
    } catch (e, s) {
      if (connected != null) {
        TelloLogger().e("SystemEventsSignaling connect() error: $e", stackTrace: s);
        if (isOnline && disposing!) await AppSettings().tryUpdate();
        disconnect();
      }
    }
  }

  Future<void> disconnect({bool closeSocket = false}) async {
    if (closeSocket && _socket != null) {
      TelloLogger().i("[SystemEventsSignaling $peerId $processLabel] disconnecting...");
      await _socket.close();
    }
    if (!(connected.isClosed )) connected.add(false);
    _isConnecting = false;
  }

  Future<void> onMessage(Map<String, dynamic> message) async {
    final data = message['data'] as Map<String, dynamic>;
    final requestId = message['id'] as int;
    final method = message['method'] as String;

    if (_requestQueue.containsKey(requestId)) {
      _requestQueue[requestId]!.completer.complete(data);
    }

    switch (method) {
      case 'logout':
        {
          disconnect();
          break;
        }
    }

    if (method != null) {
      emit(method, this, message);
      TelloLogger().i(
        'onMessage() peerId: $peerId, processLabel: $processLabel',
        data: message,
        caller: 'SystemEventsSignaling',
      );
    }

    _requestQueue.remove(requestId);
  }

  void accept(Map<String, dynamic> message, {Map<String, dynamic> data = const {}}) {
    const JsonEncoder encoder = JsonEncoder();
    _socket.add(encoder.convert({
      "response": true,
      "id": message["id"],
      "ok": true,
      "data": data,
    }));
  }

  Future<dynamic> sendWithTimeout(String method, Map<String, dynamic> data) async {
    return send(method, data).timeout(
      Duration(seconds: AppSettings().socketTimeout),
      onTimeout: () {
        TelloLogger()
            .i('[SystemEventsSignalling $peerId $processLabel] heartbeat ${AppSettings().socketTimeout} timeout!');
        // disconnect();
      },
    );
  }

  Future<dynamic> send(String method, Map<String, dynamic> data) async {
    if (_socket == null) {
      return null;
    }

    final Map<String, dynamic> message = {};
    int requestId;
    do {
      requestId = int.parse(randomNumeric(8));
    } while (_requestQueue.containsKey(requestId));

    message['method'] = method;
    message['request'] = true;
    message['id'] = requestId;
    message['data'] = data;
    TelloLogger().i("SystemEventsSignaling is sending request $method id: $requestId");
    _requestQueue[requestId] = SocketRequest(message);
    const JsonEncoder encoder = JsonEncoder();
    _socket.add(encoder.convert(message));

    return _requestQueue[requestId]!.completer.future;
  }
}
