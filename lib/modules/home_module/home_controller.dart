import 'dart:async';
import 'dart:convert';

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/coordinates_model.dart';
import 'package:bazz_flutter/models/device_state.dart';
import 'package:bazz_flutter/models/events_settings.dart';
import 'package:bazz_flutter/models/group_model.dart';
import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/shift_summary.dart';
import 'package:bazz_flutter/models/user_location_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/modules/alert_check/alert_check_service.dart';
import 'package:bazz_flutter/modules/auth_module/auth_service.dart';
import 'package:bazz_flutter/modules/auth_module/domain_module/domain_controller.dart';
import 'package:bazz_flutter/modules/chat/chat_controller.dart';
import 'package:bazz_flutter/modules/chat/chat_page.dart';
import 'package:bazz_flutter/modules/general/general_repo.dart';
import 'package:bazz_flutter/modules/home_module/events_repo.dart';
import 'package:bazz_flutter/modules/home_module/home_repo.dart';
import 'package:bazz_flutter/modules/home_module/sos_service.dart';
import 'package:bazz_flutter/modules/home_module/user_info_repo.dart';
import 'package:bazz_flutter/modules/home_module/views/events/events_view.dart';
import 'package:bazz_flutter/modules/home_module/views/ptt_view.dart';
import 'package:bazz_flutter/modules/location_tracking/location_service.dart';
import 'package:bazz_flutter/modules/message_history/message_upload_service.dart';
import 'package:bazz_flutter/modules/network_jitter/network_jitter_service.dart';
import 'package:bazz_flutter/modules/p2p_video/video_chat.dart';
import 'package:bazz_flutter/modules/p2p_video/video_chat_controller.dart';
import 'package:bazz_flutter/modules/settings_module/media_settings.dart';
import 'package:bazz_flutter/modules/settings_module/settings_controller.dart';
import 'package:bazz_flutter/modules/shift_activities/shift_activities_service.dart';
import 'package:bazz_flutter/modules/shift_module/shift_service.dart';
import 'package:bazz_flutter/modules/synchronization/sync_service.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/activity_recognition_service.dart';
import 'package:bazz_flutter/services/background_service.dart';
import 'package:bazz_flutter/services/battery_info_service.dart';
import 'package:bazz_flutter/services/camera_service.dart';
import 'package:bazz_flutter/services/chat_signaling.dart';
import 'package:bazz_flutter/services/data_connection_checker.dart';
import 'package:bazz_flutter/services/data_usage_service.dart';
import 'package:bazz_flutter/services/device_outputs_service.dart';
import 'package:bazz_flutter/services/entities_history_tracking.dart';
import 'package:bazz_flutter/services/event_handling_service.dart';
import 'package:bazz_flutter/services/harware_keys_service.dart';
import 'package:bazz_flutter/services/keyboard_service.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/notification_service.dart' as ns;
import 'package:bazz_flutter/services/pointer_service.dart';
import 'package:bazz_flutter/services/ptt_service.dart';
import 'package:bazz_flutter/services/rtc_service.dart';
import 'package:bazz_flutter/services/signaling.dart';
import 'package:bazz_flutter/services/snack_bar_display.dart';
import 'package:bazz_flutter/services/sound_pool_service.dart';
import 'package:bazz_flutter/services/statistics_service.dart';
import 'package:bazz_flutter/services/system_events_signaling.dart';
import 'package:bazz_flutter/services/vibrator.dart';
import 'package:bazz_flutter/shared_widgets/entity_details_info.dart';
import 'package:bazz_flutter/shared_widgets/loader.dart';
import 'package:bazz_flutter/shared_widgets/system_dialog.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:circular_menu/circular_menu.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:eventify/eventify.dart' as evf;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_manager/flutter_audio_manager.dart'
    show AudioInput;
import 'package:flutter_mediasoup/mediasoup_client/consumer_info.dart';
import 'package:flutter_mediasoup/mediasoup_client/device_details.dart';
import 'package:flutter_mediasoup/mediasoup_client/media_track_stats.dart';
import 'package:flutter_mediasoup/mediasoup_client/producer_info.dart';
import 'package:flutter_webrtc/enums.dart';
import 'package:flutter_webrtc/media_stream.dart';
import 'package:flutter_webrtc/rtc_video_view.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:logger/logger.dart' as log;
import 'package:pausable_timer/pausable_timer.dart';
import 'package:rxdart/rxdart.dart' as rx;
import 'package:screen/screen.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:volume_control/volume_control.dart';

typedef WidgetFunc = Widget Function();

//const MethodChannel _channelShutDown = MethodChannel('com.bazzptt/shutdown');

enum BottomNavTab {
  ptt,
  map,
  videoChat,
  chat,
  events,
}

const MethodChannel _channelScreenLock =
    MethodChannel('com.bazzptt/screenlock');

//TODO: divide this controller into smaller ones
class HomeController extends GetxController with SingleGetTickerProviderMixin {
  static HomeController get to =>
      Get.isRegistered<HomeController>() ? Get.find() : null!;

  final _homeRepo = HomeRepository();

  final _eventsRepo = EventsRepository();

  PanelController notificationsDrawerController = PanelController();

  RxBool isNotificationsDrawerOpen = false.obs;

  final _remoteRenderer = RTCVideoRenderer();

  final _localRenderer = RTCVideoRenderer();

  RxBool localVideoDisplay = false.obs;

  RxBool remoteVideoDisplay = false.obs;

  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  RTCVideoRenderer get localRenderer => _localRenderer;

  PausableTimer? shiftTimer;

  Timer? _periodicShiftTimestampTimer;

  Timer? _networkRecoveryTimer;

  final fabGlobalKey = GlobalKey<CircularMenuState>();

  TabController? homeTabBarController;
  TabController? bottomNavBarController;

  final homeTabBarBarIndex$ = 0.obs;

  //FIXME: use either currentBottomNavBarIndex$ OR bottomNavBarIndex$!!!
  final currentBottomNavBarIndex$ = 0.obs;

  int get currentBottomNavBarIndex => currentBottomNavBarIndex$.value;

  set currentBottomNavBarIndex(int i) => currentBottomNavBarIndex$.value = i;

  final bottomNavBarIndex$ = 0.obs;

  int get bottomNavBarIndex => bottomNavBarIndex$.value;

  set bottomNavBarIndex(int i) => bottomNavBarIndex$.value = i;

  BottomNavTab bottomNavBarTab = BottomNavTab.ptt;

  GlobalKey<ConvexAppBarState> bottomNavBarKey = GlobalKey<ConvexAppBarState>();

  UserInfoRepository? _userInfoRepository;

  bool get isVideoChatVisible =>
      Get.currentRoute == AppRoutes.home &&
      bottomNavBarTab == BottomNavTab.videoChat;

  bool get isChatVisible =>
      Get.currentRoute == AppRoutes.home &&
      homeTabBarController!.index == 0 &&
      bottomNavBarTab == BottomNavTab.chat;

  Future<void> gotoBottomNavTab(BottomNavTab tab,
      {bool closeOtherRoutes = true}) async {
    if (closeOtherRoutes) Get.until((route) => route.isFirst);
    bottomNavBarIndex = tab.index;
    currentBottomNavBarIndex = tab.index;
    bottomNavBarTab = tab;
    homeTabBarController!.animateTo(0);
    bottomNavBarController!.index = tab.index;
    bottomNavBarKey.currentState!.animateTo(tab.index);
    if (tab == BottomNavTab.map) {
      Get.toNamed(AppRoutes.mapTabFullscreen);
    }
  }

  final List<Widget> bottomNavBarTabs = [];

  BottomNavTab get currentBottomNavTab =>
      BottomNavTab.values[bottomNavBarIndex];

  bool _resourcesReleased = false;
  late StreamSubscription _socketErrorSub;
  late StreamSubscription _isOnlineSub;
  late StreamSubscription _isMediaOnlineSub;
  late StreamSubscription _activeGroupSub;
  late StreamSubscription _txStateSub;
  late StreamSubscription _shouldResetCurrentChatPageIndexSub;

  late evf.Listener _privateCallSub;
  late evf.Listener _userOnlineSub;
  late evf.Listener _transmittingSub;
  late evf.Listener _transmittingPrivateCallSub;
  late evf.Listener _closePrivateCallSub;
  late evf.Listener _userLocationSub;
  late evf.Listener _positionUpdateSub;
  late evf.Listener _updatedEventSub;
  late evf.Listener _newEventSub;
  late evf.Listener _groupDevicesStatSub;
  late evf.Listener _logoutEventSub;
  late evf.Listener _positionUpdatedEventSub;
  late evf.Listener _groupUpdatedEventSub;

  final groups$ = <RxGroup>[].obs;

  bool _fetchingGroups = false;
  Completer groupsFetched = Completer();

  late Rx<BatteryInfo> batteryInfo$;

  BatteryInfo get batteryInfo => batteryInfo$.value;

  final _adminUsers$ = <RxUser>[].obs;

  List<RxUser> get adminUsers => _adminUsers$();

  late Rx<RxUser> activeAdminUser$;

  RxUser get activeAdminUser => activeAdminUser$.value;

  set activeAdminUser(RxUser admin) => activeAdminUser$.value = admin;

  List<RxGroup> get groups => groups$;

  List<RxGroup> get groupsWoActive =>
      groups$.where((gr) => gr.id != activeGroup.id).toList();

  late Rx<RxGroup> activeGroup$;

  RxGroup get activeGroup => activeGroup$.value;

  late Rx<RxGroup> allGroup$;

  RxGroup get allGroup => allGroup$.value;

  final setActiveGroupError$ = false.obs;

  bool get setActiveGroupError => setActiveGroupError$.value;

  final isOnline$ = false.obs;

  bool get isOnline => isOnline$.value;

  bool get isOffline => !isOnline$.value;

  final isMediaOnline$ = false.obs;

  bool get isMediaOnline => isMediaOnline$.value;

  bool get isInRecordingMode =>
      !isMediaOnline || !isOnline || setActiveGroupError;

  bool get isPttDisabled => activeGroup == null || isSosPressed$;

  bool get isSosDisabled => isPttPressed$;

  bool get canTalk =>
      !isPttDisabled &&
      (HomeController.to.txState$().state == StreamingState.idle ||
          HomeController.to.txState$().state == StreamingState.connecting);

  RxBool isGroupsPopupOpen = false.obs;

  RxBool isAdminUsersPopupOpen = false.obs;

  ViewState _currentState = ViewState.idle;

  ViewState get currentState => _currentState;

  set currentState(ViewState state) => _currentState = state;

  final _loadingState = ViewState.idle.obs;

  ViewState get loadingState => _loadingState.value;

  set loadingState(ViewState state) => _loadingState.value = state;

  final txState$ = TxState().obs;

  bool get isSpeaking => txState$().state == StreamingState.sending;

  bool get isListening => txState$().state == StreamingState.receiving;

  late Timer lastMessageAtRefreshTimer;

  late Timer batteryLevelTimer;

