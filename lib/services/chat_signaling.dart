import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/models/chat_user.dart';
import 'package:bazz_flutter/models/group_model.dart';
import 'package:bazz_flutter/models/services_address.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/socket_request.dart';
import 'package:bazz_flutter/services/data_connection_checker.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart' as log;
import 'package:uuid/uuid.dart';

enum ChatSignalingState {
  // ignore: constant_identifier_names
  ConnectionOpen,
  // ignore: constant_identifier_names
  MessageArrived,
  // ignore: constant_identifier_names
  MessageError,
  // ignore: constant_identifier_names
  UserJoined,
  // ignore: constant_identifier_names
  UserLeft,
  // ignore: constant_identifier_names
  RoomJoined,
  // ignore: constant_identifier_names
  GetMessages,
  // ignore: constant_identifier_names
  ReceivedByClients,
  // ignore: constant_identifier_names
  FailedMessage,
  // ignore: constant_identifier_names
  ConnectionClosed,
  // ignore: constant_identifier_names
  ConnectionError,
  // ignore: constant_identifier_names
  StartTyping,
  // ignore: constant_identifier_names
  StopTyping,
}

typedef SignalingStateCallback = void Function(ChatSignalingState state, ChatMessage chatMessage);

class ChatSignaling {
  static final ChatSignaling _singleton = ChatSignaling._();

  late factory ChatSignaling() => _singleton;

  ChatSignaling._();

  // ignore: prefer_typing_uninitialized_variables
  WebSocket? _socket;
  bool ?startRecoverySupport;
  ChatSignalingState? chatState;
  bool _isConnecting = false;
  bool isConnected = false;
  bool disposing = false;
  bool isOnline = false;
 late  SignalingStateCallback ?onStateChange;
 late  StreamSubscription _isOnlineSub;
  late StreamSubscription? _socketListener;
  late  StreamSubscription? _isOnlineListener;

  //TODO: why do we need this variable?
  final List<RxGroup> _joinedGroups = <RxGroup>[];

  final Map<String, SocketRequest> _requestQueue = {};

  Future<void> init() async {
    TelloLogger().i("INIT ChatSignaling");
    startRecoverySupport = true;
    chatState = null;
    isConnected = false;
    _isConnecting = false;
    _isOnlineListener?.cancel();
    _isOnlineListener = DataConnectionChecker().onStatusChange.listen((status) {
      switch (status) {
        case DataConnectionStatus.connected:
          isOnline = true;
          break;
        case DataConnectionStatus.disconnected:
          isOnline = false;
          TelloLogger().i('[CHAT SERVICE] You are disconnected from the internet.');
          if (!_isConnecting) disconnect();
          break;
      }
    });
    await connect();
  }

  Future<void> dispose() async {
    disposing = true;
    final bool isOnline = await DataConnectionChecker().isConnectedToInternet;
    if (isOnline) leaveGroupsFromChat();
    _isOnlineSub.cancel();
    await disconnect();
    _isOnlineListener?.cancel();
    chatState = null;
    isConnected = false;
    onStateChange = null;
    _isConnecting = false;
    startRecoverySupport = false;
    _requestQueue.clear();
    disposing = false;
  }

  Future<void> connect() async {
    final schema = ServiceAddress().webSocketChatSchema;
    final host = ServiceAddress().webSocketChatAddress;
    final port = ServiceAddress().wwsChatPort;

    try {
      final bool isOnline = await DataConnectionChecker().isConnectedToInternet;
      if (!isOnline || _isConnecting) return;

      TelloLogger().i("connect() CHAT BEFORE $_isConnecting");
      _isConnecting = true;
      await disconnect();
      _socket = await _connectForSelfSignedCert(schema, host, port);
      TelloLogger().i("Connection to socket _connectForSelfSignedCert");
      _isConnecting = false;
      isConnected = true;
      _raiseStateChange(ChatSignalingState.ConnectionOpen);

      _socketListener = _socket!.listen((data) {
        const JsonDecoder decoder = JsonDecoder();
        try {
          onMessage(decoder.convert("$data") as Map<String, dynamic>);
        } catch (e, s) {
          TelloLogger().e('Error while decoding data: $e', stackTrace: s);
        }
      }, onDone: () async {
        TelloLogger().i('ChatSignaling socket closed by server! [${_socket?.closeCode} => ${_socket?.closeReason}]');
        if (isOnline && !disposing) await AppSettings().tryUpdate();
        _isConnecting = false;
        isConnected = false;
        _clearRequestQueue();
        _raiseStateChange(ChatSignalingState.ConnectionClosed);
      }, onError: (e) async {
        TelloLogger().e('ChatSignaling socket error: $e');
        if (isOnline && !disposing) await AppSettings().tryUpdate();
        _isConnecting = false;
        isConnected = false;
        _raiseStateChange(ChatSignalingState.ConnectionError);
      });
    } catch (e, s) {
      TelloLogger().e("ChatSignaling connect() error $e", stackTrace: s);
      if (isOnline && !disposing) await AppSettings().tryUpdate();
      _isConnecting = false;
      isConnected = false;
      _raiseStateChange(ChatSignalingState.ConnectionError);
    }
  }

