import 'package:bazz_flutter/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BorderedIconButton extends StatelessWidget {
  final VoidCallback? onTap;
  final String title;
  final Color borderColor;
  final Color fillColor;
  final double borderRadius, elevation, highlightElevation;
  final Icon? icon;
  final Widget? child;
  final TextStyle? titleStyle;
  final BorderSide? border;
  final bool switchDirection;
  final bool toUpperCase;
  final EdgeInsetsGeometry padding;
  final VisualDensity visualDensity;
  final double? height;
  final double? width;

  const BorderedIconButton({
    Key? key,
    this.title = '',
    this.borderColor = AppColors.brightText,
    this.fillColor = AppColors.sos,
    this.borderRadius = 7.0,
    this.elevation = 2.0,
    this.highlightElevation = 5.0,
    this.height,
    this.width,
    this.onTap,
    this.icon,
    this.child,
    this.titleStyle,
    this.border,
    this.switchDirection = false,
    this.toUpperCase = true,
    this.padding = const EdgeInsets.symmetric(horizontal: 10),
    this.visualDensity = VisualDensity.standard,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theButton = RawMaterialButton(
      visualDensity: visualDensity,
      elevation: elevation,
      padding: padding,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(borderRadius),
        side: border ?? BorderSide(color: borderColor),
      ),
      fillColor: onTap != null ? fillColor : AppTheme().colors.disabledButton,
      onPressed: onTap,
      highlightElevation: onTap != null ? highlightElevation : 0,
      child: child ??
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            textDirection:
                switchDirection ? TextDirection.rtl : TextDirection.ltr,
            children: [
              if (icon != null) ...[
                icon!,
                if (title.isNotEmpty) const SizedBox(width: 10),
              ],
              if (title.isNotEmpty)
                Text(
                  toUpperCase ? title.toUpperCase() : title.capitalize!,
                  style: titleStyle ?? AppTheme().typography.buttonTextStyle,
                ),
            ],
          ),
    );
    return height != null || width != null
        ? SizedBox(
            height: height,
            width: width,
            child: theButton,
          )
        : theButton;
  }
}
