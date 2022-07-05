import 'dart:convert';

import 'package:bazz_flutter/modules/shift_module/models/alert_check_rpoint.dart';
import 'package:meta/meta.dart';

class AlertCheckResult {
  AlertCheckResult({
    required this.timeSpent,
    required this.userScore,
    required this.maxScore,
    required this.createdAt,
    required this.snoozes,
    required this.faceRecImage64,
    this.alertCheckRPoints,
  });

  final int timeSpent;
  final int userScore;
  final int maxScore;
  final int createdAt;
  final String faceRecImage64;
  final List<int> snoozes;
  List<AlertCheckRPoint>? alertCheckRPoints;

  factory AlertCheckResult.fromMap(Map<String, dynamic> map) =>
      AlertCheckResult(
        timeSpent: map["timeSpent"] as int,
        userScore: map["userScore"] as int,
        maxScore: map["maxScore"] as int,
        createdAt: map["createdAt"] as int,
        faceRecImage64:
            map["faceRecImage64"] != null ? map["faceRecImage64"] : null,
        snoozes: List<int>.from(
            json.decode(map["snoozes"] as String) as List<dynamic>),
        alertCheckRPoints: map["alertCheckRPoints"] != null
            ? (json.decode(map["alertCheckRPoints"] as String) as List<dynamic>)
                .map((m) => AlertCheckRPoint.fromMap(m as Map<String, dynamic>))
                .toList()
            : null,
      );

  Map<String, dynamic> toMap() => {
        "timeSpent": timeSpent,
        "userScore": userScore,
        "maxScore": maxScore,
        "createdAt": createdAt,
        "faceRecImage64": faceRecImage64,
        "snoozes": json.encode(snoozes),
        "alertCheckRPoints": alertCheckRPoints != null
            ? json.encode(alertCheckRPoints?.map((e) => e.toMap()).toList())
            : null,
      };

  Map<String, dynamic> toMapForServer() => {
        "timeSpent": timeSpent,
        "userScore": userScore,
        "maxScore": maxScore,
        "createdAt": createdAt,
        "faceRecImage64": faceRecImage64,
        "snoozes": snoozes,
        "quizReportingPointStates":
            alertCheckRPoints?.map((e) => e.toMapForServer()).toList(),
      };
}
