import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:advance_pdf_viewer/advance_pdf_viewer.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/main.dart';
import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/models/chat_user.dart';
import 'package:bazz_flutter/models/group_model.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/modules/chat/chat_group_container.dart';
import 'package:bazz_flutter/modules/chat/chat_repo.dart';
import 'package:bazz_flutter/modules/chat/models/chat.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/enums.dart';
import 'package:bazz_flutter/modules/chat/widgets/chat_video_player.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import "package:bazz_flutter/services/chat_signaling.dart";
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/notification_service.dart' as ns;
import 'package:bazz_flutter/services/sound_pool_service.dart';
import 'package:bazz_flutter/services/vibrator.dart';
import 'package:bazz_flutter/shared_widgets/system_dialog.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart' as mime;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:uuid/uuid.dart';
import 'package:video_compress/video_compress.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_viewer/domain/entities/video_source.dart';
import 'package:video_viewer/video_viewer.dart';
import 'package:visibility_detector/visibility_detector.dart';

///Each group, despite having one group chat and multiple private ones (if there are any), has only one chat room
///(for historical reasons). So we get our group messages in one field and add them in a group chat,
///and all private messages in another separate field, and sort them by participants,
///forming private chats in ChatGroupContainer
class ChatController extends GetxController {
  static ChatController get to =>
      Get.isRegistered<ChatController>() ? Get.find() : null!;
  final ChatRepository _repo = ChatRepository();
  GetStorage? _readOfflineChatMessagesBox;

  static const requestedMessagesLimit = 100;

  ///Holds chat groups for all groups
  final Map<String, ChatGroupContainer> chatGroupContainers = {};

  ///Holds current chat group (a group of chats for the active group)
  late Rx<ChatGroupContainer>? _currentChatGroupContainer$;

  ChatGroupContainer get currentChatGroupContainer$ =>
      _currentChatGroupContainer$!();

  void setCurrentChatGroupContainer(ChatGroupContainer chatContainer) =>
      _currentChatGroupContainer$!(chatContainer);

  String? currentChatId;

  bool showCurrentChat = false;

  bool get isCurrentChatEmpty =>
      _currentChatGroupContainer$!().currentChat$.isEmpty;
  rx.ValueConnectableStream<int>? totalUnseen$;
  StreamSubscription? _totalUnseenSub;

  final pageController = PageController(keepPage: false);
  final currentPageIndex = 0.obs;

  bool get displayChatTitle$ => currentPageIndex() == 1;

  final TextEditingController inputController = TextEditingController();
  final ItemScrollController itemScrollCtrl = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();

  late double _currentScrollPosition;
  late double _startScrollPosition;

  final _picker = ImagePicker();
  File? selectedFile;

  late Rx<ChatMessage> quotedMessage$;

  ChatMessage get quotedMessage => quotedMessage$.value;

  void clearQuotedMessage() => quotedMessage$;

  final RxBool _isGoToBottomVisible$ = false.obs;

  bool get isGoToBottomVisible$ => _isGoToBottomVisible$();
  RxBool isDateLabelVisible$ = false.obs;
  Completer connected = Completer();
  RxBool isConnecting$ = true.obs;
  bool didAllGroupsJoin = false;
  ChatMessage? _uploadingMessage;

  final usersTyping$ = <String>[].obs;

  bool get isUploading => _uploadingMessage != null;

  StreamSubscription? _activeGroupSub;
  StreamSubscription? _groupsSub;
  StreamSubscription? _isConnectingSub;

  final Map<String, ChatMessage> _downloadingTasks = {};
  final Set<ChatMessage> _visibleMessages = {};
  final joinedGroups = <String>[];
  Rx<DateTime>? floatingDateTime$;

  final _port = ReceivePort();

  Timer? _showDateTimeLabelDebounceTimer;
  Timer? _deleteNotificationsDebounceTimer;

  final notificationsToDeleteQueue = <String>[];

  CancelToken uploadingCancelToken = CancelToken();

  bool isReceivedByPopupOpen = false;

  Rx<ChatUser>? _privateUser$;

  ChatUser get privateUser => _privateUser$!.value;

  void setPrivateUser(ChatUser value) {
    value == null ? null : _privateUser$!(value);
  }

  bool canTrackUnread = false;

  final messageHistoryLoading$ = false.obs;

  //Timer _joinGroupsTimer;

  @override
  Future<void> onInit() async {
    TelloLogger().i(
        "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@initChatController START ${currentChatGroupContainer$},, ${isDateLabelVisible$}");

    _readOfflineChatMessagesBox =
        GetStorage(StorageKeys.readOfflineChatMessagesBox);
    _bindBackgroundIsolate();
    ChatSignaling().onStateChange = handleChatState;
    pageController.addListener(() {
      currentPageIndex(pageController.page!.truncate());
    });

    ///the floating DateLabel needs that
    VisibilityDetectorController.instance.updateInterval =
        const Duration(milliseconds: 100);
    TelloLogger().i("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@initChatController end");

    _isConnectingSub = isConnecting$.listen((connecting) {
      if (connecting) return;

      final messages =
          _readOfflineChatMessagesBox!.getValues<Iterable<dynamic>>();

      for (final msg in messages) {
        final message = msg as Map<String, dynamic>;
        TelloLogger().i(
            'ChatController onInit(): sending offline read message id: ${message['id']}');
        ChatSignaling().send(message);
      }
      _readOfflineChatMessagesBox!.erase();
    });

    super.onInit();
  }

