import 'dart:convert';

import 'package:bazz_flutter/utils/utils.dart';
import 'package:geolocator/geolocator.dart';

class LocationDetails {
  LocationDetails({
    required this.accuracy,
    required this.altitude,
    required this.heading,
    required this.speed,
    required this.speedAccuracy,
    required this.createdAt,
  });

  final double accuracy;
  final double altitude;
  final double heading;
  double speed;
  final double speedAccuracy;
  final int createdAt;

  factory LocationDetails.fromJson(String str) =>
      LocationDetails.fromMap(json.decode(str) as Map<String, dynamic>);

  String toJson() => json.encode(toMap());

  factory LocationDetails.fromMap(Map<String, dynamic> map) => LocationDetails(
        accuracy: double.tryParse(map["accuracy"].toString()) ?? 0.0,
        altitude: double.tryParse(map["altitude"].toString()) ?? 0.0,
        heading: double.tryParse(map["heading"].toString()) ?? 0.0,
        speed: double.tryParse(map["speed"].toString()) ?? 0.0,
        speedAccuracy: double.tryParse(map["speedAccuracy"].toString()) ?? 0.0,
        createdAt: map["createdAt"] as int,
      );

  factory LocationDetails.fromPosition(Position position) => LocationDetails(
        accuracy: position.accuracy,
        altitude: position.altitude,
        heading: position.heading,
        speed: position.speed,
        speedAccuracy: position.speedAccuracy,
        createdAt: dateTimeToSeconds(position.timestamp!.toUtc()),
      );

  Map<String, dynamic> toMap() => {
        "accuracy": accuracy,
        "altitude": altitude,
        "heading": heading,
        "speed": speed,
        "speedAccuracy": speedAccuracy,
        "createdAt": createdAt,
      };
}
