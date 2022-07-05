import 'package:bazz_flutter/models/icon_config.dart';
import 'package:bazz_flutter/models/rating_color_config.dart';

class ShiftEndMessage {
  final String message;
  final IconConfig icon;
  final RatingRange ratingRange;

  ShiftEndMessage.fromMap(Map<String, dynamic> map)
      : message = map['message'] as String,
        icon = IconConfig.fromMap(map['icon'] as Map<String, dynamic>),
        ratingRange = RatingRange.fromMap(map['ratingRange'] as Map<String, dynamic>);

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'icon': icon.toMap(),
      'ratingRange': ratingRange.toMap(),
    };
  }
}
