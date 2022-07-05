import 'dart:convert';

import 'package:bazz_flutter/models/alert_check_config.dart';
import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/shift_end_message.dart';
import 'package:bazz_flutter/models/zone.dart';
import 'package:bazz_flutter/modules/shift_activities/models/reporting_point.dart';
import 'package:bazz_flutter/modules/shift_activities/models/tour.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:flutter/material.dart';

import 'group_model.dart';

class Shift {
  final String? zoneId,
      zoneTitle,
      groupId,
      groupTitle,
      supId,
      supFirstName,
      supLastName,
      positionId,
      positionTitle;
  final int? duration;
  int? startTime, plannedEndTime;
  AlertCheckConfig? alertCheckConfig;
  String? id;
  RxGroup? currentGroup;
  Zone? currentZone;
  Region? currentRegion;
  RxPosition? currentPosition;
  List<Tour>? tours;
  List<ReportingPoint>? reportingPoints;
  List<ShiftEndMessage>? shiftEndMessages;

  Shift({
    required this.id,
    required this.zoneId,
    required this.zoneTitle,
    required this.groupId,
    required this.groupTitle,
    required this.supId,
    required this.supFirstName,
    required this.supLastName,
    required this.positionId,
    required this.positionTitle,
    required this.duration,
    required this.startTime,
    required this.plannedEndTime,
    required this.alertCheckConfig,
    required this.currentZone,
    required this.currentRegion,
    required this.currentGroup,
    required this.currentPosition,
    required this.tours,
    required this.reportingPoints,
    required this.shiftEndMessages,
  });

  // Shift.fromPosition(Map<String, dynamic> m)
  //     : currentZone = Zone.fromMap(m['zone'] as Map<String, dynamic>),
  //       currentRegion = Region.fromMap(m['region'] as Map<String, dynamic>),
  //       currentGroup = RxGroup.fromMap(m['group'] as Map<String, dynamic>),
  //       currentPosition = RxPosition.fromMap(m['position'] as Map<String, dynamic>),
  //       zoneId = m['zone']['id'] as String,
  //       zoneTitle = m['zone']['title'] as String,
  //       groupId = m['group']['id'] as String,
  //       groupTitle = m['group']['title'] as String,
  //       supId = m['group']['supervisor'] != null ? m['group']['supervisor']['id'] as String : null,
  //       supFirstName =
  //           m['group']['supervisor'] != null ? m['group']['supervisor']['profile']['firstName'] as String : '',
  //       supLastName = m['group']['supervisor'] != null ? m['group']['supervisor']['profile']['lastName'] as String : '',
  //       duration = m['position']['shiftDuration'] as int,
  //       positionId = m['position']['id'] as String,
  //       positionTitle = m['position']['title'] as String;

  Shift.fromPositionAndGroup(RxPosition position, RxGroup group)
      : currentPosition = position,
        currentGroup = group,
        currentZone = group.zone,
        currentRegion = group.zone!.region,
        zoneId = group.zone!.id,
        zoneTitle = group.zone!.title,
        groupId = group.id,
        groupTitle = group.title,
        supId = group.supervisor?.id ?? "",
        supFirstName = group.supervisor?.firstName ?? "",
        supLastName = group.supervisor?.lastName ?? "",
        duration = position.shiftDuration,
        positionId = position.id,
        positionTitle = position.title;

  bool get hasStarted => startTime != null && id != null;

  bool get hasEnded => DateTime.now()
      .toUtc()
      .isAfter(dateTimeFromSeconds(plannedEndTime!, isUtc: true)!);

  factory Shift.fromMap(Map<String, dynamic> map) {
    return Shift(
      id: map['id'] as String,
      zoneId: map['zoneId'] as String,
      zoneTitle: map['zoneTitle'] as String,
      groupId: map['groupId'] as String,
      groupTitle: map['groupTitle'] as String,
      supId: map['supId'] as String,
      supFirstName: map['supFirstName'] as String,
      supLastName: map['supLastName'] as String,
      positionId: map['positionId'] as String,
      positionTitle: map['positionTitle'] as String,
      duration: map['duration'] as int,
      startTime: map['startTime'] as int,
      plannedEndTime: map['plannedEndTime'] as int,
      alertCheckConfig: map['alertCheckConfig'] != null
          ? AlertCheckConfig.fromMap(
              map['alertCheckConfig'] as Map<String, dynamic>,
              listFromJson: true)
          : null,
      currentPosition: map['currentPosition'] != null
          ? RxPosition.fromMap(map['currentPosition'] as Map<String, dynamic>,
              listFromJson: true)
          : null,
      currentGroup: map['currentGroup'] != null
          ? RxGroup.fromMap(map['currentGroup'] as Map<String, dynamic>,
              listFromJson: true)
          : null,
      currentZone: map['currentZone'] != null
          ? Zone.fromMap(map['currentZone'] as Map<String, dynamic>,
              listFromJson: true)
          : null,
      currentRegion: map['currentRegion'] != null
          ? Region.fromMap(map['currentRegion'] as Map<String, dynamic>,
              listFromJson: true)
          : null,
      tours: (json.decode(map['tours'] as String) as List<dynamic>)
          .map((t) =>
              Tour.fromMap(t as Map<String, dynamic>, listFromJson: true))
          .toList(),
      reportingPoints:
          (json.decode(map['reportingPoints'] as String) as List<dynamic>)
              .map((rp) => ReportingPoint.fromMap(rp as Map<String, dynamic>,
                  listFromJson: true))
              .toList(),
      shiftEndMessages:
          (json.decode(map['shiftEndMessages'] as String) as List<dynamic>)
              .map((rp) => ShiftEndMessage.fromMap(rp as Map<String, dynamic>))
              .toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'zoneId': zoneId,
      'zoneTitle': zoneTitle,
      'groupId': groupId,
      'groupTitle': groupTitle,
      'supId': supId,
      'supFirstName': supFirstName,
      'supLastName': supLastName,
      'positionId': positionId,
      'positionTitle': positionTitle,
      'duration': duration,
      'startTime': startTime,
      'plannedEndTime': plannedEndTime,
      'alertCheckConfig': alertCheckConfig?.toMap(),
      'currentPosition': currentPosition?.toMap(listToJson: true),
      'currentGroup': currentGroup?.toMap(listToJson: true),
      'currentZone': currentZone?.toMap(listToJson: true),
      'currentRegion': currentRegion?.toMap(listToJson: true),
      'tours':
          json.encode(tours!.map((t) => t.toMap(listToJson: true)).toList()),
      'reportingPoints': json.encode(
          reportingPoints!.map((rp) => rp.toMap(listToJson: true)).toList()),
      'shiftEndMessages':
          json.encode(shiftEndMessages!.map((m) => m.toMap()).toList()),
    };
  }
}
