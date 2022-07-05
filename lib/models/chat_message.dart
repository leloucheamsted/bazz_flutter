import 'dart:io';

import 'package:bazz_flutter/main.dart';
import 'package:bazz_flutter/models/chat_user.dart';
import 'package:bazz_flutter/models/group_model.dart';
import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/services_address.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/enums.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class ChatMessage {
  static const sendMessageAction = "send-message";
  static const userJoinAction = "user-join";
  static const userLeftAction = "user-left";
  static const joinRoomAction = "join-room";
  static const roomJoinedAction = "room-joined";
  static const leaveRoomAction = "leave-room";
  static const userStartWritingAction = "user-writing";
  static const userStopWritingAction = "user-stop-writing";
  static const getMessagesAction = "get-messages";
  static const failedMessageAction = "failed-message";
  static const startTypingAction = "start-typing-message";
  static const stopTypingAction = "stop-typing-message";
  static const receivedByAction = "received-by-clients";
  static const clientReadMessageAction = "clients-read-message";
  static const clientErrorMessageAction = "clients-error-message";
  final String id;
  late String action,
      text,
      attachmentUrl,
      userToken,
      backendAddress,
      fileName,
      mimeType;
  late File attachmentFile;
  late DateTime createdAt;
  final DateTime searchFromDateTime;
  final int maxLimit;
  late String messageRefId;
  late ChatMessage quotedMessage;
  final ChatUser author;
  final MessageBaseType messageType;
  late ChatRoom chatRoom;
  late List<ChatMessage> messages = [];
  late List<ChatMessage> privateMessages = [];
  late List<ChatClientReceiver> receivedBy = [];
  late bool dateIsVisible = false;

  bool hasBeenRead = false;

  bool get isUnread => !hasBeenRead;

  bool get isPrivate => chatRoom.isPrivate ?? false;

  bool get isMine => author.id == Session.user!.id;

  bool get isNotMine => !isMine;

  String? get recipientId => chatRoom.clientId ?? chatRoom.id;

  ChatUser get interlocutor {
    if (isMine) {
      if (chatRoom == null) return null as ChatUser;

      late RxUser targetMember;

      for (final group in HomeController.to.groups) {
        if (targetMember != null) break;

        targetMember = group.members.users
            .firstWhere((u) => u.id == chatRoom.clientId, orElse: () => null!);
      }
      targetMember = HomeController.to.adminUsers
          .firstWhere((admin) => admin.id == chatRoom.clientId);
      if (targetMember == null) {
        return ChatUser.fromUnknownUser(chatRoom.clientId!);
      }
      return ChatUser.fromUser(targetMember);
    } else {
      return author;
    }
  }

  bool get didAllReceive {
    if (isPrivate) {
      return receivedBy.any((rcvr) => rcvr.id == interlocutor.id);
    }
    final activeGroup = HomeController.to.activeGroup;
    final allUsersReceived = activeGroup.members.users
        .every((u) => receivedBy.any((rcvr) => rcvr.id == u.id));
    final allPositionsReceived = activeGroup.members.positions
        .every((p) => receivedBy.any((rcvr) => rcvr.id == p.id));
    return allUsersReceived && allPositionsReceived;
  }

  bool get didAnyReceive {
    if (isPrivate) {
      return receivedBy.any((rcvr) => rcvr.id == interlocutor.id);
    }
    final activeGroup = HomeController.to.activeGroup;
    final anyUsersReceived = activeGroup.members.users
        .any((u) => receivedBy.any((rcvr) => rcvr.id == u.id));
    final anyPositionsReceived = activeGroup.members.positions
        .any((p) => receivedBy.any((rcvr) => rcvr.id == p.id));
    return anyUsersReceived || anyPositionsReceived;
  }

  bool get isIncoming => !isOutgoing;

  bool isOutgoing = true;
  bool isPending = false;
  RxBool isUploading = false.obs;
  RxBool isDownloading = false.obs;
  RxBool isCompressing = false.obs;
  RxInt downloadProgress = 0.obs;
  RxInt uploadProgress = 0.obs;

  bool get isDownloaded =>
      downloadProgress() == 100 || (attachmentFile.existsSync());

  bool get isUploaded => uploadProgress() == 100;

  bool get isNotDownloaded => downloadProgress() < 100;

  bool get isNotUploaded => uploadProgress() < 100;

  ChatMessage({
    required this.id,
    required this.createdAt,
    required this.author,
    required this.chatRoom,
    this.text = '',
    this.messageType = MessageBaseType.text,
    this.attachmentUrl = '',
    required this.attachmentFile,
    this.mimeType = 'text/plain',
    this.action = sendMessageAction,
    required this.maxLimit,
    required this.searchFromDateTime,
    required this.quotedMessage,
  });

  ChatMessage.fromMap(Map<String, dynamic> map)
      : id = map['id'],
        messageRefId =
            map['messageRefId'] != null ? map['messageRefId'] : null!,
        quotedMessage = map['replayToChatMessage'] != null
            ? ChatMessage.fromMap(map['replayToChatMessage'])
            : null!,
        text = map['text'],
        userToken = map['userToken'],
        backendAddress = map['backendAddress'],
        attachmentUrl = map['attachmentUrl'],
        fileName = map['fileName'],
        createdAt = dateTimeFromSeconds(map['createdAt'])!,
        author =
            map['sender'] != null ? ChatUser.fromMap(map['sender']) : null!,
        messageType = MessageBaseType.values[map['messageType']],
        chatRoom =
            map["target"] != null ? ChatRoom.fromMap(map["target"]) : null!,
        action = map['action'],
        searchFromDateTime = map['searchFromDateTime'] != null
            ? dateTimeFromSeconds(map['searchFromDateTime'])!
            : null!,
        maxLimit = map['maxLimit'] != null ? map['maxLimit'] : 0,
        mimeType = map['mimeType'] {
    if (attachmentUrl.isNotEmpty) {
      TelloLogger().i("attachmentUrl $attachmentUrl");
      final filename = getFilenameFromUrl(attachmentUrl);

      attachmentFile = File('${temporaryDirectory.path}/$filename');
      TelloLogger().i("attachmentFile $attachmentFile");
      if (attachmentFile != null && attachmentFile.existsSync())
        downloadProgress(100);
    }
    if (map['messages'] != null) {
      setMessages(map['messages'] as List<dynamic>);
    }
    if (map['privateMessages'] != null) {
      setMessages(map['privateMessages'] as List<dynamic>, private: true);
    }
    if (map['receivedBy'] != null) {
      setReceivedBy(map['receivedBy'] as List<dynamic>);
    }
    isOutgoing = isFromAppUser(Session.user!.id);
    if (isMine) {
      hasBeenRead = true;
    } else {
      final me = receivedBy.firstWhere((rcvr) => rcvr.id == Session.user!.id,
          orElse: () => null!);
      hasBeenRead = me.hasRead;
    }
  }

  void setReceivedBy(List<dynamic> data) {
    if (data != null) {
      receivedBy = List<ChatClientReceiver>.from(data.map(
        (x) => ChatClientReceiver.fromMap(x as Map<String, dynamic>),
      ));
    }
  }

  void setMessages(List<dynamic> data, {bool private = false}) {
    if (data != null) {
      final list = List<ChatMessage>.from(data.map(
        (x) => ChatMessage.fromMap(x as Map<String, dynamic>),
      ));
      if (private) {
        privateMessages = list;
      } else {
        messages = list;
      }
    }
  }

  Map<String, dynamic> toMap() => {
        "id": id,
        "messageRefId": messageRefId,
        "text": text,
        "attachmentUrl": attachmentUrl,
        "fileName": fileName,
        "createdAt": dateTimeToSeconds(createdAt),
        "sender": author.toMap(),
        "messageType": messageType.index,
        "mimeType": mimeType,
        "target": chatRoom.toMap(),
        "action": action,
        "maxLimit": maxLimit,
        "userToken": Session.authToken,
        "backendAddress": ServiceAddress().baseUrl,
        "searchFromDateTime": searchFromDateTime != null
            ? dateTimeToSeconds(searchFromDateTime)
            : null,
        "replayToChatMessage":
            // ignore: prefer_null_aware_operators
            quotedMessage != null ? quotedMessage.toMap() : null
      };

  ChatMessage copyWith({
    required String id,
    required DateTime createdAt,
    required ChatUser author,
    required ChatRoom chatRoom,
    required String text,
    required MessageBaseType messageType,
    required String attachmentUrl,
    required File attachmentFile,
    required String mimeType,
    required String action,
    required int maxLimit,
    required DateTime searchFromDateTime,
    required ChatMessage quotedMessage,
  }) {
    return ChatMessage(
      id: id,
      createdAt: createdAt,
      author: author,
      chatRoom: chatRoom,
      text: text,
      messageType: messageType,
      attachmentUrl: attachmentUrl,
      attachmentFile: attachmentFile,
      mimeType: mimeType,
      action: action,
      maxLimit: maxLimit,
      searchFromDateTime: searchFromDateTime,
      quotedMessage: quotedMessage,
    );
  }

  factory ChatMessage.createJoinRoomMessage(
      RxGroup group, RxUser user, RxPosition position) {
    return ChatMessage(
        action: joinRoomAction,
        chatRoom: ChatRoom.fromGroup(group),
        author: ChatUser.fromUser(user, position),
        createdAt: DateTime.now().toUtc(),
        messageType: MessageBaseType.other,
        maxLimit: 100,
        searchFromDateTime: DateTime.now().toUtc(),
        attachmentFile: null as File,
        id: '',
        quotedMessage: null as ChatMessage);
  }

  factory ChatMessage.createLeaveRoomMessage(
      RxGroup group, RxUser user, RxPosition position) {
    return ChatMessage(
        action: leaveRoomAction,
        chatRoom: ChatRoom.fromGroup(group),
        author: ChatUser.fromUser(user, position),
        createdAt: DateTime.now().toUtc(),
        attachmentFile: null as File,
        id: '',
        quotedMessage: null as ChatMessage,
        messageType: MessageBaseType.other,
        maxLimit: 0,
        searchFromDateTime: null as DateTime);
  }

  bool isFromAppUser(String appUserId) => author.id == appUserId;
}

class ChatRoom {
  String? id, name, clientId;
  bool? isPrivate;

  ChatRoom({
    required this.id,
    this.name,
    this.clientId,
    this.isPrivate,
  });

  ChatRoom.fromMap(Map<String, dynamic> map)
      : id = map['id'] as String,
        name = map['name'] as String,
        clientId = map['clientId'] as String,
        isPrivate = map['private'] as bool;

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "clientId": clientId,
        "private": isPrivate,
      };

  factory ChatRoom.fromGroup(RxGroup group, {ChatUser? user}) {
    return ChatRoom(
        id: group.id,
        name: group.title,
        clientId: user?.id,
        isPrivate: user?.id != null);
  }
}

class ChatClientReceiver {
  String id, name, positionTitle, positionId;
  bool hasRead = false;

  ChatClientReceiver.fromMap(Map<String, dynamic> map)
      : id = map['id'] as String,
        name = map['name'] as String,
        positionTitle = map['positionTitle'] != null
            ? Uri.decodeQueryComponent(map['positionTitle'])
            : null!,
        positionId = map['positionId'] as String,
        hasRead = map['hasBeenRead'] as bool;

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "positionTitle": positionTitle,
        "positionId": positionId,
        "hasBeenRead": hasRead,
      };
}
