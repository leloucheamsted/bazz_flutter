import 'dart:convert';

import 'package:bazz_flutter/models/coordinates_model.dart';
import 'package:bazz_flutter/models/perimeter.dart';
import 'package:bazz_flutter/models/user_model.dart';

import 'group_model.dart';

class Zone {
  Zone({
    required this.id,
    required this.title,
    required this.supervisor,
    required this.perimeter,
    required this.region,
    required this.groups,
  });

  final String id;
  late String? regionId;
  final String title;
  final RxUser supervisor;
  final Perimeter perimeter;
  final Region region;
  final List<RxGroup> groups;

  factory Zone.fromJson(String str) =>
      Zone.fromMap(json.decode(str) as Map<String, dynamic>);

  String toJson() => json.encode(toMap());

  factory Zone.fromMap(Map<String, dynamic> map, {bool listFromJson = false}) =>
      Zone(
        id: map["id"] as String,
        title: map["title"] as String,
        supervisor: map["supervisor"] != null
            ? RxUser.fromMap(map["supervisor"])
            : null!,
        perimeter: map["perimeter"] != null
            ? Perimeter.fromMap(map["perimeter"], listFromJson: listFromJson)
            : null!,
        region: map["region"] != null
            ? Region.fromMap(map["region"] as Map<String, dynamic>,
                listFromJson: listFromJson)
            : null!,
        groups: map["groups"] != null
            ? List<RxGroup>.from((map["groups"] as List<dynamic>)
                .map((x) => RxGroup.fromMap(x as Map<String, dynamic>)))
            : null!,
      );

  Map<String, dynamic> toMap({bool listToJson = false}) => {
        "id": id,
        "title": title,
        "supervisor": supervisor.toMap(),
        "perimeter": perimeter.toMap(listToJson: listToJson),
        "region": region.toMap(listToJson: listToJson),
      };

  @override
  // ignore: type_annotate_public_apis
  bool operator ==(other) {
    return (other is Zone) && other.id == id;
  }

  @override
  // TODO: implement hashCode
  int get hashCode => id.hashCode;
}

class Region {
  Region({
    this.id,
    this.title,
    this.supervisor,
    this.perimeter,
    this.coordinates,
  });

  final String? id;
  final String? title;
  final RxUser? supervisor;
  final Perimeter? perimeter;
  final List<Coordinates>? coordinates;

  factory Region.fromMap(Map<String, dynamic> map,
      {bool listFromJson = false}) {
    final coordinates = (listFromJson
            ? json.decode(map["coordinates"] as String) as List<dynamic>
            : map["coordinates"] as List<dynamic>)
        .map((c) => Coordinates.fromMap(c as Map<String, dynamic>))
        .toList();
    return Region(
      id: map["id"] as String,
      title: map["title"] as String,
      supervisor: map["supervisor"] != null
          ? RxUser.fromMap(map["supervisor"] as Map<String, dynamic>)
          : null,
      coordinates: coordinates,
    );
  }

  Map<String, dynamic> toMap({bool listToJson = false}) {
    final coords = coordinates!.map((c) => c.toMap()).toList();
    return {
      "id": id,
      "title": title,
      "supervisor": supervisor!.toMap(),
      "coordinates": listToJson ? json.encode(coords) : coords,
    };
  }

  @override
  // ignore: type_annotate_public_apis
  bool operator ==(other) {
    return (other is Region) && other.id == id;
  }

  @override
  // TODO: implement hashCode
  int get hashCode => id.hashCode;
}
