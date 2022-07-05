import 'package:bazz_flutter/app_theme.dart';
import 'package:flutter/material.dart';

class TitledDivider extends StatelessWidget {
  const TitledDivider({
    Key? key,
    required this.text,
    required this.textColor,
    required this.dividerTitleBg,
    required this.dividerColor,
    this.indent = 10.0,
    this.endIndent = 10.0,
  }) : super(key: key);

  final String text;
  final Color textColor, dividerTitleBg, dividerColor;
  final double indent, endIndent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Divider(indent: indent, endIndent: endIndent, color: dividerColor),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 5),
          color: dividerTitleBg,
          child: Text(
            text,
            style: AppTheme()
                .typography
                .groupSectionTitleStyle
                .copyWith(color: textColor),
          ),
        ),
      ],
    );
  }
}
