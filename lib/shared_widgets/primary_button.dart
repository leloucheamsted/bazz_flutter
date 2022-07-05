import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    Key? key,
    required this.onTap,
    this.text = '',
    required this.icon,
    this.child,
    this.iconPadding = 8,
    this.color,
    this.height = 50,
    this.horizontalPadding = 5.0,
    this.toUpperCase = true,
  }) : super(key: key);

  final double iconPadding;
  final String text;
  final VoidCallback onTap;
  final Color? color;
  final Widget icon;
  final Widget? child;
  final double height;
  final double horizontalPadding;
  final bool toUpperCase;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: RawMaterialButton(
        onPressed: onTap,
        fillColor: onTap != null
            ? color ?? AppTheme().colors.primaryButton
            : AppTheme().colors.disabledButton,
        highlightElevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(7.0),
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: child ??
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) icon,
                  if (icon != null && text.isNotEmpty)
                    SizedBox(width: iconPadding),
                  TextOneLine(
                    toUpperCase
                        ? text.toUpperCase()
                        : text.capitalize as String,
                    style: AppTheme().typography.buttonTextStyle,
                  ),
                ],
              ),
        ),
      ),
    );
  }
}
