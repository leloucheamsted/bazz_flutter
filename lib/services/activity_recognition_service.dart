import 'dart:async';

import 'package:activity_recognition_flutter/activity_recognition_flutter.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/notification_service.dart' as ns;
import 'package:bazz_flutter/services/snack_bar_display.dart';
import 'package:bazz_flutter/services/vibrator.dart';
import 'package:eventify/eventify.dart' as evf;
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ActivityRecognitionService extends evf.EventEmitter {
  static final ActivityRecognitionService _singleton = ActivityRecognitionService._();

 late factory ActivityRecognitionService() => _singleton;

  ActivityRecognitionService._();

  Timer? _stillActivityTimer;
  Timer? _pausingStreamActivityTimer;
  Stream<ActivityEvent>? activityStream;
  ActivityEvent latestActivity = ActivityEvent.unknown();
  ActivityRecognition activityRecognition = ActivityRecognition();
  StreamSubscription<ActivityEvent> ? _activityEventSub;
  final RxBool movementDetected$ = false.obs;

  bool get movementDetected => movementDetected$.value;
  bool _startHandleData = false;
  Future<void> init() async {
    TelloLogger().i("START init() Activity Recognition Service");
    _startTracking();
  }

  start(){
    _startHandleData = true;
  }

  stop(){
    _startHandleData = false;
  }

  /*Future<void> dispose() async {
    Logger().log('[ActivityRecognitionService IS DISPOSING START]');
    _stopTracking();
    _stillActivityTimer?.cancel();
    _pausingStreamActivityTimer?.cancel();
  }*/

  void _startTracking() {
    activityStream = activityRecognition.activityStream(runForegroundService: true);
    _activityEventSub = activityStream?.listen(onData);
  }

  void _stopTracking() {
    _activityEventSub?.cancel();
  }

  void _validateMovement(ActivityEvent activityEvent) {
    TelloLogger().i(
        "_validateMovement activityEvent type == ${activityEvent.type} ,activityEvent confidence == ${activityEvent.confidence}");
    switch (activityEvent.type) {
      case ActivityType.STILL:
        if (activityEvent.confidence > 98) {
          movementDetected$.value = false;
        }
        break;
      case ActivityType.IN_VEHICLE:
        if (activityEvent.confidence > 70) {
          movementDetected$.value = true;
        }
        break;
      case ActivityType.RUNNING:
        if (activityEvent.confidence > 70) {
          movementDetected$.value = true;
        }
        break;
      case ActivityType.WALKING:
        if (activityEvent.confidence > 70) {
          movementDetected$.value = true;
        }
        break;
      case ActivityType.TILTING:
        break;
      case ActivityType.ON_BICYCLE:
        if (activityEvent.confidence > 70) {
          movementDetected$.value = true;
        }
        break;
      case ActivityType.ON_FOOT:
        if (activityEvent.confidence > 70) {
          movementDetected$.value = true;
        }
        break;
      case ActivityType.UNKNOWN:
        break;
      case ActivityType.INVALID:
        // TODO: Handle this case.
        break;
    }
    TelloLogger().i("_validateMovement movementDetected value == ${movementDetected$.value}");
    /*if (!movementDetected$.value) {
      if (kReleaseMode) {
        _pausingStreamActivityTimer ??=
            Timer.periodic(Duration(seconds: AppSettings().locationMovementPauseDuration), (timer) {
          LocationService().pause();
        });
      }
    } else {
      _pausingStreamActivityTimer?.cancel();
      _pausingStreamActivityTimer = null;
      LocationService().start();
    }*/
  }

  void onData(ActivityEvent activityEvent) {
    if(!_startHandleData) return;
    _validateMovement(activityEvent);
    switch (activityEvent.type) {
      case ActivityType.STILL:
        _startStillActivityTimer(activityEvent);
        break;
      case ActivityType.IN_VEHICLE:
        _cancelStillActivityTimer(activityEvent);
        break;
      case ActivityType.RUNNING:
        _cancelStillActivityTimer(activityEvent);
        break;
      case ActivityType.WALKING:
        _cancelStillActivityTimer(activityEvent);
        break;
      case ActivityType.TILTING:
        _cancelStillActivityTimer(activityEvent);
        break;
      case ActivityType.ON_BICYCLE:
        _cancelStillActivityTimer(activityEvent);
        break;
      case ActivityType.ON_FOOT:
        _cancelStillActivityTimer(activityEvent);
        break;
      case ActivityType.UNKNOWN:
        _cancelStillActivityTimer(activityEvent);
        break;
      case ActivityType.INVALID:
        // TODO: Handle this case.
        break;
    }

    latestActivity = activityEvent;
  }

  void _cancelStillActivityTimer(ActivityEvent activityEvent) {
    emit("cancelStillActivity", this, activityEvent.confidence);
    if (AppSettings().enableActivityTracking && Session.hasShift) {
      if (activityEvent.confidence > 70) {
        _stillActivityTimer?.cancel();
        _stillActivityTimer = null;
      }
    }
  }

  void _startStillActivityTimer(ActivityEvent activityEvent) {
    emit("startStillActivity", this, activityEvent.confidence);
    if (AppSettings().enableActivityTracking &&
        Session.hasShift &&
        Session.shift!.currentPosition?.positionType.locationType == LocationType.Dynamic) {
      if (activityEvent.confidence > 98) {
        if (_stillActivityTimer == null) {
          TelloLogger().i("startStillActivityTimer is started");
          _stillActivityTimer = Timer.periodic(Duration(seconds: AppSettings().stillActivityDuration), (timer) {
            if (!Session.hasShift) {
              _stillActivityTimer?.cancel();
              return;
            }
            TelloLogger().i("startStillActivityTimer period elapsed");
            //TODO: show this for a supervisor, not guard!
            // final getBar = GetBar(
            //   snackPosition: SnackPosition.TOP,
            //   backgroundColor: AppColors.warning,
            //   message: LocalizationService().localizationContext().activityAlertMsg,
            //   titleText: Text(LocalizationService().localizationContext().activityAlertTitle,
            //       style: AppTypography.captionTextStyle),
            //   icon: const Icon(Icons.warning_amber_rounded, color: AppColors.brightIcon),
            //   duration: const Duration(seconds: 30),
            //   snackbarStatus: (status) {
            //     if (status == SnackbarStatus.CLOSED) {
            //       Vibrator.stopNotificationVibration();
            //     } else if (status == SnackbarStatus.OPEN) {
            //       Vibrator.startNotificationVibration();
            //     }
            //   },
            // );
            // Get.showSnackbarEx(getBar).then((value) async {});
            // ns.NotificationService.to.add(
            //   ns.Notification(
            //     icon: getBar.icon,
            //     title: LocalizationService().localizationContext().activityAlertTitle,
            //     text: LocalizationService().localizationContext().activityAlertShortMsg,
            //     bgColor: getBar.backgroundColor,
            //     groupType: NotificationGroupType.noActivityDetected,
            //   ),
            // );
          });
        }
      }
    }
  }
}