  late Timer privateCallPeriodTimer;

  //Timer fetchOperatorsCallPeriodTimer;

  Completer servicesInit = Completer();
  RxBool servicesInitialized$ = false.obs;

  bool get servicesNotInitialized$ => !servicesInitialized$();

  List<AudioInput> _availableInputs = [];

  ///if a position doesn't receive from the customer messages for too long,
  /// we switch his group back to his primary group
  late Timer _switchToPrimaryGroupTimer;

  late StreamSubscription<DataConnectionStatus> dataConnectionCheckerSub;

  final RxBool _isRecordingOfflineMessage = false.obs;

  bool get isRecordingOfflineMessage => _isRecordingOfflineMessage();

  bool releasePttAuto = false;

  bool _needFetchingGroups = false;

  late double _currentDeviceVolume;

  TextEditingController searchInputCtrl = TextEditingController();

  late Rx<RxUser> privateCallUser$;

  late String _privateGroupId;

  RxUser get privateCallUser => privateCallUser$.value;

  bool get privateCallInProgress => privateCallUser != null;

  RxBool canClosePrivateCall$ = false.obs;

  bool get canClosePrivateCall => canClosePrivateCall$.value;

  set privateCallUser(RxUser user) => privateCallUser$.value = user;

  final RxBool _isPttPressed$ = false.obs;

  bool get isPttPressed$ => _isPttPressed$();

  set isPttPressed$(bool value) {
    _isPttPressed$(value);
  }

  final List<StreamSubscription> _sosPressedListeners = [];

  final RxBool _isSosPressed$ = false.obs;

  bool get isSosPressed$ => _isSosPressed$();

  final mediaTrackStatsAudioList$ = <MediaTrackStats>[].obs;

  RxList<MediaTrackStats> get mediaTrackStatsAudioList =>
      mediaTrackStatsAudioList$;

  final mediaTrackStatsVideoList$ = <MediaTrackStats>[].obs;

  RxList<MediaTrackStats> get mediaTrackStatsVideoList =>
      mediaTrackStatsVideoList$;

  final List<evf.Listener> _listeners = [];

  Rx<DeviceDetails>? deviceDetails$;
  RxString producerOffer$ = "".obs;
  RxString consumerOffer$ = "".obs;

  Rx<ConsumerInfo>? consumerInfo$;
  Rx<ProducerInfo>? producerInfo$;

  DeviceDetails get deviceDetails => deviceDetails$!.value;

  String get producerOffer => producerOffer$.value;

  String get consumerOffer => consumerOffer$.value;

  ConsumerInfo get consumerInfo => consumerInfo$!.value;

  ProducerInfo get producerInfo => producerInfo$!.value;

  Timer? _autoPttReleaseTimer;

  set isSosPressed$(bool value) {
    _isSosPressed$(value);
  }

  void addSosPressedListener(void Function(bool) callback) {
    _sosPressedListeners.add(_isSosPressed$.listen(callback));
  }

  void cancelSosPressedListeners() {
    for (final sub in _sosPressedListeners) {
      sub.cancel();
    }
  }

  final RxBool _isSosKeyPressed$ = false.obs;

  bool get isSosKeyPressed$ => _isSosKeyPressed$();

  set isSosKeyPressed$(bool value) {
    _isSosKeyPressed$(value);
  }

  final RxBool _isPttKeyPressed$ = false.obs;

  bool get isPttKeyPressed$ => _isPttKeyPressed$();

  set isPttKeyPressed$(bool value) {
    _isPttKeyPressed$(value);
  }

  RxBool showPtt = true.obs;

  void setShowPtt({required bool val}) {
    showPtt(val);
  }

  void setShowPtv({required bool val}) {
    showPtt(val);
  }

  bool showEventsDialogAfterSettingGroup = true;

  bool finalizingPrevRecording = false;

/*  void onData(ScreenStateEvent event) {
    Logger().log("STEP TO CLOSE 1  onData ScreenStateEvent ==> $event");
    */ /*   final deviceUnlock = DeviceUnlock();
    await deviceUnlock.request(localizedReason: "We need to check your identity.");*/ /*
  }*/

  void switchActiveGroupByButtonSwitch({bool isUp = true}) {
    TelloLogger().i("switchActiveGroupByButtonSwitch");
    final int groupIndex =
        groups.indexWhere((element) => element.id == activeGroup.id);
    TelloLogger().i("switchActiveGroupByButtonSwitch $groupIndex");
    if (isUp && groupIndex < groups.length) {
      setActiveGroup(groups[(groupIndex + 1)]);
    } else if (groupIndex - 1 >= 0) {
      setActiveGroup(groups[(groupIndex - 1)]);
    }
  }

  void createAllGroup() {
    final group = RxGroup(id: "all", title: "All");
    allGroup$.value = group;
  }

  @override
  Future<void> onInit() async {
    _loadingState(ViewState.initialize);
    if (!DomainController.isPrivateDevice) {
      Screen.setBrightness(AppSettings().screenBrightness);
    }
    //Wakelock.enable();
    TelloLogger().i("START Home onInit() ${Get.height} ${Get.width}");
    VolumeControl.setVolume(AppSettings().maxVolumeOnMobileDevice);
    TelloLogger()
        .i("START Home onInit() _currentDeviceVolume == $_currentDeviceVolume");

    // Doesn't work as expected, remove if the _periodicShiftTimestampTimer works well
    // _channelShutDown.setMethodCallHandler((call) async {
    //   if (call.method == "shutDown") {
    //     logoutFromDevice();
    //   }
    // });
    bottomNavBarTabs.add(PttView());
    bottomNavBarTabs.add(const SizedBox());
    bottomNavBarTabs.add(const VideoChatView());
    bottomNavBarTabs.add(ChatView());
    bottomNavBarTabs.add(EventsView());

    try {
      homeTabBarController = TabController(vsync: this, length: 2);
      bottomNavBarController = TabController(vsync: this, length: 5);
      homeTabBarController!.addListener(() {
        homeTabBarBarIndex$(homeTabBarController!.index);
      });

      _shouldResetCurrentChatPageIndexSub =
          rx.Rx.combineLatest2<int, int, bool>(
        homeTabBarBarIndex$.stream.shareValueSeeded(0),
        bottomNavBarIndex$.stream.shareValueSeeded(0),
        (homeTabBarBarIndex, bottomNavBarIndex) {
          return homeTabBarBarIndex != 0 || bottomNavBarIndex != 3;
        },
      ).listen((shouldResetCurrentChatPageIndex) {
        if (shouldResetCurrentChatPageIndex &&
            Get.isRegistered<ChatController>()) {
          ChatController.to.resetCurrentChatPageIndex();
        }
      });

      initHardwareKeyCodes();

      try {
        DataUsageService().start();
        await DeviceOutputs().init();
        DeviceOutputs().changeToHeadphone();
      } catch (e, s) {
        TelloLogger().e("Error while loading medium services level ==> $e",
            stackTrace: s);
      }
      _userInfoRepository = UserInfoRepository();
      final isOnline = await DataConnectionChecker().isConnectedToInternet;
      isOnline$.value = isOnline;

      if (Session.hasShiftStarted!) {
        if (Session.shift!.hasEnded) {
          return await logoutFromDevice(
              forcedShiftEnd: true, isOnline: isOnline);
        }

        //TODO: move shiftTimer and _periodicShiftTimestampTimer to the ShiftService
        shiftTimer = PausableTimer(
          Duration(
            // seconds: 60, //for testing purposes
            seconds: dateTimeFromSeconds(Session.shift!.plannedEndTime!,
                    isUtc: true)!
                .difference(DateTime.now().toUtc())
                .inSeconds,
          ),
          () {
            if (Get.isRegistered<HomeController>())
              logoutFromDevice(forcedShiftEnd: true);
          },
        )..start();

        final periodicShiftTimestamp =
            GetStorage().read<int>(StorageKeys.periodicShiftTimestamp);

        if (periodicShiftTimestamp != null) {
          final diffSec =
              (DateTime.now().millisecondsSinceEpoch - periodicShiftTimestamp) /
                  1000;

          if (diffSec > AppSettings().shiftInterruptedThresholdSec) {
            Get.showSnackbar(
              GetBar(
                snackPosition: SnackPosition.TOP,
                backgroundColor: AppColors.error,
                message: LocalizationService().of().yourShiftWasInterrupted,
                titleText: Text(
                  LocalizationService().of().warning.capitalizeFirst,
                  style: AppTypography.captionTextStyle,
                ),
                icon: const Icon(Icons.warning_amber_rounded,
                    color: AppColors.brightIcon),
              ),
            );
          }
        }

        _periodicShiftTimestampTimer =
            Timer.periodic(const Duration(seconds: 5), (timer) {
          GetStorage().write(StorageKeys.periodicShiftTimestamp,
              DateTime.now().millisecondsSinceEpoch);
        });
      }

      await fetchEventTypesConfig();
      await _initServices();

      if (AppSettings().enableHistoryTracking) {
        EntitiesHistoryTracking().init();
      }

      Loader.updateSubTitle("Start fetching groups");
      createAllGroup();
      await tryFetchAdminUsersList();
      await _fetchGroups();
      /* fetchOperatorsCallPeriodTimer = Timer.periodic(const Duration(seconds: 5), (timer) async{
        await fetchAdminUsersList();
        groups$.forEach((group) {
          update(['groupMembersOf${group.id}']);
        });
      });*/
      _updateOnlineStatusInGroups(
        positionGroupId: Session.shift!.groupId,
        userId: Session.user!.id,
        isOnline: isOnline,
        hasActiveSession: true,
      );
      Loader.updateSubTitle("Complete fetching groups");
      await _resetActiveGroup();
      Loader.updateSubTitle("Init System subscriptions");
      _addSubscriptions();
      Loader.updateSubTitle("Init Chat");
      if (Get.isRegistered<ChatController>())
        await ChatController.to.initChats(groups, activeGroup);

      _isOnlineSub = isOnline$.listen((online) async {
        TelloLogger().i("THE ONLINE STATE HAS BEEN CHANGED == $online");
        if (online) {
          SoundPoolService().playOnlineSound();
          // Updating app settings if the app has started offline
          if (AppSettings().updateNotCompleted) AppSettings().tryUpdate();
          await fetchEventTypesConfig();
          await _fetchGroups();
          await _resetActiveGroup(showEventsDialog: false);
          if (Get.isRegistered<ChatController>())
            await ChatController.to.initChats(groups, activeGroup);
        } else {
          SoundPoolService().playOfflineSound();
        }
        _updateOnlineStatusInGroups(
          positionGroupId: Session.shift!.groupId,
          userId: Session.user!.id,
          isOnline: online,
          hasActiveSession: true,
        );
      });

      try {
        Keyboard.onKeyDown.add(handleKeyDown);
      } catch (e, s) {
        TelloLogger().e('Set keyboard  Error: $e', stackTrace: s);
      }

      Pointer.pointerDown = () {};
      Pointer.pointerUp = () {
        if (!isPttKeyPressed$ && txState$.value.state != StreamingState.idle) {
          onPttRelease();
          return;
        }
      };

      TelloLogger().i(
          "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ HOME CONTROLLER ON INIT  @@@@@@@@@@@@@@@");

      Loader.updateSubTitle("Complete init controller");
      lastMessageAtRefreshTimer = Timer.periodic(
        Duration(seconds: AppSettings().lastMessageAtRefreshPeriod),
        (timer) async {
          for (final group in groups$) {
            group.lastMessageAt?.refresh();
          }
        },
      );

      batteryInfo$.value = await BatteryInfo.create();
      batteryLevelTimer = Timer.periodic(
        Duration(seconds: AppSettings().batteryLevelPeriod),
        (timer) async {
          batteryInfo$.value = await BatteryInfo.create();
        },
      );

      dataConnectionCheckerSub =
          DataConnectionChecker().onStatusChange.listen((status) async {
        switch (status) {
          case DataConnectionStatus.connected:
            TelloLogger()
                .i('DataConnectionChecker: connected to the Internet.');
            /* if (!isMediaOnline) {
              ///need to check
              await _initPttService();
              setActiveGroup(activeGroup);
            }*/
            if (!isOnline$.value) {
              _networkRecoveryTimer?.cancel();
              _networkRecoveryTimer = Timer(
                  Duration(
                      seconds: DataConnectionChecker()
                          .recoveryDurationInSeconds), () {
                isOnline$.value = true;
              });
            }
            break;
          case DataConnectionStatus.disconnected:
            TelloLogger()
                .i('DataConnectionChecker: disconnected from the Internet.');
            _networkRecoveryTimer?.cancel();
            if (isOnline$.value) {
              isOnline$.value = false;
            }
            break;
        }
      });

      StatisticsService().init();

      _loadingState(ViewState.success);

      _channelScreenLock.setMethodCallHandler((call) async {
        TelloLogger().i(
            "_channelScreenLock.setMethodCallHandler home controller == $loadingState");
        if (!Loader.isVisible) {
          loadingState = ViewState.idle;
        }
        if (loadingState == ViewState.idle ||
            loadingState == ViewState.success) {
          _loadingState(ViewState.lock);
        } else if (loadingState == ViewState.lock) {
          await Screen.setBrightness(0.01);
        }
      });
    } catch (e, s) {
      _loadingState(ViewState.error);

      TelloLogger().e(' HomeController onInit Error: $e', stackTrace: s);
      /*   await Get.showSnackbarEx(GetBar(
        backgroundColor: AppColors.error,
        message: 'Home Page Loading Errors , Details => ${e.toString()}',
        titleText: Text(LocalizationService().localizationContext().systemInfo, style: AppTypography.captionTextStyle),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.brightIcon,
        ),
      ));*/
      update();
      AuthService.throwToLogin(
          LocalizationService().of().failedLoadingHomeView);
    } finally {
      Loader.updateSubTitle("");
      _resourcesReleased = false;
    }

    try {
      CameraService().fixRearCamera();
    } catch (e, s) {
      TelloLogger()
          .e('CameraService().fixRearCamera onInit Error: $e', stackTrace: s);
    }

    searchInputCtrl.addListener(() async {
      TelloLogger().i('searchInputCtrl ${searchInputCtrl.text}');
      for (final group in groups$) {
        TelloLogger().i(
            'searchInputCtrl ${searchInputCtrl.text} sort group == ${group.title}');
        group.members.sortMembers(filter: searchInputCtrl.text);
        update(['groupMembersOf${group.id}']);
      }
    });
    super.onInit();
  }

