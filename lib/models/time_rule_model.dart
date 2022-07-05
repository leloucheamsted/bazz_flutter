class TimeRule {
  final String? fromTime;
  final String? toTime;

  TimeRule({this.fromTime, this.toTime});

  //TODO: remove replaceAll when we have correct time format from the backend
  TimeRule.fromMap(Map<String, dynamic> map)
      : fromTime = (map["fromTime"] as String).replaceAll(RegExp(r'\.'), ':'),
        toTime = (map["toTime"] as String).replaceAll(RegExp(r'\.'), ':');

  Map<String, dynamic> toMap() => {
        "fromTime": fromTime,
        "toTime": toTime,
      };

  TimeRule copyWith({
    String? fromTime,
    String? toTime,
  }) {
    return TimeRule(
      fromTime: fromTime ?? this.fromTime,
      toTime: toTime ?? this.toTime,
    );
  }
}
