import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/zone.dart';

import 'group_model.dart';

class SuggestedGroups {
  SuggestedGroups({
    this.groups,
    this.suggestedPositions,
  });

  final List<RxGroup>? groups;
  final List<SuggestedPosition>? suggestedPositions;

  factory SuggestedGroups.fromMap(Map<String, dynamic> map) => SuggestedGroups(
        groups: map['groups'] != null
            ? List<RxGroup>.from((map['groups'] as List<dynamic>)
                .map((x) => RxGroup.fromMap(x as Map<String, dynamic>)))
            : null!,
        suggestedPositions: map['suggestions'] != null
            ? List<SuggestedPosition>.from((map['suggestions'] as List<dynamic>)
                .map((x) =>
                    SuggestedPosition.fromMap(x as Map<String, dynamic>)))
            : null!,
      );
}

class SuggestedPosition {
  SuggestedPosition({
    this.id,
    this.distance,
    this.type,
  });

  final String? id;
  final int? distance;
  final SuggestionType? type;

  factory SuggestedPosition.fromMap(Map<String, dynamic> map) =>
      SuggestedPosition(
        id: map["id"] as String,
        distance: map["distance"] as int,
        type: SuggestionType.values[map["type"] as int],
      );
}
