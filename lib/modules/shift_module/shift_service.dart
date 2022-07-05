import 'dart:async';

import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/alert_check_config.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/group_model.dart';
import 'package:bazz_flutter/models/perimeter.dart';
import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/shift_end_message.dart';
import 'package:bazz_flutter/models/shift_model.dart';
import 'package:bazz_flutter/models/shift_summary.dart';
import 'package:bazz_flutter/modules/auth_module/auth_controller.dart';
import 'package:bazz_flutter/modules/auth_module/auth_repo.dart';
import 'package:bazz_flutter/modules/home_module/home_repo.dart';
import 'package:bazz_flutter/modules/location_tracking/location_service.dart';
import 'package:bazz_flutter/modules/shift_activities/models/reporting_point.dart';
import 'package:bazz_flutter/modules/shift_activities/models/tour.dart';
import 'package:bazz_flutter/modules/shift_activities/qr_scanner_page.dart';
import 'package:bazz_flutter/modules/shift_module/shift_repo.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/activity_recognition_service.dart';
import 'package:bazz_flutter/services/data_connection_checker.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/networking_client.dart';
import 'package:bazz_flutter/services/session_service.dart';
import 'package:bazz_flutter/shared_widgets/system_dialog.dart';
import 'package:bazz_flutter/utils/back_button_locker.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart' as qr_scanner;

class ShiftService extends GetxController {
  static ShiftService get to => Get.find();

  ShiftService(this._homeRepository);

  final HomeRepository _homeRepository;
  String? trackingUserId;
  String? currentGroup;

  late Rx<RxPosition> selectedPosition;

  late String errorMessage = '';

  final _loadingState = ViewState.idle.obs;

  ViewState get loadingState => _loadingState.value;

  final positionGroups = <RxGroup>[];

  final positionsInRange = <RxPosition>[];

  late Rx<LatLng>? _currentLocation;

  LatLng get currentLocation => _currentLocation!.value;

  set currentLocation(LatLng loc) => _currentLocation!.value = loc;

  bool get isBusy => loadingState == ViewState.loading;

  @override
  Future<void> onInit() async {
    TelloLogger().i("ShiftService onInit()");
    LocationService().init();

    update(["availablePositionsSelection"]);
    super.onInit();
  }

  @override
  Future<void> onReady() async {
    TelloLogger().i("ShiftService onReady()");
    super.onReady();
  }

  @override
  void onClose() {
    super.dispose();
  }

  Future<void> onShiftStartPressed() async {
    BackButtonLocker.lockBackButton();
    _loadingState(ViewState.loading);
    await Future.delayed(const Duration(), () {});
    StackTrace? stackTrace;
    try {
      final connected = await DataConnectionChecker().isConnectedToInternet;
      if (!connected) {
        _loadingState(ViewState.error);
        errorMessage = DataConnectionChecker().toString();
        return;
      }
      final resp = await ShiftRepository().createShift();
      if (resp.data != null && resp.data!['shift'] != null) {
        TelloLogger()
            .i('createShiftForSelectedPosition resp data: ${resp.data}');
        Session.shift!
          ..id = resp.data!['shift']['id']
          ..startTime = resp.data!['shift']['createdAt']
          ..plannedEndTime = resp.data!['shift']['plannedClosedAt']
          ..alertCheckConfig = (resp.data!['shift']['quizConfig'] != null
              ? AlertCheckConfig.fromMap(resp.data!['shift']['quizConfig'])
              : null)!
          ..tours = List<Tour>.from((resp.data!['tours'])
              .map((t) => Tour.fromMap(t as Map<String, dynamic>)))
          ..reportingPoints = List<ReportingPoint>.from((resp
                  .data!['reportingPoints'])
              .map((rp) => ReportingPoint.fromMap(rp as Map<String, dynamic>)));
        await SessionService.storeSession();
      }
      _loadingState(ViewState.initialize);
      await Session.storeCurrentSession();
      Get.offAllNamed(AppRoutes.home);
    } on DioError catch (e, s) {
      errorMessage = e.message;
      if (e.error is TelloError) {
        errorMessage = '${e.error.message}';
      }
      _loadingState(ViewState.error);
      stackTrace = s;
    } catch (e, s) {
      errorMessage = e.toString();
      stackTrace = s;
    } finally {
      if (errorMessage.isNotEmpty) {
        TelloLogger().e('onShiftStartPressed() error: $errorMessage',
            stackTrace: stackTrace);
        SystemDialog.showConfirmDialog(
          title: LocalizationService().of().systemInfo,
          message: errorMessage,
          confirmButtonText: LocalizationService().of().ok,
          confirmCallback: () {
            Get.back();
          },
          cancelCallback: () {},
          titleFillColor: null as Color,
        );
      }
      _loadingState(ViewState.idle);
      BackButtonLocker.unlockBackButton();
    }
  }

