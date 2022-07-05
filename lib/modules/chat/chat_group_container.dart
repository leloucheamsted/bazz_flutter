import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/models/chat_user.dart';
import 'package:bazz_flutter/modules/chat/chat_controller.dart';
import 'package:bazz_flutter/modules/chat/models/chat.dart';
import 'package:get/get.dart';

class ChatGroupContainer {
  ChatGroupContainer({this.groupChat}) {
    setCurrentChat(groupChat!);
  }

  final Chat? groupChat;
  final _privateChatsById$ = <String, Chat>{}.obs;
  late Rx<Chat>? _currentChat$;

  Chat addPrivateChat(Chat chat) => _privateChatsById$[chat.id] = chat;

  void setCurrentChat(Chat chat) => _currentChat$!(chat);

  Map<String, Chat> get privateChats$ => _privateChatsById$();

  Chat get currentChat$ => _currentChat$!();

  bool get hasPrivateChats$ => _privateChatsById$.isNotEmpty;

  bool get hasNoPrivateChats$ => _privateChatsById$.isEmpty;

  List<Chat> get chats => [groupChat!, ...privateChats$.values];

  int get totalUnseen {
    return groupChat!.unseenCounter$ +
        _privateChatsById$()
            .values
            .fold<int>(0, (acc, chat) => acc + chat.unseenCounter$);
  }

  void insertMessage(ChatMessage message) {
    if (message.isPrivate) {
      insertIntoPrivateChat(message.interlocutor.id, [message]);
    } else {
      insertSingleIntoGroupChat(message);
    }
  }

  void insertAllMessages(ChatMessage data, {bool atTheEnd = false}) {
    if (data.messages.isNotEmpty) {
      // Pending messages (sent during offline) should stay on top
      final lastPendingIndex =
          groupChat!.items.lastIndexWhere((i) => i.isPending);
      final targetIndex = atTheEnd
          ? groupChat!.items.length
          : lastPendingIndex > -1
              ? lastPendingIndex + 1
              : 0;

      for (final msg in data.messages) {
        final isTheSame = groupChat!.items.any((item) => item.id == msg.id);

        if (!isTheSame) {
          groupChat!.insertAll(targetIndex, [msg]);
        }
      }
    }

    if (data.privateMessages.isNotEmpty) {
      final privateMessagesById = <String, List<ChatMessage>>{};

      // Sorting and inserting private messages into corresponding chats
      for (final msg in data.privateMessages) {
        final targetList = privateMessagesById[msg.interlocutor.id] ??= [];
        targetList.add(msg);
        insertIntoPrivateChat(msg.interlocutor.id, targetList,
            atTheEnd: atTheEnd);
      }
    }
  }

  void insertSingleIntoGroupChat(ChatMessage message) {
    // Pending messages (sent during offline) should stay on top
    final lastPendingIndex =
        groupChat!.items.lastIndexWhere((i) => i.isPending);
    final targetIndex = lastPendingIndex > -1 ? lastPendingIndex + 1 : 0;
    groupChat!.insertAll(targetIndex, [message]);
  }

  void insertIntoPrivateChat(String interlocutorId, List<ChatMessage> messages,
      {bool atTheEnd = false}) {
    if (messages.isEmpty) return;

    final privateChat = _privateChatsById$[interlocutorId] ??
        addPrivateChat(Chat(
          ChatController.to,
          interlocutorId,
          interlocutor: messages.first.interlocutor,
        ));

    for (final msg in messages) {
      final isTheSame = privateChat.items.any((item) => item.id == msg.id);
      // Pending messages (sent during offline) should stay on top
      final lastPendingIndex =
          privateChat.items.lastIndexWhere((i) => i.isPending);
      final targetIndex = atTheEnd
          ? privateChat.items.length
          : lastPendingIndex > -1
              ? lastPendingIndex + 1
              : 0;

      if (!isTheSame) {
        privateChat.insertAll(targetIndex, [msg]);
      }
    }
  }

  void selectPrivateChat(ChatUser chatUser) {
    final privateChat = _privateChatsById$[chatUser.id] ??
        addPrivateChat(Chat(
          ChatController.to,
          chatUser.id,
          interlocutor: chatUser,
        ));
    setCurrentChat(privateChat);
  }

  void selectGroupChat() {
    setCurrentChat(groupChat!);
  }
}
