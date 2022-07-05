import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/coordinates_model.dart';
import 'package:flutter/cupertino.dart';

class AlertCheckRPoint {
  final String rPointId, rPointName;
  RPValidationType validationType;
  Coordinates location;

  bool get geoValidationRequired =>
      validationType == RPValidationType.geo ||
      validationType == RPValidationType.geoQr;

  bool get qrValidationRequired =>
      validationType == RPValidationType.qr ||
      validationType == RPValidationType.geoQr;

  bool isCheckPassed = false;

  AlertCheckRPoint({
    required this.rPointId,
    required this.rPointName,
    required this.validationType,
    required this.location,
  });

  factory AlertCheckRPoint.fromMap(Map<String, dynamic> map) {
    return AlertCheckRPoint(
      rPointId: map['reportingPointId'] as String,
      rPointName: map['rPointName'] as String,
      validationType: RPValidationType.values[map['validationType'] as int],
      location: Coordinates.fromMap(map['location'] as Map<String, dynamic>),
    )..isCheckPassed = map['isCheckPassed'] as bool;
  }

  Map<String, dynamic> toMap() {
    return {
      'reportingPointId': rPointId,
      'rPointName': rPointName,
      'isCheckPassed': isCheckPassed,
      'validationType': validationType.index,
      'location': location.toMap(),
    };
  }

  Map<String, dynamic> toMapForServer() {
    return {
      'reportingPointId': rPointId,
      'isCheckPassed': isCheckPassed,
    };
  }

  AlertCheckRPoint copy() {
    return AlertCheckRPoint(
      rPointId: rPointId,
      rPointName: rPointName,
      validationType: RPValidationType.values[validationType.index],
      location: location.copyWith(latitude: 0, longitude: 0),
    )..isCheckPassed = isCheckPassed;
  }
}
