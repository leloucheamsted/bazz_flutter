import 'package:bazz_flutter/models/time_rule_model.dart';

class DayRule {
  int dayId;
  TimeRule timeRule;

  DayRule.fromMap(Map<String, dynamic> map)
      : dayId = map["dayId"] as int,
        timeRule = map["timeRule"] != null
            ? TimeRule.fromMap(map["timeRule"] as Map<String, dynamic>)
            : null!;

  Map<String, dynamic> toMap() => {
        "dayId": dayId,
        "timeRule": timeRule.toMap(),
      };
}
