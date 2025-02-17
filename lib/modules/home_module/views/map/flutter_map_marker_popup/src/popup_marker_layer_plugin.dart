import 'package:flutter/widgets.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/plugin_api.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_marker_popup/src/popup_marker_layer.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_marker_popup/src/popup_marker_layer_options.dart';

class PopupMarkerPlugin extends MapPlugin {
  @override
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<void> stream) {
    return PopupMarkerLayer(
        options as PopupMarkerLayerOptions, mapState, stream as Stream<Null>);
  }

  @override
  bool supportsLayer(LayerOptions options) {
    return options is PopupMarkerLayerOptions;
  }
}