  @override
  Future<void> onClose() async {
    TelloLogger().i("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@CHAT CONTROLLER ON CLOSE");
    _showDateTimeLabelDebounceTimer?.cancel();
    _deleteNotificationsDebounceTimer?.cancel();
    pageController.dispose();
    inputController.dispose();
    _totalUnseenSub?.cancel();
    _activeGroupSub?.cancel();
    _groupsSub?.cancel();
    _isConnectingSub?.cancel();
    _unbindBackgroundIsolate();
    //_joinGroupsTimer.cancel();
    ChatSignaling().dispose();
    TelloLogger()
        .i("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@CHAT CONTROLLER ON CLOSE DONE");
    super.onClose();
  }

  ///We re-init each chat for each group every time we go online
  Future<void> initChats(List<RxGroup> groups, RxGroup activeGroup) async {
    TelloLogger().i(
        "loadChatController with groups ==>  ${HomeController.to.groups.length}");
    for (final group in groups) {
      chatGroupContainers[group.id!] ??= ChatGroupContainer(
          groupChat: Chat(to, group.id!, interlocutor: null as ChatUser));
    }

    TelloLogger().i("loadChatController end INIT");

    await ChatSignaling().init();

    _activeGroupSub =
        HomeController.to.activeGroup$.listen((activeGroup) async {
      if (activeGroup == null) return;
      setCurrentChatGroupContainer(chatGroupContainers[activeGroup.id]!);
    });

    if (HomeController.to.activeGroup$() != null) {
      setCurrentChatGroupContainer(
          chatGroupContainers[HomeController.to.activeGroup$().id]!);
    }

    itemPositionsListener.itemPositions.addListener(() {
      if (canTrackUnread) _markVisibleMessagesRead();
    });
  }

  void resetCurrentChatPageIndex() => currentPageIndex(0);

  Future<void> disconnect() {
    TelloLogger().i("ChatController disconnecting rooms...");
    return ChatSignaling().leaveGroupsFromChat();
  }

  void _bindBackgroundIsolate() {
    final removePortNameMappingSuccess =
        IsolateNameServer.removePortNameMapping('downloader_send_port');
    TelloLogger().i(
        'ChatController _bindBackgroundIsolate(): removePortNameMappingSuccess: $removePortNameMappingSuccess');
    final registerPortWithNameSuccess = IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port');
    TelloLogger().i(
        'ChatController _bindBackgroundIsolate(): registerPortWithNameSuccess: $registerPortWithNameSuccess');
    _port.listen((dynamic data) {
      final String taskId = data[0] as String;
      final DownloadTaskStatus status = data[1] as DownloadTaskStatus;
      final int progress = data[2] as int;
      final message = _downloadingTasks[taskId];

      TelloLogger().i(
          'Downloading status: taskId: $taskId, status: $status, progress: $progress');

      if (status == DownloadTaskStatus.running) {
        message!.isDownloading(true);
        message.downloadProgress(progress);
      }

      if (status == DownloadTaskStatus.canceled ||
          status == DownloadTaskStatus.failed) {
        message!.downloadProgress(0);
        message.isDownloading(false);
        _downloadingTasks.remove(taskId);
        FlutterDownloader.remove(taskId: taskId, shouldDeleteContent: true);
      }

      if (status == DownloadTaskStatus.complete) {
        message!.downloadProgress(100);
        message.isDownloading(false);
        _downloadingTasks.remove(taskId);
        FlutterDownloader.remove(taskId: taskId);
      }

      TelloLogger().i('_downloadingTasks: ${_downloadingTasks.length}');
    });
  }

  void _unbindBackgroundIsolate() {
    _port.close();
    IsolateNameServer.removePortNameMapping('downloader_send_port');
  }

