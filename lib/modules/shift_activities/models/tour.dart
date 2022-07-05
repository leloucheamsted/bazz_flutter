import 'dart:convert';

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/time_rule_model.dart';
import 'package:bazz_flutter/modules/shift_activities/models/tour_point.dart';
import 'package:flutter/cupertino.dart';

class Tour {
  final String tourId;
  final List<TourPoint> path;
  int? startedAt;
  int? endedAt;
  final TimeRule? timeRule;

  bool get isNotStarted => path.every((tp) => tp.reportingPoint.isNotStarted);

  bool get isInProgress =>
      path.any((tp) => tp.reportingPoint.isFinished) && !isFinished;

  bool get isFinished => path.every((tp) => tp.reportingPoint.isFinished);

  bool get hasOngoingVisit =>
      path.any((tp) => tp.reportingPoint.hasCurrentVisit);

  bool get hasNoOngoingVisits => !hasOngoingVisit;

  Color get statusColor => isFinished
      ? AppColors.rPointFinished
      : isNotStarted
          ? AppColors.rPointNotStarted
          : AppColors.rPointInProgress;

  Tour({
    this.timeRule,
    required this.tourId,
    required this.path,
    this.startedAt,
    this.endedAt,
  });

  factory Tour.fromMap(Map<String, dynamic> map, {bool listFromJson = false}) {
    final path = (listFromJson
            ? json.decode(map['path'] as String) as List<dynamic>
            : map['path'] as List<dynamic>)
        .map((act) => TourPoint.fromMap(
              act as Map<String, dynamic>,
              map['tourId'] as String,
              listFromJson: listFromJson,
            ))
        .toList();
    return Tour(
      tourId: map['tourId'] as String,
      path: path,
      timeRule: map['timeRule'] != null
          ? TimeRule.fromMap(map['timeRule'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toMap({bool listToJson = false}) {
    final pathList =
        path.map((tp) => tp.toMap(listToJson: listToJson)).toList();
    return {
      'tourId': tourId,
      'path': listToJson ? json.encode(pathList) : pathList,
      'timeRule': timeRule!.toMap(),
    };
  }

  Tour copyWith({
    String? tourId,
    int? startedAt,
    int? endedAt,
    List<TourPoint>? path,
    TimeRule? timeRule,
  }) {
    return Tour(
      tourId: tourId ?? this.tourId,
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      path: path ?? this.path.map((e) => e.copyWith()).toList(),
      timeRule: timeRule ?? this.timeRule!.copyWith(),
    );
  }
}
