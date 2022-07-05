import 'dart:math' as math show sqrt;

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/sos_service.dart';
import 'package:bazz_flutter/services/keyboard_service.dart';
import 'package:bazz_flutter/services/vibrator.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

class SosButton extends StatefulWidget {
  @override
  _SosButtonState createState() => _SosButtonState();
}

class _SosButtonState extends State<SosButton> with TickerProviderStateMixin {
  late AnimationController _animController;
  final _buttonSizeCoefficient = 0.9;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    HomeController.to.addSosPressedListener((isPressed) {
      if (isPressed) {
        _animController.repeat();
      } else {
        _animController.stop();
      }
      setState(() {});
    });
  }

  @override
  void dispose() {
    HomeController.to.cancelSosPressedListeners();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(builder: (_, constraints) {
        final buttonDiameter = constraints.maxHeight * _buttonSizeCoefficient;
        return Stack(
          alignment: Alignment.center,
          children: [
            CustomPaint(
              painter: CirclePainter(
                // CurvedAnimation(parent: _animController, curve: Curves.ease),
                _animController,
                color: AppColors.error,
                waves: 4,
              ),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: _animController.isAnimating
                    ? buttonDiameter
                    : buttonDiameter / 2,
                height: _animController.isAnimating
                    ? buttonDiameter
                    : buttonDiameter / 2,
              ),
            ),
            _buildSosButton(buttonDiameter),
          ],
        );
      }),
    );
  }

  Widget _buildSosButton(double buttonDiameter) {
    return Obx(() {
      final sosDisabled = HomeController.to.isSosDisabled;
      final isPressed = HomeController.to.isSosPressed$;
      return Listener(
        onPointerDown: (_) {
          if (HomeController.to.isSosKeyPressed$) return;
          HomeController.to.onSosPress();
        },
        onPointerUp: (_) {
          if (HomeController.to.isSosKeyPressed$) return;
          HomeController.to.onSosRelease();
        },
        child: Container(
          width: buttonDiameter,
          height: buttonDiameter,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            border: Border.all(width: 4, color: AppTheme().colors.sosBtnBorder),
            shape: BoxShape.circle,
            color: sosDisabled ? AppTheme().colors.disabledButton : null,
            gradient: sosDisabled
                ? null
                : isPressed
                    ? LinearGradient(
                        begin: Alignment.topRight,
                        end: Alignment.bottomLeft,
                        colors: [
                          AppColors.error,
                          Colors.red[900]!,
                          Colors.red[800]!,
                          Colors.red[700]!,
                        ],
                        // ignore: prefer_const_literals_to_create_immutables
                        stops: [0, .1, .3, 1],
                      )
                    : const RadialGradient(
                        center: Alignment(.1, -.3),
                        focal: Alignment(.2, -.5),
                        // focalRadius: .02,
                        colors: [
                          Color(0xffff1f1f),
                          Color(0xffec1c1c),
                          Color(0xfff31f1f),
                        ],
                        stops: [.0, .0, .0],
                      ),
          ),
          child: Get.height > AppSettings().highResolutionDeviceDensity
              ? const Text(
                  'SOS',
                  style: AppTypography.subtitle1TextStyle,
                )
              : const Text(
                  'SOS',
                  style: AppTypography.subtitle7TextStyle,
                ),
        ),
      );
    });
  }
}

class CirclePainter extends CustomPainter {
  CirclePainter(
    this._animation, {
    required this.color,
    this.waves,
  }) : super(repaint: _animation);

  final Color color;
  final Animation<double> _animation;
  final int? waves;

  void circle(Canvas canvas, Rect rect, double value) {
    final double opacity = (1 - (value / 5.0)).clamp(0.0, 1.0).toDouble();
    final Color _color = color.withOpacity(opacity);
    final double size = rect.width / 2;
    final double area = size * size;
    final double radius = math.sqrt(area * value / 2.5);
    final Paint paint = Paint()..color = _color;
    canvas.drawCircle(rect.center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);
    for (int _waves = waves!; _waves >= 0; _waves--) {
      circle(canvas, rect, _waves + _animation.value);
    }
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) => true;
}
