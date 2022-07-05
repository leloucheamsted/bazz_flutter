import 'dart:async';

import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/coordinates_model.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/location_tracking/location_service.dart';
import 'package:bazz_flutter/modules/media_uploading/media_upload_service.dart';
import 'package:bazz_flutter/modules/shift_activities/models/reporting_point.dart';
import 'package:bazz_flutter/modules/shift_activities/models/reporting_point_visit.dart';
import 'package:bazz_flutter/modules/shift_activities/models/shift_activity_result.dart';
import 'package:bazz_flutter/modules/shift_activities/models/shift_activity_task.dart';
import 'package:bazz_flutter/modules/shift_activities/models/tour.dart';
import 'package:bazz_flutter/modules/shift_activities/qr_scanner_page.dart';
import 'package:bazz_flutter/modules/shift_module/shift_repo.dart';
import 'package:bazz_flutter/modules/synchronization/sync_service.dart';
import 'package:bazz_flutter/services/data_connection_checker.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/session_service.dart';
import 'package:bazz_flutter/shared_widgets/loader.dart';
import 'package:bazz_flutter/shared_widgets/system_dialog.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:eventify/eventify.dart' as evf;
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:logger/logger.dart' as log;
import 'package:pausable_timer/pausable_timer.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class ShiftActivitiesService extends GetxController
    with SingleGetTickerProviderMixin {
  static ShiftActivitiesService? get to => instance != null ? Get.find() : null;
  static ShiftActivitiesService? instance;
  final _repo = ShiftRepository();
  TabController? tabController;
  GlobalKey<State> guardTabBarKey = GlobalKey();

  GetStorage? rPointVisitsUploadQueue;

  PausableTimer? currentActivityTimer;
  Tour? currentTour;

  int get currentTourIndex =>
      Session.shift!.tours!.indexWhere((t) => t.tourId == currentTour!.tourId);

  ///Shows RPoints without the ones present in the currentTour
  List<ReportingPoint>? get otherRPoints => currentTour != null
      ? Session.shift!.reportingPoints!
          .where((rp) =>
              currentTour!.path.any((tp) => tp.reportingPoint.id == rp.id))
          .toList()
      : Session.shift!.reportingPoints!;

  // ReportingPoint currentReportingPoint;
  RxBool isMapVisible = false.obs;

  evf.Listener? locationUpdateSub;

  static Future<Position> getCurrPositionWithLoader(
      BuildContext context) async {
    final loaderTimer = Timer(const Duration(milliseconds: 300), () {
      Loader.show(context,
          text: '{AppLocalizations.of(context).gettingYourLocation}...',
          themeData: null as ThemeData);
    });
    final position =
        await LocationService().getCurrentPosition(ignoreLastKnownPos: true);
    loaderTimer.cancel();
    Loader.hide();
    return position;
  }

  Future<ShiftActivitiesService> init() async {
    instance = this;
    tabController = TabController(vsync: this, length: 2);
    rPointVisitsUploadQueue =
        GetStorage(StorageKeys.rPointVisitsUploadQueueBox);
    if (Session.shift?.tours != null && Session.shift!.tours!.isNotEmpty) {
      try {
        _setCurrentTour();
        //TODO: read the real duration
        currentActivityTimer = PausableTimer(
          const Duration(seconds: 3600),
          () {},
        )..start();
      } catch (e, s) {
        TelloLogger().e('error init ShiftActivitiesService: $e', stackTrace: s);
      }
    }

    locationUpdateSub = LocationService().on('locationUpdate', this,
        (evf.Event ev, Object? context) async {
      final Position position = ev.eventData as Position;

      ReportingPoint targetRPoint;
      int targetTabIndex = 0;

      if (position == null) return;

      if (position.speed > 1.7) {
        TelloLogger().i(
            'You are moving too fast! Speed: ${position.speed}, speedAccuracy: ${position.speedAccuracy}');
        return;
      }

      targetRPoint = currentTour!.path.firstWhere(
        (tp) {
          final rp = tp.reportingPoint;

          if (rp.isFinished || rp.validationType != RPValidationType.geo)
            return false;

          final distanceToReportingPoint = LocationService().distanceBetween(
            position.latitude,
            position.longitude,
            rp.location.latitude,
            rp.location.longitude,
          );
          final isWithinRPRadius = distanceToReportingPoint <
              AppSettings().reportingPointLocationTolerance;
          return isWithinRPRadius;
        },
        orElse: () => null!,
      ).reportingPoint;

      if (targetRPoint != null &&
          currentTour != null &&
          currentTour!.hasNoOngoingVisits &&
          otherRPoints!.every((rp) => rp.hasNoCurrentVisit)) {
        targetTabIndex = 1;
        targetRPoint.setCurrentVisit(ReportingPointVisit(
          tourId: targetRPoint.tourId,
          rPointId: targetRPoint.id,
          startedAt: dateTimeToSeconds(DateTime.now()),
          isLocationCheckPassed: true,
          guardLocation:
              position != null ? Coordinates.fromPosition(position) : null,
          activities: targetRPoint.activities.map((a) => a.copyWith()).toList(),
        ));
        if (targetRPoint.hasActivities) {
          update(['reportingPoint${targetRPoint.id}']);
          final canChangeTab = guardTabBarKey.currentWidget != null;
          if (canChangeTab && tabController!.index != targetTabIndex)
            tabController!.index = targetTabIndex;
          await Future.delayed(const Duration());
          targetRPoint.expand();
          SessionService.storeSession();
        } else {
          await _finishVisit(targetRPoint);
        }
      }
    });

    return instance!;
  }

  @override
  void onClose() {
    currentActivityTimer?.cancel();
    locationUpdateSub!.cancel();
    tabController!.dispose();
    instance = null;
    super.onClose();
  }

  void _setCurrentTour() {
    if (Session.shift?.tours != null) {
      currentTour = Session.shift!.tours!.firstWhere(
        (t) => t.path.any((tp) => tp.reportingPoint.isNotFinished),
        orElse: () => Session.shift!.tours!.last,
      );
    }
  }

  ///CAUTION: should be invoked only when the corresponding TabBar is visible!
  Future<void> restoreUnfinishedRPoint() async {
    final plannedRPoint = currentTour?.path
        .firstWhere((tp) => tp.reportingPoint.hasCurrentVisit,
            orElse: () => null!)
        .reportingPoint;
    if (plannedRPoint != null) {
      tabController!.index = 0;
      await Future.delayed(const Duration());
      plannedRPoint.expand();
    }
    final unplannedRPoint = otherRPoints!
        .firstWhere((rp) => rp.hasCurrentVisit, orElse: () => null!);
    if (unplannedRPoint != null) {
      tabController!.index = 1;
      await Future.delayed(const Duration());
      unplannedRPoint.expand();
    }
  }

  Future<void> submitActivity({
    @required BuildContext? context,
    ReportingPoint? rPoint,
    ShiftActivityTask? activity,
    ShiftActivityResult? result,
  }) async {
    final media = MediaUploadService.to.allMediaByEventId[activity!.id] ?? [];

    for (final m in media) {
      if (m.isUploadDeferred()) {
        final deferredUploadMedia = result!.deferredUploadMedia ?? [];
        deferredUploadMedia.add(m);
        result.deferredUploadMedia = deferredUploadMedia;
      } else if (m.publicUrl != null) {
        result!.addMediaUrl(m);
      }
    }
    activity.result = result!;
    //FIXME: not the best idea to save updated tours every time via storing Session
    final canFinishVisit =
        rPoint!.currentVisit.activities.every((act) => act.isFinished);
    if (canFinishVisit) {
      await _finishVisit(rPoint);
    } else {
      SessionService.storeSession();
      update(['reportingPoint${rPoint.id}']);
    }
    MediaUploadService.to.deleteAllById(activity.id);
  }

  Future<void> _finishVisit(ReportingPoint rPoint) async {
    rPoint.currentVisit.endedAt = dateTimeToSeconds(DateTime.now().toUtc());
    rPoint
      ..collapse()
      ..finishVisit();
    final theVisit = rPoint.visits!.last;

    try {
      final isOnline = await DataConnectionChecker().isConnectedToInternet;
      if (isOnline) {
        if (theVisit.activities
            .any((act) => act.result.hasDeferredUploadMedia)) {
          await SyncService.to.rPointsSyncCompleted.future;
          await saveRPointVisit(theVisit);
          SyncService.to.syncRPointVisits();
        } else {
          _repo.sendRPointVisit(theVisit);
        }
      } else {
        saveRPointVisit(theVisit);
      }
    } catch (e, s) {
      saveRPointVisit(theVisit);
      TelloLogger()
          .e('error while sending the reporting point: $e', stackTrace: s);
    }

    final canChangeTour =
        currentTour!.path.every((tp) => tp.reportingPoint.isFinished) &&
            currentTourIndex < Session.shift!.tours!.length - 1;
    if (canChangeTour) {
      _setCurrentTour();
      update(['ShiftActivitiesPage']);
    } else {
      update(['reportingPoint${rPoint.id}']);
    }

    SessionService.storeSession();
  }

  Future<void> discardVisitForRPoint(ReportingPoint rp) async {
    rp.collapse();
    for (final act in rp.currentVisit.activities) {
      MediaUploadService.to.deleteAllById(act.id);
    }
    rp.currentVisit = null as ReportingPointVisit;
    await SessionService.storeSession();
    update(['reportingPoint${rp.id}']);
    Get.back();
  }

  Future<void> saveRPointVisit(ReportingPointVisit rPointVisit) async {
    await rPointVisitsUploadQueue!.write(
      '${rPointVisit.tourId}_${rPointVisit.rPointId}_${rPointVisit.id}',
      rPointVisit.toMap(listToJson: true),
    );
  }

  Future<void> onQrScanPressed(BuildContext context) async {
    if (Get.isOverlaysOpen) Get.until((_) => Get.isOverlaysClosed);
    final result = await Get.to(() => const QrScanner());

    if (result is! Barcode) return;

    if (currentTour!.hasOngoingVisit ||
        otherRPoints!.any((rp) => rp.hasCurrentVisit)) {
      return SystemDialog.showConfirmDialog(
        title: "AppLocalizations.of(Get.context).warning.capitalize",
        message:
            'You have the unfinished reporting point visit. Please, finish it first',
        confirmCallback: Get.back,
      );
    }

    TelloLogger().i(result.code);
    int targetTabIndex = 0;
    ReportingPoint matchedRPoint = currentTour!.path
        .firstWhere((tp) => tp.reportingPoint.qrToken == result.code,
            orElse: () => null!)
        .reportingPoint;

    if (matchedRPoint == null) {
      return SystemDialog.showConfirmDialog(
        message:
            '{AppLocalizations.of(context).cantOpenRP} - {AppLocalizations.of(context).wrongQR}!',
      );
    }

    targetTabIndex = 1;

    bool? isLocationCheckPassed;
    Position? position;

    if (matchedRPoint.geoValidationRequired) {
      position = await getCurrPositionWithLoader(context);

      if (position != null) {
        final distanceToReportingPoint = LocationService().distanceBetween(
          position.latitude,
          position.longitude,
          matchedRPoint.location.latitude,
          matchedRPoint.location.longitude,
        );
        isLocationCheckPassed = distanceToReportingPoint <
            AppSettings().reportingPointLocationTolerance;
      } else {
        isLocationCheckPassed = false;
      }

      if (isLocationCheckPassed == false) {
        final canChangeTab = guardTabBarKey.currentWidget != null;
        if (canChangeTab && tabController!.index != targetTabIndex)
          tabController!.index = targetTabIndex;
        await Future.delayed(const Duration());
        return SystemDialog.showConfirmDialog(
          message:
              '{AppLocalizations.of(context).cantOpenRP} ${matchedRPoint.title} - {AppLocalizations.of(context).youAreOutside}!',
        );
      }
    }
    matchedRPoint.setCurrentVisit(ReportingPointVisit(
      rPointId: matchedRPoint.id,
      tourId: matchedRPoint.tourId,
      startedAt: dateTimeToSeconds(DateTime.now()),
      isLocationCheckPassed: isLocationCheckPassed,
      isQrCheckPassed: true,
      guardLocation:
          position != null ? Coordinates.fromPosition(position) : null,
      activities: matchedRPoint.activities.map((a) => a.copyWith()).toList(),
    ));

    if (matchedRPoint.hasActivities) {
      update(['reportingPoint${matchedRPoint.id}']);
      final canChangeTab = guardTabBarKey.currentWidget != null;
      if (canChangeTab && tabController!.index != targetTabIndex)
        tabController!.index = targetTabIndex;
      await Future.delayed(const Duration());
      matchedRPoint.expand();
      SessionService.storeSession();
    } else {
      await _finishVisit(matchedRPoint);
    }
  }

  //TODO: validate the RP properly, + message localization
  Future<void> onRPointOpen(ReportingPoint rp) async {
    if (currentTour!.hasOngoingVisit ||
        otherRPoints!.any((rp) => rp.hasCurrentVisit)) {
      return SystemDialog.showConfirmDialog(
        title: "AppLocalizations.of(Get.context).warning.capitalize",
        message:
            'You have the unfinished reporting point visit. Please, finish it first',
        confirmCallback: Get.back,
      );
    }

    SystemDialog.showConfirmDialog(
      title: "AppLocalizations.of(Get.context).warning.capitalize",
      message:
          'Reporting point ${rp.title} validation will be failed. Continue?',
      confirmCallback: () async {
        rp.setCurrentVisit(ReportingPointVisit(
          rPointId: rp.id,
          tourId: rp.tourId,
          startedAt: dateTimeToSeconds(DateTime.now()),
          isLocationCheckPassed: rp.geoValidationRequired ? false : null,
          isQrCheckPassed: rp.qrValidationRequired ? false : null,
          activities: rp.activities.map((a) => a.copyWith()).toList(),
        ));
        if (rp.hasActivities) {
          update(['reportingPoint${rp.id}']);
          await Future.delayed(const Duration());
          rp.expand();
          SessionService.storeSession();
        } else {
          await _finishVisit(rp);
        }
        Get.back();
      },
      cancelCallback: Get.back,
    );
  }

  void onRPointClose(ReportingPoint rp) {
    if (rp.hasNoActivities) return;

    SystemDialog.showConfirmDialog(
      title: " AppLocalizations.of(Get.context).warning.capitalize",
      message:
          'Your progress on activities for this reporting point will be lost. Continue?',
      confirmCallback: () => discardVisitForRPoint(rp),
      cancelCallback: Get.back,
    );
  }

  void toggleMapVisibility() => isMapVisible.toggle();
}
