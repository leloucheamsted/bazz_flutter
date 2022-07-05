import 'package:flutter/material.dart';

class CircularIconButton extends StatelessWidget {
  const CircularIconButton({
    this.color = Colors.transparent,
    required this.child,
    required this.buttonSize,
    required this.onTap,
    this.elevation = 0,
  });

  final Color color;
  final Widget child;
  final double buttonSize, elevation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color,
      elevation: elevation, // button color
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap, // inkwell color
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: buttonSize,
          height: buttonSize,
          child: Center(child: child),
        ),
      ),
    );
  }
}
