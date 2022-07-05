import 'dart:async';

import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/coordinates_model.dart';
import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/shift_activities/models/reporting_point.dart';
import 'package:bazz_flutter/modules/shift_activities/models/reporting_point_visit.dart';
import 'package:bazz_flutter/modules/shift_activities/models/shift_activity_result.dart';
import 'package:bazz_flutter/modules/shift_activities/models/tour.dart';
import 'package:bazz_flutter/modules/shift_activities/shift_activities_stats/shift_activities_stats_repo.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/system_events_signaling.dart';
import 'package:eventify/eventify.dart' as evf;
import 'package:get/get.dart';

class ShiftActivitiesStatsController extends GetxController {
  static ShiftActivitiesStatsController get to => Get.find();
  final repo = ShiftActivitiesStatsRepository();
  StreamSubscription? _isOnlineSub;
  final loadingState = ViewState.idle.obs;
  List<Tour> tours = [];
  List<ReportingPoint> unplannedRPoints = [];
  RxPosition? selectedPosition;
  evf.Listener? _newEventSub;

  ///Positions with tours only
  List<RxPosition>? positions;
  RxBool isMapVisible = false.obs;

  int get tabsLength => tours.length + (unplannedRPoints.isNotEmpty ? 1 : 0);

  @override
  Future<void> onInit() async {
    positions = HomeController.to.groups
        .firstWhere(
          (gr) => gr.id == HomeController.to.activeGroup.id,
          orElse: () => null!,
        )
        .members
        .positions
        .where((pos) => pos.hasTours)
        .toList();

    if (Session.hasShift &&
        Session.shift!.tours!.isNotEmpty &&
        positions != null) {
      //putting the self's position at the beginning
      final myPositionIndex =
          positions!.indexWhere((pos) => Session.shift!.positionId == pos.id);
      final myPosition = positions!.removeAt(myPositionIndex);
      positions!.insert(0, myPosition);
    }
    if (positions?.isNotEmpty ?? false) {
      selectPosition(positions!.first);
    }
    _isOnlineSub = HomeController.to.isOnline$.listen((online) {
      if (online && selectedPosition != null) {
        fetchSelectedPosition();
      }
    });

    _newEventSub = SystemEventsSignaling()
        .on('PositionReportingPointStateEvent', this, (event, context) {
      final data = (event.eventData as Map<String, dynamic>)['data']
          as Map<String, dynamic>;
      if (data['groupId'] == HomeController.to.activeGroup.id &&
          data['positionId'] == selectedPosition?.id) {
        fetchSelectedPosition();
      }
    });
    super.onInit();
  }

