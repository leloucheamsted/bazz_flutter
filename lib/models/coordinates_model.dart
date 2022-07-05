import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:latlong/latlong.dart' as flutter_map;

class Coordinates {
  Coordinates({
    required this.latitude,
    required this.longitude,
  });

  late double latitude;
  late double longitude;

  factory Coordinates.fromJson(String str) =>
      Coordinates.fromMap(json.decode(str) as Map<String, dynamic>);

  String toJson() => json.encode(toMap());

  factory Coordinates.fromMap(Map<String, dynamic> json) => Coordinates(
        latitude: json["latitude"] as double,
        longitude: json["longitude"] as double,
      );

  factory Coordinates.fromPosition(Position position) => Coordinates(
        latitude: position.latitude,
        longitude: position.longitude,
      );

  factory Coordinates.fromLatLng(LatLng latLng) => Coordinates(
        latitude: latLng.latitude,
        longitude: latLng.longitude,
      );

  Map<String, dynamic> toMap() => {
        "latitude": latitude,
        "longitude": longitude,
      };

  bool isEmpty() {
    if (latitude == null || longitude == null) {
      return true;
    }
    return false;
  }

  LatLng toLatLng() => LatLng(latitude, longitude);
  flutter_map.LatLng toMapLatLng() {
    if (latitude == null || longitude == null) {
      return null!;
    }
    return flutter_map.LatLng(latitude, longitude);
  }

  Coordinates copyWith({
    required double latitude,
    required double longitude,
  }) {
    return Coordinates(
      latitude: latitude,
      longitude: longitude,
    );
  }
}
