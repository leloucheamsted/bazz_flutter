import 'dart:convert';

import 'package:bazz_flutter/models/coordinates_model.dart';

class PolygonPerimeter {
  final List<Coordinates> perimeter, perimeterWithTolerance;

  PolygonPerimeter.fromMap(Map<String, dynamic> map, {bool listFromJson = false})
      : perimeter = (listFromJson
                ? json.decode(map["coordinates"] as String) as List<dynamic>
                : map["coordinates"] as List<dynamic>)
            .map((x) => Coordinates.fromMap(x as Map<String, dynamic>))
            .toList(),
        perimeterWithTolerance = (listFromJson
                ? json.decode(map["borderCoordinates"] as String) as List<dynamic>
                : map["borderCoordinates"] as List<dynamic>)
            .map((x) => Coordinates.fromMap(x as Map<String, dynamic>))
            .toList();

  Map<String, dynamic> toMap({bool listToJson = false}) {
    final p = perimeter.map((e) => e.toMap()).toList();
    final pwt = perimeterWithTolerance.map((e) => e.toMap()).toList();
    return {
      'coordinates': listToJson ? json.encode(p) : p,
      'borderCoordinates': listToJson ? json.encode(pwt) : pwt,
    };
  }
}