  Future fetchSelectedPosition({bool displayLoader = false}) async {
    try {
      if (displayLoader) loadingState(ViewState.loading);
      if (selectedPosition == null) throw 'No selected position!';
      final resp = await repo.fetchStatsForPosition(selectedPosition!.id);

      final currentTourCopy = tours
          .firstWhere(
              (tour) => tour.path.any((tp) => tp.reportingPoint.isExpanded),
              orElse: () => null!)
          .copyWith();

      final List<ReportingPoint> unplannedRPointsCopy = unplannedRPoints
          .where((rp) => rp.isExpanded)
          .map((e) => e.copyWith())
          .toList();

      tours
        ..clear()
        ..addAll((resp.data!['tours']).map((t) => Tour.fromMap(t)));
      unplannedRPoints
        ..clear()
        ..addAll((resp.data!['reportingPoints'])
            .map((t) => ReportingPoint.fromMap(t)));
      final tourStates = resp.data!['tourStates'];
      if (tourStates.isNotEmpty) {
        //updating our tours and reporting points with states
        for (final tourState in tourStates) {
          final targetTour =
              tours.firstWhere((tour) => tour.tourId == tourState['tourId']);
          targetTour.startedAt = tourState['startedAt'];
          targetTour.endedAt =
              tourState['endedAt'] != null ? tourState['endedAt'] : null;
          for (final rPointVisit in tourState['reportingPointStates']) {
            final targetRPoint = tours
                .firstWhere((t) => t.tourId == rPointVisit['tourId'])
                .path
                .firstWhere((tp) =>
                    tp.reportingPoint.id == rPointVisit['reportPointId'])
                .reportingPoint;
            final visit = ReportingPointVisit(
              tourId: rPointVisit['tourId'],
              rPointId: rPointVisit['reportPointId'],
              isLocationCheckPassed:
                  rPointVisit['isLocationCheckPassed'] != null
                      ? rPointVisit['isLocationCheckPassed']
                      : null,
              isQrCheckPassed: rPointVisit['isQrPassed'] != null
                  ? rPointVisit['isQrPassed']
                  : null,
              guardLocation: rPointVisit['location'] != null
                  ? Coordinates.fromMap(rPointVisit['location'])
                  : null,
              startedAt: rPointVisit['startAt'],
              endedAt: rPointVisit['endAt'],
              activities:
                  targetRPoint.activities.map((a) => a.copyWith()).toList(),
            );
            targetRPoint.addVisit(visit);
            if (rPointVisit['activityStats'] != null) {
              for (final result in rPointVisit['activityStats']) {
                final activityTask = visit.activities
                    .firstWhere((task) => task.id == result['activityId']);
                activityTask.result = ShiftActivityResult.fromMap(result);
              }
            }
          }
        }
      }
      for (final tour in tours) {
        for (final tourPoint in tour.path) {
          final rPoint = tourPoint.reportingPoint;
          late ReportingPoint prevRPoint;
          if (tour.tourId == currentTourCopy.tourId) {
            prevRPoint = currentTourCopy.path
                .firstWhere((tp) => tp.reportingPoint.id == rPoint.id)
                .reportingPoint;
          }

          if (rPoint.visits!.isNotEmpty) {
            rPoint
              ..sortVisitsAscEndTime()
              ..setCurrentVisit(rPoint.visits!.first);
            if (prevRPoint.isExpanded) {
              rPoint
                ..setCurrentVisit(rPoint.visits!
                    .firstWhere((v) => v.id == prevRPoint.currentVisit.id))
                ..expand();
            }
          }
        }
      }
      for (final unplannedVisit
          in resp.data!['unplannedStates'] as List<dynamic>) {
        final targetRPoint = unplannedRPoints
            .firstWhere((urp) => urp.id == unplannedVisit['reportPointId']);
        final visit = ReportingPointVisit(
          tourId: unplannedVisit['tourId'] as String,
          rPointId: unplannedVisit['reportPointId'] as String,
          isLocationCheckPassed: unplannedVisit['isLocationCheckPassed'] != null
              ? unplannedVisit['isLocationCheckPassed'] as bool
              : null,
          isQrCheckPassed: unplannedVisit['isQrPassed'] != null
              ? unplannedVisit['isQrPassed'] as bool
              : null,
          guardLocation: unplannedVisit['location'] != null
              ? Coordinates.fromMap(
                  unplannedVisit['location'] as Map<String, dynamic>)
              : null,
          startedAt: unplannedVisit['startAt'] as int,
          endedAt: unplannedVisit['endAt'] as int,
          activities: targetRPoint.activities.map((a) => a.copyWith()).toList(),
        );
        targetRPoint.addVisit(visit);
        if (unplannedVisit['activityStats'] != null) {
          for (final result
              in unplannedVisit['activityStats'] as List<dynamic>) {
            final activityTask = visit.activities
                .firstWhere((task) => task.id == result['activityId']);
            activityTask.result =
                ShiftActivityResult.fromMap(result as Map<String, dynamic>);
          }
        }
        if (targetRPoint.visits!.isNotEmpty) {
          targetRPoint
            ..sortVisitsAscEndTime()
            ..setCurrentVisit(targetRPoint.visits!.first);
          final targetRPointCopy = unplannedRPointsCopy.firstWhere(
              (rp) => rp.id == targetRPoint.id,
              orElse: () => null!);
          if (targetRPointCopy.isExpanded) {
            targetRPoint
              ..setCurrentVisit(targetRPoint.visits!
                  .firstWhere((v) => v.id == targetRPointCopy.currentVisit.id))
              ..expand();
          }
        }
      }
      unplannedRPoints.retainWhere((rp) => rp.isFinished);
      update(['positionTours']);
    } catch (e, s) {
      TelloLogger().e('Error while fetching position stats: $e', stackTrace: s);
    } finally {
      if (displayLoader) loadingState(ViewState.idle);
    }
  }

  Future<void> selectPosition(RxPosition position) async {
    if (position.id != selectedPosition?.id) {
      selectedPosition = position;
      update(['positionsList']);
      if (Session.shift?.positionId != selectedPosition!.id &&
          HomeController.to.isOnline) {
        await fetchSelectedPosition(displayLoader: true);
      } else {
        update(['positionTours']);
      }
    }
  }

  void selectRPointVisit(ReportingPoint rPoint, ReportingPointVisit visit) {
    rPoint.setCurrentVisit(visit);
    rPoint.isChooseVisitPopupOpen(false);
    update(['reportingPoint${rPoint.id}']);
  }

  void toggleMapVisibility() => isMapVisible.toggle();

  @override
  void onClose() {
    _isOnlineSub!.cancel();
    _newEventSub!.cancel();
    super.onClose();
  }
}
