import 'package:bazz_flutter/models/app_settings.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DateLabel extends StatelessWidget {
  const DateLabel({
    required this.date,
    this.dateFormat,
  });

  final DateTime date;
  final DateFormat? dateFormat;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(10.0),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      child: Text(
        date != null
            ? (dateFormat != null
                ? dateFormat!.format(date.toLocal())
                : DateFormat(AppSettings().dateFormat).format(date.toLocal()))
            : "",
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12.0,
        ),
      ),
    );
  }
}