  Future<void> resetPtt() async {
    _loadingState(ViewState.initialize);
    try {
      Loader.updateSubTitle("Initializing Ptt Service");
      await PTTService().reset();
      Loader.updateSubTitle("Setting Active Group");
      await setActiveGroup(activeGroup$.value);
      setActiveGroupError$.bindStream(RTCService().setActiveGroupError$);
      isMediaOnline$.bindStream(RTCService().isOnline$);
      txState$.bindStream(RTCService().callState$);
      activeGroup$.bindStream(PTTService().activeGroup$);
      _loadingState(ViewState.success);
    } catch (e) {
      _loadingState(ViewState.error);
    } finally {
      Loader.updateSubTitle("");
    }
  }

  Future<void> openVideoPeerToAdminUser() async {
    try {
      //if (users.isEmpty) return;
      //Logger().log("openVideoPeerToAdminUser ==> ${users[0].fullName}");
      if (Get.isBottomSheetOpen!) Get.back();
      await gotoBottomNavTab(BottomNavTab.videoChat);
      VideoChatController.to.currentUser = activeAdminUser;
      VideoChatController.to.invitePeer(activeAdminUser);
    } catch (e) {
      Get.showSnackbarEx(GetBar(
        backgroundColor: Colors.red,
        message: LocalizationService().of().failedLaunchingAdminVideoCall,
        duration: const Duration(seconds: 5),
      ));
    }
  }

  Future<void> tryFetchAdminUsersList() async {
    Iterable<RxUser> adminUsers;

    if (isOnline) {
      final data = await _userInfoRepository!.getAdminList();
      adminUsers = (data['users'] as List<dynamic>).map((x) =>
          RxUser.fromMap(x as Map<String, dynamic>)..isVideoActive(true));
      GetStorage().write(StorageKeys.adminUsers, json.encode(data['users']));
    } else {
      final data = GetStorage().read<String>(StorageKeys.adminUsers);
      adminUsers = (json.decode(data!) as List<dynamic>).map((m) =>
          RxUser.fromMap(m as Map<String, dynamic>)..isVideoActive(true));
    }

    _adminUsers$.clear();
    _adminUsers$.addAll(adminUsers);
    if (_adminUsers$.isNotEmpty) {
      activeAdminUser = _adminUsers$[0];
    }

    TelloLogger().i("fetchAdminUsersList == > ${_adminUsers$.length}");
  }

  Future<void> _showLogoutFromDeviceMessage({bool error = false}) async {
    await SystemDialog.showConfirmDialog(
      title: LocalizationService().of().sessionTimeout,
      message: error
          ? LocalizationService().of().yourSessionIsClosedByTheServerErr
          : LocalizationService().of().yourSessionIsClosedByTheServer,
      confirmButtonText: LocalizationService().of().ok,
      confirmCallback: logoutFromDevice,
    );
  }

  Future<void> logoutFromDevice(
      {bool forcedShiftEnd = false, bool? isOnline}) async {
    try {
      if (Get.isRegistered<AlertCheckService>())
        AlertCheckService.to.pauseAlertCheckTimer();
      Loader.updateSubTitle('');
      _loadingState(ViewState.exit);
      isOnline ??= await DataConnectionChecker().isConnectedToInternet;
      await PTTService().dispose(isOnline: isOnline);
      if (Get.isRegistered<ChatController>() && ChatSignaling().isConnected)
        await ChatController.to.disconnect();
      if (isOnline) {
        if (SyncService.to.hasData$ || MessageUploadService.to.hasData$) {
          Loader.updateSubTitle('Syncing User Data...');
          await Future.wait(
            [
              SyncService.to.otherDataSyncCompleted.future,
              SyncService.to.rPointsSyncCompleted.future,
              SyncService.to.offlineEventsSyncCompleted.future,
              MessageUploadService.to.syncMessagesCompleted.future,
            ],
          ).timeout(const Duration(seconds: 30), onTimeout: () {
            Loader.updateSubTitle('Syncing User Data Timeout...');
            return null!;
          });
          Loader.updateSubTitle('');
        }
        if (Session.hasShift) {
          ShiftSummary sessionSummary;
          Loader.updateSubTitle('End Current Shift and logout...');
          sessionSummary = await ShiftService.to.onShiftEndPressed(
            DateTime.now().toUtc(),
            forcedShiftEnd: forcedShiftEnd,
          );
          Get.offAllNamed(AppRoutes.shiftSummary, arguments: sessionSummary);
        } else {
          Loader.updateSubTitle('Logout from device...');
          await AuthService.to.logOut();
          _loadingState(ViewState.success);
        }
      } else {
        if (Session.hasShift) {
          SystemDialog.showConfirmDialog(
            title: LocalizationService().of().error,
            message: LocalizationService().of().offlineLogoutMsg,
            cancelCallback: Get.back,
            cancelButtonText: LocalizationService().of().cancel,
            confirmButtonText: LocalizationService().of().logout,
            confirmCallback: () => AuthService.to.logOut(locally: true),
          );
          _loadingState(ViewState.error);
        } else {
          await AuthService.to.logOut(locally: true);
          _loadingState(ViewState.success);
        }
      }
    } catch (e, s) {
      _loadingState(ViewState.error);
      TelloLogger().e("logoutFromDevice Failure === > $e", stackTrace: s);

      ///WE WILL NEED IT LATER, now we're just exiting the app
      // Get.showSnackbarEx(GetBar(
      //   backgroundColor: Colors.red,
      //   message: Session.hasShift
      //       ? "${LocalizationService().localizationContext().failedEndShiftFromSystem} , $e"
      //       : "${LocalizationService().localizationContext().failedLogoutFromSystem}, $e",
      //   duration: const Duration(seconds: 5),
      // ));
      await AuthService.to.logOut(locally: true);
    } finally {
      Loader.updateSubTitle('');
    }
  }

