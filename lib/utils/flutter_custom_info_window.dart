library flutter_custom_info_window;

import 'dart:math';

import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/flutter_map.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/plugin_api.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_marker.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
// import 'package:latlong/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart';

typedef GetBool = bool Function();

/// Controller to add, update and controll the custom info window.
class FlutterCustomInfoWindowController {
  /// Add custom [Widget] and [Marker]'s [LatLng] to [CustomInfoWindow] and make it visible.
  late Function(Widget, LatLng, double, double, FlutterMarker) addInfoWindow;

  late Function(LatLng) updateInfoWindow;

  /// Notifies [CustomInfoWindow] to redraw as per change in position.
  VoidCallback? onCameraMove;

  /// Hides [CustomInfoWindow].
  VoidCallback? hideInfoWindow;

  Widget? child;

  LatLng? latLng;

  late double offsetLeft;

  late double offsetTop;

  late GetBool isVisible;

  late RxPosition currentPosition;

  void dispose() {
    addInfoWindow = null as dynamic;
    onCameraMove = null;
    hideInfoWindow = null;
    updateInfoWindow = null as dynamic;
  }
}

/// A stateful widget responsible to create widget based custom info window.
class FlutterCustomInfoWindow extends StatefulWidget {
  /// A [CustomInfoWindowController] to manipulate [CustomInfoWindow] state.
  final FlutterCustomInfoWindowController controller;

  /// Offset to maintain space between [Marker] and [CustomInfoWindow].
  final double offsetLeft;

  final double offsetTop;

  /// Height of [CustomInfoWindow].
  final double height;

  /// Width of [CustomInfoWindow].
  final double width;

  const FlutterCustomInfoWindow({
    Key? key,
    required this.controller,
    this.offsetLeft = 50,
    this.offsetTop = 50,
    this.height = 50,
    this.width = 100,
  })  : assert(controller != null),
        assert(height != null),
        assert(height >= 0),
        assert(width != null),
        assert(width >= 0),
        super(key: key);

  @override
  _CustomInfoWindowState createState() => _CustomInfoWindowState();
}

class _CustomInfoWindowState extends State<FlutterCustomInfoWindow> {
  bool _showNow = false;
  bool _tempHidden = false;
  double _leftMargin = 0;
  double _topMargin = 0;
  late double _offsetLeft;
  late double _offsetTop;
  late FlutterMarker _marker;
  late Widget _child;
  late LatLng _latLng;

  bool _isVisible() => _showNow;

  @override
  void initState() {
    super.initState();
    widget.controller.addInfoWindow = _addInfoWindow;
    widget.controller.onCameraMove = _onCameraMove;
    widget.controller.hideInfoWindow = _hideInfoWindow;
    widget.controller.updateInfoWindow = _updateOpenInfoWindow;
    widget.controller.isVisible = _isVisible;
    if (widget.controller.child != null && widget.controller.latLng != null) {
      _latLng = widget.controller.latLng!;
      _child = widget.controller.child!;
      _updateInfoWindow();
    }
  }

  /// Calculate the position on [CustomInfoWindow] and redraw on screen.
  Future<void> _updateInfoWindow() async {
    if (_latLng == null || _child == null) {
      return;
    }
    final Point<double> point = _marker.getMarkerScreenCoordinate();

    final double left =
        ((point.x) + (_marker.width / 2)) - ((widget.width / 2) + _offsetLeft);
    final double top = point.y - ((widget.height) - _offsetTop);
    TelloLogger().i(
        "_updateInfoWindow left ${point.x} ${_marker.width} ${widget.width}  ${Get.width} == $left");
    TelloLogger().i("_updateInfoWindow top $top ${_marker.height}");
    setState(() {
      _showNow = true;
      _tempHidden = false;
      _leftMargin = left;
      _topMargin = top;
    });
  }

  /// Assign the [Widget] and [Marker]'s [LatLng].
  void _addInfoWindow(Widget child, LatLng latLng, double offsetLeft,
      double offsetTop, FlutterMarker marker) {
    assert(child != null);
    assert(latLng != null);
    _child = widget.controller.child = child;
    _latLng = widget.controller.latLng = latLng;
    _offsetLeft = widget.controller.offsetLeft = offsetLeft;
    _offsetTop = widget.controller.offsetTop = offsetTop;
    _marker = marker;
    _updateInfoWindow();
  }

  void _updateOpenInfoWindow(LatLng latLng) {
    assert(latLng != null);
    _latLng = latLng;
    _updateInfoWindow();
  }

  /// Notifies camera movements on [GoogleMap].
  void _onCameraMove() {
    if (!_showNow) return;
    _updateInfoWindow();
  }

  /// Disables [CustomInfoWindow] visibility.
  void _hideInfoWindow() {
    if (mounted) {
      setState(() {
        widget.controller.latLng = null as LatLng;
        widget.controller.child = null;
        _showNow = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: _leftMargin,
      top: _topMargin,
      child: Visibility(
        visible: (_showNow == false ||
                _tempHidden == true ||
                (_leftMargin == 0 && _topMargin == 0) ||
                _child == null ||
                _latLng == null)
            ? false
            : true,
        child: Container(
          child: _child,
          height: widget.height,
          width: widget.width,
        ),
      ),
    );
  }
}
