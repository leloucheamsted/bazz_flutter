import 'package:bazz_flutter/modules/home_module/flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter/widgets.dart';

class FlutterPolyline extends Polyline {
  String _id = "";
  FlutterPolyline({
    String? id,
    List<LatLng>? points,
    double? strokeWidth,
    Color color = const Color(0xFF00FF00),
    double borderStrokeWidth = 0.0,
    Color borderColor = const Color(0xFFFFFF00),
    List<double>? colorsStop,
    List<Color>? gradientColors,
    bool isDotted = false,
  }) : super(
            points: points!,
            color: color,
            borderStrokeWidth: borderStrokeWidth,
            colorsStop: colorsStop!,
            borderColor: borderColor,
            isDotted: isDotted,
            gradientColors: gradientColors!,
            strokeWidth: strokeWidth!) {
    _id = id!;
  }

  String get id => _id;
}
