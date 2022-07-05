import 'dart:convert';

import 'package:bazz_flutter/constants.dart';

class PositionType {
  PositionType(
      {required this.id,
      required this.title,
      required this.mobilityType,
      required this.locationType});

  final String id;
  final String title;
  final MobilityType mobilityType;
  final LocationType locationType;

  factory PositionType.fromJson(String str) =>
      PositionType.fromMap(json.decode(str) as Map<String, dynamic>);

  String toJson() => json.encode(toMap());

  factory PositionType.fromMap(Map<String, dynamic> json) => PositionType(
        id: json["id"] as String,
        title: json["title"] as String,
        mobilityType: json["mobilityType"] != null
            ? MobilityType.values[json["mobilityType"] as int]
            : MobilityType.values[0],
        locationType: json["locationType"] != null
            ? LocationType.values[json["locationType"] as int]
            : LocationType.values[0],
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "title": title,
        "mobilityType": mobilityType.index,
        "locationType": locationType.index,
      };

  PositionType copyWith({
    required String id,
    required String title,
    required MobilityType mobilityType,
    required LocationType locationType,
  }) {
    return PositionType(
      id: id,
      title: title,
      mobilityType: mobilityType,
      locationType: locationType,
    );
  }
}
