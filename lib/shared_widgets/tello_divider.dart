import 'package:bazz_flutter/app_theme.dart';
import 'package:flutter/material.dart';

class TelloDivider extends StatelessWidget {
  const TelloDivider({
    Key? key,
    this.color,
    this.height = 3,
  }) : super(key: key);

  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      color: color ?? AppTheme().colors.listSeparator,
    );
  }
}
