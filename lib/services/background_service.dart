import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui';

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/coordinates_model.dart';
import 'package:bazz_flutter/models/events_settings.dart';
import 'package:bazz_flutter/models/group_model.dart';
import 'package:bazz_flutter/models/incoming_event.dart';
import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/services_address.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/modules/general/general_repo.dart';
import 'package:bazz_flutter/modules/home_module/events_repo.dart';
import 'package:bazz_flutter/modules/home_module/home_repo.dart';
import 'package:bazz_flutter/modules/settings_module/settings_controller.dart';
import 'package:bazz_flutter/services/data_connection_checker.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/networking_client.dart';
import 'package:bazz_flutter/services/notification_service.dart' as ns;
import 'package:bazz_flutter/services/session_service.dart';
import 'package:bazz_flutter/services/signaling.dart';
import 'package:bazz_flutter/services/system_events_signaling.dart';
import 'package:bazz_flutter/services/vibrator.dart';
import 'package:external_app_launcher/external_app_launcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_sound_lite/flutter_sound.dart' as fs;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:pausable_timer/pausable_timer.dart';

import 'background_main.dart';
import 'logger.dart';
import 'ptt_service.dart';

const MethodChannel _channel = MethodChannel('com.bazzptt/stopservice');

class PortMessage {
  String cmd;
  dynamic payload;

  PortMessage({required this.cmd, this.payload});
}

class BackgroundService {
  String playerSosReceiveAlarmFilePath = 'assets/sounds/sos_receive_alarm.mp3';
  String playerQUIZAlarmFilePath = 'assets/sounds/sos_sending_alarm.mp3';
  String quizAlarmFilePath = 'assets/sounds/quiz_alarm.mp3';
  fs.FlutterSoundPlayer playerModule = fs.FlutterSoundPlayer();
  bool isBackground = false;

  factory BackgroundService.instance() => _instance;

  BackgroundService._internal();

  static final _instance = BackgroundService._internal();
  final _applicationPinChannel = const MethodChannel('com.bazzptt/kiosk_mode');
  final _applicationInstallChannel =
      const MethodChannel('com.bazzptt/install_app');
  final _applicationSettings = const MethodChannel('com.bazzptt/settings');
  final _volumeControl = const MethodChannel('com.bazzptt/volume_control');

  Completer isolateCommunicationReady = Completer();
  final int alarmId = 0;
  static int INTERVAL = 60;
  bool _foregroundServiceStopped = true;

  int? _currentDay;
  String? _currentDate;
  DateTime? _todayCheckStartsAt;
  DateTime? _todayCheckEndsAt;
  Timer? _checkScheduleTimer;
  PausableTimer? _alertCheckTimer;
  Timer? _periodicShiftTimestampTimer;

  int? _secondsSinceLastCheck;
  bool? _isAppPinned = false;
  String? _activeGroupId;
  RxGroup? _activePositionGroup;

  final List<String> _groupsDidBroadcastIds = [];
  final List<String> _outOfRangeIds = [];
  final List<String> _alertnessFailedIds = [];

  void installAPK(String apkDestination) {
    _applicationInstallChannel
        .invokeMethod('installApp', {"destination": apkDestination});
  }

  void disableVolume() {
    _volumeControl.invokeMethod('disableVolume');
  }

  void enableVolume() {
    _volumeControl.invokeMethod('enableVolume');
  }

  void openNetworkSettings() {
    _applicationSettings.invokeMethod('showNetworkSettings');
  }

  void startApplicationPin() {
    if (!_isAppPinned!) {
      _applicationPinChannel.invokeMethod('onStartScreenPinning');
      _isAppPinned = true;
    }
  }

  void stopApplicationPin() {
    _applicationPinChannel.invokeMethod('onStopScreenPinning');
    _isAppPinned = false;
  }

  void activateScreenLock() {
    _applicationPinChannel.invokeMethod('activateScreenLock');
  }

  Future<void> playOutOfRangeSound() async {
    final languageCode = LocalizationService().getLanguageCode();
    final String soundOutOfRangeFilePath =
        'assets/sounds/out_of_range_$languageCode.mp3';

    final Uint8List soundBuffer =
        (await rootBundle.load(soundOutOfRangeFilePath)).buffer.asUint8List();
    if (playerModule.isPlaying) return;

    await playerModule.openAudioSession(
      focus: fs.AudioFocus.requestFocusAndDuckOthers,
      audioFlags: fs.outputToSpeaker,
    );
    await playerModule
        .setSubscriptionDuration(const Duration(milliseconds: 100));
    try {
      await playerModule.startPlayer(
        fromDataBuffer: soundBuffer,
        codec: fs.Codec.mp3,
        whenFinished: () {
          Vibrator.stopNotificationVibration();
        },
      );
    } catch (e, s) {
      TelloLogger().e('playOutOfRangeSound() error: $e', stackTrace: s);
    }
  }

