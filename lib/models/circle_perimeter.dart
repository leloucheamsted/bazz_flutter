import 'package:bazz_flutter/models/coordinates_model.dart';

class CirclePerimeter {
  final Coordinates center;
  final double radius;

  CirclePerimeter.fromMap(Map<String, dynamic> map)
      : center = Coordinates.fromMap(map['centerCoordinate'] as Map<String, dynamic>),
        radius = double.parse('${map['radius']}');

  Map<String, dynamic> toMap() {
    return {
      'centerCoordinate': center.toMap(),
      'radius': radius,
    };
  }
}
