import 'dart:async';
import 'dart:typed_data';

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/audio_message.dart';
import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_controller.dart';
import 'package:bazz_flutter/modules/message_history/audio_messages_repo.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/data_connection_checker.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/notification_service.dart' as ns;
import 'package:bazz_flutter/services/system_events_signaling.dart';
import 'package:bazz_flutter/shared_widgets/entity_details_info.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:eventify/eventify.dart' as evf;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_manager/flutter_audio_manager.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class MessageHistoryController extends GetxController
    with SingleGetTickerProviderMixin {
  static MessageHistoryController get to => Get.find();

  ViewState loadingState = ViewState.idle;

  final _playerModule = FlutterSoundPlayer();
  final _notificationsPlayer = FlutterSoundPlayer();
  final _notificationSoundFilePath =
      'assets/sounds/alert_check_snooze_alarm.mp3';
  Uint8List? _notificationSoundBuffer;

  TextEditingController searchInputCtrl = TextEditingController();
  String prevSearchInputText = '';
  final ItemScrollController itemScrollController = ItemScrollController();
  final ItemPositionsListener itemPositionsListener =
      ItemPositionsListener.create();
  final ItemScrollController itemScrollController2 = ItemScrollController();
  final ItemPositionsListener itemPositionsListener2 =
      ItemPositionsListener.create();
  TabController? tabController;
  final RxBool _$isTabIndexChanging = false.obs;

  bool get $isTabIndexChanging => _$isTabIndexChanging.value;

  void setIsTabIndexChanging(bool value) => _$isTabIndexChanging(value);

  RxInt currentProgress = 0.obs;

  Rx<AudioMessage>? currentTrack;
  final RxInt _currentTrackIndex = 0.obs;

  int get currentTrackIndex => _currentTrackIndex();

  RxBool isPlaying = false.obs;
  RxBool isFetchingLocations$ = false.obs;
  RxBool isConnecting = false.obs;
  RxBool isSeeking = false.obs;
  StreamSubscription? dispositionStreamSub;
  StreamSubscription? _activeGroupSub;
  StreamSubscription? _audioMessagesSub;
  evf.Listener? _newMessageSub;

  Worker? intervalWorker;

  bool get isPaused => _playerModule.isPaused;

  bool get isStopped => _playerModule.isStopped;

  bool get isFetchingLocations => isFetchingLocations$.value;

  final _audioMessages = <AudioMessage>[].obs;

  RxBool showMissed = false.obs;

  bool get showAll => showMissed.isFalse;

  List<AudioMessage> get filteredAudioMessages => _audioMessages.where((msg) {
        final query = searchInputCtrl.text.toLowerCase();
        if (query.isEmpty) return true;
        return msg.owner.fullName!.toLowerCase().startsWith(query) ||
            (msg.ownerPosition?.title.toLowerCase().startsWith(query) ?? false);
      }).where((msg) {
        if (showAll)
          return tabController!.index == 0 ? msg.isForGroup : msg.isPrivate;
        return msg.isNotListened &&
            (tabController!.index == 0 ? msg.isForGroup : msg.isPrivate);
      }).toList();

  late Timer _debounceTimer;
  late Timer _stopPlayerTimer;
  late Timer _cleanupTimer;

  @override
  Future<void> onInit() async {
    tabController = TabController(vsync: this, length: 2);

    tabController!.addListener(() async {
      if (tabController!.indexIsChanging) {
        setIsTabIndexChanging(true);
        _stopPlayback();
      } else {
        selectTrack(0);
        setIsTabIndexChanging(false);
      }
    });

    if (HomeController.to.activeGroup != null) await _fetchAudioMessages();

    _activeGroupSub = HomeController.to.activeGroup$.listen((aGroup) async {
      if (aGroup == null) return;

      await _fetchAudioMessages();
    });

    await _playerModule.openAudioSession(
      focus: AudioFocus.requestFocusAndKeepOthers,
      audioFlags: outputToSpeaker,
    );

    await _notificationsPlayer.openAudioSession(
      focus: AudioFocus.requestFocusAndKeepOthers,
      audioFlags: outputToSpeaker,
    );

    await _playerModule
        .setSubscriptionDuration(const Duration(milliseconds: 100));
    await _notificationsPlayer
        .setSubscriptionDuration(const Duration(milliseconds: 100));
    _notificationSoundBuffer =
        (await rootBundle.load(_notificationSoundFilePath))
            .buffer
            .asUint8List();

    dispositionStreamSub =
        _playerModule.dispositionStream()!.listen((disp) async {
      if (isSeeking()) return;

      final difference = disp.position.inSeconds - currentProgress();
      if (difference > 0.5 || difference < -0.5) {
        currentProgress(disp.position.inSeconds);
      }
    });

    _newMessageSub = SystemEventsSignaling().on('NewAudioMessageEvent', this,
        (evf.Event event, context) async {
      final data = (event.eventData as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      TelloLogger().i('Getting NewAudioMessageEvent: ${data['message']['id']}');
      final newAudioMessage =
          AudioMessage.fromMap(data['message'] as Map<String, dynamic>);
      final fromOtherGroup =
          newAudioMessage.groupId != HomeController.to.activeGroup.id;

      if (fromOtherGroup) {
        if (newAudioMessage.owner.isCustomer! ||
            (newAudioMessage.owner.isSupervisor! &&
                HomeController.to.activeGroup.isCustomerGroup)) {
          showNotification(
              newAudioMessage.groupId, newAudioMessage.owner.fullName!);
        }
        return;
      }

      if (Session.user!.id == newAudioMessage.owner.id)
        newAudioMessage.isListened(true);

      // inserting chronologically
      if (_audioMessages.isEmpty) {
        _audioMessages.add(newAudioMessage);
        currentTrack!(newAudioMessage);
      } else {
        final targetIndex = _audioMessages
            .indexWhere((msg) => newAudioMessage.createdAt > msg.createdAt);
        if (targetIndex > -1) {
          _audioMessages.insert(targetIndex, newAudioMessage);
        } else {
          _audioMessages.add(newAudioMessage);
        }
      }

      final filteredMessages = filteredAudioMessages;
      final oldCurrentTrackIndex = currentTrackIndex;

      // if the first track was selected and newAudioMessage was inserted at the beginning, select it instead
      if (!tabController!.indexIsChanging) {
        if (oldCurrentTrackIndex == 0 &&
            filteredMessages.length > 1 &&
            filteredMessages.first.id == newAudioMessage.id) {
          selectTrack(0);
        } else {
          // else update index for the current track
          _updateCurrentTrackIndex();
          if (Get.currentRoute == AppRoutes.messageHistory)
            scrollToIndex(currentTrackIndex);
        }
      }

      TelloLogger().i('New audio message added: ${data['message']['id']}');
    });

    searchInputCtrl.addListener(() async {
      final filteredMessages = filteredAudioMessages;

      if (searchInputCtrl.text.isNotEmpty) {
        await _stopPlayback();
        if (filteredMessages.isNotEmpty &&
            !filteredMessages.contains(currentTrack!())) {
          await selectTrack(0);
        }
      } else if (prevSearchInputText.isNotEmpty && _audioMessages.isNotEmpty) {
        await selectTrack(0, withScrolling: false);
      }
      _audioMessages.refresh();
      prevSearchInputText = searchInputCtrl.text;
    });

    _cleanupTimer = Timer.periodic(10.seconds, (_) async {
      if (_audioMessages.isNotEmpty && currentTrack!() != null) {
        if (_isAudioMessageObsolete(currentTrack!().createdAt) &&
            _audioMessages.length > 1) {
          if (currentTrack!().isNotPlaying) await selectTrack(0);
        }
        _audioMessages.removeWhere((msg) =>
            _isAudioMessageObsolete(msg.createdAt) &&
            (msg.id != currentTrack!().id || _playerModule.isStopped));
        _updateCurrentTrackIndex();
        if (_audioMessages.isEmpty) searchInputCtrl.text = '';
      }
    });

    _audioMessagesSub = _audioMessages.listen((_) async {
      if (filteredAudioMessages.isNotEmpty) {
        if (currentTrack!() == null) currentTrack!(filteredAudioMessages.first);
      } else {
        currentTrack?.isNull;
      }
    });

    super.onInit();
  }

  @override
  void onClose() {
    dispositionStreamSub?.cancel();
    _playerModule.closeAudioSession();
    _notificationsPlayer.closeAudioSession();
    _activeGroupSub?.cancel();
    _debounceTimer.cancel();
    _stopPlayerTimer.cancel();
    _cleanupTimer.cancel();
    _newMessageSub?.cancel();
    _audioMessagesSub?.cancel();
    searchInputCtrl.dispose();
    super.onClose();
  }

  Future<void> showNotification(String srcGroupId, String fullName) async {
    if (Get.isSnackbarOpen) {
      Get.until((route) => route.isFirst || Get.isDialogOpen!);
    }
    _playNotificationSound();
    final getBar = GetBar(
      title: fullName,
      message: LocalizationService().of().newAudioMessage,
      duration: const Duration(seconds: 30),
      animationDuration: const Duration(milliseconds: 500),
      icon: const Center(
        child: FaIcon(
          FontAwesomeIcons.voicemail,
          size: 20,
        ),
      ),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black26,
      barBlur: 10,
      onTap: (_) async {
        if (_notificationsPlayer.isPlaying) _notificationsPlayer.stopPlayer();
        if (Get.isSnackbarOpen) {
          Get.until((route) => route.isFirst || Get.isDialogOpen!);
        }
        final targetGroup = HomeController.to.groups.firstWhere(
          (gr) => gr.id == srcGroupId,
          orElse: () => null!,
        );
        await HomeController.to.setActiveGroup(targetGroup);
        HomeController.to.gotoBottomNavTab(BottomNavTab.ptt);
      },
    );

    ns.NotificationService.to.add(
      ns.Notification(
        icon: getBar.icon,
        title: getBar.title!,
        text: getBar.message!,
        bgColor: getBar.backgroundColor,
        callback: () => getBar.onTap!(getBar),
        groupType: NotificationGroupType.messagesHistory,
      ),
    );

    // Get.showSnackbar(getBar).whenComplete(() {
    //   if (_notificationsPlayer.isPlaying) _notificationsPlayer.stopPlayer();
    //   return null;
    // });
  }

  void setShowMissed(bool val) {
    showMissed(val);
    _audioMessages.refresh();
  }

  void _updateCurrentTrackIndex() {
    final newIndex =
        filteredAudioMessages.indexWhere((msg) => currentTrack!().id == msg.id);
    _currentTrackIndex(newIndex);
  }

  Future _fetchAudioMessages() async {
    if (loadingState == ViewState.loading) return;

    try {
      loadingState = ViewState.loading;
      final data = await AudioMessagesRepository()
          .fetchAudioMessages(HomeController.to.activeGroup.id!);
      if (data != null) {
        _audioMessages
          ..clear()
          ..addAll(data);
      }
      TelloLogger().i("History Messages Numbers ${data.length}");
      loadingState = ViewState.success;
    } on Exception catch (e, s) {
      TelloLogger().e('error while fetching audio messages: $e', stackTrace: s);
      loadingState = ViewState.error;
    }
  }

  Future<void> selectTrack(int index, {bool withScrolling = true}) async {
    await _stopPlayback();
    _currentTrackIndex(index);
    if (filteredAudioMessages.isNotEmpty)
      currentTrack!(filteredAudioMessages[currentTrackIndex]);
    if (Get.currentRoute == AppRoutes.messageHistory && withScrolling)
      scrollToIndex(index);
  }

  Future<void> play(int index) async {
    _stopPlayerTimer.cancel();

    await selectTrack(index);

    TelloLogger().i('Starting player...');
    try {
      isConnecting(true);
      final connected = await DataConnectionChecker().isConnectedToInternet;
      if (connected) {
        await FlutterAudioManager.changeToSpeaker();
        await _playerModule.startPlayer(
          fromURI: filteredAudioMessages[_currentTrackIndex()].fileUrl,
          codec: Codec.mp3,
          whenFinished: () {
            TelloLogger().i('Play finished');
            isPlaying(false);
            currentTrack!().isPlaying(false);
            currentProgress(0);
          },
        );
        isPlaying(true);
        currentTrack!().isPlaying(true);
        _markListened();
      }
    } catch (e, s) {
      TelloLogger().e('error while starting player: $e', stackTrace: s);
    } finally {
      isConnecting(false);
    }
  }

  Future _stopPlayback() async {
    if (!_playerModule.isStopped) {
      await _playerModule.stopPlayer();
      isPlaying(false);
      currentTrack!().isPlaying(false);
      currentProgress(0);
    }
  }

  Future<void> _playNotificationSound() async {
    try {
      if (HomeController.to.txState$.value.state != StreamingState.idle) return;
      await _notificationsPlayer.startPlayer(
        fromDataBuffer: _notificationSoundBuffer,
        codec: Codec.mp3,
        whenFinished: () {
          TelloLogger().i('Play finished');
        },
      );
    } catch (e, s) {
      TelloLogger().e('_playNotificationSound() error: $e', stackTrace: s);
    }
  }

  Future<void> _markListened() async {
    if (currentTrack!().isListened()) return;

    currentTrack!().isListened(true);
    try {
      await AudioMessagesRepository().markListened(currentTrack!().id);
    } catch (e, s) {
      currentTrack!().isListened(false);
      TelloLogger().e('_markListened() error: $e', stackTrace: s);
    }
  }

  void stopPlayer() {
    _setStopPlayerTimer();
  }

  void _setStopPlayerTimer() {
    _stopPlayerTimer = Timer(30.seconds, () async {
      await _playerModule.stopPlayer();
      currentProgress(0);
      isPlaying(false);
      _audioMessages.refresh();
    });
  }

  Future<void> pause() async {
    TelloLogger().i('Pausing player...');
    await _playerModule.pausePlayer();
    isPlaying(false);
    currentTrack!().isPlaying(false);
    _setStopPlayerTimer();
  }

  Future<void> resume() async {
    TelloLogger().i('Resuming player...');
    _stopPlayerTimer.cancel();
    await _playerModule.resumePlayer();
    isPlaying(true);
    currentTrack!().isPlaying(true);
  }

  Future<void> playPrev() async {
    TelloLogger().i('Playing prev...');
    if (isPlaying()) {
      play(_currentTrackIndex.value + 1);
    } else {
      selectTrack(_currentTrackIndex.value + 1);
    }
  }

  Future<void> playNext() async {
    TelloLogger().i('Playing next...');
    if (isPlaying()) {
      play(_currentTrackIndex.value - 1);
    } else {
      selectTrack(_currentTrackIndex.value - 1);
    }
  }

  Future<void> goToFirst() async {
    TelloLogger().i('Going to the first item...');
    await selectTrack(0);
  }

  Future<void> goToLast() async {
    TelloLogger().i('Going to the last item...');
    await selectTrack(filteredAudioMessages.length - 1);
  }

  void setNewPosition(int value) {
    _stopPlayerTimer.cancel();
    isSeeking(true);
    currentProgress(value);

    if (_debounceTimer.isActive) _debounceTimer.cancel();

    _debounceTimer = Timer(const Duration(milliseconds: 300), () async {
      TelloLogger().i('Setting new position...');
      await _playerModule.seekToPlayer(value.seconds);
      isSeeking(false);
      if (isPaused) _setStopPlayerTimer();
    });
  }

  void scrollToIndex(int index) {
    final scrollCtrl = tabController!.index == 0
        ? itemScrollController
        : itemScrollController2;
    if (scrollCtrl.isAttached) {
      scrollCtrl.scrollTo(
          index: index,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOutCubic,
          alignment: 0.02);
    }
  }

  bool _isAudioMessageObsolete(int timestamp) {
    final audioMessageLifePeriod = Duration(
        seconds:
            Session.shift?.duration ?? AppSettings().audioMessageLifePeriodSec);
    return dateTimeFromSeconds(timestamp, isUtc: true)!
        .isBefore(DateTime.now().toUtc().subtract(audioMessageLifePeriod));
  }

  void showUserInfo(RxUser owner, PositionInfoCard ownerPosition) {
    Get.bottomSheet(EntityDetailsInfo.createDetails(
        user: owner, posInfoCard: ownerPosition));
  }

  Future<SnackbarController> showPlayerOnMap() async {
    if (currentTrack!().audioLocations == null) {
      isFetchingLocations$.value = true;
      final data = await AudioMessagesRepository()
          .getAudioLocations(filteredAudioMessages[_currentTrackIndex()].id);
      currentTrack!().audioLocations = data!;
      isFetchingLocations$.value = false;
    }
    TelloLogger().i(
        "currentMessage.audioLocations ${currentTrack!().audioLocations?.coordinates.length}");

    if (currentTrack!().audioLocations?.coordinates.isEmpty ?? true) {
      return Get.showSnackbar(GetBar(
        backgroundColor: AppColors.error,
        message: "AppLocalizations.of(Get.context).noLocationsForMessage,",
        duration: const Duration(seconds: 3),
      ));
    }

    if (Get.currentRoute == AppRoutes.messageHistory) Get.back();

    final targetLocation = currentTrack!()
        .audioLocations!
        .coordinates
        .first
        .coordinate
        .toMapLatLng();
    FlutterMapController.to
      ..showPlayer$ = true
      ..animateToLatLngZoom(targetLocation);
    HomeController.to.gotoBottomNavTab(BottomNavTab.map);
    return null!;
  }
}