  Future<void> playSOSReceiveSound() async {
    final Uint8List soundBuffer =
        (await rootBundle.load(playerSosReceiveAlarmFilePath))
            .buffer
            .asUint8List();

    await playerModule.openAudioSession(
      focus: fs.AudioFocus.requestFocusAndDuckOthers,
      audioFlags: fs.outputToSpeaker,
    );
    await playerModule
        .setSubscriptionDuration(const Duration(milliseconds: 100));
    try {
      await playerModule.startPlayer(
        fromDataBuffer: soundBuffer,
        codec: fs.Codec.mp3,
        whenFinished: () {},
      );
    } catch (e, s) {
      TelloLogger().e('playSOSReceiveSound() error: $e', stackTrace: s);
    }
  }

  Future<void> playQUIZAlarmSound() async {
    final Uint8List soundBuffer =
        (await rootBundle.load(quizAlarmFilePath)).buffer.asUint8List();
    if (playerModule.isPlaying) return;

    await playerModule.openAudioSession(
      focus: fs.AudioFocus.requestFocusAndDuckOthers,
      audioFlags: fs.outputToSpeaker,
    );
    await playerModule
        .setSubscriptionDuration(const Duration(milliseconds: 100));
    try {
      await playerModule.startPlayer(
        fromDataBuffer: soundBuffer,
        codec: fs.Codec.mp3,
        whenFinished: () {
          _startCheckTimerBySchedule(alertCheckDuration: 0 as Duration);
          Vibrator.stopNotificationVibration();
        },
      );
    } catch (e, s) {
      TelloLogger().e('playQUIZAlarmSound() error: $e', stackTrace: s);
    }
  }

  Future<void> cleanResources() async {
    try {
      final isOnline = await DataConnectionChecker().isConnectedToInternet;
      PTTService().dispose(isOnline: isOnline);
      SystemEventsSignaling().removeListener('NewEvent', (ev, context) {});
      SystemEventsSignaling()
          .removeListener('PositionUpdateEvent', (ev, context) {});
      SystemEventsSignaling().dispose();

      if (_alertCheckTimer != null) {
        GetStorage().write(StorageKeys.secondsSinceLastAlertCheck,
            _alertCheckTimer!.elapsed.inSeconds);
        _alertCheckTimer?.cancel();
      }

      playerModule.closeAudioSession();
      _periodicShiftTimestampTimer?.cancel();
      _checkScheduleTimer?.cancel();
      Vibrator.stopNotificationVibration();
    } catch (e, s) {
      TelloLogger().e('Application is detached EX: $e', stackTrace: s);
    }
  }

