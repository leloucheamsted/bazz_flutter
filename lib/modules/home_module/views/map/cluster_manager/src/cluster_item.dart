import 'package:geohash/geohash.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'cluster_manager.dart';

class ClusterItem<T> {
  final LatLng location;
  final String geohash;
  final T item;

  ClusterItem(this.location, {required this.item})
      : geohash = Geohash.encode(location.latitude, location.longitude,
            codeLength: ClusterManager.precision);
}