  void initHardwareKeyCodes() {
    if (Session.device!.hardwareKeyType == 1) {
      HardwareKey.init();

      HardwareKey.addPttDownHardwareKey(Session.device!.pttKeyDownName!);
      HardwareKey.addChannelUpHardwareKey(Session.device!.pttKeyUpName!);
      HardwareKey.addSosDownHardwareKey(Session.device!.sosKeyDownName!);
      HardwareKey.addSosUpHardwareKey(Session.device!.sosKeyUpName!);
      if (Session.device!.pttChannelKeyDownName != null) {
        HardwareKey.addSosDownHardwareKey(
            Session.device!.pttChannelKeyDownName!);
      }
      if (Session.device!.pttChannelKeyUpName != null) {
        HardwareKey.addSosDownHardwareKey(Session.device!.pttChannelKeyUpName!);
      }
      HardwareKey.onHardwareKey = (key) {
        TelloLogger().i("onHardwareKey ===> $key");
        if (key == Session.device!.pttKeyDownName) {
          handlePttButtonDown(null, null);
        } else if (key == Session.device!.pttKeyUpName) {
          handlePttButtonUp(null, null);
        } else if (key == Session.device!.sosKeyDownName) {
          handleSOSButtonDown(null, null);
        } else if (key == Session.device!.sosKeyUpName) {
          handleSOSButtonUp(null, null);
        } else if (key == Session.device!.pttChannelKeyDownName) {
          handleSwitchButtonDown(null, null);
        } else if (key == Session.device!.pttChannelKeyUpName) {
          handleSwitchButtonUp(null, null);
        }
      };
      HardwareKey.startReceiver();
    } else {
      if (GetStorage().hasData(StorageKeys.pttKeyCodeId)) {
        //Keyboard.setPttButtonCode(266); //for testing purposes
        Keyboard.setPttButtonCode(
            int.parse(GetStorage().read(StorageKeys.pttKeyCodeId)));
      } else if (Session.device != null && Session.device!.pttKeyCode! > 0) {
        //Keyboard.setPttButtonCode(266); //for testing purposes
        Keyboard.setPttButtonCode(Session.device!.pttKeyCode!);
      }
      if (GetStorage().hasData(StorageKeys.sosKeyCodeId)) {
        // Keyboard.setSOSButtonCode(24); //for testing purposes
        Keyboard.setSOSButtonCode(
            int.parse(GetStorage().read(StorageKeys.sosKeyCodeId)));
      } else if (Session.device != null && Session.device!.sosKeyCode! > 0) {
        // Keyboard.setSOSButtonCode(24); //for testing purposes
        Keyboard.setSOSButtonCode(Session.device!.sosKeyCode!);
      }
      if (GetStorage().hasData(StorageKeys.switchUpKeyCodeId)) {
        Keyboard.setSwitchUpButtonCode(
            int.parse(GetStorage().read(StorageKeys.switchUpKeyCodeId)));
      } else if (Session.device != null &&
          Session.device!.switchUpKeyCode! > 0) {
        Keyboard.setSwitchUpButtonCode(Session.device!.switchUpKeyCode!);
      }
      if (GetStorage().hasData(StorageKeys.switchDownKeyCodeId)) {
        Keyboard.setSwitchDownButtonCode(
            int.parse(GetStorage().read(StorageKeys.switchDownKeyCodeId)));
      } else if (Session.device != null &&
          Session.device!.switchDownKeyCode! > 0) {
        Keyboard.setSwitchDownButtonCode(Session.device!.switchDownKeyCode!);
      }
      try {
        Keyboard.onPttButtonDown.add(handlePttButtonDown);
        Keyboard.onPttButtonUp.add(handlePttButtonUp);
        Keyboard.onSOSButtonDown.add(handleSOSButtonDown);
        Keyboard.onSOSButtonUp.add(handleSOSButtonUp);
        Keyboard.onSwitchButtonDown.add(handleSwitchButtonDown);
        Keyboard.onSwitchButtonUp.add(handleSwitchButtonUp);
      } catch (e, s) {
        TelloLogger().e('Set keyboard  Error: $e', stackTrace: s);
      }
    }
  }

  void initDeviceConfiguration() {
    if (Session.isSupervisor) {
      BackgroundService.instance().enableVolume();
    }
  }

  void onNotificationsDrawerOpened() {
    update(['notificationsDrawerArrow', 'notificationTime']);
  }

  void onNotificationsDrawerClosed() {
    update(['notificationsDrawerArrow']);
  }

  void handlePttButtonDown(code, event) {
    if (isPttPressed$ || !canTalk) return;
    onPttPress(isHardware: true);
  }

  void handlePttButtonUp(code, event) {
    if (!isPttKeyPressed$) return;
    onPttRelease();
  }

  void handleSOSButtonDown(code, event) {
    if (isSosPressed$) return;
    onSosPress(sosKeyValue: true);
  }

  void handleSOSButtonUp(code, event) {
    if (!isSosKeyPressed$) return;
    onSosRelease();
  }

  void handleSwitchButtonUp(code, event) {
    switchActiveGroupByButtonSwitch(isUp: true);
  }

  void handleSwitchButtonDown(code, event) {
    switchActiveGroupByButtonSwitch(isUp: false);
  }

  Future<void> handleKeyDown(code, event) async {
    double volumeUnit = 0.1;
    if (DomainController.isPrivateDevice) return;
    if (code.toString() == "24") {
      _currentDeviceVolume = await VolumeControl.volume;
      TelloLogger().i(
          "Key Code 24 == $code _currentDeviceVolume == $_currentDeviceVolume");
      if (_currentDeviceVolume == 1.0) {
        return;
      }
      if (volumeUnit + _currentDeviceVolume > volumeUnit) {
        volumeUnit = _currentDeviceVolume - volumeUnit;
      }
      _currentDeviceVolume += volumeUnit;
      TelloLogger()
          .i("Key Code 24 == _currentDeviceVolume $_currentDeviceVolume");
      VolumeControl.setVolume(_currentDeviceVolume);
    } else if (code.toString() == "25") {
      _currentDeviceVolume = await VolumeControl.volume;
      TelloLogger().i(
          "Key Code 25 == $code _currentDeviceVolume == $_currentDeviceVolume");
      if (!Session.isManager) {
        if (_currentDeviceVolume <=
            (Session.isSupervisor
                ? 0.5
                : AppSettings().maxVolumeOnMobileDevice)) {
          return;
        }
      }
      if (_currentDeviceVolume - volumeUnit < 0.0) {
        volumeUnit = _currentDeviceVolume - volumeUnit;
      }
      _currentDeviceVolume -= volumeUnit;
      TelloLogger()
          .i("Key Code 25 == _currentDeviceVolume $_currentDeviceVolume");
      VolumeControl.setVolume(_currentDeviceVolume);
    }
    TelloLogger().i("Key Code  == $code");
  }

  RxBool isAllGroupSelected$ = false.obs;

  bool get isAllGroupSelected => isAllGroupSelected$.value;

  Future<void> setAllGroup() async {
    await PTTService().setActiveGroup(allGroup);
    isAllGroupSelected$.value = true;
  }

  Future<void> removeAllGroup() async {
    await PTTService().setActiveGroup(activeGroup);
    isAllGroupSelected$.value = false;
  }

  Future<void> setActiveGroup(RxGroup group,
      {bool showEventsDialog = true}) async {
    if (isAllGroupSelected) {
      return;
    }
    showEventsDialogAfterSettingGroup = showEventsDialog;
    await PTTService().setActiveGroup(group);
    GetStorage().write(StorageKeys.activeGroup, group.toMap(listToJson: true));
  }

  Future<void> _resetActiveGroup({bool showEventsDialog = true}) async {
    if (groups$.isEmpty) return;

    final savedActiveGroup =
        GetStorage().read<Map<String, dynamic>>(StorageKeys.activeGroup);
    final prevActiveGroupId =
        savedActiveGroup != null ? savedActiveGroup['id'] as String : null;

    RxGroup group;
    group = groups$.firstWhere(
        (gr) => gr.id == (prevActiveGroupId ?? Session.shift?.groupId),
        orElse: () => null!);

    await setActiveGroup(group, showEventsDialog: showEventsDialog);
  }

  Future<void> _fetchGroups() async {
    if (_fetchingGroups) return;

    _needFetchingGroups = false;
    _fetchingGroups = true;
    if (groupsFetched.isCompleted) groupsFetched = Completer();

    try {
      TelloLogger().i("call _fetchGroups ########### ");
      Iterable<RxGroup> groups;

      if (isOnline) {
        final groupsData = await _homeRepo.fetchGroups();

        groups = (groupsData['groups'] as List<dynamic>)
            .map((x) => RxGroup.fromMap(x as Map<String, dynamic>));
        GetStorage().write(StorageKeys.groups,
            json.encode(groups.map((g) => g.toMap(listToJson: true)).toList()));
      } else {
        final data = GetStorage().read<String>(StorageKeys.groups);
        groups = (json.decode(data!) as List<dynamic>).map((m) =>
            RxGroup.fromMap(m as Map<String, dynamic>, listFromJson: true)
              ..restoreEvents());
      }

      groups$
        ..clear()
        ..addAll(groups);

      allGroup.members.positions.clear();
      allGroup.members.users.clear();

      groups$.forEach((element) {
        allGroup.members.positions.addAll(element.members.positions);
        allGroup.members.users.addAll(element.members.users);
      });

      TelloLogger().i("_fetchGroups ########### ${groups$.length}");
    } catch (e, s) {
      TelloLogger().e('HomeController fetchGroups() error: $e', stackTrace: s);
      rethrow;
    } finally {
      _fetchingGroups = false;
      groupsFetched.complete();
    }
  }

  Future<void> fetchEventTypesConfig() async {
    try {
      if (isOnline) {
        final data = await _eventsRepo.fetchEventTypesConfig();
        await AppSettings().updateEventSettings(EventsSettings.fromMap(data));
        GetStorage().write(
            StorageKeys.eventSettings, AppSettings().eventSettings.toMap());
      } else {
        final data =
            GetStorage().read<Map<String, dynamic>>(StorageKeys.eventSettings);
        if (data == null)
          throw "AppSettings().eventSettings is null, can't work with events during offline";

        if (AppSettings().hasNoEventSettings) {
          await AppSettings().updateEventSettings(
              EventsSettings.fromMap(data, listFromJson: true));
        }
      }
      if (Get.isRegistered<EventHandlingService>())
        EventHandlingService.to!.populateUserEvents();
    } catch (e, s) {
      TelloLogger()
          .e('HomeController fetchEventTypesConfig() error: $e', stackTrace: s);
      rethrow;
    }
  }

  void _addSubscriptions() {
    _privateCallSub = RTCService().on("privateCallBusy", this, (ev, context) {
      stopPrivateCall();
      Get.showSnackbarEx(GetBar(
        backgroundColor: AppColors.error,
        message: LocalizationService().of().failedStartingPrivateCallTo,
        titleText: Text(LocalizationService().of().privateCall,
            style: AppTypography.captionTextStyle),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.brightIcon,
        ),
      ));
    });