  Future<void> callServicesHandler() async {
/*    SystemChannels.lifecycle.setMessageHandler((msg) async {
      switch (msg) {
        case "AppLifecycleState.paused":
          Logger().log("@@@@@@@@@@@@@@@@@@@@@@ background AppLifecycleState.paused");
          break;
        case "AppLifecycleState.inactive":
          Logger().log("@@@@@@@@@@@@@@@@@@@@@@ background AppLifecycleState.inactive");
          break;
        case "AppLifecycleState.resumed":
          Logger().log("@@@@@@@@@@@@@@@@@@@@@@ background AppLifecycleState.resumed");
          break;
        case "AppLifecycleState.detached":
          Logger().log(" callServicesHandler background Application is detached!");
          try {
            PTTService().dispose();
            SystemEventsSignaling().removeListener('NewEvent', (ev, context) {});
            SystemEventsSignaling().removeListener('PositionUpdateEvent', (ev, context) {});
            SystemEventsSignaling().dispose();

            if (_alertCheckTimer != null) {
              GetStorage().write(StorageKeys.secondsSinceLastAlertCheck, _alertCheckTimer.elapsed.inSeconds);
              _alertCheckTimer.cancel();
            }

            playerModule?.closeAudioSession();
            Vibrator.stopNotificationVibration();
          } catch (e, s) {
            Logger().log('Application is detached EX: ${e.toString()}');
            Logger().log(s.toString());
          }
          break;
        default:
      }

      return null;
    });*/

    try {
      _channel.setMethodCallHandler((call) async {
        TelloLogger().i(
            " ######################### setMethodCallHandler ##############");
        if (call.method == "destoryService") {
          TelloLogger().i(
              " #########################CALLING cleanResources ##############");
          await cleanResources();
        }
      });
      TelloLogger().i(
          " #########################CALLING THE SERVICES HANDLER BEFORE ##############");
      isBackground = true;
      Get.put(SettingsController());
      LocalizationService().loadCurrentLocale();
      await GetStorage.init();
      SessionService.restoreSession();
      _activeGroupId = GetStorage().read(StorageKeys.currentActiveGroup);

      if (_activeGroupId == null || Session.user == null) {
        TelloLogger().i(
            "BGService callServicesHandler(): no _activeGroupId or Session.user, returning...");
        return;
      }

      TelloLogger().i(
          "###########RESTORING SERVICES FOR USER ${Session.user!.id} and group $_activeGroupId ######");

      AppSettings().tryRestore();
      ServiceAddress().tryInit(AppSettings());

      if (ServiceAddress().notInitialized) {
        TelloLogger().i(
            "BGService callServicesHandler(): ServiceAddress().notInitialized, returning...");
        return;
      }

      NetworkingClient.init(ServiceAddress().baseUrl);
      NetworkingClient2.init(ServiceAddress().baseUrl);

      final isOnline = await DataConnectionChecker().isConnectedToInternet;
      if (!isOnline) {
        TelloLogger().i(
            "BGService callServicesHandler(): you are offline, returning...");
        return;
      }

      final data =
          await GeneralRepository().fetchSettings(AppSettings().simSerial);
      AppSettings().setExternalSettings(data);

      final eventTypesConfigData =
          await EventsRepository().fetchEventTypesConfig();
      AppSettings()
          .updateEventSettings(EventsSettings.fromMap(eventTypesConfigData));

      await PTTService().init();
      await SystemEventsSignaling().init();

      final groupsData = await HomeRepository().fetchGroups();
      final groups = (groupsData['groups'] as List<dynamic>)
          .map((x) => RxGroup.fromMap(x as Map<String, dynamic>));
      TelloLogger().i(
          " #########################GET GROUPS for $_activeGroupId ##############");

      _activePositionGroup = groups.firstWhere((gr) => gr.id == _activeGroupId,
          orElse: () => null as RxGroup);
      TelloLogger()
          .i(" #########################SETTING ACTIVE GROUP ##############");
      if (_activePositionGroup != null) {
        await PTTService().setActiveGroup(_activePositionGroup!);
      }

      Signaling().on("TransmittingEvent", this, (ev, context) {
        final data = (ev.eventData as Map<String, dynamic>)["data"]
            as Map<String, dynamic>;
        if (data != null) {
          final String groupId = data["groupId"] as String;
          final didGroupBroadcast = _groupsDidBroadcastIds.contains(groupId);

          if (didGroupBroadcast) return;

          final srcGroup = groups.firstWhere((gr) => gr.id == groupId);

          final notification = ns.Notification(
            title: srcGroup.title!,
            text: '${srcGroup.title} did broadcast',
            groupType: NotificationGroupType.broadcast,
            srcGroupId: groupId,
            bgColor: Colors.black26,
          ).toMap();

          saveNotification(notification);
          Vibrator.startNotificationVibration();
          _groupsDidBroadcastIds.add(groupId);

          TelloLogger().i('${srcGroup.title} did broadcast');
        }
      });

      //FIXME: cancel the subscription
      SystemEventsSignaling().on('NewEvent', this, (event, context) {
        final data = (event.eventData as Map<String, dynamic>)['data']
            as Map<String, dynamic>;
        final newEvent = IncomingEvent.fromMap(data);

        if (newEvent.isSos) {
          TelloLogger()
              .i(" ################BACKGROUND NewSosEvent SOUND##############");
          playSOSReceiveSound();
          Vibrator.startNotificationVibration();
        }
      });

      //FIXME: cancel the subscription
      SystemEventsSignaling().on('PositionUpdateEvent', this,
          (event, context) async {
        final data = (event.eventData as Map<String, dynamic>)['data']
            as Map<String, dynamic>;

        TelloLogger().i(
            'Background service PositionUpdateEvent ${data['positionState']['positionId']} == ${Session.shift?.positionId} ${Session.shift?.positionId == data['positionState']['positionId']}##############################');
        validatePositionStatus(
          positionId: data['positionState']['positionId'] as String,
          status: PositionStatus.values[data['positionState']['status'] as int],
          alertCheckState: AlertCheckState
              .values[(data['positionState']['checkState'] as int) - 1],
          worker: data["worker"] != null
              ? RxUser.fromMap(data["worker"])
              : null as RxUser,
          workerLocation: data['positionState']['coordinate'] != null
              ? Coordinates.fromMap(data['positionState']['coordinate'])
              : null,
          statusUpdatedAt: data['positionState']['statusUpdatedAt'] as int,
          alertCheckStateUpdatedAt:
              data['positionState']['checkStateUpdatedAt'] as int,
        );

        TelloLogger().i(
            'Background service Position updated for position ${data['positionState']['title']} == ${data['positionState']['positionId']} STATUS == ${PositionStatus.values[data['positionState']['status'] as int]} alertnessState: ${AlertCheckState.values[(data['positionState']['checkState'] as int) - 1]}');
      });
      if (Session.hasShiftStarted!) {
        _secondsSinceLastCheck =
            GetStorage().read(StorageKeys.secondsSinceLastAlertCheck) ?? 0;
        final alertCheckDuration =
            (Session.shift!.alertCheckConfig!.alertCheckInterval -
                    _secondsSinceLastCheck!)
                .seconds;

        _startCheckTimerBySchedule(alertCheckDuration: alertCheckDuration);

        _checkScheduleTimer = Timer.periodic(
          const Duration(seconds: 10),
          (_) => _startCheckTimerBySchedule(alertCheckDuration: 0 as Duration),
        );
        _periodicShiftTimestampTimer =
            Timer.periodic(const Duration(seconds: 5), (timer) {
          GetStorage().write(StorageKeys.periodicShiftTimestamp,
              DateTime.now().millisecondsSinceEpoch);
        });
      }
    } catch (e, s) {
      TelloLogger()
          .e('Application is Init on background with ex: $e', stackTrace: s);
    }
  }