  Future<void> handleChatState(
      ChatSignalingState state, ChatMessage message) async {
    switch (state) {
      case ChatSignalingState.MessageError:
        final getBar = GetBar(
          title: LocalizationService().of().error,
          message: message.text,
          duration: const Duration(seconds: 10),
          animationDuration: const Duration(milliseconds: 500),
          // backgroundColor: Colors.black26,
        );

        Get.showSnackbar(getBar);
        break;
      case ChatSignalingState.MessageArrived:
        //FIXME: check why chatMessage can be null
        if (message == null) break;
        TelloLogger().i("MESSAGE ARRIVED");
        TelloLogger().i(message.toMap().toString());

        if (message.isNotMine) {
          final targetChatGroupContainer =
              chatGroupContainers[message.chatRoom.id];
          final fromOtherGroup =
              message.chatRoom.id != HomeController.to.activeGroup.id;
          final fromOtherChat = message.isPrivate
              ? currentChatGroupContainer$.currentChat$.id != message.author.id
              : currentChatGroupContainer$.currentChat$.id !=
                  message.chatRoom.id;

          if (!HomeController.to.isChatVisible ||
              pageController.page == 0 ||
              fromOtherGroup ||
              fromOtherChat) {
            _showNotification(message, isFromOtherGroup: fromOtherGroup);
          }
          targetChatGroupContainer!.insertMessage(message);
        }

        break;
      case ChatSignalingState.UserJoined:
        TelloLogger().i("USER JOINED");

        break;
      case ChatSignalingState.UserLeft:
        TelloLogger().i("USER LEFT");
        break;
      case ChatSignalingState.ConnectionError:
      case ChatSignalingState.ConnectionClosed:
        TelloLogger().i("CONNECTION CLOSED");
        isConnecting$(true);
        connected = Completer();
        joinedGroups.clear();
        break;
      case ChatSignalingState.StartTyping:
        TelloLogger().i("START TYPING ALL");
        if (message.author.id != Session.user!.id) {
          if (!usersTyping$.contains(message.author.name)) {
            usersTyping$.addAll([message.author.name]);
          }
          TelloLogger().i("START TYPING ${message.author.name}");
        }
        break;
      case ChatSignalingState.StopTyping:
        TelloLogger().i("STOP TYPING ALL");
        if (message.author.id != Session.user!.id) {
          usersTyping$.clear();
          TelloLogger().i("STOP TYPING");
        }
        break;
      case ChatSignalingState.ConnectionOpen:
        TelloLogger().i("CONNECTION OPEN");
        ChatSignaling().joinGroupsToChat(HomeController.to.groups);
        break;
      case ChatSignalingState.RoomJoined:
        TelloLogger().i(
            "ROOM JOINED ===> ${message.chatRoom.id} / ${message.chatRoom.name}."
            " Active group: ${HomeController.to.activeGroup.title}");
        TelloLogger()
            .i("chatMessage.messages.length ===> ${message.messages.length}");

        if (message.messages.isNotEmpty || message.privateMessages.isNotEmpty) {
          // chatGroupContainers[message.chatRoom.id].groupChat.removeSelectedItems();
          TelloLogger().i(
              "ROOM JOINED chatMessage.messages ===> ${message.messages.length}");

          chatGroupContainers[message.chatRoom.id]!.insertAllMessages(message);

          // messages.forEach((element) {
          //   if (chats[message.chatRoom.id].items.firstWhere((msg) => msg.id == element.id, orElse: () => null) ==
          //       null) {
          //     chats[message.chatRoom.id].insertAll(
          //       chats[message.chatRoom.id].items.length,
          //       [element],
          //     );
          //   }
          // });
          /*if (message.messages.isNotEmpty) {
            chats[message.chatRoom.id].removeSelectedItems();
            Logger().log("ROOM JOINED chatMessage.messages ===> ${message.messages.length}");
            final messages = message.messages.reversed.toList();
            messages.forEach((element) {
              if(chats[message.chatRoom.id].items.firstWhere((msg) => msg.id ==element.id,orElse: () => null ) == null){
                chats[message.chatRoom.id].insertAll(
                  chats[message.chatRoom.id].items.length,
                  [element],
                );
              }
            });*/
        }

        joinedGroups.add(message.chatRoom.id!);

        if (joinedGroups.length == HomeController.to.groups.length)
          didAllGroupsJoin = true;

        if (message.chatRoom.id == HomeController.to.activeGroup.id) {
          isConnecting$(false);
          if (!connected.isCompleted) connected.complete();
        }
        break;
      case ChatSignalingState.GetMessages:
        final messages = message.messages.isNotEmpty
            ? message.messages
            : message.privateMessages;
        TelloLogger().i("messages length ===> ${messages.length}");

        final targetContainer =
            chatGroupContainers[HomeController.to.activeGroup.id];
        targetContainer!.currentChat$.allMessagesLoaded =
            messages.length != ChatController.requestedMessagesLimit;
        targetContainer.insertAllMessages(message, atTheEnd: true);
        messageHistoryLoading$(false);
        break;
      case ChatSignalingState.FailedMessage:
        break;
      case ChatSignalingState.ReceivedByClients:
        final targetMessage =
            currentChatGroupContainer$.currentChat$.getById(message.id);
        if (targetMessage == null) break;

        targetMessage.receivedBy = message.receivedBy;
        update(['received-by-icon${message.id}']);
        // currentChat$().updateItem(targetMessage);
        break;
    }
  }

