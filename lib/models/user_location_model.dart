import 'dart:convert';

import 'package:bazz_flutter/models/coordinates_model.dart';
import 'package:bazz_flutter/models/location_details_model.dart';

class UserLocation {
  UserLocation({
    this.coordinates,
    this.updatedAt,
    this.locationDetails,
  });

  final Coordinates? coordinates;
  final int? updatedAt;
  final LocationDetails? locationDetails;

  factory UserLocation.fromJson(String str) =>
      UserLocation.fromMap(json.decode(str) as Map<String, dynamic>);

  String toJson() => json.encode(toMap());

  factory UserLocation.fromMap(Map<String, dynamic> json) => UserLocation(
        coordinates:
            Coordinates.fromMap(json["coordinate"] as Map<String, dynamic>),
        updatedAt: json["updatedAt"] as int,
        locationDetails: json["locationDetails"] != null
            ? LocationDetails.fromMap(
                json["locationDetails"] as Map<String, dynamic>)
            : null,
      );

  Map<String, dynamic> toMap() => {
        "coordinate": coordinates!.toMap(),
        "updatedAt": updatedAt,
        "locationDetails": locationDetails?.toMap(),
      };

  UserLocation clone() {
    return UserLocation(
        coordinates: coordinates,
        updatedAt: updatedAt,
        locationDetails: locationDetails != null
            ? LocationDetails(
                accuracy: locationDetails!.accuracy,
                altitude: locationDetails!.altitude,
                heading: locationDetails!.heading,
                speed: locationDetails!.speed,
                speedAccuracy: locationDetails!.speedAccuracy,
                createdAt: 0 as int)
            : null);
  }
}
