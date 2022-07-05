import 'package:bazz_flutter/app_theme.dart';
import 'package:flutter/material.dart';

class BadgeCounter extends StatelessWidget {
  const BadgeCounter(this.counter, {Key? key}) : super(key: key);

  final String counter;

  @override
  Widget build(BuildContext context) {
    if (counter == null || counter == '0') return const SizedBox();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        counter,
        style: AppTypography.bodyText4TextStyle.copyWith(color: Colors.white),
      ),
    );
  }
}