  void _clearRequestQueue() {
    for (final req in _requestQueue.values) {
      req.completer.complete();
    }
    _requestQueue.clear();
  }

  Future<void> disconnect() async {
    if (_socket == null) return;

    TelloLogger().i('ChatSignaling: disconnecting...');
    await _socket!.close().timeout(const Duration(seconds: 5));
    _socket = null;
    _socketListener?.cancel();
    _raiseStateChange(ChatSignalingState.ConnectionClosed);
  }

  Future<void> joinGroupsToChat(List<RxGroup> groups) async {
    _joinedGroups.clear();
    groups.forEach((group) async {
      TelloLogger().i("group ${group.title} has joined the chat");
      await _sendWithTimeout(ChatMessage.createJoinRoomMessage(group, Session.user!, Session.shift!.currentPosition!));
      _joinedGroups.add(group);
    });
    TelloLogger().i("joinGroupsToChat length: ${groups.length}");
  }

  Future<void> leaveGroupsFromChat() async {
    TelloLogger().i("LEAVE GroupsToChat ${_joinedGroups.length}");
    _joinedGroups.forEach((group) async {
      TelloLogger().i("LEAVE GroupsToChat ${group.title}");
      await _sendWithTimeout(ChatMessage.createLeaveRoomMessage(group, Session.user!, Session.shift!.currentPosition!));
    });
    _joinedGroups.clear();
  }

  Future<void> sendMessage(ChatMessage chatMessage) async {
    await _sendWithTimeout(chatMessage);
  }

  Future<void> onMessage(Map<String, dynamic> map) async {
    TelloLogger().i('onMessage()', data: map, caller: 'ChatSignaling');

    if (map['commandName'] != null) {
      final data = map['data'] as Map<String, dynamic>;
      final requestId = map['requestId'] as String;

      if (_requestQueue.containsKey(requestId)) {
        _requestQueue[requestId]!.completer.complete(data);
        _requestQueue.remove(requestId);
      }

      if (map['commandName'] == 'ListMessageResponse') {
        // final chatRoomId = data['targetClientId'] != null ? data['targetClientId'] as String : data['roomId'] as String;
        final chatMessage = ChatMessage(attachmentFile: null as File, author: null as ChatUser, chatRoom: null as ChatRoom, createdAt: null as DateTime, id: '', maxLimit: null as int , quotedMessage: null as ChatMessage, searchFromDateTime: null as DateTime);
        chatMessage.setMessages(
          data['messages'] as List<dynamic>,
          private: data['targetClientId'] != null && (data['targetClientId'] as String).isNotEmpty,
        );
        _raiseStateChange(ChatSignalingState.GetMessages, chatMessage: chatMessage);
      }
    } else {
      final chatMessage = ChatMessage.fromMap(map);
      switch (chatMessage.action) {
        case ChatMessage.sendMessageAction:
          _raiseStateChange(ChatSignalingState.MessageArrived, chatMessage: chatMessage);
          break;
        case ChatMessage.clientErrorMessageAction:
          _raiseStateChange(ChatSignalingState.MessageError, chatMessage: chatMessage);
          break;
        case ChatMessage.userJoinAction:
          _raiseStateChange(ChatSignalingState.UserJoined, chatMessage: chatMessage);
          break;
        case ChatMessage.userLeftAction:
          _raiseStateChange(ChatSignalingState.UserLeft, chatMessage: chatMessage);
          break;
        case ChatMessage.roomJoinedAction:
          _raiseStateChange(ChatSignalingState.RoomJoined, chatMessage: chatMessage);
          break;
        case ChatMessage.getMessagesAction:
          _raiseStateChange(ChatSignalingState.GetMessages, chatMessage: chatMessage);
          break;
        case ChatMessage.failedMessageAction:
          _raiseStateChange(ChatSignalingState.FailedMessage, chatMessage: chatMessage);
          break;
        case ChatMessage.startTypingAction:
          _raiseStateChange(ChatSignalingState.StartTyping, chatMessage: chatMessage);
          break;
        case ChatMessage.stopTypingAction:
          _raiseStateChange(ChatSignalingState.StopTyping, chatMessage: chatMessage);
          break;
        case ChatMessage.receivedByAction:
          _raiseStateChange(ChatSignalingState.ReceivedByClients, chatMessage: chatMessage);
          break;
      }
    }
  }

