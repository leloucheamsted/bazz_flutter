import 'dart:async';
import 'dart:ui' as ui;
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/alert_check_config.dart';
import 'package:bazz_flutter/models/alert_check_result.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/alert_check/alert_check_repo.dart';
import 'package:bazz_flutter/modules/alert_check/alert_check_service.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/location_tracking/location_service.dart';
import 'package:bazz_flutter/modules/shift_activities/qr_scanner_page.dart';
import 'package:bazz_flutter/modules/shift_activities/shift_activities_service.dart';
import 'package:bazz_flutter/modules/shift_module/models/alert_check_rpoint.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/utils/back_button_locker.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:eventify/eventify.dart' as evf;
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';

class AlertCheckController extends GetxController {
  static AlertCheckController get to => Get.find();
  final AlertCheckRepository _repository;

  AlertCheckController(this._repository);

  final _loadingState = ViewState.idle.obs;

  ViewState get loadingState => _loadingState.value;

  late evf.Listener locationUpdateSub = evf.Listener as evf.Listener;

  @override
  void onInit() {
    locationUpdateSub = LocationService().on('locationUpdate', this,
        (evf.Event ev, Object? context) async {
      Position? position;
      late AlertCheckRPoint? targetAlertCheckRP;
      if (position == null ||
          (AlertCheckService.to.alertCheckRPoints.isEmpty)) {
        return;
      }

      if (position.speed > 1.7) {
        TelloLogger().i(
            'You are moving too fast! Speed: {position.speed}, speedAccuracy: {position.speedAccuracy}');
        return;
      }

      targetAlertCheckRP = AlertCheckService.to.alertCheckRPoints.firstWhere(
        (rp) {
          if (rp.validationType != RPValidationType.geo) return false;

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
      );

      if (targetAlertCheckRP == null) return;

      targetAlertCheckRP.isCheckPassed = true;
    });

    super.onInit();
  }

  @override
  void onClose() {
    locationUpdateSub.cancel();
    super.onClose();
  }

  Future<void> onFaceDetection() async {
    Get.toNamed(AppRoutes.faceAuth);
  }

  Future<void> onSendPressed({String? base64Image}) async {
    int maxScore = 0;
    int userScore = 0;

    if (Session.shift!.alertCheckConfig!.alertCheckType ==
        AlertCheckType.reportingPoints) {
      maxScore = AlertCheckService.to.alertCheckRPoints.length;
      for (final r in AlertCheckService.to.alertCheckRPoints) {
        if (r.isCheckPassed) userScore++;
      }
    } else {
      for (final i in quizItems) {
        if (i.isCorrect) {
          maxScore++;
          if (i.isSelected()) {
            userScore++;
          }
        }
      }
    }

    final result = AlertCheckResult(
      timeSpent: AlertCheckService.to.timeSpent,
      userScore: userScore,
      maxScore: maxScore,
      createdAt: dateTimeToSeconds(DateTime.now().toUtc()),
      faceRecImage64: base64Image!,
      snoozes: AlertCheckService.to.alertCheckSnoozes,
      alertCheckRPoints: AlertCheckService.to.alertCheckRPoints,
    );

    try {
      BackButtonLocker.lockBackButton();
      _loadingState(ViewState.loading);

      if (HomeController.to.isOnline) {
        await _repository.sendResult(result);
      } else {
        await AlertCheckService.to.saveResult(result);
      }
    } catch (e, s) {
      await AlertCheckService.to.saveResult(result);
      TelloLogger()
          .e('AlertCheckController onSendPressed error: $e', stackTrace: s);
    } finally {
      _loadingState(ViewState.success);
      BackButtonLocker.unlockBackButton();
      AlertCheckService.to.finishAlertCheck();
      Get.back(result: true, closeOverlays: true);
    }
  }

  Future<void> onReportingPointPressed(BuildContext context) async {
    if (Get.isOverlaysOpen) Get.until((_) => Get.isOverlaysClosed);
    final result = await Get.to(() => const QrScanner());

    if (result is! Barcode) return;

    TelloLogger().i(result.code);

    final matchedReportingPoint = Session
        .shift!.alertCheckConfig!.reportingPoints
        .firstWhere((rp) => rp.qrToken == result.code, orElse: () => null!);

    if (matchedReportingPoint == null) {
      // return
      Get.showSnackbar(
        GetBar(
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.error,
          message:
              '{AppLocalizations.of(context).cantMatchRP} - {AppLocalizations.of(context).wrongQR}!',
          titleText: const Text('Error', style: AppTypography.captionTextStyle),
          icon: const Icon(Icons.warning_amber_rounded,
              color: AppColors.brightIcon),
        ),
      );
    }

    if (matchedReportingPoint.geoValidationRequired) {
      bool isLocationCheckPassed = false;
      final position =
          await ShiftActivitiesService.getCurrPositionWithLoader(context);

      final distanceToReportingPoint = LocationService().distanceBetween(
        position.latitude,
        position.longitude,
        matchedReportingPoint.location.latitude,
        matchedReportingPoint.location.longitude,
      );
      isLocationCheckPassed = distanceToReportingPoint <
          AppSettings().reportingPointLocationTolerance;

      if (!isLocationCheckPassed) {
        // return
        Get.showSnackbar(GetBar(
          snackPosition: SnackPosition.TOP,
          backgroundColor: AppColors.error,
          message:
              '{AppLocalizations.of(context).cantMatchRP} - {AppLocalizations.of(context).youAreOutside}!',
          titleText: const Text('Error', style: AppTypography.captionTextStyle),
          icon: const Icon(Icons.warning_amber_rounded,
              color: AppColors.brightIcon),
        ));
      }
    }

    final targetAlertCheckRPoint =
        AlertCheckService.to.getAlertCheckRPointById(matchedReportingPoint.id);
    targetAlertCheckRPoint.isCheckPassed = true;
    AlertCheckService.to.storeCurrentAlertCheckRPoints();
    update();
  }

  //TODO: replace with real local images
  final quizItems = [
    RxQuizItem(Container(color: Colors.black38)),
    RxQuizItem(Container(color: Colors.red)),
    RxQuizItem(Container(color: Colors.orange), isCorrect: true),
    RxQuizItem(Container(color: Colors.orange), isCorrect: true),
    RxQuizItem(Container(color: Colors.orange), isCorrect: true),
    RxQuizItem(Container(color: Colors.blueAccent)),
    RxQuizItem(Container(color: Colors.purple)),
    RxQuizItem(Container(color: Colors.black)),
    RxQuizItem(Container(color: Colors.blue.withOpacity(0.5))),
  ];
}

class RxQuizItem {
  final Widget image;
  final bool isCorrect;
  final RxBool isSelected = false.obs;

  RxQuizItem(this.image, {this.isCorrect = false});
}