    _privateCallSub =
        RTCService().on("recipientPeerNotFound", this, (ev, context) {
      stopPrivateCall();
      Get.showSnackbarEx(GetBar(
        backgroundColor: AppColors.error,
        message: LocalizationService().of().failedStartingPrivateCallTo,
        titleText: Text(LocalizationService().of().privateCall,
            style: AppTypography.captionTextStyle),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.brightIcon,
        ),
      ));
    });

    _activeGroupSub = activeGroup$.listen((activeGroup) {
      if (activeGroup == null) return;

      if (Session.hasShift && activeGroup.isCustomerGroup) {
        resetSwitchGroupTimer();
      } else {
        _cancelSwitchGroupTimer();
      }
      GetStorage().write(StorageKeys.currentActiveGroup, activeGroup.id);
    });

    _txStateSub = txState$.listen((txState) {
      try {
        if (txState.state == StreamingState.idle && _needFetchingGroups)
          _fetchGroups();
      } catch (e) {
        Get.showSnackbarEx(GetBar(
          backgroundColor: AppColors.error,
          message: 'Error While Refresh the Groups , Details => $e',
          titleText: Text(LocalizationService().of().systemInfo,
              style: AppTypography.captionTextStyle),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.brightIcon,
          ),
        ));
      }
    });

    _userOnlineSub = SystemEventsSignaling().on('UserOnlineEvent', this,
        (evf.Event event, context) async {
      try {
        final data = (event.eventData as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
        if (Session.user?.id == data['userId']) return;

        _updateOnlineStatusInGroups(
          positionGroupId:
              data['positionId'] != null ? data['activeGroupId'] : null,
          userId: data['userId'] as String,
          isOnline: data['online'] as bool,
          hasActiveSession: data['hasActiveSession'] as bool,
          roleId: data['roleId'] as String,
        );
        TelloLogger().i(
            'User ${data['userId']} role ${data['roleId']} online status: ${data['online']}');
      } catch (e, s) {
        TelloLogger().e('TransmittingEvent error: $e', stackTrace: s);
        Get.showSnackbarEx(GetBar(
          backgroundColor: AppColors.error,
          message: 'UserOnlineEvent error: $e',
          titleText: Text(LocalizationService().of().systemInfo,
              style: AppTypography.captionTextStyle),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.brightIcon,
          ),
        ));
      }
    });

    _transmittingSub = Signaling().on('TransmittingEvent', this,
        (evf.Event event, context) async {
      try {
        final data = (event.eventData as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
        _handleTransmittingEvent(data);
      } catch (e, s) {
        TelloLogger().e('TransmittingEvent error: $e', stackTrace: s);
        Get.showSnackbarEx(GetBar(
          backgroundColor: AppColors.error,
          message: 'TransmittingEvent error: $e',
          titleText: Text(LocalizationService().of().systemInfo,
              style: AppTypography.captionTextStyle),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.brightIcon,
          ),
        ));
      }
    });

    _transmittingPrivateCallSub = Signaling().on(
        'TransmittingPrivateCallEvent', this, (evf.Event event, context) async {
      try {
        final data = (event.eventData as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
        final bool isTransmitting = data["transmitting"] as bool;
        final groupId = data["groupId"] as String;
        final user = _handleTransmittingEvent(data, isPrivate: true);
        TelloLogger().i(
            'TransmittingPrivateCallEvent User ${data['userId']} groupId: $groupId');
        if (isTransmitting) {
          startPrivateCall(user, groupId: groupId);
        }
      } catch (e, s) {
        TelloLogger()
            .e('TransmittingPrivateCallEvent error: $e', stackTrace: s);
        Get.showSnackbarEx(GetBar(
          backgroundColor: AppColors.error,
          message: 'TransmittingPrivateCallEvent error: $e',
          titleText: Text(LocalizationService().of().systemInfo,
              style: AppTypography.captionTextStyle),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.brightIcon,
          ),
        ));
      }
    });

    _closePrivateCallSub = Signaling().on('ClosePrivateCallEvent', this,
        (evf.Event event, context) async {
      try {
        TelloLogger().i("Get ClosePrivateCallEvent");
        final data = (event.eventData as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
        stopPrivateCall();
      } catch (e, s) {
        TelloLogger().e('ClosePrivateCallEvent error: $e', stackTrace: s);
        Get.showSnackbarEx(GetBar(
          backgroundColor: AppColors.error,
          message: 'ClosePrivateCallEvent error: $e',
          titleText: Text(LocalizationService().of().systemInfo,
              style: AppTypography.captionTextStyle),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.brightIcon,
          ),
        ));
      }
    });

    _userLocationSub = SystemEventsSignaling().on('UserLocationEvent', this,
        (evf.Event event, context) async {
      try {
        final data = (event.eventData as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
        if (AppSettings().enableHistoryTracking &&
            EntitiesHistoryTracking().isTracking) {
          return;
        }
        //we update the self location separately in the LocationService
        if (data['userId'] as String != Session.user!.id) {
          final location = data['location'] != null
              ? UserLocation.fromMap(data['location'] as Map<String, dynamic>)
              : null;
          TelloLogger().i(
              "UserLocationEvent 1111111111 ===> ${location?.locationDetails?.speed}");
          _updateUserLocationInGroups(
            userId: data['userId'] as String,
            location: location!,
          );
        }

        TelloLogger().i('User location updated for user ${data['userId']}');
      } catch (e, s) {
        TelloLogger().e('UserLocationEvent error: $e', stackTrace: s);
        Get.showSnackbarEx(GetBar(
          backgroundColor: AppColors.error,
          message: 'UserLocationEvent error: $e',
          titleText: Text(LocalizationService().of().systemInfo,
              style: AppTypography.captionTextStyle),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.brightIcon,
          ),
        ));
      }
    });

    _positionUpdateSub = SystemEventsSignaling().on('PositionUpdateEvent', this,
        (evf.Event event, context) async {
      try {
        final data = (event.eventData as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
        if (AppSettings().enableHistoryTracking &&
            EntitiesHistoryTracking().isTracking) {
          return;
        }
        TelloLogger()
            .i("PositionUpdateEvent ===> ${data["worker"].toString()}");
        final worker = data["worker"] != null
            ? RxUser.fromMap(data["worker"] as Map<String, dynamic>)
            : null;
        TelloLogger().i(
            'PositionUpdateEvent ${data['positionState']['positionId']} == ${Session.shift?.positionId} ${Session.shift?.positionId == data['positionState']['positionId']}##############################');

        updatePosition(
          positionId: data['positionState']['positionId'] as String,
          status: PositionStatus.values[data['positionState']['status'] as int],
          alertCheckState: AlertCheckState
              .values[(data['positionState']['checkState'] as int) - 1],
          worker: worker!,
          workerLocation: data['positionState']['coordinate'] != null
              ? Coordinates.fromMap(data['positionState']['coordinate'])
              : null!,
          statusUpdatedAt: data['positionState']['statusUpdatedAt'] as int,
          alertCheckStateUpdatedAt:
              data['positionState']['checkStateUpdatedAt'] as int,
        );

        TelloLogger().i(
            'Position updated for position ${data['positionState']['title']} == ${data['positionState']['positionId']} STATUS == ${PositionStatus.values[data['positionState']['status'] as int]} alertnessState: ${AlertCheckState.values[(data['positionState']['checkState'] as int) - 1]}');
      } catch (e, s) {
        TelloLogger().e('PositionUpdateEvent error: $e', stackTrace: s);
        Get.showSnackbarEx(GetBar(
          backgroundColor: AppColors.error,
          message: 'PositionUpdateEvent error: $e',
          titleText: Text(LocalizationService().of().systemInfo,
              style: AppTypography.captionTextStyle),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.brightIcon,
          ),
        ));
      }
    });

    _groupDevicesStatSub = SystemEventsSignaling()
        .on('GroupDevicesStatEvent', this, (evf.Event event, context) async {
      try {
        final data = (event.eventData as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
        final List<dynamic> list = data['deviceStats'] as List<dynamic>;
        TelloLogger().i('GroupDevicesStatEvent LENGTH: ${list.length}');
        // final stopwatch = Stopwatch()..start();

        for (int index = 0; index < list.length; index++) {
          final deviceState = DeviceState.fromMap(
              list[index]['deviceInfo'] as Map<String, dynamic>);
          if (AppSettings().enableHistoryTracking &&
              EntitiesHistoryTracking().isTracking) {
            return;
          }
          _updateDeviceState(
              groupId: data['groupId'] as String,
              positionId: list[index]['positionId'] as String,
              userId: list[index]['userId'] as String,
              deviceState: deviceState);
          TelloLogger().i(
              'Group Devices StatEvent Group Id:${data['groupId']} | positionId:${list[index]['positionId']} userId: ${list[index]['userId']} | deviceStats:${list[index]['deviceInfo']}');
        }
        // stopwatch.stop();
        // Logger().log("GroupDevicesStatEvent stopwatch elapsed: ${stopwatch?.elapsedMilliseconds}");
      } catch (e, s) {
        TelloLogger().e('GroupDevicesStatEvent error: $e', stackTrace: s);
        Get.showSnackbarEx(GetBar(
          backgroundColor: AppColors.error,
          message: 'GroupDevicesStatEvent error: $e',
          titleText: Text(LocalizationService().of().systemInfo,
              style: AppTypography.captionTextStyle),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.brightIcon,
          ),
        ));
      }
    });
    _newEventSub =
        SystemEventsSignaling().on('NewEvent', this, (event, context) {
      try {
        final data = (event.eventData as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
        TelloLogger().i('Incoming NewEvent $data');

        EventHandlingService.to!.handleEvent(data);
      } catch (e, s) {
        TelloLogger().e('NewEvent error: $e', stackTrace: s);
        Get.showSnackbarEx(GetBar(
          backgroundColor: AppColors.error,
          message: 'NewEvent error: $e',
          titleText: Text(LocalizationService().of().systemInfo,
              style: AppTypography.captionTextStyle),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.brightIcon,
          ),
        ));
      }
    });

    _updatedEventSub =
        SystemEventsSignaling().on('UpdatedEvent', this, (event, context) {
      try {
        final data = (event.eventData as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
        TelloLogger().i('Incoming UpdatedEvent $data');

        EventHandlingService.to!.handleEventUpdate(data);
      } catch (e, s) {
        TelloLogger().e('UpdatedEvent error: $e', stackTrace: s);
        Get.showSnackbarEx(GetBar(
          backgroundColor: AppColors.error,
          message: 'UpdatedEvent error: $e',
          titleText: Text(LocalizationService().of().systemInfo,
              style: AppTypography.captionTextStyle),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.brightIcon,
          ),
        ));
      }
    });

    _logoutEventSub =
        SystemEventsSignaling().on('LogoutEvent', this, (event, context) async {
      if (loadingState == ViewState.exit) return;

      TelloLogger().i('LogoutEvent received, logging out...');
      await _showLogoutFromDeviceMessage();
    });

    _socketErrorSub =
        SystemEventsSignaling().errorOnSocket.listen((value) async {
      TelloLogger().i('errorOnSocket, logging out...');
      await _showLogoutFromDeviceMessage(error: true);
    });

    _positionUpdatedEventSub = SystemEventsSignaling()
        .on('PositionUpdatedEvent', this, (event, context) async {
      try {
        final data = (event.eventData as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
        TelloLogger().i('PositionUpdatedEvent data: $data');
        //TODO: uncomment when positions list is reactive
        // final id = data['id'] as String;
        // final groupId = data['groupId'] as String;
        // final isLocked = data['isLocked'] as bool;
        // final isDeleted = data['isDeleted'] as bool;
        // if (isLocked || isDeleted) {
        //   Logger().log('Deleting item...');
        //   groups$
        //     .firstWhere((gr) => gr.id == groupId, orElse: () => null)
        //       ?.members
        //       ?.positions
        //       ?.removeWhere((pos) => pos.id == id);
        // } else {
        if (isSpeaking || isListening) {
          _needFetchingGroups = true;
        } else {
          _loadingState(ViewState.loading);
          await _fetchGroups();
          _loadingState(ViewState.success);
        }
        if (!_fetchingGroups) await _resetActiveGroup(showEventsDialog: false);
        // }
      } catch (e) {
        Get.showSnackbarEx(GetBar(
          backgroundColor: AppColors.error,
          message: 'Error On PositionUpdatedEvent , Details => $e',
          titleText: Text(LocalizationService().of().systemInfo,
              style: AppTypography.captionTextStyle),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.brightIcon,
          ),
        ));
      }
    });

    _groupUpdatedEventSub = SystemEventsSignaling()
        .on('GroupUpdatedEvent', this, (event, context) async {
      try {
        final data = (event.eventData as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
        TelloLogger().i('GroupUpdatedEvent data: $data, fetching groups...');
        if (isSpeaking || isListening) {
          _needFetchingGroups = true;
        } else {
          _loadingState(ViewState.loading);
          await _fetchGroups();
          _loadingState(ViewState.success);
        }
        if (!_fetchingGroups) await _resetActiveGroup(showEventsDialog: false);
      } catch (e) {
        Get.showSnackbarEx(GetBar(
          backgroundColor: AppColors.error,
          message: 'Error On GroupUpdatedEvent , Details => $e',
          titleText: Text(LocalizationService().of().systemInfo,
              style: AppTypography.captionTextStyle),
          icon: const Icon(
            Icons.warning_amber_rounded,
            color: AppColors.brightIcon,
          ),
        ));
      }
    });
  }

  RxUser _handleTransmittingEvent(Map<String, dynamic> data,
      {bool isPrivate = false}) {
    final isPosition = data['positionId'] != null;
    final String positionId =
        data["positionId"] != null ? data["positionId"] : null;
    final groupId = data['groupId'] as String;
    final bool isTransmitting = data["transmitting"] as bool;
    final userId = data['userId'] as String;
    RxUser? user;
    if (!isPrivate &&
        groupId != 'all' &&
        groups.firstWhere((element) => element.id == groupId,
                orElse: () => null!) ==
            null) {
      return null!;
    }
    TelloLogger().i(
        "_handleTransmittingEvent ==== > ${user!.id} ,,$isPrivate ,, $isTransmitting");
    if (userId != null && groupId != null) {
      final group =
          groups$.firstWhere((gr) => gr.id == groupId, orElse: () => null!);
      user = group.members.users
          .firstWhere((u) => u.id == userId, orElse: () => null!);
      final isCustomer = user.isCustomer ?? false;
      if (isCustomer) resetSwitchGroupTimer();
    }

    if (isPosition &&
        Session.shift?.positionId != (data['positionId'] as String)) {
      _updatePositionTransmittingStatus(
        groupId: data['groupId'] as String,
        positionId: data['positionId'] as String,
        value: data['transmitting'] as bool,
      );
    } else if (Session.user!.id != data['userId'] as String) {
      _updateUserTransmittingStatus(
        groupId: data['groupId'] as String,
        userId: data['userId'] as String,
        value: data['transmitting'] as bool,
      );
    }

    user = RxUser.unknownUser(userId);

    user.isOnline.value = true;

    if (!isPrivate) {
      _updateLastMessageAt(data);
      _groupIsTransmitting(user, positionId, isTransmitting, groupId);
    }

    if (!isTransmitting && AppSettings().videoModeEnabled) {
      remoteVideoDisplay.value = false;
      if (_remoteRenderer != null) {
        _remoteRenderer.srcObject = null as MediaStream;
      }
    }

    TelloLogger().i('Transmitting status updated for '
        '${isPosition ? 'position' : 'user'} ${data[isPosition ? 'positionId' : 'userId']}');
    TelloLogger().i('is transmitting: ${data['transmitting']}');
    return user;
  }

  void _cancelSwitchGroupTimer() {
    if (_switchToPrimaryGroupTimer.isActive)
      _switchToPrimaryGroupTimer.cancel();
  }

  void resetSwitchGroupTimer() {
    _cancelSwitchGroupTimer();

    _switchToPrimaryGroupTimer = Timer(
        Duration(seconds: AppSettings().switchToPrimaryGroupTimeoutSec), () {
      final targetGroup = groups.firstWhere(
          (gr) => Session.shift?.groupId == gr.id,
          orElse: () => null!);
      if (targetGroup != null) {
        setActiveGroup(targetGroup);
      } else {
        throw 'resetSwitchGroupTimer() => no target group found!';
      }
    });
  }

  void _updateLastMessageAt(Map<String, dynamic> data) {
    final sourceGroup = groups$.firstWhere((gr) => gr.id == data['groupId'],
        orElse: () => null!);
    if (sourceGroup != null)
      sourceGroup.lastMessageAt!(dateTimeToSeconds(DateTime.now().toUtc()));
  }

  Future<void> showUserInfo(RxUser user) async {
    await Get.bottomSheet(EntityDetailsInfo.createDetails(user: user));
  }

  Future<void> showPositionInfo(RxPosition position) async {
    await Get.bottomSheet(EntityDetailsInfo.createDetails(pos: position));
  }

  void switchCamera() {
    PTTService().switchCamera();
  }

  Future<void> _initPttService() async {
    Loader.updateSubTitle("Init PTT Services");
    try {
      for (final listener in _listeners) {
        listener.cancel();
      }
      MediaSettings().init();
      await PTTService().init(isOnline: isOnline);

      TelloLogger().i("PTTService().init() ##########################");
      setActiveGroupError$.bindStream(RTCService().setActiveGroupError$);
      isMediaOnline$.bindStream(RTCService().isOnline$);
      txState$.bindStream(RTCService().callState$);
      activeGroup$.bindStream(PTTService().activeGroup$);
      _isMediaOnlineSub = isMediaOnline$.listen((online) {
        if (!online) {
          stopPrivateCall();
        }
      });

      deviceDetails$!.value = RTCService().device.deviceDetails;
      _listeners.add(PTTService().on('trackStats', this, (event, context) {
        final MediaTrackStats mediaTrackStats =
            event.eventData as MediaTrackStats;
        if (mediaTrackStats == null) return;

        if (mediaTrackStats.bytesSent! > 0) {
          StatisticsService().avgPttBytesSent = mediaTrackStats.bytesSent!;
        }

        if (mediaTrackStats.bytesReceived! > 0) {
          StatisticsService().avgPttBytesReceived =
              mediaTrackStats.bytesReceived!;
        }

        if (SettingsController.to!.showTransportStats) {
          if (!mediaTrackStats.isVideo!) {
            if (mediaTrackStatsAudioList$.length > 600) {
              mediaTrackStatsAudioList$.clear();
            }
            mediaTrackStatsAudioList$.add(mediaTrackStats);
          } else {
            if (mediaTrackStatsVideoList$.length > 600) {
              mediaTrackStatsVideoList$.clear();
            }
            mediaTrackStatsVideoList$.add(mediaTrackStats);
          }
        }
      }));

      _listeners.add(PTTService().on('producerOffer', this, (event, context) {
        if (SettingsController.to!.showTransportStats) {
          producerOffer$.value = event.eventData as String;
          TelloLogger().i("producerOffer ====> ${producerOffer$.value}");
        }
      }));

      _listeners.add(PTTService().on('consumerOffer', this, (event, context) {
        if (SettingsController.to!.showTransportStats) {
          consumerOffer$.value = event.eventData as String;
          TelloLogger().i("consumerOffer ====> ${consumerOffer$.value}");
        }
      }));

      _listeners.add(PTTService().on('consumerInfo', this, (event, context) {
        if (SettingsController.to!.showTransportStats) {
          consumerInfo$!.value = event.eventData as ConsumerInfo;
          TelloLogger().i("consumerInfo ====> ${consumerInfo$!.value}");
        }
      }));

      _listeners.add(PTTService().on('producerInfo', this, (event, context) {
        if (SettingsController.to!.showTransportStats) {
          producerInfo$!.value = event.eventData as ProducerInfo;
          TelloLogger().i("producerInfo ====> ${producerInfo$!.value}");
        }
      }));

      if (AppSettings().videoModeEnabled) {
        _listeners
            .add(PTTService().on("localStreamAdded", this, (ev, context) async {
          if (_localRenderer.textureId == null) {
            await _localRenderer.initialize();
          }
          final MediaStream stream = ev.eventData as MediaStream;
          if (stream.getVideoTracks().isNotEmpty) {
            _localRenderer.objectFit =
                RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
            _localRenderer.srcObject = ev.eventData as MediaStream;
            update(["localVideoDisplayId"]);
            localVideoDisplay.value = true;
          }
        }));

        _listeners.add(
            PTTService().on("localStreamRemoved", this, (ev, context) async {
          _localRenderer.srcObject = null as MediaStream;
          localVideoDisplay.value = false;
        }));

        _listeners.add(PTTService().on("videoRemoteStreamAdded", this,
            (ev, context) async {
          if (_remoteRenderer.textureId == null) {
            await _remoteRenderer.initialize();
          }
          TelloLogger()
              .i("videoRemoteStreamAdded == ${ev.eventData as MediaStream}");
          remoteVideoDisplay.value = true;
          _remoteRenderer.objectFit =
              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover;
          _remoteRenderer.srcObject = ev.eventData as MediaStream;
          update(["videoDisplayId"]);
        }));

        _listeners.add(
            PTTService().on("videoRemoteStreamRemoved", this, (ev, context) {
          TelloLogger()
              .i("videoRemoteStreamRemoved == ${ev.eventData as MediaStream}");
          final MediaStream stream = ev.eventData as MediaStream;
          if (stream != null &&
              stream.getVideoTracks().isNotEmpty &&
              remoteVideoDisplay.value) {
            remoteVideoDisplay.value = false;
            if (_remoteRenderer != null) {
              _remoteRenderer.srcObject = null as MediaStream;
            }
          }
        }));
      }
    } catch (e, s) {
      TelloLogger().e("PTTService().init() With Errors $e", stackTrace: s);
    } finally {
      Loader.updateSubTitle("");
    }
    TelloLogger().i("PTTService().init() DONE ##########################");
  }

  Future<void> _initServices() async {
    Loader.updateSubTitle("Start Init Services");
    await _initPttService();
    Loader.updateSubTitle("Init Location Services");
    LocationService().init();
    Loader.updateSubTitle("Init Sound pool Services");
    await SoundPoolService().init();
    Loader.updateSubTitle("Init System Events Services");
    await SystemEventsSignaling().init();

    if (Session.hasShiftStarted!) {
      Loader.updateSubTitle("Init Shift Activities Services");
      await Get.putAsync(() => ShiftActivitiesService().init());
    }

    Get.put(ns.NotificationService());
    Get.put(EventHandlingService());
    Get.put(NetworkJitterController(
        RxBool(isOnline$())..bindStream(isOnline$.stream)));
    Loader.updateSubTitle("InitSystem Events Service");
    await SystemEventsSignaling().connect();
    Loader.updateSubTitle("Getting Current Location");
    final Position myPosition = await LocationService().getCurrentPosition();
    Loader.updateSubTitle("Update Current Location");
    SystemEventsSignaling().sendUpdatedLocation(myPosition);
    Loader.updateSubTitle("Complete Init Services");
    servicesInit.complete();
    servicesInitialized$(true);
  }

  Future<void> _disposeServices() async {
    StatisticsService().dispose();
    await DataUsageService().stop();
    LocationService().dispose();
    await SoundPoolService().dispose();
    await PTTService().dispose();
    await SystemEventsSignaling().dispose();
    if (AppSettings().enableHistoryTracking) {
      EntitiesHistoryTracking().close();
    }
    try {
      ActivityRecognitionService().stop();
      if (AppSettings().videoModeEnabled) {
        if (_remoteRenderer != null) {
          _remoteRenderer.dispose();
        }
        if (_localRenderer != null) {
          _localRenderer.dispose();
        }
      }
    } catch (e, s) {
      TelloLogger().e("Error ActivityRecognitionService().dispose() = $e",
          stackTrace: s);
    }
    Get.delete<ShiftService>(force: true);
  }

  Future<void> _cancelAllSubscribers() async {
    shiftTimer?.cancel();
    _autoPttReleaseTimer?.cancel();
    Keyboard.onPttButtonDown.remove(handlePttButtonDown);
    Keyboard.onPttButtonUp.remove(handlePttButtonUp);
    Keyboard.onSwitchButtonDown.remove(handleSwitchButtonUp);
    Keyboard.onKeyDown.remove(handleKeyDown);
    Keyboard.onSOSButtonDown.remove(handleSOSButtonDown);
    Keyboard.onSOSButtonUp.remove(handleSOSButtonUp);
    searchInputCtrl.dispose();
    activeGroup$.value = null as RxGroup;
    Pointer.pointerUp = null;
    Pointer.pointerDown = null;
    HardwareKey.onHardwareKey = null;
    _periodicShiftTimestampTimer?.cancel();
    dataConnectionCheckerSub.cancel();
    _switchToPrimaryGroupTimer.cancel();
    batteryLevelTimer.cancel();
    _userOnlineSub.cancel();
    _transmittingSub.cancel();
    _transmittingPrivateCallSub.cancel();
    _closePrivateCallSub.cancel();
    lastMessageAtRefreshTimer.cancel();
    _isMediaOnlineSub.cancel();
    _isOnlineSub.cancel();
    _activeGroupSub.cancel();
    _privateCallSub.cancel();
    _txStateSub.cancel();
    _shouldResetCurrentChatPageIndexSub.cancel();
    _userLocationSub.cancel();
    _positionUpdateSub.cancel();
    _groupDevicesStatSub.cancel();
    _updatedEventSub.cancel();
    _newEventSub.cancel();
    _logoutEventSub.cancel();
    _socketErrorSub.cancel();
    _positionUpdatedEventSub.cancel();
    _groupUpdatedEventSub.cancel();
    privateCallPeriodTimer.cancel();
    _networkRecoveryTimer?.cancel();
    //fetchOperatorsCallPeriodTimer?.cancel();
    cancelSosPressedListeners();
    for (final listener in _listeners) {
      listener.cancel();
    }
    for (final sub in _sosPressedListeners) {
      sub.cancel();
    }

    SystemEventsSignaling().removeListener('LogoutEvent', (ev, context) {});
    SystemEventsSignaling()
        .removeListener('GroupDevicesStatEvent', (ev, context) {});
    SystemEventsSignaling().removeListener('UpdatedEvent', (ev, context) {});
    SystemEventsSignaling()
        .removeListener('TransmittingEvent', (ev, context) {});
    SystemEventsSignaling().removeListener('UserOnlineEvent', (ev, context) {});
    SystemEventsSignaling()
        .removeListener('UserLocationEvent', (ev, context) {});
    SystemEventsSignaling()
        .removeListener('PositionUpdateEvent', (ev, context) {});
    SystemEventsSignaling().removeListener('NewEvent', (ev, context) {});

    shiftTimer = null;
    privateCallPeriodTimer = 0 as Timer;
    _periodicShiftTimestampTimer = null;
    _switchToPrimaryGroupTimer = 0 as Timer;
    batteryLevelTimer = 0 as Timer;
    lastMessageAtRefreshTimer = null as Timer;
    _isOnlineSub = null as StreamSubscription<Object>;
    _isMediaOnlineSub = null as StreamSubscription<Object>;
    _activeGroupSub = null as StreamSubscription<Object>;
    _txStateSub = null as StreamSubscription<Object>;
    _privateCallSub = null!;
    _userOnlineSub = null!;
    _transmittingSub = null!;
    _transmittingPrivateCallSub = null!;
    _closePrivateCallSub = null!;
    _userLocationSub = null!;
    _positionUpdateSub = null!;
    _groupDevicesStatSub = null!;
    _updatedEventSub = null!;
    _newEventSub = null!;
    _logoutEventSub = null!;
    _positionUpdatedEventSub = null!;
    _groupUpdatedEventSub = null!;
  }

  Future<void> releaseResources() async {
    if (_resourcesReleased) return;
    await _cancelAllSubscribers();
    await _disposeServices();
    _resourcesReleased = true;
  }

  @override
  Future<void> onClose() async {
    TelloLogger()
        .i("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@HOME CONTROLLER ON CLOSE START");
    //Wakelock.disable();
    homeTabBarController?.dispose();
    bottomNavBarController?.dispose();
    await releaseResources();

    super.onClose();
    TelloLogger()
        .i("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@HOME CONTROLLER ON CLOSE COMPLETE");
  }

  void _updateOnlineStatusInGroups({
    required String userId,
    required bool isOnline,
    required bool hasActiveSession,
    String? roleId,
    String? positionGroupId,
  }) {
    if (roleId != null && roleId == "Admin") {
      final adminUser = adminUsers.firstWhere((element) => element.id == userId,
          orElse: () => null!);
      if (adminUser != null) {
        adminUser
          ..isOnline(isOnline)
          ..onlineUpdatedAt = dateTimeToSeconds(DateTime.now())
          ..hasActiveSession(hasActiveSession);
        groups$.forEach((group) {
          update(['groupMembersOf${group.id}']);
        });
      }
    }
    for (final group in groups$) {
      if (group.id == positionGroupId) {
        final position = group.members.positions
            .firstWhere((p) => p.worker().id == userId, orElse: () => null!);
        position.worker().isOnline(isOnline);
      } else {
        final user = group.members.users
            .firstWhere((u) => u.id == userId, orElse: () => null!);
        if (user != null) {
          user
            ..isOnline(isOnline)
            ..onlineUpdatedAt = dateTimeToSeconds(DateTime.now())
            ..hasActiveSession(hasActiveSession);
          group.members.sortMembers(filter: searchInputCtrl.text);
          update(['groupMembersOf${group.id}']);
        }
      }
    }
  }

  void _updateUserTransmittingStatus(
      {required String groupId, required String userId, required bool value}) {
    final group =
        groups$.firstWhere((gr) => gr.id == groupId, orElse: () => null!);
    group.members.users
        .firstWhere((u) => u.id == userId, orElse: () => null!)
        .isTransmitting(value);
  }

  void _updateUserLocationInGroups(
      {required String userId,
      required UserLocation location,
      String? skipGroupId}) {
    for (final group in groups) {
      if (group.id == skipGroupId) continue;
      final user = group.members.users
          .firstWhere((u) => u.id == userId, orElse: () => null!);
      if (user != null) user.location(location);
    }
  }

  void _updatePositionTransmittingStatus(
      {required String groupId,
      required String positionId,
      required bool value}) {
    final group =
        groups$.firstWhere((gr) => gr.id == groupId, orElse: () => null!);
    group.members.positions
        .firstWhere((p) => p.id == positionId, orElse: () => null!)
        .isTransmitting(value);
  }

  Future<void> updatePosition({
    required String positionId,
    PositionStatus? status,
    AlertCheckState? alertCheckState,
    Coordinates? workerLocation,
    RxUser? worker,
    int? statusUpdatedAt,
    int? alertCheckStateUpdatedAt,
  }) async {
    final group = groups$.firstWhere(
        (gr) => gr.members.positions.any((p) => p.id == positionId),
        orElse: () => null!);
    if (group != null) {
      final position =
          group.members.positions.firstWhere((p) => p.id == positionId);
      final bool isMyPosition = position.worker().id == Session.user!.id;
      bool membersNeedSorting = false;

      if (status != null && position.status() != status) {
        position
          ..status(status)
          ..statusUpdatedAt = statusUpdatedAt!;
        membersNeedSorting = true;
      }
      if (position.alertCheckState() != alertCheckState) {
        position
          ..alertCheckState(alertCheckState)
          ..alertCheckStateUpdatedAt = alertCheckStateUpdatedAt!;
        membersNeedSorting = true;
      }
      if (membersNeedSorting) {
        group.members.sortMembers(filter: searchInputCtrl.text);
        update(['groupMembersOf${group.id}']);
      }

      if (worker != null) {
        if (position.worker() == null) {
          position.worker(worker);
        } else {
          position.worker().updateFromUser(worker, completely: !isMyPosition);
        }

        final hasLocationChanged = position.workerLocation().latitude !=
                workerLocation?.latitude ||
            position.workerLocation().longitude != workerLocation?.longitude;

        TelloLogger().i("position.workerLocation");
        position.workerLocation(workerLocation);

        //we update the self location separately in the LocationService
        if (!isMyPosition && worker.location() != null && hasLocationChanged) {
          final userLocation = worker.location().clone();
          //skipGroupId - we don't update user's location in the group, where he is on a position
          _updateUserLocationInGroups(
              userId: worker.id, location: userLocation, skipGroupId: group.id);
        }
      }

      // if (Session.user.isSupervisor) {
      //   _checkPositionOutOfRangeState(position);
      //   _checkPositionAlertnessState(position);
      // }
    }
  }

  //TODO: refactor in favor of using EventHandlingService when we get the event via system events and not in a position update
  // void _checkPositionOutOfRangeState(RxPosition pos) {
  //   final isPTTBusy = txState$().state != StreamingState.idle;
  //
  //   if (pos == null || isPTTBusy || pos.worker().hasGPSSignal) return;
  //
  //   final isMyPosition = Session.shift?.positionId == pos.id;
  //   final isOutOfRange = pos.status() == PositionStatus.outOfRange;
  //   final isPositionInGroup = activeGroup?.members?.positions?.any((p) => p.id == pos.id) ?? false;
  //
  //   if (Session.isSupervisor && !isMyPosition && isOutOfRange && isPositionInGroup) {
  //     final event = Event(
  //       // id: Uuid().v1(),
  //       groupId: activeGroup.id,
  //       createdAt: DateTime.now().millisecondsSinceEpoch,
  //       type: EventType.outOfRange,
  //       coordinates: pos.coordinates,
  //       // isConfirmed$: false.obs,
  //       // ownerId: null,
  //       ownerPositionId: pos.id,
  //       // ownerTitle: pos.title,
  //       // status: EventStatus.open.obs,
  //     );
  //
  //     // EventHandlingService.to.handleEvent(event, activeGroup);
  //   }
  // }

  //TODO: refactor in favor of using EventHandlingService when we get the event via system events and not in a position update
  // void _checkPositionAlertnessState(RxPosition pos) {
  //   final isPTTBusy = txState$().state != StreamingState.idle;
  //
  //   if (pos == null || isPTTBusy) return;
  //
  //   final isAlertCheckFailed = pos.alertCheckState() == AlertCheckState.failed;
  //   final isAlertCheckPassed = !isAlertCheckFailed;
  //   final isMyPosition = Session.shift?.positionId == pos.id;
  //   final isPositionInGroup = activeGroup?.members?.positions?.any((p) => p.id == pos.id) ?? false;
  //
  //   if (Session.isSupervisor && isAlertCheckFailed && !isMyPosition && isPositionInGroup) {
  //     final event = Event(
  //       // id: Uuid().v1(),
  //       groupId: activeGroup.id,
  //       createdAt: DateTime.now().millisecondsSinceEpoch,
  //       type: EventType.alertnessFailed,
  //       coordinates: pos.coordinates,
  //       // isConfirmed$: false.obs,
  //       // ownerId: null,
  //       ownerPositionId: pos.id,
  //       // ownerTitle: pos.title,
  //       // status: EventStatus.open.obs,
  //     );
  //
  //     // EventHandlingService.to.handleEvent(event, activeGroup);
  //   }
  // }

  void _updateDeviceState(
      {required String groupId,
      required String userId,
      required DeviceState deviceState,
      String? positionId}) {
    for (int groupIndex = 0; groupIndex < groups$.length; groupIndex++) {
      if (positionId != null) {
        if (groups$[groupIndex].members.positions != null) {
          final position = groups$[groupIndex]
              .members
              .positions
              .firstWhere((p) => p.id == positionId, orElse: () => null!);

          position.worker().deviceCard.deviceState(deviceState);
        }
      } else if (userId != null) {
        if (groups$[groupIndex].members.users != null) {
          final user = groups$[groupIndex]
              .members
              .users
              .firstWhere((u) => u.id == userId, orElse: () => null!);
          user.deviceCard.deviceState(deviceState);
          if (AppSettings().enableHistoryTracking &&
              EntitiesHistoryTracking().isTracking &&
              user != null) {
            EntitiesHistoryTracking().trackUserData(user,
                deviceState: deviceState,
                alertCheckState: null as AlertCheckState,
                isOnline: null as bool,
                location: null as UserLocation,
                onlineUpdatedAt: null as int,
                rating: null as int);
            return;
          }
        }
        if (groups$[groupIndex].members.positions != null) {
          final position = groups$[groupIndex]
              .members
              .positions
              .firstWhere((p) => p.worker().id == userId, orElse: () => null!);
          if (AppSettings().enableHistoryTracking &&
              EntitiesHistoryTracking().isTracking &&
              position != null &&
              position.worker.value != null) {
            EntitiesHistoryTracking().trackPositionData(position,
                workerLocation: position.workerLocation.value,
                status: position.status.value,
                alertCheckState: position.alertCheckState.value,
                worker: position.worker.value,
                statusUpdatedAt: position.statusUpdatedAt,
                alertCheckStateUpdatedAt: position.alertCheckStateUpdatedAt,
                deviceState: deviceState);
            return;
          }
          position.worker().deviceCard.deviceState(deviceState);
        }
      }
    }
  }

  // ignore: use_setters_to_change_properties
  void startPrivateCall(RxUser operator,
      {String? groupId, bool canClosePrivateCall = false}) {
    if (privateCallUser != null && privateCallUser.id != operator.id) {
      SystemDialog.showConfirmDialog(
        title: LocalizationService().of().info,
        message: LocalizationService().of().privateCallIsOngoing,
        confirmButtonText: LocalizationService().of().ok,
      );
      return;
    }
    if (operator != null && privateCallUser == null) {
      privateCallUser = operator;
      _privateGroupId = groupId!;
      canClosePrivateCall$.value = canClosePrivateCall;
      if (canClosePrivateCall) {
        privateCallPeriodTimer.cancel();
        privateCallPeriodTimer = null as Timer;
        privateCallPeriodTimer = Timer(const Duration(seconds: 60), () {
          stopPrivateCall();
        });
      }
    }
  }

  Future<void> stopPrivateCall() async {
    if (canClosePrivateCall) {
      await RTCService().closePrivateCall(privateCallUser$.value);
      privateCallPeriodTimer.cancel();
      privateCallPeriodTimer = null!;
    }
    privateCallUser = null as RxUser;
    canClosePrivateCall$.value = false;
  }

  /// We record every transmission, and stopping recording takes some time, especially the online one.
  /// When the PTT button is released, we don't await for the recording to be finalized, so we do this
  /// during the next button press, if we need.
  /// The PTT button can be released during finalizing the prev.recording, so we return, if it's not pressed anymore.
  ///
  /// E.g.: right after the transmission a user starts another one, and instantly releases the button.
  Future<void> onPttPress({bool auto = false, bool isHardware = false}) async {
    if (isPttDisabled) return;
    isPttPressed$ = true;
    isPttKeyPressed$ = isHardware;
    try {
      releasePttAuto = auto;
      if (RTCService().prevRecordingComplete != null &&
          !RTCService().prevRecordingComplete.isCompleted) {
        finalizingPrevRecording = true;
        TelloLogger().i(
            "HomeController onPttPress(): waiting for prevRecordingComplete...");
        RTCService().setPreparing();
        await RTCService().prevRecordingComplete.future;
        finalizingPrevRecording = false;
        if (!isPttPressed$) {
          TelloLogger().i(
              "HomeController onPttPress(): button released during finalizingPrevRecording, aborting...");
          return;
        }
      }
      if (isInRecordingMode ||
          (privateCallUser != null && !privateCallUser.isOnline())) {
        _isRecordingOfflineMessage(true);
        RTCService().recordOfflineMessage(privateCallUser: privateCallUser);
      } else {
        PTTService().sendRTCMessage(
            privateCallUser: privateCallUser,
            privateGroupId: _privateGroupId,
            isPtt: showPtt.value);
      }
      if (AppSettings().pttBroadcastTimeoutDuration >= 10) {
        _autoPttReleaseTimer = Timer(
            Duration(seconds: AppSettings().pttBroadcastTimeoutDuration),
            onPttRelease);
      }
    } catch (e) {
      Get.showSnackbarEx(GetBar(
        backgroundColor: AppColors.error,
        message: 'on Ptt Press failure cant get receiving user $e',
        titleText:
            const Text("on Ptt Press", style: AppTypography.captionTextStyle),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.brightIcon,
        ),
      ));
    }
  }

  /// If a user releases the PTT button before finalizingPrevRecording, we return
  void onPttRelease({bool auto = false}) {
    try {
      if (releasePttAuto && !auto) return;
      _autoPttReleaseTimer?.cancel();
      isPttPressed$ = false;
      isPttKeyPressed$ = false;

      if (finalizingPrevRecording) {
        finalizingPrevRecording = false;
        RTCService().unsetPreparing();
        TelloLogger().i(
            "HomeController onPttRelease(): released during finalizing prev. recording, aborting...");
        return;
      }

      if (isRecordingOfflineMessage) {
        _isRecordingOfflineMessage(false);
        RTCService().stopOfflineRecording();
      } else {
        PTTService().stopSending();
      }
    } catch (e, s) {
      TelloLogger().e("onPttRelease error $e", stackTrace: s);
      Get.showSnackbarEx(GetBar(
        backgroundColor: AppColors.error,
        message: 'on Ptt Release failure cant get receiving user $e',
        titleText:
            const Text("on Ptt Release", style: AppTypography.captionTextStyle),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.brightIcon,
        ),
      ));
    }
  }

  void onSosPress({bool sosKeyValue = false}) {
    if (isSosDisabled) return;
    isSosPressed$ = true;
    isSosKeyPressed$ = sosKeyValue;
    final sosService = SosService.to;
    Vibrator.startShortVibration();
    sosService.playSosSendingSound();
    sosService.buildCountdownSnackBar();
    HapticFeedback.lightImpact();
  }

  void onSosRelease({bool sosKeyValue = false}) {
    isSosKeyPressed$ = sosKeyValue;
    isSosPressed$ = false;
    final sosService = SosService.to;
    if (Get.isSnackbarOpen) Get.back();
    sosService.timerController.pause();
    sosService.stopSosSendingSound();
  }

  Future<void> showTransmittingNotification(
      String srcGroupId, String fullName, String message,
      {bool longNotificationVibration = true}) async {
    if (Get.isSnackbarOpen)
      Get.until((route) => route.isFirst || Get.isDialogOpen!);

    final getBar = GetBar(
      title: fullName,
      message: message,
      duration: const Duration(seconds: 60),
      animationDuration: const Duration(milliseconds: 500),
      icon: const Center(
        child: FaIcon(
          FontAwesomeIcons.broadcastTower,
          size: 20,
        ),
      ),
      snackPosition: SnackPosition.TOP,
      backgroundColor: Colors.black26,
      barBlur: 60,
      snackbarStatus: (status) {
        if (status == SnackbarStatus.CLOSED) {
          Vibrator.stopNotificationVibration();
        } else if (status == SnackbarStatus.OPEN) {
          longNotificationVibration
              ? Vibrator.startNotificationVibration()
              : Vibrator.startShortNotificationVibration();
        }
      },
      onTap: (_) async {
        if (Get.isSnackbarOpen)
          Get.until((route) => route.isFirst || Get.isDialogOpen!);
        final targetGroup = HomeController.to.groups.firstWhere(
          (gr) => gr.id == srcGroupId,
          orElse: () => null!,
        );
        await HomeController.to.setActiveGroup(targetGroup);
        HomeController.to.gotoBottomNavTab(BottomNavTab.ptt);
      },
    );

    Get.showSnackbar(getBar);

    ns.NotificationService.to.add(
      ns.Notification(
        icon: getBar.icon,
        title: getBar.title!,
        text: getBar.message!,
        bgColor: getBar.backgroundColor,
        callback: () => getBar.onTap!(getBar),
        groupType: NotificationGroupType.broadcast,
      ),
    );
  }

  // ignore: avoid_positional_boolean_parameters
  void _groupIsTransmitting(
      RxUser user, String positionId, bool isTransmit, String groupId) {
    if (activeGroup.id == groupId || !isTransmit || isAllGroupSelected) {
      return;
    }
    String? message;
    final RxGroup transmittingGroup =
        groups.firstWhere((group) => group.id == groupId, orElse: () => null!);
    if (transmittingGroup != null) {
      if (positionId != null) {
        final RxPosition position = transmittingGroup.members.positions
            .firstWhere((pos) => pos.id == positionId, orElse: () => null!);
        if (position != null) {
          message =
              "${position.title} ${LocalizationService().of().broadcastingIn} ${transmittingGroup.title}";
        }
      }
      message ??=
          "${user.fullName} ${LocalizationService().of().broadcastingIn} ${transmittingGroup.title}";
      showTransmittingNotification(groupId, transmittingGroup.title!, message,
          longNotificationVibration: false);
    }
  }
}
