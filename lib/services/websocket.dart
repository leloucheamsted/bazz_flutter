import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bazz_flutter/models/session_model.dart';

import 'logger.dart';

typedef OnMessageCallback = void Function(String msg);
typedef OnCloseCallback = void Function(int code, String reason);
typedef OnOpenCallback = void Function();
typedef OnTimeoutCallback = void Function();

class SimpleWebSocket {
  final String? _host;
  final String? _schema;
  final int? _port;
  late WebSocket? _socket;
  late OnOpenCallback onOpen;
  late OnMessageCallback onMessage;
  late OnCloseCallback onClose;
  late OnTimeoutCallback? onTimeout;
  late String? peerId;
  late String? userId;
  late String? positionId;
  late bool? isBackgroundService;
  late bool failedCreatingSocket = false;
  late StreamSubscription? _socketSub;

  SimpleWebSocket(this._schema, this._host, this._port,
      {this.peerId,
      this.userId,
      this.positionId,
      this.isBackgroundService,
      this.onTimeout,
      required String roomId});

  Future<void> connect() async {
    try {
      _socket = await _connectForSelfSignedCert(_schema!, _host!, _port!);
      if (_socket == null) {
        failedCreatingSocket = true;
        if (onTimeout != null) {
          onTimeout!();
        }
        return;
      }
      failedCreatingSocket = false;
      if (onOpen != null) {
        onOpen();
      }
      _socketSub = _socket!.listen((data) {
        if (onMessage != null) {
          onMessage(data.toString());
        }
      }, onDone: () {
        if (onClose != null) {
          onClose(_socket!.closeCode as int, _socket!.closeReason as String);
        }
      }, onError: (e) {
        TelloLogger().e('SimpleWebSocket error: $e');
        if (onClose != null) {
          onClose(_socket!.closeCode as int, _socket!.closeReason as String);
        }
      });
    } catch (e) {
      if (onClose != null) {
        onClose(500, e.toString());
      }
    }
  }

  void send(String data) {
    if (_socket != null) {
      _socket!.add(data);
      TelloLogger().i('websocket send data: $data');
    }
  }

  Future<void> close() async {
    _socketSub?.cancel();
    await _socket?.close();
  }

  Future<WebSocket?> _connectForSelfSignedCert(
      String schema, String host, int port) async {
    try {
      final String key =
          base64.encode(List<int>.generate(8, (_) => Random().nextInt(255)));
      final SecurityContext securityContext = SecurityContext();
      final HttpClient client = HttpClient(context: securityContext);
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        TelloLogger().i('Allow self-signed certificate => $host:$port. ');
        return true;
      };
      String urlSchema = schema;
      if (schema == "ws") {
        urlSchema = "http";
      } else if (schema == "wss") {
        urlSchema = "https";
      }
      final String url = port == null
          ? '$urlSchema://$host?peerId=$peerId&userId=$userId&positionId=${positionId ?? ''}&backgroundService=$isBackgroundService&token=${Session.authToken}'
          : '$urlSchema://$host:$port?peerId=$peerId&userId=$userId&positionId=${positionId ?? ''}&backgroundService=$isBackgroundService&token=${Session.authToken}';
      TelloLogger().i("GET REQUEST 00000000 $url");
      TelloLogger().i(url);

      final HttpClientRequest request = await client
          .getUrl(Uri.parse(url))
          .timeout(const Duration(seconds: 5), onTimeout: () {
        return null as FutureOr<HttpClientRequest>;
      }); // form the correct url here
      if (request == null) {
        return null;
      }
      request.headers.add('Connection', 'Upgrade');
      request.headers.add('Upgrade', 'websocket');
      request.headers.add(
          'Sec-WebSocket-Version', '13'); // insert the correct version here
      request.headers.add('Sec-WebSocket-Key', key.toLowerCase());
      request.headers.add('sec-websocket-protocol', 'protoo');
      final HttpClientResponse response = await request.close();
      final Socket socket = await response.detachSocket();
      final webSocket = WebSocket.fromUpgradedSocket(
        socket,
        protocol: 'signaling',
        serverSide: false,
      );
      return webSocket;
    } catch (e, s) {
      TelloLogger().e('_connectForSelfSignedCert error: $e', stackTrace: s);
      rethrow;
    }
  }
}
