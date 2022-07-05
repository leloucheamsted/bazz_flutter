import 'dart:async';

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/flutter_map.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/plugin_api.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:flutter/material.dart';

typedef OnCreateCallback = void Function(MapState mapState);

class ZoomButtonsPluginOption extends LayerOptions {
  final double minZoom;
  final double maxZoom;
  final bool mini;
  final double padding;
  final Color? zoomInColor;
  final Color? zoomInIconColor;
  final Color? zoomOutColor;
  final Color? zoomOutIconColor;
  final IconData zoomInIcon;
  final IconData zoomOutIcon;
  final double top;
  final double right;
  final double bottom;

  ZoomButtonsPluginOption({
    Key? key,
    this.minZoom = 1,
    this.maxZoom = 21,
    this.mini = true,
    this.padding = 2.0,
    this.top = 5,
    this.right = 5,
    this.bottom = 140,
    this.zoomInColor,
    this.zoomInIconColor,
    this.zoomInIcon = Icons.zoom_in,
    this.zoomOutColor,
    this.zoomOutIconColor,
    this.zoomOutIcon = Icons.zoom_out,
    Stream<Null>? rebuild,
  }) : super(key: key!, rebuild: rebuild!);
}

class ZoomButtonsPlugin implements MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<Null> stream) {
    if (options is ZoomButtonsPluginOption) {
      return ZoomButtons(
          zoomButtonsOpts: options, mapState: mapState, stream: stream);
    }
    throw Exception('Unknown options type for ZoomButtonsPlugin: $options');
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is ZoomButtonsPluginOption;
  }
}

class ZoomButtons extends StatefulWidget {
  final ZoomButtonsPluginOption zoomButtonsOpts;
  final Stream<Null> stream;
  final MapState mapState;
  late FitBoundsOptions options;
  ZoomButtons(
      {required this.zoomButtonsOpts,
      required this.mapState,
      required this.stream})
      : super(key: zoomButtonsOpts.key) {
    options = FitBoundsOptions(maxZoom: zoomButtonsOpts.maxZoom);
  }

  @override
  // ignore: no_logic_in_create_state
  _ZoomButtonsState createState() => _ZoomButtonsState();
}

class _ZoomButtonsState extends State<ZoomButtons> {
  bool zoomInEnabled = true;
  bool zoomOutEnabled = true;

  void calculateZoomState() {
    zoomInEnabled = true;
    zoomOutEnabled = true;
    if (widget.mapState.zoom >= widget.zoomButtonsOpts.maxZoom) {
      zoomInEnabled = false;
    }

    if (widget.mapState.zoom <= widget.zoomButtonsOpts.minZoom) {
      zoomOutEnabled = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    TelloLogger().i("BUILD ZOOM PLUGIN");

    return Stack(
      children: [
        Positioned(
          top: widget.zoomButtonsOpts.top,
          bottom: widget.zoomButtonsOpts.bottom,
          right: widget.zoomButtonsOpts.right,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              FloatingActionButton(
                heroTag: 'zoomInButton',
                mini: widget.zoomButtonsOpts.mini,
                backgroundColor: widget.zoomButtonsOpts.zoomInColor ??
                    AppTheme().colors.popupBg,
                onPressed: () {
                  if (zoomInEnabled) {
                    final zoom = (widget.mapState.zoom + 1.0).floorToDouble();
                    TelloLogger().i(
                        "zoomInButton ==> $zoom ,,, ${widget.zoomButtonsOpts.maxZoom}");
                    if (zoom > widget.zoomButtonsOpts.maxZoom) {
                      return;
                    }
                    final bounds = widget.mapState.getBounds();
                    final centerZoom = widget.mapState
                        .getBoundsCenterZoom(bounds, widget.options);
                    widget.mapState.move(centerZoom.center!, zoom);
                  }
                  setState(() {
                    calculateZoomState();
                  });
                },
                child: Icon(widget.zoomButtonsOpts.zoomInIcon,
                    color: zoomInEnabled
                        ? (widget.zoomButtonsOpts.zoomInIconColor ??
                            AppTheme().colors.bgText)
                        : AppTheme().colors.disabledButton),
              ),
              FloatingActionButton(
                heroTag: 'zoomOutButton',
                mini: widget.zoomButtonsOpts.mini,
                backgroundColor: widget.zoomButtonsOpts.zoomOutColor ??
                    AppTheme().colors.popupBg,
                onPressed: () {
                  if (zoomOutEnabled) {
                    final zoom = (widget.mapState.zoom - 1.0).floorToDouble();
                    TelloLogger().i(
                        "zoomOutEnabled ==> $zoom ,,, ${widget.zoomButtonsOpts.maxZoom}");
                    if (zoom < widget.zoomButtonsOpts.minZoom) {
                      return;
                    }
                    final bounds = widget.mapState.getBounds();
                    final centerZoom = widget.mapState
                        .getBoundsCenterZoom(bounds, widget.options);
                    widget.mapState.move(centerZoom.center!, zoom);
                  }
                  setState(() {
                    calculateZoomState();
                  });
                },
                child: Icon(widget.zoomButtonsOpts.zoomOutIcon,
                    color: zoomOutEnabled
                        ? (widget.zoomButtonsOpts.zoomOutIconColor ??
                            AppTheme().colors.bgText)
                        : AppTheme().colors.disabledButton),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
