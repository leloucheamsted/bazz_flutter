import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/device_model.dart' as deviceModel;
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/shift_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/modules/alert_check/alert_check_controller.dart';
import 'package:bazz_flutter/modules/auth_module/auth_controller.dart';
import 'package:bazz_flutter/modules/auth_module/auth_repo.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/camera_service.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/ml_vision_service.dart';
import 'package:bazz_flutter/services/networking_client.dart';
import 'package:bazz_flutter/shared_widgets/system_dialog.dart';
import 'package:camera/camera.dart';
import 'package:dio/dio.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'package:flutter_exif_rotation/flutter_exif_rotation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';

// TODO: finish SupervisorAuthController
class FaceAuthController extends GetxController {
  static FaceAuthController get to => Get.find();
  bool _detectingFaces = false;
  bool fromAlertCheck = false;
  String errorMessage = '';

  // service injection
  final MLVisionService _mlVisionService = MLVisionService();

  late Rx<Face>? _faceDetected$;
  late Rx<Size>? _imageSize$;
  String? imagePath;
  final _loadingState = ViewState.idle.obs;
  final _pictureTaken = false.obs;
  final _bottomSheetEnabled = false.obs;
  late Rx<Future>? _initializeControllerFuture$;
  final cameraService = CameraService();

  Face get faceDetected => _faceDetected$!.value;

  Size get imageSize => _imageSize$!.value;

  bool get pictureTaken => _pictureTaken.value;

  bool get bottomSheetEnabled => _bottomSheetEnabled.value;

  Future get initializeControllerFuture => _initializeControllerFuture$!.value;

  ViewState get loadingState => _loadingState.value;

  late CameraImage currentImage;

  bool isStarted = false;

  @override
  Future<void> onInit() async {
    _mlVisionService.initialize(cameraService);
    _loadingState(ViewState.idle);
    fromAlertCheck = Get.previousRoute != AppRoutes.login;
    final cameras = await availableCameras();

    /// takes the front camera
    final CameraDescription cameraDescription = cameras.firstWhere(
      (CameraDescription camera) =>
          camera.lensDirection == CameraLensDirection.front,
    );
    _initializeControllerFuture$!(
        cameraService.startService(cameraDescription));

    await _initializeControllerFuture$!.value;
    _frameFaces();
    _pictureTaken(false);
    isStarted = true;

    super.onInit();
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }

  void stop() {
    if (isStarted) {
      cameraService.dispose();
      _mlVisionService.dispose();
    }
  }

  Future<void> performLogin(String formatImg64,
      {bool ignoreActiveSession = false}) async {
    Map<String, dynamic> data;
    try {
      NetworkingClient().setBearerVersion();
      data = await AuthRepository().faceLogin(
          AuthController.to.usernameController.text,
          AppSettings().simSerial,
          formatImg64,
          ignoreActiveSession: ignoreActiveSession,
          skipErrorDisplay: true);
      final authToken = data['token'] as String;
      loginIntoApp(data, authToken);
    } on DioError catch (e, s) {
      _loadingState(ViewState.error);
      errorMessage = e.message;

      if (e.type == DioErrorType.cancel &&
          e.error != null &&
          e.error is TelloError) {
        final TelloError bazzError = e.error as TelloError;
        //TODO: localize error messages
        errorMessage = e.error.message as String;

        if (bazzError.code == 99) {
          SystemDialog.showConfirmDialog(
            title: LocalizationService().of().mobileVersionNotSupportedTitle,
            message: LocalizationService().of().mobileVersionNotSupportedMsg,
            confirmButtonText: LocalizationService().of().ok,
            confirmCallback: () {
              Get.back();
            },
          );
        } else if (bazzError.code == 4) {
          TelloLogger().e('performLogin error: $e', stackTrace: s);
          SystemDialog.showConfirmDialog(
            title: LocalizationService().of().userAlreadyLoggedInTitle,
            message: LocalizationService().of().userAlreadyLoggedInMsg,
            confirmButtonText: LocalizationService().of().ok,
            cancelButtonText: LocalizationService().of().cancel,
            confirmCallback: () {
              Get.back();
              performLogin(formatImg64, ignoreActiveSession: true);
            },
            cancelCallback: () {
              Get.back();
            },
          );
        }
      }
    }
  }

