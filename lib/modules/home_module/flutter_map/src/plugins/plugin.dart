import 'package:flutter/widgets.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/src/layer/layer.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/src/map/map.dart';

abstract class MapPlugin {
  bool supportsLayer(LayerOptions options);
  Widget createLayer(
      LayerOptions options, MapState mapState, Stream<Null> stream);
}