  Future<void> continueAsUser() async {
    if (Session.groupCount == 0) {
      SystemDialog.showConfirmDialog(
        title: LocalizationService().of().info,
        message: LocalizationService().of().userIsNotAssociatedToGroups,
        confirmButtonText: LocalizationService().of().ok,
        cancelCallback: () {},
      );
      return;
    }
    _loadingState(ViewState.loading);
    try {
      final connected = await DataConnectionChecker().isConnectedToInternet;
      if (!connected) {
        _loadingState(ViewState.error);
        errorMessage = DataConnectionChecker().toString();
        return;
      }
      errorMessage = "";
      await Session.storeCurrentSession();
      await Get.offAllNamed(AppRoutes.home);
    } catch (e) {
      _loadingState(ViewState.error);
    } finally {
      if (errorMessage.isNotEmpty) {
        TelloLogger().e('onShiftStartPressed: $errorMessage');
        SystemDialog.showConfirmDialog(
          title: LocalizationService().of().systemInfo,
          message: errorMessage,
          confirmButtonText: LocalizationService().of().ok,
          confirmCallback: () {
            Get.back();
          },
        );
      }
      _loadingState(ViewState.idle);
    }
  }

  Future<void> onShiftStartWithPositionPressed() async {
    _loadingState(ViewState.loading);
    await Future.delayed(const Duration(), () {});
    StackTrace? stackTrace;
    try {
      /*if (AppSettings().verifyUserLocationForPositionShift &&
          currentLocation != null &&
          !_checkIfLocationInsidePositionArea(selectedPosition.value)) {
        SystemDialog.showConfirmDialog(
          title: LocalizationService().localizationContext().notInShiftPositionRangeTitle,
          message: LocalizationService().localizationContext().notInShiftPositionRangeMag,
          confirmButtonText: LocalizationService().localizationContext().ok,
        );
        _loadingState(ViewState.error);
        return;
      }*/
      Position? currentPosition;
      if (currentLocation != null) {
        currentPosition = await LocationService().getCurrentPosition();
      }
      final resp = await ShiftRepository().createShiftForSelectedPosition(
          selectedPosition.value.id, currentPosition!);

      if (resp.data != null && resp.data!['shift'] != null) {
        TelloLogger()
            .i('createShiftForSelectedPosition resp data: ${resp.data}');
        Session.shift = Shift.fromPositionAndGroup(
            selectedPosition.value, selectedPosition.value.parentGroup);

        final reportingPoints = (resp.data!['reportingPoints'])
            .map((rp) => ReportingPoint.fromMap(rp))
            .toList();
        final shiftEndMessages = (resp.data!['shiftEndMessages'])
            .map((rp) => ShiftEndMessage.fromMap(rp))
            .toList();

        await processShiftEndMessagesIcons(shiftEndMessages);

        Session.shift!
          ..id = resp.data!['shift']['id'] as String
          ..startTime = resp.data!['shift']['createdAt'] as int
          ..plannedEndTime = resp.data!['shift']['plannedClosedAt'] as int
          ..alertCheckConfig = (resp.data!['shift']['quizConfig'] != null
              ? AlertCheckConfig.fromMap(resp.data!['shift']['quizConfig'])
              : null)!
          ..tours =
              List<Tour>.from((resp.data!['tours']).map((t) => Tour.fromMap(t)))
          ..reportingPoints = reportingPoints
          ..shiftEndMessages = shiftEndMessages;
        await SessionService.storeSession();
      }
      await Session.storeCurrentSession();
      ActivityRecognitionService().start();
      await Get.offAllNamed(AppRoutes.home);
    } on DioError catch (e, s) {
      errorMessage = e.message;
      stackTrace = s;
      if (e.error is TelloError) {
        final errorCode = (e.error as TelloError).code;
        if (errorCode == 301) {
          errorMessage =
              LocalizationService().of().cantStartRotationWrongLocation;
        } else if (errorCode == 401) {
          errorMessage =
              LocalizationService().of().cantStartRotationUnlockedPosition;
        } else if (errorCode == 5) {
          errorMessage =
              LocalizationService().of().positionRotationAssignmentIsNotValid;
        }
      }
      _loadingState(ViewState.error);
    } catch (e, s) {
      errorMessage = "onShiftStartWithPositionPressed() error: $e";
      stackTrace = s;
      _loadingState(ViewState.error);
    } finally {
      if (errorMessage.isNotEmpty) {
        TelloLogger().e(
            'onShiftStartWithPositionPressed() error: $errorMessage',
            stackTrace: stackTrace);
        SystemDialog.showConfirmDialog(
          title: LocalizationService().of().systemInfo,
          message: errorMessage,
          confirmButtonText: LocalizationService().of().ok,
          confirmCallback: () {
            Get.back();
          },
        );
      }
      _loadingState(ViewState.idle);
    }
  }