  void _showNotification(ChatMessage message,
      {required bool isFromOtherGroup}) {
    final chatNotification =
        ns.NotificationService.createChatNotification(message);

    Future<void> snackBarCallback([_]) async {
      await SoundPoolService().stopMessageReceivedSound();
      if (Get.isSnackbarOpen) Get.back();
      chatNotification.callback!();
    }

    final getBar = GetBar(
      title: chatNotification.title,
      message: chatNotification.text.isNotEmpty ? chatNotification.text : ' ',
      icon: chatNotification.icon,
      duration: const Duration(seconds: 10),
      animationDuration: const Duration(milliseconds: 500),
      // backgroundColor: Colors.black26,
      onTap: snackBarCallback,
      snackbarStatus: (status) {
        if (status == SnackbarStatus.CLOSED) {
          Vibrator.stopNotificationVibration();
        } else if (status == SnackbarStatus.OPEN) {
          Vibrator.startNotificationVibration();
        }
      },
    );

    SoundPoolService().playMessageReceivedSound();

    if (Get.isSnackbarOpen) Get.back();
    // Get.showSnackbar(getBar).whenComplete(() async {
    //   await SoundPoolService().stopMessageReceivedSound();
    // });

    ns.NotificationService.to.add(chatNotification);
  }

  Future<void> sendMessageHistoryRequest() async {
    if (messageHistoryLoading$()) return;

    messageHistoryLoading$(true);

    ChatSignaling().sendV2(
      method: 'ListMessage',
      data: {
        'roomId': HomeController.to.activeGroup.id,
        'targetClientId': currentChatGroupContainer$.currentChat$.isPrivate
            ? currentChatGroupContainer$.currentChat$.id
            : '',
        'pagination': {
          'take': requestedMessagesLimit,
          'skip': currentChatGroupContainer$.currentChat$.length,
        },
      },
      onTimeout: () => messageHistoryLoading$(false),
    );
  }

  void typingCallback(TypingEvent event) {
    if (isConnecting$()) return;

    final chatMessage = ChatMessage(
      id: Uuid().v1(),
      author: ChatUser.fromUser(Session.user!, Session.shift?.currentPosition),
      action: ChatMessage.startTypingAction,
      createdAt: DateTime.now().toUtc(),
      chatRoom:
          ChatRoom.fromGroup(HomeController.to.activeGroup, user: privateUser),
      attachmentFile: null as File,
      maxLimit: null as int,
      quotedMessage: null as ChatMessage,
      searchFromDateTime: null as DateTime,
    );

    if (event == TypingEvent.stop)
      chatMessage.action = ChatMessage.stopTypingAction;

    ChatSignaling().sendMessage(chatMessage);
  }

  void sendMessage(String text, ChatMessage quotedMessage) {
    TelloLogger().i('sendMessage ====> 0000');
    final activeGroup = HomeController.to.activeGroup;
    if (activeGroup == null) return;
    TelloLogger().i(
        'sendMessage ====> 11111 private user ${privateUser.id} ${privateUser.name}');
    final message = ChatMessage(
      id: Uuid().v1(),
      author: ChatUser.fromUser(Session.user!, Session.shift?.currentPosition),
      text: text,
      createdAt: DateTime.now().toUtc(),
      chatRoom:
          ChatRoom.fromGroup(HomeController.to.activeGroup, user: privateUser),
      attachmentFile: null as File,
      maxLimit: null as int,
      quotedMessage: null as ChatMessage,
      searchFromDateTime: null as DateTime,
      //quotedMessage: quotedMessage,
    )
      ..hasBeenRead = true
      ..isPending = isConnecting$();

    currentChatGroupContainer$.currentChat$.insertAll(0, [message]);
    clearQuotedMessage();
    if (isConnecting$.isFalse) ChatSignaling().sendMessage(message);
  }

  void resendMessage(ChatMessage message) {
    TelloLogger()
        .i('resendMessage() message id: ${message.id}, text: ${message.text}');
    final currentChat = currentChatGroupContainer$.currentChat$;

    //Can be positive only (or -1)
    final indexOfLastSent =
        currentChat.items.indexWhere((msg) => msg.isPending == false);
    final noSentMessages = indexOfLastSent == -1;
    final pendingMessages =
        currentChat.items.sublist(0, noSentMessages ? null : indexOfLastSent);
    final currentMessageIndex =
        pendingMessages.indexWhere((msg) => msg.id == message.id);
    final isPendingMsgFirstInQueue =
        currentMessageIndex == pendingMessages.length - 1;

    if (!isPendingMsgFirstInQueue) {
      //rearranging current message to be the first in queue
      currentChat.items.removeRange(
          0, noSentMessages ? currentChat.items.length : indexOfLastSent);
      final msg = pendingMessages.removeAt(currentMessageIndex);
      pendingMessages.insert(pendingMessages.length, msg);
      currentChat.items.insertAll(0, pendingMessages);
    }

    if (isConnecting$.isFalse) {
      currentChat.updateItem(message
        ..isPending = false
        ..createdAt = DateTime.now().toUtc());
      // Logger().log('Message sent');
      ChatSignaling().sendMessage(message);
    }
  }

  void deletePending(String id) {
    final targetItem = currentChatGroupContainer$.currentChat$.getById(id);
    currentChatGroupContainer$.currentChat$.removeItem(targetItem);
  }