  void saveNotification(Map<String, dynamic> notification) {
    List<dynamic> savedNotifications = [];
    final rawData = GetStorage().read(StorageKeys.notifications);
    if (rawData != null) {
      savedNotifications = json.decode(rawData as String) as List<dynamic>;
    }
    savedNotifications.add(notification);
    GetStorage()
        .write(StorageKeys.notifications, json.encode(savedNotifications));
  }

  Future<void> validatePositionStatus({
    required String positionId,
    required PositionStatus status,
    AlertCheckState? alertCheckState,
    Coordinates? workerLocation,
    required RxUser worker,
    required int statusUpdatedAt,
    required int alertCheckStateUpdatedAt,
  }) async {
    final position = _activePositionGroup?.members.positions
        .firstWhere((p) => p.id == positionId);
    await _checkCurrentPositionOutOfRangeState(position!);

    await _checkCurrentPositionAlertnessState(position);
  }

  Future<void> _checkCurrentPositionOutOfRangeState(RxPosition pos) async {
    if (pos == null) return;

    final isMyPosition = Session.shift?.positionId == pos.id;
    final isOutOfRange = pos.status() == PositionStatus.outOfRange;
    final isPositionInGroup =
        _activePositionGroup?.members.positions.any((p) => p.id == pos.id) ??
            false;

    // if (txState$.value.state != StreamingState.idle) return;
    if (Session.isSupervisor &&
        isOutOfRange &&
        !isMyPosition &&
        isPositionInGroup) {
      final alreadyNotified = _outOfRangeIds.contains(pos.id);

      if (alreadyNotified) return;

      final notification = ns.Notification(
        title: 'Out of range',
        text: 'You are out of your position range!',
        groupType: NotificationGroupType.systemEvents,
        bgColor: AppColors.error,
      ).toMap();

      saveNotification(notification);
      Vibrator.startNotificationVibration();
      _outOfRangeIds.add(pos.id);
    }
  }

  Future<void> _checkCurrentPositionAlertnessState(RxPosition pos) async {
    if (pos == null) return;

    final isAlertCheckFailed = pos.alertCheckState() == AlertCheckState.failed;
    final isAlertCheckPassed = !isAlertCheckFailed;
    final isMyPosition = Session.shift?.positionId == pos.id;
    final isPositionInGroup =
        _activePositionGroup?.members.positions.any((p) => p.id == pos.id) ??
            false;

    //if (txState$.value.state != StreamingState.idle) return;
    if (Session.isSupervisor &&
        isAlertCheckFailed &&
        !isMyPosition &&
        isPositionInGroup) {
      final alreadyNotified = _alertnessFailedIds.contains(pos.id);

      if (alreadyNotified) return;

      final notification = ns.Notification(
        title: 'Alertness Failed',
        text: '${pos.title} failed alertness check!',
        groupType: NotificationGroupType.systemEvents,
        bgColor: AppColors.alertnessFailed,
      ).toMap();

      saveNotification(notification);
      Vibrator.startNotificationVibration();
      _alertnessFailedIds.add(pos.id);
    }
  }