  /// For each icon we check and set if we have this icon in assets folder
  Future<void> processShiftEndMessagesIcons(
      List<ShiftEndMessage> shiftEndMessages) async {
    final futures = <Future<bool>>[];

    for (final msg in shiftEndMessages) {
      if (msg.icon.iconAssetNotExists)
        futures.add(msg.icon.setIconAssetExists());
    }

    await Future.wait(futures);
  }

  Future<ShiftSummary> onShiftEndPressed(DateTime shiftEndTime,
      {bool forcedShiftEnd = false}) async {
    BackButtonLocker.lockBackButton();
    _loadingState(ViewState.loading);
    ShiftSummary shiftSummary;
    try {
      shiftSummary =
          await endShift(shiftEndTime, forcedShiftEnd: forcedShiftEnd);
      _loadingState(ViewState.success);
    } catch (_) {
      _loadingState(ViewState.error);
      rethrow;
    } finally {
      BackButtonLocker.unlockBackButton();
    }
    return shiftSummary;
  }

  Future<ShiftSummary> endShift(DateTime shiftEndTime,
      {bool forcedShiftEnd = false}) async {
    ShiftSummary? shiftSummary;
    StackTrace? stackTrace;
    try {
      final resp = await ShiftRepository().closeShift(shiftEndTime);
      if (resp.data != null &&
          resp.data!['shift'] != null &&
          resp.data!['shift']['closedAt'] != null) {
        shiftSummary = ShiftSummary.fromMap(resp.data!['shift']);
        shiftSummary
          ..forcedShiftEnd = forcedShiftEnd
          ..rating = resp.data!['rating'] as int;
      }
    } on DioError catch (e, s) {
      if (e.error is TelloError) {
        errorMessage = '${e.error.message}';
      } else {
        errorMessage = LocalizationService().of().failedEndingShiftAssignment;
      }
      stackTrace = s;
      rethrow;
    } catch (e, s) {
      errorMessage = e.toString();
      stackTrace = s;
    } finally {
      if (errorMessage.isNotEmpty) {
        TelloLogger().e('onShiftEndPressed() error: $errorMessage',
            stackTrace: stackTrace);
      }
    }
    return shiftSummary!;
  }

  Future<void> selectAvailablePosition(RxPosition pos) async {
    selectedPosition.value = pos;
    if (!Session.hasShift) {
      await onShiftStartWithPositionPressed();
    } else {
      await onShiftStartPressed();
    }
  }

