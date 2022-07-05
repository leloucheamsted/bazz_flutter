import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/modules/shift_activities/models/reporting_point_visit.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class RPointInfoWindowVisitsList extends StatelessWidget {
  const RPointInfoWindowVisitsList({Key? key, required this.visits})
      : super(key: key);

  final List<ReportingPointVisit> visits;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 5),
      child: ListView.separated(
        shrinkWrap: true,
        itemCount: visits.length,
        itemBuilder: (context, index) {
          final timeCreateVisit =
              dateTimeFromSeconds(visits[index].startedAt!, isUtc: true)!
                  .toLocal();
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat(AppSettings().dateFormat).format(timeCreateVisit),
                style: AppTheme().typography.memberNameStyle,
              ),
              const SizedBox(width: 10),
              Text(
                DateFormat(AppSettings().timeFormat).format(timeCreateVisit),
                style: AppTheme().typography.memberNameStyle,
              ),
              const Spacer(),
              if (visits[index].isQrCheckPassed != null)
                Icon(
                  Icons.qr_code,
                  color: visits[index].isQrCheckPassed!
                      ? Colors.green
                      : Colors.red,
                  size: 16,
                ),
              if (visits[index].isLocationCheckPassed != null)
                Icon(
                  Icons.add_location,
                  color: visits[index].isLocationCheckPassed!
                      ? Colors.green
                      : Colors.red,
                  size: 16,
                ),
            ],
          );
        },
        separatorBuilder: (_, __) => const SizedBox(height: 5),
      ),
    );
  }
}
