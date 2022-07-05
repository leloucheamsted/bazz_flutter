import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/circle_perimeter.dart';
import 'package:bazz_flutter/models/perimeter_style.dart';
import 'package:bazz_flutter/models/polygon_perimeter.dart';

class Perimeter {
  final CirclePerimeter circlePerimeter;
  final PolygonPerimeter polygonPerimeter;
  final PerimeterType type;
  final PerimeterStyle style;
  final int tolerance;

  Perimeter.fromMap(Map<String, dynamic> map, {bool listFromJson = false})
      : circlePerimeter = map['circlePerimeter'] != null
            ? CirclePerimeter.fromMap(
                map['circlePerimeter'] as Map<String, dynamic>)
            : null!,
        polygonPerimeter = map['polygonPerimeter'] != null
            ? PolygonPerimeter.fromMap(
                map['polygonPerimeter'] as Map<String, dynamic>,
                listFromJson: listFromJson)
            : null!,
        style = PerimeterStyle.fromMap(map['style'] as Map<String, dynamic>),
        type = PerimeterType.values[map['type'] as int],
        tolerance = map['tolerance'] as int;

  Map<String, dynamic> toMap({bool listToJson = false}) {
    return {
      'circlePerimeter': circlePerimeter.toMap(),
      'polygonPerimeter': polygonPerimeter.toMap(listToJson: listToJson),
      'style': style.toMap(),
      'type': type.index,
      'tolerance': tolerance,
    };
  }
}
