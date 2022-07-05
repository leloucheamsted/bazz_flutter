import 'package:bazz_flutter/modules/shift_activities/models/reporting_point.dart';
import 'package:flutter/cupertino.dart';

class TourPoint {
  final ReportingPoint reportingPoint;

  const TourPoint({
    required this.reportingPoint,
  });

  factory TourPoint.fromMap(Map<String, dynamic> map, String tourId,
      {bool listFromJson = false}) {
    return TourPoint(
      reportingPoint: ReportingPoint.fromMap(
        map['reportingPoint'] as Map<String, dynamic>,
        tourId: tourId,
        listFromJson: listFromJson,
      ),
    );
  }

  Map<String, dynamic> toMap({bool listToJson = false}) {
    return {
      'reportingPoint': reportingPoint.toMap(listToJson: listToJson),
    };
  }

  TourPoint copyWith({
    ReportingPoint? reportingPoint,
  }) {
    return TourPoint(
      reportingPoint: reportingPoint ?? this.reportingPoint.copyWith(),
    );
  }
}
