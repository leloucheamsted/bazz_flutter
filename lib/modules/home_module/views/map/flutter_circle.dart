import 'package:bazz_flutter/modules/home_module/flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter/widgets.dart';

class FlutterCircle extends CircleMarker {
  String _id = "";
  FlutterCircle({
    String? id,
    LatLng? point,
    double? radius,
    bool useRadiusInMeter = false,
    Color color = const Color(0xFF00FF00),
    double borderStrokeWidth = 0.0,
    Color borderColor = const Color(0xFFFFFF00),
  }) : super(
            point: point!,
            radius: radius!,
            useRadiusInMeter: useRadiusInMeter,
            color: color,
            borderStrokeWidth: borderStrokeWidth,
            borderColor: borderColor) {
    _id = id!;
  }
  String get id => _id;
}