  Future<void> uploadFile() async {
    final activeGroup = HomeController.to.activeGroup;
    if (activeGroup == null) return;

    MessageBaseType messageType;
    final mimeType = mime.lookupMimeType(selectedFile!.path);
    var fileName = getFilenameFromUrl(selectedFile!.path);

    if (mimeType!.startsWith('image')) {
      messageType = MessageBaseType.image;
    } else if (mimeType.startsWith('video')) {
      messageType = MessageBaseType.video;
    } else if (mimeType.startsWith('audio')) {
      messageType = MessageBaseType.audio;
    } else if (mimeType.startsWith('application/pdf')) {
      messageType = MessageBaseType.pdf;
    } else {
      messageType = MessageBaseType.other;
    }

    final message = ChatMessage(
      id: Uuid().v1(),
      author: ChatUser.fromUser(Session.user!, Session.shift?.currentPosition),
      messageType: messageType,
      mimeType: mimeType,
      createdAt: DateTime.now().toUtc(),
      chatRoom:
          ChatRoom.fromGroup(HomeController.to.activeGroup, user: privateUser),
      attachmentFile: null as File,
      maxLimit: null as int,
      quotedMessage: null as ChatMessage,
      searchFromDateTime: null as DateTime,
    )..isUploading(true);

    currentChatGroupContainer$.currentChat$.insertAll(0, [message]);

    _uploadingMessage =
        currentChatGroupContainer$.currentChat$.getById(message.id);

    try {
      TelloLogger().i("The selected file ${selectedFile!.path}");
      Subscription? subscription;
      if (messageType == MessageBaseType.video) {
        _uploadingMessage!.isCompressing(true);
        try {
          subscription = VideoCompress.compressProgress$.subscribe((progress) {
            _uploadingMessage!.uploadProgress(progress.round());
          });

          _uploadingMessage!.uploadProgress(0);

          final info = await VideoCompress.compressVideo(selectedFile!.path,
              quality: VideoQuality.LowQuality, deleteOrigin: true);

          TelloLogger().i("AFTER COMPRESSING VIDEO ${info!.path}");
          fileName = getFilenameFromUrl(info.path!);
          final File compressedFile = File(info.path!);
          selectedFile = compressedFile;
          TelloLogger().i("AFTER COPY COMPRESSING VIDEO ${selectedFile!.path}");
        } catch (e, s) {
          TelloLogger().e('error while compressing video: $e', stackTrace: s);
          currentChatGroupContainer$.currentChat$
              .removeItem(_uploadingMessage!);
        } finally {
          subscription!.unsubscribe();
          _uploadingMessage!.isCompressing(false);
          _uploadingMessage!.uploadProgress(0);
        }
      }

      final fileExistsInCache =
          File('${temporaryDirectory.path}/$fileName').existsSync();
      if (!fileExistsInCache)
        selectedFile =
            selectedFile!.copySync('${temporaryDirectory.path}/$fileName');

      final signedUrlResponse = await _repo.getSignedUrl(fileName);
      if (signedUrlResponse == null) throw 'signedUrlResponse is null!';

      _uploadingMessage!
        ..attachmentUrl = signedUrlResponse.publicUrl
        ..fileName = fileName
        ..attachmentFile = selectedFile!;

      await _repo.uploadFile(
        signedUrlResponse.signedUrl,
        mimeType,
        selectedFile!,
        (sent, total) {
          final progress = (sent / total * 100).toInt();
          _uploadingMessage!.uploadProgress(progress);
          if (progress == 100) _uploadingMessage!.isUploading(false);
        },
        uploadingCancelToken,
      );

      currentChatGroupContainer$.currentChat$.updateItem(_uploadingMessage!);
      message.attachmentUrl = signedUrlResponse.publicUrl;
      ChatSignaling().sendMessage(message);
    } catch (e, s) {
      TelloLogger().e('error while uploading chat message attachment: $e',
          stackTrace: s);
      currentChatGroupContainer$.currentChat$.removeItem(_uploadingMessage!);
    } finally {
      _uploadingMessage = null;
      selectedFile = null;
    }
  }

  Future<String?> uploadVideoThumbnail(File videoPath) async {
    try {
      final thumbnailFilePath = await VideoThumbnail.thumbnailFile(
        video: videoPath.path,
        thumbnailPath: (await getExternalStorageDirectory())!.path,
        imageFormat: ImageFormat.PNG,
        maxWidth: 300,
        maxHeight: 240,
        // specify the width of the thumbnail, let the height auto-scaled to keep the source aspect ratio
        quality: 10,
      ).timeout(const Duration(seconds: 5), onTimeout: () {
        return "no data";
      });

      TelloLogger().i(
          "thumbnailFilePath====> $thumbnailFilePath ,,, ${(await getExternalStorageDirectory())!.path}");

      final signedUrlResponse = await _repo.getSignedUrl(thumbnailFilePath!);
      if (signedUrlResponse == null) throw 'signedUrlResponse is null!';
      final mimeType = mime.lookupMimeType(thumbnailFilePath);
      await _repo.uploadFile(
        signedUrlResponse.signedUrl,
        mimeType!,
        selectedFile!,
        (sent, total) {},
        uploadingCancelToken,
      );
    } catch (e, s) {
      TelloLogger().e("Loading _videoThumbnail err ===> $e", stackTrace: s);
      return "no data";
    }
    return null;
  }

