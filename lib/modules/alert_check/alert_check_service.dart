import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/alert_check_config.dart';
import 'package:bazz_flutter/models/alert_check_result.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/alert_check/alert_check_repo.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/shift_module/models/alert_check_rpoint.dart';
import 'package:bazz_flutter/modules/synchronization/sync_service.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/vibrator.dart';
import 'package:bazz_flutter/shared_widgets/primary_button.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:custom_timer/custom_timer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:pausable_timer/pausable_timer.dart';

class AlertCheckService extends GetxController {
  static AlertCheckService get to => Get.find();

  late int _currentDay;
  late String _currentDate;
  late DateTime _todayCheckStartsAt;
  late DateTime _todayCheckEndsAt;
  late Timer _checkScheduleTimer;
  late PausableTimer _alertCheckTimer;

  final List<int> alertCheckSnoozes = [];
  late List<AlertCheckRPoint> alertCheckRPoints;

  late StreamSubscription _callStateSub;
  late StreamSubscription _activeGroupSub;
  late StreamSubscription _sosEventsSub;
  late StreamSubscription _isCheckSilentSub;

  //TODO: can be removed later, 'cause now _intervalTimer allows us to read Duration
  DateTime _checkStartedAt = DateTime.now();

  int get timeSpent => DateTime.now().difference(_checkStartedAt).inSeconds;

  RxBool isCheckSilent = true.obs;
  final alertCheckInProgress = false.obs;
  final minimumAlertSavingPeriodInSeconds = 120;
  final maxSnoozesPerCheck =
      Session.shift!.alertCheckConfig!.snoozeCountPerQuiz;
  late Duration checkButtonTimeLeft;

  FlutterSoundPlayer playerModule = FlutterSoundPlayer();
  String loudCheckAlarmFilePath = 'assets/sounds/quiz_alarm.mp3';
  String snoozeDialogAlarmFilePath =
      'assets/sounds/alert_check_snooze_alarm.mp3';
  Uint8List? loudCheckAlarmBuffer;
  Uint8List? snoozeDialogAlarmBuffer;

  bool get isCheckEscalated => checkButtonTimeLeft != null;

  @override
  Future<void> onInit() async {
    final secondsSinceLastCheck =
        GetStorage().read<int>(StorageKeys.secondsSinceLastAlertCheck) ?? 0;
    final alertCheckDuration =
        (Session.shift!.alertCheckConfig!.alertCheckInterval -
                secondsSinceLastCheck)
            .seconds;

    _startCheckTimerBySchedule(alertCheckDuration: alertCheckDuration);

    _checkScheduleTimer = Timer.periodic(
      const Duration(seconds: 10),
      (_) => _startCheckTimerBySchedule(),
    );

    await playerModule.openAudioSession(
      focus: AudioFocus.requestFocusAndDuckOthers,
      audioFlags: outputToSpeaker,
    );

    await playerModule
        .setSubscriptionDuration(const Duration(milliseconds: 100));
    loudCheckAlarmBuffer =
        (await rootBundle.load(loudCheckAlarmFilePath)).buffer.asUint8List();
    snoozeDialogAlarmBuffer =
        (await rootBundle.load(snoozeDialogAlarmFilePath)).buffer.asUint8List();

    _isCheckSilentSub = isCheckSilent.listen((silent) {
      if (silent) {
        if (playerModule.isPlaying) playerModule.stopPlayer();
      } else {
        _playAlarmCheckSound(loudCheckAlarmBuffer!);
      }
    });

    if (HomeController.to.activeGroup.hasUnconfirmedSos) {
      if (playerModule.isPlaying) playerModule.stopPlayer();
    }

    _callStateSub = HomeController.to.txState$.listen((value) {
      if (value.state == StreamingState.receiving ||
          value.state == StreamingState.sending) {
        if (playerModule.isPlaying) playerModule.stopPlayer();
      }
    });

    _activeGroupSub = HomeController.to.activeGroup$.listen((aGroup) {
      if (aGroup == null) return;

      if (aGroup.hasUnconfirmedSos) {
        if (playerModule.isPlaying) playerModule.stopPlayer();
      }

      _sosEventsSub = aGroup.events$.listen((events) {
        if (aGroup.sosEvents.any((sos) => sos.isNotConfirmed$)) {
          if (playerModule.isPlaying) playerModule.stopPlayer();
        } else {
          _startCheckTimerBySchedule();
        }
      });
    });

    SystemChannels.lifecycle.setMessageHandler((msg) async {
      switch (msg) {
        case "AppLifecycleState.detached":
          if (_alertCheckTimer.elapsed.inSeconds >
              minimumAlertSavingPeriodInSeconds) {
            GetStorage().write(StorageKeys.secondsSinceLastAlertCheck,
                _alertCheckTimer.elapsed.inSeconds);
          }
          break;
        default:
      }
      return null;
    });
    super.onInit();
  }

