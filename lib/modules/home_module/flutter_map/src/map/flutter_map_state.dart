import 'dart:async';

import 'package:async/async.dart';
import 'package:flutter/widgets.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/flutter_map.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/src/gestures/gestures.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/src/layer/group_layer.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/src/layer/overlay_image_layer.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/src/map/map.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/src/map/map_state_widget.dart';
import 'package:positioned_tap_detector/positioned_tap_detector.dart';

class FlutterMapState extends MapGestureMixin {
  final MapControllerImpl mapController;
  final List<StreamGroup<Null>> groups = <StreamGroup<Null>>[];
  final _positionedTapController = PositionedTapController();

  @override
  MapOptions get options => widget.options;

  @override
  late MapState mapState;

  FlutterMapState(MapController mapController)
      : mapController = mapController as MapControllerImpl;

  @override
  void didUpdateWidget(FlutterMap oldWidget) {
    super.didUpdateWidget(oldWidget);

    mapState.options = options;
  }

  @override
  void initState() {
    super.initState();
    mapState = MapState(options, (degree) {
      if (mounted) setState(() => {});
    }, mapController.mapEventSink);
    mapController.state = mapState;
    mapController.mapState = this;
  }

  void _disposeStreamGroups() {
    for (var group in groups) {
      group.close();
    }

    groups.clear();
  }

  @override
  void dispose() {
    _disposeStreamGroups();
    mapState.dispose();
    mapController.dispose();

    super.dispose();
  }

  Stream<Null> _merge(LayerOptions options) {
    if (options.rebuild == null) return mapState.onMoved;

    var group = StreamGroup<Null>();
    group.add(mapState.onMoved);
    group.add(options.rebuild!);
    groups.add(group);
    return group.stream;
  }

  @override
  Widget build(BuildContext context) {
    _disposeStreamGroups();
    return LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
      mapState.setOriginalSize(constraints.maxWidth, constraints.maxHeight);
      var size = mapState.size;

      return MapStateInheritedWidget(
        mapState: mapState,
        child: Listener(
          onPointerDown: savePointer,
          onPointerCancel: removePointer,
          onPointerUp: removePointer,
          child: PositionedTapDetector(
            controller: _positionedTapController,
            onTap: handleTap,
            onLongPress: handleLongPress,
            onDoubleTap: handleDoubleTap,
            child: GestureDetector(
              onScaleStart: handleScaleStart,
              onScaleUpdate: handleScaleUpdate,
              onScaleEnd: handleScaleEnd,
              onTap: _positionedTapController.onTap,
              onLongPress: _positionedTapController.onLongPress,
              onTapDown: _positionedTapController.onTapDown,
              onTapUp: handleOnTapUp,
              child: ClipRect(
                child: Stack(
                  children: [
                    OverflowBox(
                      minWidth: size.x as double,
                      maxWidth: size.x as double,
                      minHeight: size.y as double,
                      maxHeight: size.y as double,
                      child: Transform.rotate(
                        angle: mapState.rotationRad,
                        child: Stack(
                          children: [
                            if (widget.children != null &&
                                widget.children.isNotEmpty)
                              ...widget.children,
                            if (widget.layers != null &&
                                widget.layers.isNotEmpty)
                              ...widget.layers.map(
                                (layer) =>
                                    _createLayer(layer, options.plugins!),
                              )
                          ],
                        ),
                      ),
                    ),
                    Stack(
                      children: [
                        if (widget.nonRotatedChildren != null &&
                            widget.nonRotatedChildren.isNotEmpty)
                          ...widget.nonRotatedChildren,
                        if (widget.nonRotatedLayers != null &&
                            widget.nonRotatedLayers.isNotEmpty)
                          ...widget.nonRotatedLayers.map(
                            (layer) => _createLayer(layer, options.plugins!),
                          )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    });
  }

  List<Widget> layers = <Widget>[];

  Widget _createLayer(LayerOptions options, List<MapPlugin> plugins) {
    for (var plugin in plugins) {
      if (plugin.supportsLayer(options)) {
        final layer = plugin.createLayer(options, mapState, _merge(options));
        layers.add(layer);
        return layer;
      }
    }
    if (options is TileLayerOptions) {
      final layer = TileLayer(
          options: options, mapState: mapState, stream: _merge(options));
      layers.add(layer);
      return layer;
    }
    if (options is MarkerLayerOptions) {
      final layer = MarkerLayer(options, mapState, _merge(options));
      layers.add(layer);
      return layer;
    }
    if (options is PolylineLayerOptions) {
      final layer = PolylineLayer(options, mapState, _merge(options));
      layers.add(layer);
      return layer;
    }
    if (options is PolygonLayerOptions) {
      final layer = PolygonLayer(options, mapState, _merge(options));
      layers.add(layer);
      return layer;
    }
    if (options is CircleLayerOptions) {
      final layer = CircleLayer(options, mapState, _merge(options));
      layers.add(layer);
      return layer;
    }
    if (options is GroupLayerOptions) {
      final layer = GroupLayer(options, mapState, _merge(options));
      layers.add(layer);
      return layer;
    }
    if (options is OverlayImageLayerOptions) {
      final layer = OverlayImageLayer(options, mapState, _merge(options));
      layers.add(layer);
      return layer;
    }
    assert(false, """
Can't find correct layer for $options. Perhaps when you create your FlutterMap you need something like this:

    options: new MapOptions(plugins: [MyFlutterMapPlugin()])""");
    return null!;
  }
}
