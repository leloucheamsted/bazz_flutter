import 'package:bazz_flutter/modules/home_module/flutter_map/flutter_map.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/plugin_api.dart';
import 'package:flutter/material.dart';
import 'package:latlong/latlong.dart';
import 'package:flutter/widgets.dart';
import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/user_model.dart';

import 'dart:math' as math;

class FlutterMarker extends Marker {
  String _id = "";
  late MapController _controller;
  double topOffset = 0.0;
  late RxPosition _position;
  late RxUser _user;
  RxPosition get position => _position;
  RxUser get user => _user;
  bool get isEventMarker => _isEventMarker;
  bool _isEventMarker = false;
  late Color _color;
  FlutterMarker(
      {MapController? controller,
      String? id,
      LatLng? point,
      WidgetBuilder? builder,
      double width = 30.0,
      double height = 30.0,
      AnchorPos? anchorPos,
      RxPosition? position,
      RxUser? user,
      bool isEventMarker = false,
      Color color = Colors.transparent})
      : super(
            point: point!,
            builder: builder!,
            width: width,
            height: height,
            anchorPos: anchorPos!) {
    _id = id!;
    _controller = controller!;
    _user = user!;
    _position = position!;
    _isEventMarker = isEventMarker;
    _color = color;
  }

  String get id => _id;

  Color get color => _color;

  math.Point<double> getMarkerScreenCoordinate() {
    var pos = _controller.project(point);
    final pixelPosX = (pos.x - (width - anchor.left)).toDouble();
    final pixelPosY = (pos.y - (height - anchor.top)).toDouble();
    return math.Point<double>(pixelPosX, pixelPosY);
  }
}
