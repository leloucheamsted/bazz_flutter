import 'dart:ui';
import 'package:bazz_flutter/app_theme.dart';
import 'package:firebase_ml_vision/firebase_ml_vision.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class FacePainter extends CustomPainter {
  FacePainter({required this.imageSize, required this.face});
  final Size imageSize;
  late double scaleX, scaleY;
  Face face;
  @override
  void paint(Canvas canvas, Size size) {
    if (face == null) return;

    Paint paint;

    if (face.headEulerAngleY! > 10 || face.headEulerAngleY! < -10) {
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = Colors.red;
    } else {
      paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.0
        ..color = AppColors.primaryAccent;
    }

    scaleX = size.width / imageSize.width;
    scaleY = size.height / imageSize.height;

    canvas.drawRRect(
        _scaleRect(
            rect: face.boundingBox,
            imageSize: imageSize,
            widgetSize: size,
            scaleX: scaleX,
            scaleY: scaleY),
        paint);
  }

  @override
  bool shouldRepaint(FacePainter oldDelegate) {
    return oldDelegate.imageSize != imageSize || oldDelegate.face != face;
  }
}

RRect _scaleRect(
    {required Rect rect,
    required Size imageSize,
    required Size widgetSize,
    double? scaleX,
    double? scaleY}) {
  // ignore: unnecessary_parenthesis
  return RRect.fromLTRBR(
      (widgetSize.width - rect.left.toDouble() * scaleX!),
      rect.top.toDouble() * scaleY!,
      widgetSize.width - rect.right.toDouble() * scaleX,
      rect.bottom.toDouble() * scaleY,
      const Radius.circular(10));
}
