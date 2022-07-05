import 'dart:convert';

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/models/chat_user.dart';
import 'package:bazz_flutter/models/group_model.dart';
import 'package:bazz_flutter/modules/chat/chat_controller.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/enums.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

class NotificationService extends GetxController {
  static NotificationService get to => Get.find();
  static NotificationService? instance;

  final notificationGroups = <NotificationGroup>{}.obs;

  @override
  void onInit() {
    final rawData = GetStorage().read(StorageKeys.notifications);
    final savedNotifications = <Notification>[];
    if (rawData != null) {
      savedNotifications.addAll(
          (json.decode(rawData as String) as List<dynamic>)
              .map((e) => Notification.fromMap(e as Map<String, dynamic>)));
      for (final notification in savedNotifications) {
        add(notification, doNotSaveLocally: true);
      }
      Get.showSnackbar(
        GetBar(
          title: '${savedNotifications.length} new notifications',
          message: 'Tap to see more',
          snackPosition: SnackPosition.TOP,
          onTap: (_) {
            if (Get.isSnackbarOpen) Get.back();
            HomeController.to.notificationsDrawerController.open();
          },
        ),
      );
    }
    super.onInit();
    instance = this;
  }

  static Notification createChatNotification(ChatMessage message) {
    final title = '${message.chatRoom.name}: ${message.author.name}';
    Widget? icon;
    String text = '';

    if (message.messageType == MessageBaseType.text) {
      text = message.text;
    } else if (message.messageType == MessageBaseType.image) {
      icon = const Center(
        child: FaIcon(FontAwesomeIcons.image),
      );
      text = 'Image file';
    } else if (message.messageType == MessageBaseType.video) {
      icon = const Center(
        child: FaIcon(FontAwesomeIcons.film),
      );
      text = 'Video file';
    } else if (message.messageType == MessageBaseType.pdf) {
      icon = const Center(
        child: FaIcon(FontAwesomeIcons.filePdf),
      );
      text = 'Pdf file';
    }

    final chatMessageData = {
      'isPrivate': message.isPrivate,
      'author': message.author.toMap(),
    };
    return Notification(
      id: message.id,
      srcGroupId: message.chatRoom.id,
      icon: icon!,
      title: title,
      text: text,
      bgColor: Colors.grey.withOpacity(0.2),
      callback: () => Notification.chatNotificationCallback(
        isPrivate: message.isPrivate,
        author: message.author,
        srcGroupId: message.chatRoom.id,
      ),
      chatMessageData: chatMessageData,
      groupType: NotificationGroupType.chat,
    );
  }

  void add(Notification notification,
      {bool allowBodyDuplicates = true, bool doNotSaveLocally = false}) {
    NotificationGroup group = notificationGroups.firstWhere(
      (group) => group.type == notification.groupType,
      orElse: () => null as NotificationGroup,
    );

    if (group != null) {
      final canAdd =
          allowBodyDuplicates || group.isNotificationBodyUnique(notification);
      if (canAdd) {
        group.add(notification);
        notificationGroups.refresh();
      }
    } else {
      group = NotificationGroup(notification.groupType)..add(notification);
      notificationGroups.add(group);
    }

    if (doNotSaveLocally) return;

    List<dynamic> savedNotifications = [];
    final rawData = GetStorage().read(StorageKeys.notifications);
    if (rawData != null) {
      savedNotifications = json.decode(rawData as String) as List<dynamic>;
    }
    savedNotifications.add(notification.toMap());
    GetStorage()
        .write(StorageKeys.notifications, json.encode(savedNotifications));
  }

  /// Ids must be from one group!
  void removeNotifications(List<String> ids) {
    assert(ids.isNotEmpty);
    if (ids.isEmpty) return;

    final targetGroup = notificationGroups.firstWhere(
      (group) => group.notifications.any((n) => n.id == ids.first),
      orElse: () => null as NotificationGroup,
    );

    if (targetGroup == null) {
      TelloLogger()
          .i('removeNotifications() targetGroup not found, returning...');
      return;
    }

    for (final id in ids) {
      targetGroup.notifications.removeWhere((n) => n.id == id);
    }

    if (targetGroup.notifications.isEmpty) {
      removeGroup(targetGroup);
    } else {
      notificationGroups.refresh();
    }

    List<dynamic> savedNotifications = [];
    final rawData = GetStorage().read(StorageKeys.notifications);
    if (rawData != null) {
      savedNotifications = json.decode(rawData as String) as List<dynamic>;
    }

    for (final id in ids) {
      savedNotifications.removeWhere((element) {
        return (element as Map<String, dynamic>)['id'] == id;
      });
    }

    GetStorage().write(
      StorageKeys.notifications,
      savedNotifications.isNotEmpty ? json.encode(savedNotifications) : null,
    );
  }

  void removeGroup(NotificationGroup group) {
    notificationGroups.remove(group);
    List<dynamic> savedNotifications = [];
    final rawData = GetStorage().read(StorageKeys.notifications);
    if (rawData != null) {
      savedNotifications = json.decode(rawData as String) as List<dynamic>;
    }
    final filteredNotifications = savedNotifications.where((element) {
      return (element as Map<String, dynamic>)['groupType'] != group.type.index;
    }).toList();

    GetStorage().write(
      StorageKeys.notifications,
      filteredNotifications.isNotEmpty
          ? json.encode(filteredNotifications)
          : null,
    );
  }