  void cancelUploading(ChatMessage message) {
    uploadingCancelToken.cancel('Cancelled by user');
    uploadingCancelToken = CancelToken();
    currentChatGroupContainer$.currentChat$.removeItem(message);
  }

  Future<void> downloadFile(ChatMessage message) async {
    final fileName = getFilenameFromUrl(message.fileName);

    final taskId = await FlutterDownloader.enqueue(
      url: message.attachmentUrl,
      savedDir: temporaryDirectory.path,
      fileName: fileName,
      showNotification: false,
      openFileFromNotification: false,
    );

    if (taskId == null)
      return TelloLogger().i("ChatController: failed enqueuing $fileName");

    _downloadingTasks[taskId] = message;
    message.attachmentFile = File('${temporaryDirectory.path}/$fileName');
    TelloLogger()
        .i("ChatController: successfully enqueued $fileName, taskId: $taskId");
  }

  Future<void> cancelDownloading(ChatMessage message) async {
    for (final entry in _downloadingTasks.entries) {
      if (entry.value.id == message.id) {
        await FlutterDownloader.cancel(taskId: entry.key);
      }
    }
  }

  Future<void> openPdf(ChatMessage message) async {
    final file =
        File('${temporaryDirectory.path}/${basename(message.attachmentUrl)}');
    try {
      PDFDocument document;
      message.isDownloading(true);
      if (file.existsSync()) {
        document = await PDFDocument.fromFile(file);
      } else {
        document = await PDFDocument.fromURL(
          message.attachmentUrl,
          cacheManager: CacheManager(
            Config(
              "customCacheKey",
              stalePeriod: const Duration(days: 2),
              maxNrOfCacheObjects: 10,
            ),
          ),
        );
      }

      Get.dialog(GestureDetector(
        onTap: Get.back,
        child: Scaffold(
          backgroundColor: Colors.black26,
          appBar: AppBar(
              title: Row(children: [
            Text(
              LocalizationService().of().pdfViewer,
              style: AppTypography.subtitleChatViewersTextStyle,
            )
          ])),
          body: SafeArea(
            child: Center(
              child: PDFViewer(
                document: document,
                zoomSteps: 1,
              ),
            ),
          ),
        ),
      ));
    } catch (e, s) {
      SystemDialog.showConfirmDialog(
        title: "AppLocalizations.of(Get.context).error.capitalize",
        message: e.toString(),
        confirmCallback: Get.back,
      );
      TelloLogger().e('Error showing the pdf file: $e', stackTrace: s);
    } finally {
      message.isDownloading(false);
    }
  }

  void playVideo(File file) {
    Get.dialog(GestureDetector(
      onTap: Get.back,
      child: Scaffold(
        backgroundColor: Colors.black26,
        appBar: AppBar(
            backgroundColor: AppTheme().colors.appBar,
            title: Row(children: [
              Text(
                LocalizationService().of().videoPlayer,
                style: AppTypography.subtitleChatViewersTextStyle,
              )
            ])),
        body: SafeArea(
          child: Center(
            child: ChatVideoPlayer(
                {"1": VideoSource(video: VideoPlayerController.file(file))}),
          ),
        ),
      ),
    ));
    /* Get.dialog(
      ChatVideoPlayer({"1": VideoSource(video: VideoPlayerController.file(file))}),
    );*/
  }

  void showImage(Widget child) {
    Get.dialog(GestureDetector(
      onTap: Get.back,
      child: Scaffold(
        backgroundColor: Colors.black26,
        appBar: AppBar(
            backgroundColor: AppTheme().colors.appBar,
            title: Row(children: [
              Text(
                LocalizationService().of().viewImage,
                style: AppTypography.subtitleChatViewersTextStyle,
              )
            ])),
        body: SafeArea(
          child: Center(
            child: InteractiveViewer(child: child),
          ),
        ),
      ),
    ));
  }

  Future<void> takePhoto() async {
    if (Get.isBottomSheetOpen!) Get.back();

    final pickedFile = await _picker.getImage(
        source: ImageSource.camera,
        maxHeight: 480,
        maxWidth: 640,
        imageQuality: 50);

    if (pickedFile != null) {
      selectedFile = File(pickedFile.path);
      uploadFile();
    }
  }

  Future<void> takeVideo() async {
    if (Get.isBottomSheetOpen!) Get.back();
    await SoundPoolService().dispose();
    final pickedFile = await _picker.getVideo(source: ImageSource.camera);

    if (pickedFile != null) {
      selectedFile = File(pickedFile.path);
      uploadFile();
    }
    await SoundPoolService().init();
  }

