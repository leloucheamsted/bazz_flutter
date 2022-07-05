import 'package:bazz_flutter/modules/home_module/flutter_map/flutter_map.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter/widgets.dart';

class FlutterPolygon extends Polygon {
  String _id = "";
  FlutterPolygon({
    String? id,
    List<LatLng>? points,
    List<List<LatLng>>? holePointsList,
    Color color = const Color(0xFF00FF00),
    double borderStrokeWidth = 0.0,
    Color borderColor = const Color(0xFFFFFF00),
    bool disableHolesBorder = false,
    bool isDotted = false,
  }) : super(
            points: points!,
            holePointsList: holePointsList!,
            color: color,
            borderStrokeWidth: borderStrokeWidth,
            borderColor: borderColor,
            disableHolesBorder: disableHolesBorder,
            isDotted: isDotted) {
    _id = id!;
  }

  String get id => _id;
}
