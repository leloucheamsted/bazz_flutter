import 'package:camera/camera.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/material.dart';
import 'camera_service.dart';

class MLVisionService {
  // singleton boilerplate
  static final MLVisionService _cameraServiceService =
      MLVisionService._internal();

  factory MLVisionService() {
    return _cameraServiceService;
  }
  // singleton boilerplate
  MLVisionService._internal();

  // service injection
  CameraService? _cameraService;
  FaceDetector? _faceDetector;
  FaceDetector get faceDetector => _faceDetector!;

  void initialize(CameraService cameraService) {
    _cameraService = cameraService;
    _faceDetector = FirebaseVision.instance.faceDetector(
      const FaceDetectorOptions(
        mode: FaceDetectorMode.accurate,
      ),
    );
  }

  void dispose() {
    _faceDetector?.close();
    _cameraService?.dispose();
  }

  Future<List<Face>> getFacesFromImage(CameraImage image) async {
    if (_faceDetector == null) return [];
    final FirebaseVisionImageMetadata _firebaseImageMetadata =
        FirebaseVisionImageMetadata(
      rotation: _cameraService!.cameraRotation,
      rawFormat: image.format.raw,
      size: Size(image.width.toDouble(), image.height.toDouble()),
      planeData: image.planes.map(
        (Plane plane) {
          return FirebaseVisionImagePlaneMetadata(
            bytesPerRow: plane.bytesPerRow,
            height: plane.height,
            width: plane.width,
          );
        },
      ).toList(),
    );

    /// Transform the image input for the _faceDetector
    final FirebaseVisionImage _firebaseVisionImage =
        FirebaseVisionImage.fromBytes(
            image.planes[0].bytes, _firebaseImageMetadata);

    /// proces the image and makes inference
    final List<Face> faces =
        await _faceDetector!.processImage(_firebaseVisionImage);
    return faces;
  }
}
