import 'dart:convert';

import 'package:bazz_flutter/modules/shift_activities/models/shift_activity_result.dart';
import 'package:flutter/cupertino.dart';

class ShiftActivityTask {
  final String id;
  final String name;
  final String description;
  final bool isCheckable, isCommentRequired, isMediaRequired;
  ShiftActivityResult result;

  bool get isFinished => result != null;

  bool get isNotFinished => !isFinished;

  ShiftActivityTask({
    required this.id,
    required this.name,
    required this.description,
    required this.isCheckable,
    required this.isCommentRequired,
    required this.isMediaRequired,
    required this.result,
  });

  factory ShiftActivityTask.fromMap(Map<String, dynamic> map) {
    return ShiftActivityTask(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String,
      isCheckable: map['isCheckable'] as bool,
      isCommentRequired: map['isCommentRequired'] as bool,
      isMediaRequired: map['isAttachedFileRequired'] as bool,
      result: map['result'] != null
          ? ShiftActivityResult.fromMap(map['result'] as Map<String, dynamic>,
              listFromJson: true)
          : null!,
    );
  }

  Map<String, dynamic> toMap({bool listToJson = false}) {
    return {
      'id': id,
      'name': name,
      'description': description,
      'isCheckable': isCheckable,
      'isCommentRequired': isCommentRequired,
      'isAttachedFileRequired': isMediaRequired,
      'result': result.toMap(),
    };
  }

  void resetResult() => result = null!;

  String toJson() => json.encode(toMap());

  factory ShiftActivityTask.fromJson(String str) =>
      ShiftActivityTask.fromMap(json.decode(str) as Map<String, dynamic>);

  ShiftActivityTask copyWith({
    String? id,
    String? name,
    String? description,
    bool? isCheckable,
    bool? isCommentRequired,
    bool? isMediaRequired,
    ShiftActivityResult? result,
  }) {
    return ShiftActivityTask(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      isCheckable: isCheckable ?? this.isCheckable,
      isCommentRequired: isCommentRequired ?? this.isCommentRequired,
      isMediaRequired: isMediaRequired ?? this.isMediaRequired,
      result: result ?? this.result.copyWith(),
    );
  }
}