  Future<void> loadShiftData() async {
    try {
      TelloLogger().i("loadShiftData ");

      Session.shift!.currentPosition!.parentGroup =
          Session.shift!.currentGroup!;
    } catch (e, s) {
      TelloLogger()
          .e('shift controller.fetchGroups() error: $e', stackTrace: s);
    }
  }

  Future<void> fetchSuggestedPositionsByLocation() async {
    TelloLogger().i("STARTING fetchGroups");
    _loadingState(ViewState.loading);
    errorMessage = "";
    StackTrace? stackTrace;
    try {
      final connected = await DataConnectionChecker().isConnectedToInternet;
      if (!connected) {
        _loadingState(ViewState.error);
        errorMessage = DataConnectionChecker().toString();
        return;
      }
      positionsInRange.clear();
      if (Session.hasShift) {
        Session.shift!.currentPosition!.parentGroup =
            Session.shift!.currentGroup!;
        positionsInRange.add(Session.shift!.currentPosition!);
      } else {
        final Position currentPosition =
            await LocationService().getCurrentPosition();
        if (currentPosition == null) {
          update(["availablePositionsSelection"]);
          errorMessage =
              LocalizationService().of().currentLocationIsntAvailable;
          throw errorMessage;
        }
        currentLocation =
            LatLng(currentPosition.latitude, currentPosition.longitude);

        final resp = await _homeRepository.fetchSuggestedPositions(
            current: currentLocation,
            minSearchRadius: AppSettings().positionSearchMinRadius,
            maxSearchRadius: AppSettings().positionSearchMaxRadius);
        if (resp == null) {
          errorMessage = LocalizationService().of().cantFindRelatedGroups;
          throw errorMessage;
        }
        TelloLogger().i(
            "fetchSuggestedPositions results == ${resp.suggestedPositions!.length}");
        for (final group in resp.groups!) {
          for (final pos in group.members.positions) {
            pos.parentGroup = group;
            final suggestionIsFound =
                resp.suggestedPositions?.any((sp) => sp.id == pos.id) ?? false;
            final noDuplicatesFound =
                positionsInRange.every((p) => p.id != pos.id);

            if (suggestionIsFound && noDuplicatesFound)
              positionsInRange.add(pos);
          }
        }
      }
      _loadingState(ViewState.success);
    } on DioError catch (e, s) {
      _loadingState(ViewState.error);
      errorMessage = e.message;
      stackTrace = s;
      if (e.error is TelloError) {
        errorMessage = e.error.message as String;
      }
    } catch (e, s) {
      _loadingState(ViewState.error);
      errorMessage = e.toString();
      stackTrace = s;
    } finally {
      if (errorMessage.isNotEmpty) {
        TelloLogger().e(
            'ShiftService fetchSuggestedPositions() error: $errorMessage',
            stackTrace: stackTrace);
        SystemDialog.showConfirmDialog(
          title: LocalizationService().of().systemInfo,
          message: errorMessage,
          confirmButtonText: LocalizationService().of().ok,
          confirmCallback: () {
            Get.back();
          },
        );
      }
      update(["availablePositionsSelection"]);
      _loadingState(ViewState.idle);
    }
  }

