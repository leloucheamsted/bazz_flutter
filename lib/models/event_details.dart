
class EventDetails{
  bool isPostponable;
  bool isSystem;

  EventDetails.fromMap(Map<String, dynamic> map)
  : isPostponable = map['postponable'] as bool,
    isSystem = map['isSystem'] as bool;

  Map<String, dynamic> toMap() {
    return {
      'postponable': isPostponable,
      'isSystem': isSystem,
    };
  }
}