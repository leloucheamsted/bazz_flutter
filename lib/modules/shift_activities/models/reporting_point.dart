import 'dart:convert';

import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/coordinates_model.dart';
import 'package:bazz_flutter/modules/shift_activities/models/reporting_point_visit.dart';
import 'package:bazz_flutter/modules/shift_activities/models/shift_activity_task.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class ReportingPoint {
  final String id, tourId;
  final String title, qrToken, qrTokenUrl, description;
  Coordinates location;
  ReportingPointVisit currentVisit;
  List<ReportingPointVisit>? visits = [];
  List<ShiftActivityTask> activities = [];
  RPValidationType validationType;
  RxBool isChooseVisitPopupOpen = false.obs;
  bool isExpanded;

  final ExpandableController expandableController = ExpandableController();

  bool get isNotExpanded => !isExpanded;

  bool get hasCurrentVisit => currentVisit != null;

  bool get hasNoCurrentVisit => !hasCurrentVisit;

  bool get isFinished => visits!.isNotEmpty;

  bool get hasVisits => visits!.isNotEmpty;

  bool get isNotFinished => currentVisit != null || visits!.isEmpty;

  bool get isNotStarted =>
      visits!.isEmpty &&
      (currentVisit.activities.every((act) => act.isNotFinished));

  bool get hasActivities => activities.isNotEmpty;

  bool get hasNoActivities => !hasActivities;

  bool get geoValidationRequired =>
      validationType == RPValidationType.geo ||
      validationType == RPValidationType.geoQr;

  bool get qrValidationRequired =>
      validationType == RPValidationType.qr ||
      validationType == RPValidationType.geoQr;

  int get visitsCounter => visits!.length;

  List<ReportingPointVisit> get visitsWithoutCurrent => currentVisit != null
      ? visits!.where((v) => v.id != currentVisit.id).toList()
      : [];

  ReportingPoint({
    required this.id,
    required this.tourId,
    required this.title,
    required this.qrToken,
    required this.description,
    required this.location,
    required this.activities,
    required this.validationType,
    required this.qrTokenUrl,
    required this.visits,
    required this.currentVisit,
    this.isExpanded = false,
  });

// initially tourId is being passed from the tour, and restored from the map later on, 'cause we should be
// able to save a Reporting Point individually, not as a part of a Tour
  factory ReportingPoint.fromMap(Map<String, dynamic> map,
      {bool listFromJson = false, String? tourId}) {
    final activities =
        (listFromJson ? json.decode(map['activities']) : map['activities'])
            .map((act) => ShiftActivityTask.fromMap(act))
            .toList();
    final visits = map['visits'] != null
        ? (listFromJson ? json.decode(map['visits']) : map['visits'])
            .map((act) =>
                ReportingPointVisit.fromMap(act, listFromJson: listFromJson))
            .toList()
        : <ReportingPointVisit>[];
    return ReportingPoint(
      id: map['id'],
      tourId: map['tourId'] ?? tourId,
      title: map['name'],
      qrToken: map['qrToken'],
      qrTokenUrl: map['qrTokenUrl'],
      description: map['description'],
      location: Coordinates.fromMap(map['location']),
      validationType: RPValidationType.values[map['validationType'] as int],
      activities: activities,
      visits: visits,
      currentVisit: map['currentVisit'] != null
          ? ReportingPointVisit.fromMap(map['currentVisit'],
              listFromJson: listFromJson)
          : null as ReportingPointVisit,
    );
  }

  Map<String, dynamic> toMap({bool listToJson = false}) {
    final activitiesList =
        activities.map((a) => a.toMap(listToJson: listToJson)).toList();
    final visitsList =
        visits!.map((v) => v.toMap(listToJson: listToJson)).toList();
    return {
      'id': id,
      'tourId': tourId,
      'name': title,
      'qrToken': qrToken,
      'qrTokenUrl': qrTokenUrl,
      'description': description,
      'location': location.toMap(),
      'validationType': validationType.index,
      'currentVisit': currentVisit.toMap(listToJson: listToJson),
      'activities': listToJson ? json.encode(activitiesList) : activitiesList,
      'visits': listToJson ? json.encode(visitsList) : visitsList,
    };
  }

  void setCurrentVisit(ReportingPointVisit visit) {
    currentVisit = visit;
  }

  void finishVisit() {
    visits!.add(currentVisit);
    currentVisit = null as ReportingPointVisit;
  }

  void addVisit(ReportingPointVisit visit) {
    visits!.add(visit);
  }

  void expand() {
    if (hasActivities) {
      expandableController.expanded = true;
      isExpanded = true;
    }
  }

  void collapse() {
    expandableController.expanded = false;
    isExpanded = false;
  }

  void sortVisitsAscEndTime() {
    visits!.sort((a, b) => a.endedAt! - b.endedAt!);
  }

  ReportingPoint copyWith({
    String? id,
    String? tourId,
    String? title,
    String? qrToken,
    String? qrTokenUrl,
    String? description,
    bool? isExpanded,
    Coordinates? location,
    ReportingPointVisit? currentVisit,
    List<ShiftActivityTask>? activities,
    List<ReportingPointVisit>? visits,
    RPValidationType? validationType,
  }) {
    return ReportingPoint(
      id: id ?? this.id,
      tourId: tourId ?? this.tourId,
      title: title ?? this.title,
      qrToken: qrToken ?? this.qrToken,
      qrTokenUrl: qrTokenUrl ?? this.qrTokenUrl,
      description: description ?? this.description,
      isExpanded: isExpanded ?? this.isExpanded,
      location: location ?? this.location.copyWith(latitude: 0, longitude: 0),
      currentVisit: currentVisit ?? this.currentVisit.copyWith(),
      activities:
          activities ?? this.activities.map((e) => e.copyWith()).toList(),
      visits: visits ?? this.visits!.map((e) => e.copyWith()).toList(),
      validationType:
          validationType ?? RPValidationType.values[this.validationType.index],
    );
  }
}
