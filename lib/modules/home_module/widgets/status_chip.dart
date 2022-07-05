import 'package:bazz_flutter/app_theme.dart';
import 'package:flutter/cupertino.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({
    Key? key,
    required this.color,
    required this.text,
    this.showIndicator = true,
    this.padding = const EdgeInsets.all(8),
  }) : super(key: key);

  final Color color;
  final String text;
  final bool showIndicator;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(25),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showIndicator)
            Container(
              height: 18,
              width: 18,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
              ),
            ),
          if (showIndicator) const SizedBox(width: 8),
          Text(
            text,
            style: AppTypography.bodyText4TextStyle.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