  Future<void> pickMedia() async {
    if (Get.isBottomSheetOpen!) Get.back();

    final FilePickerResult? pickedFile =
        await FilePicker.platform.pickFiles(type: FileType.media);

    if (pickedFile != null) {
      selectedFile = File(pickedFile.files.first.path!);
      uploadFile();
    }
  }

  Future<void> pickPdf() async {
    if (Get.isBottomSheetOpen!) Get.back();

    final FilePickerResult? pickedFile = await FilePicker.platform
        .pickFiles(type: FileType.custom, allowedExtensions: ["pdf"]);

    if (pickedFile != null) {
      selectedFile = File(pickedFile.files.first.path!);
      uploadFile();
    }
  }

  Future<void> pickFile() async {
    if (Get.isBottomSheetOpen!) Get.back();

    final FilePickerResult? pickedFile = await FilePicker.platform.pickFiles();

    if (pickedFile != null) {
      selectedFile = File(pickedFile.files.first.path!);
      uploadFile();
    }
  }

  void goToBottom({bool jump = false}) {
    if (jump) {
      itemScrollCtrl.jumpTo(index: 0);
    } else {
      itemScrollCtrl.scrollTo(
          index: 0, duration: 300.milliseconds, curve: Curves.easeInOut);
    }
    for (final msg in currentChatGroupContainer$.currentChat$.unseenItems) {
      _markMessageRead(msg);
    }
    currentChatGroupContainer$.currentChat$.refreshItems();
    // _clearDownloads();
  }

  Future<void> goToMessage({
    int? index,
    String? messageId,
    bool jump = false,
    Duration duration = const Duration(milliseconds: 300),
  }) async {
    assert(index != null || messageId != null);

    final i = index ??
        currentChatGroupContainer$.currentChat$.items
            .indexWhere((msg) => msg.id == messageId);
    //FIXME: for some reason itemScrollController doesn't show the first item when alignment is 1
    // final isFirst = i == currentChatGroupContainer$.currentChat$.items.length - 1;
    // final alignment = isFirst ? 0.7 : 1.0;
    if (jump) {
      itemScrollCtrl.jumpTo(
        index: i,
        alignment: 0.5,
      );
      await 200.milliseconds.delay();
      _markVisibleMessagesRead();
    } else {
      await itemScrollCtrl.scrollTo(
        index: i,
        duration: duration,
        curve: Curves.easeInOut,
        alignment: 0.5,
      );
      await 200.milliseconds.delay();
      _markVisibleMessagesRead();
    }
    canTrackUnread = true;
  }

  void _markVisibleMessagesRead() {
    TelloLogger().i('_markVisibleMessagesRead() fired');
    bool needUpdateUI = false;
    for (final item in itemPositionsListener.itemPositions.value) {
      final visible = (item.itemLeadingEdge > 0 && item.itemLeadingEdge < 1) ||
          (item.itemTrailingEdge > 0 && item.itemTrailingEdge < 1);
      final msg = currentChatGroupContainer$.currentChat$.items[item.index];
      if (visible && msg.isUnread) {
        if (!needUpdateUI) needUpdateUI = true;
        _markMessageRead(msg);
        TelloLogger().i('message ${msg.text} has been read');
      }
    }
    if (needUpdateUI) currentChatGroupContainer$.currentChat$.refreshItems();
  }

  void _markMessageRead(ChatMessage msg) {
    msg.hasBeenRead = true;
    // We overwrite the chatRoom, because messages obtained from the messages history with the 'ListMessage' commandName don't have it
    msg.chatRoom =
        ChatRoom.fromGroup(HomeController.to.activeGroup, user: privateUser);
    if (isConnecting$.isFalse) {
      ChatSignaling().sendMessage(ChatMessage(
        id: msg.id,
        author:
            ChatUser.fromUser(Session.user!, Session.shift?.currentPosition),
        action: ChatMessage.clientReadMessageAction,
        createdAt: DateTime.now().toUtc(),
        chatRoom: msg.chatRoom,
        attachmentFile: null as File,
        maxLimit: 0,
        quotedMessage: null as ChatMessage,
        searchFromDateTime: null as DateTime,
      ));
    } else {
      _readOfflineChatMessagesBox!.write(msg.id, msg.toMap());
    }
    _deleteNotificationDebounce(msg.id);
  }

  void _clearDownloads() {
    for (final item in currentChatGroupContainer$.currentChat$.items) {
      if (item.downloadProgress() == 100) {
        item.attachmentFile.deleteSync();
        item.downloadProgress(0);
      }
    }
  }

  void showDateTimeLabel() {
    if (_showDateTimeLabelDebounceTimer?.isActive ?? false)
      _showDateTimeLabelDebounceTimer!.cancel();

    isDateLabelVisible$(true);
  }

  void hideDateTimeLabel() {
    if (_showDateTimeLabelDebounceTimer?.isActive ?? false)
      _showDateTimeLabelDebounceTimer!.cancel();

    _showDateTimeLabelDebounceTimer =
        Timer(const Duration(milliseconds: 500), () {
      isDateLabelVisible$(false);
    });
  }