  Future<WebSocket> _connectForSelfSignedCert(String schema, String host, int port) async {
    try {
      final Random random = Random();
      final String key = base64.encode(List<int>.generate(8, (_) => random.nextInt(255)));
      final SecurityContext securityContext = SecurityContext();
      final HttpClient client = HttpClient(context: securityContext);
      client.badCertificateCallback = (X509Certificate cert, String host, int port) {
        TelloLogger().i('Allow self-signed certificate => $host:$port. ');
        return true;
      };
      String urlSchema = schema;
      if (schema == "ws") {
        urlSchema = "http";
      } else if (schema == "wss") {
        urlSchema = "https";
      }
      final String serverUri =
          "$urlSchema://$host:$port/ws?name=${Session.user!.fullName}&id=${Session.user!.id}&token=${Session.authToken}&positionTitle=${Uri.encodeQueryComponent(Session.shift?.positionTitle ?? "")}&positionId=${Session.shift?.positionId ?? ""}";
      TelloLogger().i(serverUri);
      final HttpClientRequest request =
          await client.getUrl(Uri.parse(serverUri)).timeout(const Duration(seconds: 5), onTimeout: () {
        throw Exception("timeout");
      }); // form the correct url here
      request.headers.add('Connection', 'Upgrade');
      request.headers.add('Upgrade', 'websocket');
      request.headers.add('Sec-WebSocket-Version', '13'); // insert the correct version here
      request.headers.add('Sec-WebSocket-Key', key.toLowerCase());

      final HttpClientResponse response = await request.close();
      final Socket socket = await response.detachSocket();
      final webSocket = WebSocket.fromUpgradedSocket(
        socket,
        protocol: 'signaling',
        serverSide: false,
      );
      return webSocket;
    } catch (e, s) {
      TelloLogger().e("_connectForSelfSignedCert ERROR $e", stackTrace: s);
      rethrow;
    }
  }

  void _raiseStateChange(ChatSignalingState signalingState, {ChatMessage ? chatMessage}) {
    chatState = signalingState;
    TelloLogger().i("_raiseStateChange onStateChange === $onStateChange");
    if (onStateChange != null) {
      onStateChange!(signalingState, chatMessage!);
    }
  }

  Future<void> _sendWithTimeout(ChatMessage chatMessage) async {
    await send(chatMessage.toMap()).timeout(Duration(seconds: AppSettings().socketTimeout), onTimeout: () {
      TelloLogger().i('[send timeout!');
    });
  }

  Future<void> send(Map<String, dynamic> data) async {
    TelloLogger().i('############# SEND CHAT MESSAGE START');
    //data['data'] = data;
    // data['type'] = event;
    const JsonEncoder encoder = JsonEncoder();
    final String encodedData = encoder.convert(data);
    _socket?.add(encodedData);
    TelloLogger().i('############# CHAT MESSAGE SENT: $encodedData');
  }

  Future<void> sendV2({required String method, required Map<String, dynamic> data, VoidCallback? onTimeout}) {
    final requestId = Uuid().v1();
    final payload = {
      'commandName': method,
      'requestId': requestId,
      'data': data,
    };

    TelloLogger().i('ChatSignaling sending payload: $payload');
    _requestQueue[requestId] = SocketRequest(payload);
    const JsonEncoder encoder = JsonEncoder();
    final String encodedPayload = encoder.convert(payload);
    _socket?.add(encodedPayload);
    return _requestQueue[requestId]!.completer.future.timeout(
      Duration(seconds: AppSettings().socketTimeout),
      onTimeout: () {
        _requestQueue.remove(requestId);
        onTimeout?.call();
        TelloLogger().i('ChatSignalling $requestId timeout. _requestQueue.length: ${_requestQueue.length}');
      },
    );
  }
}