  void _startCheckTimerBySchedule({required Duration alertCheckDuration}) {
    final currentTime = DateTime.now();
    final timeRule = Session
        .shift!.alertCheckConfig!.dayRules[currentTime.weekday - 1].timeRule;

    if (timeRule == null) return;

    if (_currentDay != currentTime.weekday) {
      _currentDay = currentTime.weekday;
      _currentDate = currentTime.toIso8601String().substring(0, 10);
      _todayCheckStartsAt = DateFormat("yyyy-MM-dd HH:mm")
          .parse('$_currentDate ${timeRule.fromTime}');
      _todayCheckEndsAt = DateFormat("yyyy-MM-dd HH:mm")
          .parse('$_currentDate ${timeRule.toTime}');
    }
    final isInsideCheckTimeframe = currentTime.isAfter(_todayCheckStartsAt!) &&
        currentTime.isBefore(_todayCheckEndsAt!);
    if (isInsideCheckTimeframe) {
      if (_alertCheckTimer == null || _alertCheckTimer!.isCancelled) {
        initAlertCheckTimer(duration: alertCheckDuration);
      }
    } else if (_alertCheckTimer != null) {
      _alertCheckTimer!.cancel();
      _alertCheckTimer = null;
    }
  }

  void initAlertCheckTimer({Duration? duration}) {
    duration ??= Session.shift!.alertCheckConfig!.alertCheckInterval.seconds;
    _alertCheckTimer?.cancel();

    try {
      _alertCheckTimer = PausableTimer(
        duration,
        () {
          final notification = ns.Notification(
            title: 'Alert Check',
            text: 'You have to pass the alert check!',
            groupType: NotificationGroupType.alertCheck,
            bgColor: AppColors.alertnessFailed,
          ).toMap();
          saveNotification(notification);
          Vibrator.startNotificationVibration();
          playQUIZAlarmSound();
          //TODO: fail quiz here
        },
      )..start();
    } catch (e, s) {
      TelloLogger().e('StartAlertCheckTimer ex: $e', stackTrace: s);
    }
  }

  Future<void> openBazzApp() async {
    await LaunchApp.openApp(
      androidPackageName: 'net.pulsesecure.pulsesecure',
    );
  }

  Future<void> startKeepAliveFromForeground() async {
    if (_foregroundServiceStopped) return;
    TelloLogger()
        .i('###################START startKeepAlive########################');
    await callServicesHandler();
    TelloLogger().i(
        '###################Background call PTT Service Init########################');
  }

  Future<void> startKeepAliveAlarmService() async {
    TelloLogger()
        .i('###################START startKeepAlive########################');
    await callServicesHandler();
    TelloLogger().i(
        '###################Background call PTT Service Init########################');
  }

  Future<void> startKeepAliveBackgroundService() async {
    TelloLogger()
        .i('###################START startKeepAlive########################');
    await callServicesHandler();
    TelloLogger().i(
        '###################Background call PTT Service Init########################');
  }

  void stopForegroundService() {
    _foregroundServiceStopped = true;
  }

  void startForegroundService() {
    _foregroundServiceStopped = false;
  }

  void intilaizeLifecycleEvents() {
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      TelloLogger().i('SystemChannels> $msg');

      switch (msg) {
        case "AppLifecycleState.paused":
          TelloLogger().i(
              "#######################@@@@@@@@@@@@@@@@@@@@@@AppLifecycleState.paused################");
          break;
        case "AppLifecycleState.inactive":
          TelloLogger().i(
              "########################@@@@@@@@@@@@@@@@@@@@@@AppLifecycleState.inactive#################");
          break;
        case "AppLifecycleState.resumed":
          TelloLogger().i(
              "########################@@@@@@@@@@@@@@@@@@@@@@AppLifecycleState.resumed##########");
          break;
        case "AppLifecycleState.detached":
          TelloLogger().i(
              "#########################@@@@@@@@@@@@@@@@@@@@@@AppLifecycleState.detached##############");
          break;
        default:
      }

      return null;
    });
  }

  Future<void> initializeBackgroundService() async {
    if (!Platform.isAndroid) return;
    intilaizeLifecycleEvents();
    const channel = MethodChannel('com.bazzptt/background_service');
    final callbackHandle = PluginUtilities.getCallbackHandle(backgroundMain);
    channel.invokeMethod('startService', callbackHandle!.toRawHandle());
  }
}