  @override
  void onClose() {
    GetStorage().remove(StorageKeys.secondsSinceLastAlertCheck);
    _resetAlertCheckSnoozes();
    playerModule.closeAudioSession();
    _isCheckSilentSub.cancel();
    _checkScheduleTimer.cancel();
    _alertCheckTimer.cancel();
    _activeGroupSub.cancel();
    _sosEventsSub.cancel();
    _callStateSub.cancel();
    super.onClose();
  }

  void _startCheckTimerBySchedule({Duration? alertCheckDuration}) {
    final currentTime = DateTime.now();
    final timeRule = Session
        .shift!.alertCheckConfig!.dayRules[currentTime.weekday - 1].timeRule;

    if (alertCheckInProgress() || timeRule == null) return;

    if (_currentDay != currentTime.weekday) {
      _currentDay = currentTime.weekday;
      _currentDate = currentTime.toIso8601String().substring(0, 10);
      _todayCheckStartsAt = DateFormat("yyyy-MM-dd HH:mm")
          .parse('$_currentDate ${timeRule.fromTime}');
      _todayCheckEndsAt = DateFormat("yyyy-MM-dd HH:mm")
          .parse('$_currentDate ${timeRule.toTime}');
    }
    final isInsideCheckTimeframe = currentTime.isAfter(_todayCheckStartsAt) &&
        currentTime.isBefore(_todayCheckEndsAt);
    if (isInsideCheckTimeframe) {
      if (_alertCheckTimer == null ||
          _alertCheckTimer.isCancelled ||
          _alertCheckTimer.isPaused ||
          _alertCheckTimer.isExpired) {
        initAlertCheckTimer(duration: alertCheckDuration!);
      }
    } else if (_alertCheckTimer != null) {
      _alertCheckTimer.cancel();
      _alertCheckTimer = null!;
    }
  }

  void pauseAlertCheckTimer() {
    _alertCheckTimer.pause();
  }

  void setCheckButtonTimeLeft(Duration duration) {
    checkButtonTimeLeft = duration;
  }