  void loginIntoApp(Map<String, dynamic> data, String authToken) {
    Session.updateAndStoreSession(
      authToken: authToken,
      user: RxUser.fromMap(data['userCard'] as Map<String, dynamic>),
      device: data['device'] != null
          ? deviceModel.Device.fromResponse(
              data['device'] as Map<String, dynamic>)
          : null!,
      groupCount: data['groupCount'] != null ? data['groupCount'] as int : 0,
      authenticationMethod: AuthenticationType.FaceId,
      shift: null as Shift,
    );
    NetworkingClient().setBearerToken(authToken);

    _loadingState(ViewState.success);
    Get.offAllNamed(AppRoutes.shiftPositionProfile);
  }

  /// handles the button pressed event
  Future<void> onShot() async {
    try {
      _bottomSheetEnabled(false);
      await cameraService.cameraController.stopImageStream();
      TelloLogger().i("imagePath == $imagePath");
      //await Future.delayed(const Duration(milliseconds: 500));
      _imageSize$!(cameraService.getImageSize());
      //await Future.delayed(const Duration(milliseconds: 200));
      final image = await cameraService.takePicture();

      imagePath = image.path;

      _pictureTaken(true);

      final File rotatedImage =
          await FlutterExifRotation.rotateAndSaveImage(path: image.path);

      //final bytes = await convertImagetoPng(currentImage);
      final bytes = await rotatedImage.readAsBytes();
      final String img64 = base64Encode(bytes);
      final String formatImg64 = "data:image/png;base64,$img64";

      if (fromAlertCheck) {
        TelloLogger().i("Send Image To QIZ");
        _loadingState(ViewState.success);
        Get.back();
        await AlertCheckController.to.onSendPressed(base64Image: formatImg64);
      } else {
        _loadingState(ViewState.loading);
        await Session.wipeSession();
        performLogin(formatImg64);
      }
      stop();
    } on DioError catch (e, s) {
      errorMessage = 'FACE RECOGNITION FAILED';
      _loadingState(ViewState.error);
      errorMessage = e.message;
      if (e.type == DioErrorType.cancel &&
          e.error != null &&
          e.error is TelloError) {
        //TODO: localize error messages
        errorMessage = e.error.message as String;
      }
      TelloLogger().e('onFaceloginPressed error: $e', stackTrace: s);
    } catch (e, s) {
      errorMessage = 'FACE RECOGNITION FAILED';
      _loadingState(ViewState.error);
      TelloLogger().e('onFaceloginPressed error: $e', stackTrace: s);
    } finally {
      _pictureTaken(false);
      if (_loadingState.value == ViewState.error) {
        _bottomSheetEnabled(true);
        _frameFaces();
      }
    }
  }

  /// draws rectangles when detects faces
  Future<void> _frameFaces() async {
    _imageSize$!(cameraService.getImageSize());
    try {
      cameraService.cameraController.startImageStream((image) async {
        if (cameraService.cameraController != null) {
          // if its currently busy, avoids over processing
          if (_detectingFaces) return;

          _detectingFaces = true;

          try {
            final List<Face> faces =
                await _mlVisionService.getFacesFromImage(image);

            if (faces.isNotEmpty) {
              _faceDetected$!(faces[0]);
              if (faces[0].headEulerAngleY! > 10 ||
                  faces[0].headEulerAngleY! < -10) {
                _bottomSheetEnabled(false);
              } else {
                currentImage = image;
                _bottomSheetEnabled(true);
              }
            } else {
              _faceDetected$!(null);
              _bottomSheetEnabled(false);
            }
            _detectingFaces = false;
          } catch (e, s) {
            TelloLogger().e("_mlVisionService.getFacesFromImage error $e",
                stackTrace: s);
            _detectingFaces = false;
          }
        }
      });
    } catch (e, s) {
      TelloLogger().e(
          "cameraService.value.cameraController.startImageStream error $e",
          stackTrace: s);
      _detectingFaces = false;
    }
  }
}
