import 'dart:math' as math;

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get_utils/get_utils.dart';

typedef SetDuration = void Function(Duration duration);

class CountDownTimer extends StatefulWidget {
  final Duration? duration;
  final VoidCallback? onFinish;
  final SetDuration? onValueChanged;

  const CountDownTimer(
      {Key? key, this.duration, this.onFinish, this.onValueChanged})
      : super(key: key);

  @override
  _CountDownTimerState createState() => _CountDownTimerState();
}

class _CountDownTimerState extends State<CountDownTimer>
    with TickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();
    controller = AnimationController(
      vsync: this,
      duration: widget.duration ?? const Duration(seconds: 5),
    )
      ..addListener(_valueListener)
      ..value = widget.duration!.inMilliseconds /
          (Session.shift!.alertCheckConfig!.alertCheckTimeout * 1000);
  }

  void _valueListener() {
    if (controller == null) return;

    if (controller.value == 0) {
      widget.onFinish!();
    } else {
      widget.onValueChanged!(
          widget.duration! - (controller.lastElapsedDuration ?? 0.seconds));
    }
  }

  @override
  void dispose() {
    controller
      ..removeListener(_valueListener)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    controller.reverse(from: controller.value == 0.0 ? 1.0 : controller.value);
    final ThemeData themeData = Theme.of(context);
    return AnimatedBuilder(
        animation: controller,
        builder: (context, child) {
          return Stack(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(6.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Expanded(
                      child: Align(
                        alignment: FractionalOffset.center,
                        child: AspectRatio(
                          aspectRatio: 1.0,
                          child: Stack(
                            children: <Widget>[
                              Positioned.fill(
                                child: CustomPaint(
                                    painter: CustomTimerPainter(
                                  animation: controller,
                                  backgroundColor: Colors.transparent,
                                  color: AppColors.darkIcon.withOpacity(0.5),
                                )),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        });
  }
}

class CustomTimerPainter extends CustomPainter {
  CustomTimerPainter({
    this.animation,
    this.backgroundColor,
    this.color,
  }) : super(repaint: animation);

  final Animation<double>? animation;
  final Color? backgroundColor, color;

  @override
  void paint(Canvas canvas, Size size) {
    final Paint paint = Paint()
      ..color = backgroundColor!
      ..strokeWidth = 10.0
      ..strokeCap = StrokeCap.butt
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(size.center(Offset.zero), size.width / 2.0, paint);
    paint.color = color!;
    final double progress = (1.0 - animation!.value) * 2 * math.pi;
    canvas.drawArc(Offset.zero & size, math.pi * 1.5, -progress, false, paint);
  }

  @override
  bool shouldRepaint(CustomTimerPainter old) {
    return animation!.value != old.animation!.value ||
        color != old.color ||
        backgroundColor != old.backgroundColor;
  }
}