  Future<void> showSnoozeDialog() async {
    await Get.generalDialog(
      barrierLabel: 'BarrierLabel',
      pageBuilder: (_, __, ___) {
        return Center(
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(5)),
            child: SizedBox(
              width: Get.width * 0.75,
              height: Get.height * 0.25,
              child: Scaffold(
                backgroundColor: AppTheme().colors.mainBackground,
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 5),
                      color: AppColors.sos,
                      child: TextOneLine(
                        LocalizationService().of().alertnessCheck,
                        textAlign: TextAlign.center,
                        style: AppTheme().typography.dialogTitleStyle,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            Expanded(
                              child: Align(
                                child: Text(
                                  LocalizationService()
                                      .of()
                                      .snoozeCheckDialogMessage(Session.shift!
                                          .alertCheckConfig!.snoozeInterval
                                          .toString()),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: AppTheme().typography.bgText3Style,
                                ),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                PrimaryButton(
                                  height: 40,
                                  onTap: goToAlertCheckPage,
                                  text: LocalizationService().of().passCheck,
                                  icon: null as Icon,
                                ),
                                PrimaryButton(
                                  height: 40,
                                  onTap: _snoozeAlertCheck,
                                  icon: null as Icon,
                                  child: CustomTimer(
                                    begin: Session.shift!.alertCheckConfig!
                                        .snoozeTimeout.seconds,
                                    end: const Duration(),
                                    // onBuildAction: CustomTimerAction.auto_start,
                                    // onFinish: _snoozeAlertCheck,
                                    builder: (remaining) {
                                      return TextOneLine(
                                        "${LocalizationService().of().snooze} ${remaining.seconds}",
                                        style: AppTheme()
                                            .typography
                                            .buttonTextStyle,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> goToAlertCheckPage() async {
    Vibrator.stopNotificationVibration();
    if (playerModule.isPlaying && isCheckSilent()) playerModule.stopPlayer();

    _alertCheckTimer.pause();

    if (Get.isOverlaysOpen) Get.until((_) => Get.isOverlaysClosed);

    final isAlertCheckDone = await Get.toNamed(AppRoutes.alertCheck);
    update(['CountDownTimer']);

    if (isAlertCheckDone != null && isAlertCheckDone as bool) {
      _startCheckTimerBySchedule();
    } else if (alertCheckInProgress() && !isCheckEscalated) {
      // snoozing in case of just going back from the AlertCheckPage
      _snoozeAlertCheck(
          registerSnooze: alertCheckSnoozes.length < maxSnoozesPerCheck);
    }
  }

  void _snoozeAlertCheck({bool registerSnooze = true}) {
    Vibrator.stopNotificationVibration();
    if (playerModule.isPlaying && isCheckSilent()) playerModule.stopPlayer();

    if (registerSnooze) {
      alertCheckSnoozes.add(dateTimeToSeconds(DateTime.now()));
      final encodedSnoozes = json.encode(alertCheckSnoozes);
      GetStorage().write(StorageKeys.alertCheckSnoozes, encodedSnoozes);
    }

    if (_alertCheckTimer.isPaused) {
      _alertCheckTimer.start();
    } else {
      initAlertCheckTimer(
          duration: Session.shift!.alertCheckConfig!.snoozeInterval.seconds);
    }
    if (Get.isOverlaysOpen) Get.back();
  }

  void initAlertCheckTimer({Duration? duration, bool isPaused = false}) {
    duration ??= Session.shift!.alertCheckConfig!.alertCheckInterval.seconds;
    _alertCheckTimer.cancel();

    _alertCheckTimer = PausableTimer(
      duration,
      () async {
        _startAlertCheck();
        Vibrator.startNotificationVibration();
        _readAlertCheckSnoozes();
        if (alertCheckSnoozes.length < maxSnoozesPerCheck) {
          await _playAlarmCheckSound(snoozeDialogAlarmBuffer!);
          showSnoozeDialog();
        } else {
          isCheckSilent(false);
        }

        GetStorage().remove(StorageKeys.secondsSinceLastAlertCheck);
      },
    );

    if (!isPaused) _alertCheckTimer.start();
  }

  void _readAlertCheckSnoozes() {
    final rawData = GetStorage().read(StorageKeys.alertCheckSnoozes);
    if (rawData != null) {
      final decodedData = json.decode(rawData as String) as List<dynamic>;
      alertCheckSnoozes
        ..clear()
        ..addAll(List<int>.from(decodedData));
    }
  }

  void _startAlertCheck({bool isSilent = true}) {
    alertCheckInProgress(true);
    isCheckSilent(isSilent);
    _checkStartedAt = DateTime.now();

    if (Session.shift!.alertCheckConfig!.alertCheckType ==
        AlertCheckType.reportingPoints) {
      // storing empty RPointAlertCheckResults to modify later during the alert check
      alertCheckRPoints = Session.shift!.alertCheckConfig!.reportingPoints
          .map((rp) => AlertCheckRPoint(
                rPointId: rp.id,
                rPointName: rp.title,
                validationType: rp.validationType,
                location: rp.location,
              ))
          .toList();
      GetStorage().write(
        StorageKeys.currentAlertCheckRPoints,
        json.encode(alertCheckRPoints.map((r) => r.toMap()).toList()),
      );

      //that's if we need to restore prev results
      // final rawData = GetStorage().read(StorageKeys.currentAlertCheckRPointResults);
      // if (rawData != null) {
      //   rPointsCheckResults = (json.decode(rawData as String) as List<dynamic>)
      //       .map((m) => RPointAlertCheckResult.fromMap(m as Map<String, dynamic>))
      //       .toList();
      // } else {
      //   // storing empty RPointAlertCheckResults to modify later during the alert check
      //   rPointsCheckResults = Session.shift.alertCheckConfig.reportingPoints
      //       .map((rp) => RPointAlertCheckResult(
      //             rPointId: rp.id,
      //             rPointName: rp.name,
      //           ))
      //       .toList();
      //   GetStorage().write(
      //     StorageKeys.currentAlertCheckRPointResults,
      //     json.encode(rPointsCheckResults.map((r) => r.toMap()).toList()),
      //   );
      // }
    }
  }

  void finishAlertCheck() {
    if (Session.shift!.alertCheckConfig!.alertCheckType ==
        AlertCheckType.reportingPoints) {
      alertCheckRPoints = null as List<AlertCheckRPoint>;
      GetStorage().remove(StorageKeys.currentAlertCheckRPoints);
    }
    _resetAlertCheckSnoozes();
    isCheckSilent(true);
    _checkStartedAt = null as DateTime;
    checkButtonTimeLeft = null as Duration;
    alertCheckInProgress(false);
    _startCheckTimerBySchedule();
  }

  Future<void> _playAlarmCheckSound(Uint8List dataBuffer) async {
    try {
      if (HomeController.to.txState$.value.state != StreamingState.idle) return;
      await playerModule.startPlayer(
        fromDataBuffer: dataBuffer,
        codec: Codec.mp3,
        whenFinished: () {
          TelloLogger().i('Play finished');
        },
      );
    } catch (e, s) {
      TelloLogger().e('_playAlarmCheckSound() error: $e', stackTrace: s);
    }
  }

  //TODO: make use of it
  void restartCheckTimer() {
    _alertCheckTimer
      ..reset()
      ..start();
  }

  void _resetAlertCheckSnoozes() {
    alertCheckSnoozes.clear();
    GetStorage().remove(StorageKeys.alertCheckSnoozes);
  }

  Future<void> sendFailedAlertCheck() async {
    final result = AlertCheckResult(
      timeSpent: AlertCheckService.to.timeSpent,
      userScore: 0,
      maxScore: alertCheckRPoints.length,
      createdAt: dateTimeToSeconds(DateTime.now()),
      snoozes: [...alertCheckSnoozes],
      faceRecImage64: null as String,
      alertCheckRPoints: alertCheckRPoints.map((e) => e.copy()).toList(),
    );

    if (HomeController.to.isOnline) {
      SyncService.to.otherDataSyncCompleted.future.then((_) {
        AlertCheckRepository().sendResult(result).catchError((e, s) {
          saveResult(result);
          TelloLogger().e('AlertCheckService data sending error: $e',
              stackTrace: s is StackTrace ? s : null);
        });
      }).catchError((e, s) {
        saveResult(result);
      });
    } else {
      saveResult(result);
    }

    finishAlertCheck();

    Get.until((route) => route.isFirst);
  }

  Future<void> saveResult(AlertCheckResult result) async {
    final combinedResults = [result];

    final existingResultsString =
        GetStorage().read(StorageKeys.offlineAlertCheckResults);

    TelloLogger().i(
        'AlertCheckService saveResult(): existingResults: $existingResultsString');

    if (existingResultsString != null) {
      final decodedData = json.decode(existingResultsString as String);
      combinedResults.addAll(
        (decodedData as List<dynamic>)
            .map((el) => AlertCheckResult.fromMap(el as Map<String, dynamic>)),
      );
    }

    await GetStorage().write(
      StorageKeys.offlineAlertCheckResults,
      json.encode(combinedResults.map((el) => el.toMap()).toList()),
    );
  }

  AlertCheckRPoint getAlertCheckRPointById(String rPointId) {
    return alertCheckRPoints.firstWhere((res) => res.rPointId == rPointId);
  }

  void storeCurrentAlertCheckRPoints() {
    GetStorage().write(StorageKeys.currentAlertCheckRPoints,
        json.encode(alertCheckRPoints.map((r) => r.toMap()).toList()));
  }
}
