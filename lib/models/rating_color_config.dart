import 'package:meta/meta.dart';

class RatingColorConfig {
  RatingColorConfig({
    required this.color,
    required this.ratingRange,
  });

  final String color;
  final RatingRange ratingRange;

  factory RatingColorConfig.fromMap(Map<String, dynamic> map) =>
      RatingColorConfig(
        color: map["color"] as String,
        ratingRange:
            RatingRange.fromMap(map["ratingRange"] as Map<String, dynamic>),
      );

  Map<String, dynamic> toMap() => {
        "color": color,
        "ratingRange": ratingRange.toMap(),
      };
}

class RatingRange {
  RatingRange({
    required this.to,
    required this.from,
  });

  final int to;
  final int from;

  bool contains(int val) => val >= from && val <= to;

  factory RatingRange.fromMap(Map<String, dynamic> map) => RatingRange(
        to: map["to"] as int,
        from: map["from"] as int,
      );

  Map<String, dynamic> toMap() => {
        "to": to,
        "from": from,
      };
}