  Future<void> displayPositionByQRCode() async {
    errorMessage = '';
    try {
      final connected = await DataConnectionChecker().isConnectedToInternet;
      if (!connected) {
        _loadingState(ViewState.error);
        errorMessage = DataConnectionChecker().toString();
        return;
      }
      positionsInRange.clear();
      final result = await Get.to(() => QrScanner());
      _loadingState(ViewState.loading);
      if (result is qr_scanner.Barcode) {
        TelloLogger().i(result.code);
        final group = await _homeRepository.getByBaseRpToken(result.code!);
        if (group == null) throw "Positions not found";
        TelloLogger()
            .i("group.members.positions == ${group.members.positions.length}");
        group.members.positions.first.parentGroup = group;
        selectedPosition(group.members.positions.first);
        TelloLogger().i(
            "group.members.positions.first ${group.members.positions.first.title}");
        for (final pos in group.members.positions) {
          pos.parentGroup = group;
          positionsInRange.add(pos);
        }
      }
      currentLocation = null as LatLng;
    } on DioError catch (e, s) {
      _loadingState(ViewState.error);
      errorMessage = e.message;
      if (e.error is TelloError) {
        final errorCode = (e.error as TelloError).code;
        if (errorCode == 400) {
          errorMessage =
              LocalizationService().of().cantStartRotationPositionNotFound;
        } else if (errorCode == 401) {
          errorMessage =
              LocalizationService().of().cantStartRotationUnlockedPosition;
        } else if (errorCode == 5) {
          errorMessage =
              LocalizationService().of().positionRotationAssignmentIsNotValid;
        }
      }
      TelloLogger()
          .e('Failed getting position by QR Code DioError: $e', stackTrace: s);
    } catch (e, s) {
      errorMessage = "Failed getting position by QR Code => $e";
      TelloLogger()
          .e("Failed getting position by QR Code => $e", stackTrace: s);
      _loadingState(ViewState.error);
    } finally {
      if (errorMessage.isNotEmpty) {
        SystemDialog.showConfirmDialog(
          title: LocalizationService().of().systemInfo,
          message: errorMessage,
          confirmButtonText: LocalizationService().of().ok,
          confirmCallback: () {
            Get.back();
          },
        );
      }
      _loadingState(ViewState.idle);
      update(["availablePositionsSelection"]);
    }
  }

  Future<void> goBackToLoginPage() async {
    try {
      _loadingState(ViewState.loading);
      positionsInRange.clear();
      if (Session.user != null) {
        await AuthRepository().logOut();
        await Session.wipeSession();
        TelloLogger().i("onLogInPressed logout ${Session.shift}");
      }
      AuthController.to.startNFCReaderStream();
      Get.back();
    } finally {
      update(["availablePositionsSelection"]);
      _loadingState(ViewState.idle);
    }
  }

  bool _checkIfLocationInsideArea(LatLng location, List<LatLng> vertices) {
    if (vertices == null) return false;
    int intersectCount = 0;
    for (int j = 0; j < vertices.length - 1; j++) {
      if (rayCastIntersect(location, vertices[j], vertices[j + 1])) {
        intersectCount++;
      }
    }
    return (intersectCount % 2) == 1; // odd = inside, even = outside;
  }

  bool rayCastIntersect(LatLng tap, LatLng vertA, LatLng vertB) {
    final double aY = vertA.latitude;
    final double bY = vertB.latitude;
    final double aX = vertA.longitude;
    final double bX = vertB.longitude;
    final double pY = tap.latitude;
    final double pX = tap.longitude;

    if ((aY > pY && bY > pY) || (aY < pY && bY < pY) || (aX < pX && bX < pX)) {
      return false; // a and b can't both be above or below pt.y, and a or
      // b must be east of pt.x
    }

    final double m = (aY - bY) / (aX - bX); // Rise over run
    final double bee = (-aX) * m + aY; // y = mx + b
    final double x = (pY - bee) / m; // algebra is neat!

    return x > pX;
  }

  bool _checkIfLocationInsidePositionArea(RxPosition pos) {
    if (currentLocation == null) return false;
    List<LatLng>? points;
    final Perimeter perimeter = pos.perimeter;
    if (perimeter.circlePerimeter != null) {
      points = GeoUtils.createCirclePoints(
          perimeter.circlePerimeter.center.toLatLng(),
          perimeter.circlePerimeter.radius + perimeter.tolerance,
          1);
    } else if (perimeter.polygonPerimeter != null) {
      points = perimeter.polygonPerimeter.perimeterWithTolerance
          .map((x) => x.toLatLng())
          .toList();
    }
    // return _checkIfLocationInsideArea(LatLng(3.897970, 11.510860), points);
    return _checkIfLocationInsideArea(currentLocation, points!);
  }
}