  void clearAll() {
    notificationGroups.clear();
    GetStorage().remove(StorageKeys.notifications);
    HomeController.to.notificationsDrawerController.close();
  }
}

class Notification {
  String? id;
  final String? srcGroupId;
  final String title, text;
  final Color bgColor;
  VoidCallback? callback;
  Widget? icon = const Icon(Icons.info_outline_rounded);
  final Widget? mainButton;
  final NotificationGroupType groupType;
  final Map<String, dynamic>? chatMessageData;
  DateTime messageTime = DateTime.now();

  Notification({
    required this.title,
    required this.text,
    required this.bgColor,
    required this.groupType,
    this.srcGroupId,
    this.icon,
    this.callback,
    this.mainButton,
    this.id,
    this.chatMessageData,
  }) {
    id ??= Uuid().v1();
  }

  static Future<void> chatNotificationCallback(
      {bool? isPrivate, ChatUser? author, String? srcGroupId}) async {
    final fromOtherGroup = srcGroupId != HomeController.to.activeGroup.id;
    final targetGroup = fromOtherGroup
        ? HomeController.to.groups.firstWhere(
            (gr) => gr.id == srcGroupId,
            orElse: () => null as RxGroup,
          )
        : null;

    ChatController.to.showCurrentChat = true;

    final targetChatGroupContainer =
        ChatController.to.chatGroupContainers[srcGroupId];

    if (isPrivate!) {
      ChatController.to.setPrivateUser(author!);
      targetChatGroupContainer!.selectPrivateChat(author);
    } else {
      ChatController.to.setPrivateUser(null as ChatUser);
      targetChatGroupContainer!.selectGroupChat();
    }

    if (fromOtherGroup) {
      HomeController.to.setActiveGroup(targetGroup!);
    }

    if (!HomeController.to.isChatVisible) {
      HomeController.to.gotoBottomNavTab(BottomNavTab.chat);
    }

    HomeController.to.notificationsDrawerController.close();
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'text': text,
      'bgColor': bgColor.value,
      'groupType': groupType.index,
      'messageTime': messageTime.toIso8601String(),
      'srcGroupId': srcGroupId,
      'chatMessageData': chatMessageData,
    };
  }

  factory Notification.fromMap(Map<String, dynamic> map) {
    final groupType = NotificationGroupType.values[map["groupType"] as int];
    final srcGroupId = map["srcGroupId"] as String;
    Widget icon;
    VoidCallback? callback;
    switch (groupType) {
      case NotificationGroupType.chat:
        final isPrivate = map['chatMessageData']['isPrivate'] as bool;
        final author = ChatUser.fromMap(
            map['chatMessageData']['author'] as Map<String, dynamic>);

        icon = const Center(
          child: Icon(Icons.message, color: Colors.white),
        );
        callback = () => chatNotificationCallback(
            isPrivate: isPrivate, author: author, srcGroupId: srcGroupId);
        break;
      case NotificationGroupType.broadcast:
        icon = const Center(
          child: FaIcon(
            FontAwesomeIcons.broadcastTower,
            size: 20,
          ),
        );
        callback = () async {
          final targetGroup = HomeController.to.groups.firstWhere(
            (gr) => gr.id == srcGroupId,
            orElse: () => null as RxGroup,
          );

          if (targetGroup == null) return;

          await HomeController.to.setActiveGroup(targetGroup);
          HomeController.to
            ..gotoBottomNavTab(BottomNavTab.ptt)
            ..notificationsDrawerController.close();
        };
        break;
      case NotificationGroupType.systemEvents:
        icon = const Icon(Icons.warning_amber_rounded,
            color: AppColors.brightIcon);
        callback = () async {
          final targetGroup = HomeController.to.groups.firstWhere(
              (gr) => gr.id == srcGroupId,
              orElse: () => null as RxGroup);
          if (targetGroup != null) {
            await HomeController.to.setActiveGroup(targetGroup);
            HomeController.to
              ..gotoBottomNavTab(BottomNavTab.events)
              ..notificationsDrawerController.close();
          }
        };
        break;
      default:
        icon = const Icon(Icons.info_outline_rounded);
    }
    return Notification(
      id: map['id'] as String,
      title: map["title"] as String,
      text: map["text"] as String,
      bgColor: Color(map["bgColor"] as int),
      srcGroupId: srcGroupId,
      groupType: groupType,
    )
      ..messageTime = DateTime.parse(map["messageTime"] as String)
      ..icon = icon
      ..callback = callback;
  }
}

class NotificationGroup {
  final String id = Uuid().v1();
  final notifications = <Notification>[].obs;
  final NotificationGroupType type;
  final ExpandableController expandableController = ExpandableController();

  int get length => notifications.length;

  bool isNotificationBodyUnique(Notification notification) =>
      notifications.every((nf) => nf.text != notification.text);

  NotificationGroup(this.type);

  void add(Notification notification) {
    notifications.insert(0, notification);
    if (notifications.length > 100) notifications.removeLast();
  }
}