  void _deleteNotificationDebounce(String id) {
    if (_deleteNotificationsDebounceTimer?.isActive ?? false)
      _deleteNotificationsDebounceTimer!.cancel();

    notificationsToDeleteQueue.add(id);

    _deleteNotificationsDebounceTimer =
        Timer(const Duration(milliseconds: 500), () {
      TelloLogger().i(
          'ChatController: deleting ${notificationsToDeleteQueue.length} notifications...');
      final notifications = [...notificationsToDeleteQueue];
      notificationsToDeleteQueue.clear();
      ns.NotificationService.to.removeNotifications(notifications);
    });
  }

  ///CAUTION: don't use _currentScrollPosition, it can contain incorrect value since the ScrollablePositionedList, which
  /// is being listened to by this callback, uses 2 different ListViews
  void onScroll(ScrollNotification scroll) {
    // For testing purposes
    // debugPrint('scroll.metrics.extentBefore: ${scroll.metrics.extentBefore}');
    // debugPrint('scroll.metrics.extentAfter: ${scroll.metrics.extentAfter}');
    // debugPrint('scroll.metrics.pixels: ${scroll.metrics.pixels}');
    // debugPrint('scroll.metrics.maxScrollExtent: ${scroll.metrics.maxScrollExtent}');
    // debugPrint('=================================');
    if (scroll is ScrollUpdateNotification) {
      _currentScrollPosition = scroll.metrics.pixels;
      final isDownward = scroll.scrollDelta! < 0;
      _startScrollPosition;
      final delta = (scroll.metrics.pixels - _startScrollPosition).abs();
      if (delta > 50) _isGoToBottomVisible$(isDownward);

      if (scroll.metrics.extentAfter < 100) {
        final canLoadMessages = isConnecting$.isFalse &&
            !chatGroupContainers[HomeController.to.activeGroup.id]!
                .currentChat$
                .allMessagesLoaded;
        if (canLoadMessages) sendMessageHistoryRequest();
      }
    }
    if (scroll is ScrollEndNotification) {
      _startScrollPosition = 0;
      final isFarFromBeginning =
          itemPositionsListener.itemPositions.value.first.index > 0;
      _isGoToBottomVisible$(isFarFromBeginning);
    }
  }

  void onSwipeItem(BuildContext context, int index, ChatMessage item) {
    TelloLogger().i("onSwipeItem ${item.text}");
    quotedMessage$(item);
    itemScrollCtrl.scrollTo(
        index: 0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut);
  }

  void onMsgVisibilityChanged(ChatMessage msg, double visibility) {
    if (visibility > 0) {
      if (_visibleMessages.contains(msg)) return;
      _visibleMessages.add(msg);
    } else {
      _visibleMessages.remove(msg);
    }

    if (_visibleMessages.length <= 1) return;

    updateFloatingDateTime();
  }

  void onStartPrivateChatTap(RxUser member) {
    showCurrentChat = true;
    setPrivateUser(ChatUser.fromUser(member));
    if (Get.isBottomSheetOpen!) Get.back();
    currentChatGroupContainer$.selectPrivateChat(ChatUser.fromUser(member));
    HomeController.to.gotoBottomNavTab(BottomNavTab.chat);
  }

  void onChatTap(Chat chat) {
    //in case of group chat, interlocutor will be null
    canTrackUnread = false;
    setPrivateUser(chat.interlocutor);
    currentChatGroupContainer$.setCurrentChat(chat);
    pageController.animateToPage(1,
        duration: 300.milliseconds, curve: Curves.easeInOut);
  }

  ///Must be called only when the ChatPage is visible
  void goToCurrentChat() {
    pageController.animateToPage(1,
        duration: 300.milliseconds, curve: Curves.easeInOut);
    showCurrentChat = false;
  }

  void goToChats() {
    pageController.animateToPage(0,
        duration: 300.milliseconds, curve: Curves.easeInOut);
    clearQuotedMessage();
  }

  void updateFloatingDateTime() {
    // find and assign the oldest DateTime
    final newDateTime = _visibleMessages.reduce((val, el) {
      return val.createdAt.isBefore(el.createdAt) ? val : el;
    }).createdAt;

    // compare and update if different
    if (floatingDateTime$!() == null) {
      floatingDateTime$!(newDateTime);
    } else {
      final oldYear = floatingDateTime$!().year;
      final oldMonth = floatingDateTime$!().month;
      final oldDay = floatingDateTime$!().day;

      final newYear = newDateTime.year;
      final newMonth = newDateTime.month;
      final newDay = newDateTime.day;

      if (newYear == oldYear && newMonth == oldMonth && newDay == oldDay) {
        return;
      } else {
        floatingDateTime$!(newDateTime);
      }
    }
  }

  int getUnseenForGroup(String groupId) =>
      chatGroupContainers[groupId]!.totalUnseen;

  void toggleIsReceivedByPopupOpen({bool? value, String? id}) {
    isReceivedByPopupOpen = value ?? !isReceivedByPopupOpen;
    update(['received-by-icon$id']);
  }
}
