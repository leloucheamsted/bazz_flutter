import 'package:flutter/material.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/plugin_api.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_marker_cluster/src/marker_cluster_layer.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_marker_cluster/src/marker_cluster_layer_options.dart';

class MarkerClusterPlugin extends MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<void> stream) {
    return MarkerClusterLayer(
        options as MarkerClusterLayerOptions, mapState, stream);
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is MarkerClusterLayerOptions;
  }
}
