import 'dart:ui';

import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';

//TODO: refactor this singleton if favor of GetxController - we don't need it all the time
class CameraService {
  // singleton boilerplate
  static final CameraService _cameraServiceService = CameraService._internal();

  factory CameraService() {
    return _cameraServiceService;
  }

  // singleton boilerplate
  CameraService._internal();

  CameraController? _cameraController;

  CameraController get cameraController => _cameraController!;

  CameraDescription? _cameraDescription;

  ImageRotation? _cameraRotation;

  ImageRotation get cameraRotation => _cameraRotation!;

  Future<void> startService(CameraDescription cameraDescription) {
    _cameraDescription = cameraDescription;
    _cameraController = CameraController(
      _cameraDescription!,
      ResolutionPreset.max,
      enableAudio: false,
    );

    // sets the rotation of the image
    _cameraRotation = rotationIntToImageRotation(
      _cameraDescription!.sensorOrientation,
    );

    // Next, initialize the controller. This returns a Future.
    return _cameraController!.initialize();
  }

  ///this is the dirty hack, which fixes inability to init CameraController with rear camera. Should be run beforehand
  //TODO: figure out why this sh*t happens
  Future<void> fixRearCamera() async {
    final cameras = await availableCameras();
    if (cameras == null || cameras.isEmpty) return;
    final frontCameraDescription = cameras.firstWhere(
        (CameraDescription cd) => cd.lensDirection == CameraLensDirection.front,
        orElse: () => null as CameraDescription);

    if (frontCameraDescription == null) return;

    final cameraController = CameraController(
      frontCameraDescription,
      ResolutionPreset.high,
      enableAudio: false,
    );

    await cameraController.initialize();
    await cameraController.dispose();
  }

  ImageRotation rotationIntToImageRotation(int rotation) {
    switch (rotation) {
      case 90:
        return ImageRotation.rotation90;
      case 180:
        return ImageRotation.rotation180;
      case 270:
        return ImageRotation.rotation270;
      default:
        return ImageRotation.rotation0;
    }
  }

  /// takes the picture and returns it 📸
  Future<XFile> takePicture() {
    return _cameraController!.takePicture();
  }

  /// returns the image size 📏
  Size getImageSize() {
    return Size(
      _cameraController!.value.previewSize!.height,
      _cameraController!.value.previewSize!.width,
    );
  }

  // ignore: type_annotate_public_apis
  dispose() {
    _cameraController!.dispose();
  }
}
