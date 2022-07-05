import 'package:bazz_flutter/models/coordinates_model.dart';
import 'package:bazz_flutter/models/location_details_model.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class Location {
  Coordinates coordinates;
  int updatedAt;
  LocationDetails? locationDetails;

  Location({
    required this.coordinates,
    required this.updatedAt,
    this.locationDetails,
  });

  Map<String, dynamic> toMap() {
    return {
      'coordinate': coordinates.toMap(),
      'updatedAt': updatedAt,
      'locationDetails': locationDetails?.toMap(),
    };
  }

  factory Location.fromMap(Map<String, dynamic> map) {
    return Location(
      coordinates:
          Coordinates.fromMap(map['coordinate'] as Map<String, dynamic>),
      updatedAt: map['updatedAt'] as int,
      locationDetails: map['locationDetails'] != null
          ? LocationDetails.fromMap(
              map['locationDetails'] as Map<String, dynamic>)
          : null,
    );
  }

  factory Location.fromPosition(Position position) {
    return Location(
      coordinates: Coordinates.fromPosition(position),
      updatedAt: dateTimeToSeconds(position.timestamp!.toUtc()),
      locationDetails: LocationDetails.fromPosition(position),
    );
  }
}
