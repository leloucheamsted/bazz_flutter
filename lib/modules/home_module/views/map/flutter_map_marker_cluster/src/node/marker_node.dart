import 'package:bazz_flutter/modules/home_module/flutter_map/flutter_map.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_marker_cluster/src/node/marker_cluster_node.dart';
import 'package:latlong/latlong.dart';

class MarkerNode implements Marker {
  final Marker marker;
  late MarkerClusterNode parent;

  MarkerNode(this.marker);

  @override
  Anchor get anchor => marker.anchor;

  @override
  get builder => marker.builder;

  @override
  double get height => marker.height;

  @override
  LatLng get point => marker.point;

  @override
  double get width => marker.width;
}
