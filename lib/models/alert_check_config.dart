import 'dart:convert';

import 'package:bazz_flutter/models/day_rule_model.dart';
import 'package:bazz_flutter/modules/shift_activities/models/reporting_point.dart';
import 'package:flutter/foundation.dart';

enum AlertCheckType {
  standard,
  reportingPoints,
}

class AlertCheckConfig {
  AlertCheckConfig({
    required this.alertCheckType,
    required this.reportingPoints,
    required this.dayRules,
    required this.alertCheckInterval,
    required this.alertCheckTimeout,
    required this.snoozeTimeout,
    required this.snoozeInterval,
    required this.snoozeCountPerQuiz,
    required this.useFaceDetection,
  });

  final bool useFaceDetection;
  final int alertCheckInterval;
  final int alertCheckTimeout;
  final int snoozeTimeout;
  final int snoozeInterval;
  final int snoozeCountPerQuiz;
  final AlertCheckType alertCheckType;
  final List<ReportingPoint> reportingPoints;
  final List<DayRule> dayRules;

  factory AlertCheckConfig.fromMap(Map<String, dynamic> map,
      {bool listFromJson = false}) {
    final reportingPoints = map["reportingPoints"] != null
        ? (listFromJson
                ? json.decode(map['reportingPoints'] as String) as List<dynamic>
                : map['reportingPoints'] as List<dynamic>)
            .map((act) => ReportingPoint.fromMap(act as Map<String, dynamic>,
                listFromJson: listFromJson))
            .toList()
        : null;
    final dayRules = (listFromJson
            ? json.decode(map['dayRules'] as String) as List<dynamic>
            : map['dayRules'] as List<dynamic>)
        .map((dr) => DayRule.fromMap(dr as Map<String, dynamic>))
        .toList();
    return AlertCheckConfig(
      //TODO: for testing purposes, remove later
      // alertCheckType: AlertCheckType.reportingPoints,
      // alertCheckInterval: 60,
      // alertCheckTimeout: 30,
      // snoozeTimeout: 30,
      // snoozeInterval: 30,
      // snoozeCountPerQuiz: 1,
      // reportingPoints: null,
      // dayRules: List.generate(7, (i) => DayRule.fromMap({
      //   'dayId': i,
      //   'timeRule': {
      //     'fromTime': '00:00',
      //     'toTime': '25:59',
      //   }
      // })),

      alertCheckType: map["type"] != null
          ? AlertCheckType.values[map["type"] as int]
          : AlertCheckType.values[0],
      alertCheckInterval: map["quizInterval"] as int,
      alertCheckTimeout: map["quizTimeout"] as int,
      useFaceDetection: (map["useFaceDetection"] ?? false) as bool,
      snoozeTimeout: map["snoozeConfig"]["duration"] as int,
      snoozeInterval: map["snoozeConfig"]["interval"] as int,
      snoozeCountPerQuiz: map["snoozeConfig"]["countPerQuiz"] as int,
      reportingPoints: reportingPoints!,
      dayRules: dayRules,
    );
  }

  Map<String, dynamic> toMap() => {
        "quizInterval": alertCheckInterval,
        "quizTimeout": alertCheckTimeout,
        "useFaceDetection": useFaceDetection,
        "snoozeConfig": {
          "duration": snoozeTimeout,
          "interval": snoozeInterval,
          "countPerQuiz": snoozeCountPerQuiz,
        },
        "type": alertCheckType.index,
        "reportingPoints": reportingPoints != null
            ? json.encode(reportingPoints
                .map((rp) => rp.toMap(listToJson: true))
                .toList())
            : null,
        "dayRules": json.encode(dayRules.map((dr) => dr.toMap()).toList()),
      };
}
