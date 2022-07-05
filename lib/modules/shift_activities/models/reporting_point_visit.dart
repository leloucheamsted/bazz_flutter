import 'dart:convert';

import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/coordinates_model.dart';
import 'package:bazz_flutter/modules/media_uploading/media_upload_service.dart';
import 'package:bazz_flutter/modules/shift_activities/models/shift_activity_task.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReportingPointVisit {
  final String rPointId, tourId;
  late Coordinates? guardLocation;
  late int? startedAt, endedAt;
  late bool? isLocationCheckPassed, isQrCheckPassed;
  List<ShiftActivityTask> activities = [];

  String get id => startedAt.toString();

  bool get isFinished => endedAt != null;

  bool get isNotFinished => !isFinished;

  bool get hasDeferredUploadMedia =>
      activities.any((act) => act.result.hasDeferredUploadMedia);

  bool get hasActivities => activities.isNotEmpty;

  bool get hasNoActivities => !hasActivities;

  String get finishDateTimeFormatted => DateFormat(AppSettings().dateTimeFormat)
      .format(dateTimeFromSeconds(endedAt!, isUtc: true)!.toLocal());

  ReportingPointVisit({
    required this.rPointId,
    required this.tourId,
    this.guardLocation,
    required this.startedAt,
    this.endedAt,
    this.isLocationCheckPassed,
    this.isQrCheckPassed,
    required this.activities,
  });

  ReportingPointVisit.fromMap(Map<String, dynamic> map,
      {bool listFromJson = false})
      : tourId = map['tourId'] as String,
        rPointId = map['reportPointId'] as String,
        guardLocation = map['location'] != null
            ? Coordinates.fromMap(map['location'] as Map<String, dynamic>)
            : null,
        startedAt = map['startAt'] as int,
        endedAt = map['endAt'] as int,
        isLocationCheckPassed = map['isLocationCheckPassed'] as bool,
        isQrCheckPassed = map['isQrPassed'] as bool,
        activities = (listFromJson
                ? json.decode(map['activities'] as String) as List<dynamic>
                : map['activities'] as List<dynamic>)
            .map(
                (act) => ShiftActivityTask.fromMap(act as Map<String, dynamic>))
            .toList();

  Map<String, dynamic> toMap({bool listToJson = false}) {
    final activitiesList =
        activities.map((a) => a.toMap(listToJson: listToJson)).toList();
    return {
      'tourId': tourId,
      'reportPointId': rPointId,
      'location': guardLocation?.toMap(),
      'isLocationCheckPassed': isLocationCheckPassed,
      'isQrPassed': isQrCheckPassed,
      'startAt': startedAt,
      'endAt': endedAt,
      'activities': listToJson ? json.encode(activitiesList) : activitiesList,
    };
  }

  Map<String, dynamic> toMapForServer() {
    return {
      'tourId': tourId,
      'reportPointId': rPointId,
      'location': guardLocation?.toMap(),
      'isLocationCheckPassed': isLocationCheckPassed,
      'isQrPassed': isQrCheckPassed,
      'startAt': startedAt,
      'endAt': endedAt,
      'activityStats': List<Map<String, dynamic>>.from(
          activities.map((a) => a.result.toMapForServer())),
    };
  }

  Future<bool> getLinksForDeferredMedia(
      MediaUploadService uploadService) async {
    TelloLogger().i('getLinksForDeferredMedia() called');
    bool result = false;
    for (final act in activities) {
      if (act.result.hasDeferredUploadMedia) {
        final defMedia = uploadService.allMediaByEventId[act.id] = [
          ...act.result.deferredUploadMedia!
        ];
        final greatSuccess = await uploadService.getAllLinksById(act.id);

        if (greatSuccess) {
          for (final m in defMedia) {
            if (m.isImage) {
              final tempImageUrls = act.result.imageUrls ?? [];
              tempImageUrls.add(m.publicUrl);
              act.result.imageUrls = tempImageUrls;
            } else {
              final tempVideoUrls = act.result.videoUrls ?? [];
              tempVideoUrls.add(m.publicUrl);
              act.result.videoUrls = tempVideoUrls;
            }
          }
          MediaUploadService.to.deleteAllById(act.id);
          result = true;
        } else {
          MediaUploadService.to.deleteAllById(act.id);
          result = false;
          break;
        }
      }
    }
    TelloLogger().i('getLinksForDeferredMedia() output: $result');
    return result;
  }

  Future<void> uploadAllDeferredMedia(MediaUploadService uploadService) async {
    TelloLogger().i('uploadAllDeferredMedia() called');
    for (final act in activities) {
      if (act.result.hasDeferredUploadMedia) {
        final defMedia = uploadService.allMediaByEventId[act.id] = [
          ...act.result.deferredUploadMedia!
        ];
        uploadService.uploadAllMediaForId(act.id, showError: false);
        try {
          await Future.wait(defMedia.map((m) => m.uploadComplete.future));
          MediaUploadService.to.deleteAllById(act.id);
        } catch (e) {
          MediaUploadService.to.deleteAllById(act.id);
          rethrow;
        }
      }
    }
    TelloLogger().i('uploadAllDeferredMedia() finished');
  }

  ReportingPointVisit copyWith({
    String? rPointId,
    String? tourId,
    Coordinates? guardLocation,
    int? startedAt,
    int? endedAt,
    bool? isLocationCheckPassed,
    bool? isQrCheckPassed,
    List<ShiftActivityTask>? activities,
    bool? result,
  }) {
    return ReportingPointVisit(
      rPointId: rPointId ?? this.rPointId,
      tourId: tourId ?? this.tourId,
      guardLocation: guardLocation ??
          this.guardLocation?.copyWith(latitude: 0, longitude: 0),
      startedAt: startedAt ?? this.startedAt,
      endedAt: endedAt ?? this.endedAt,
      isLocationCheckPassed:
          isLocationCheckPassed ?? this.isLocationCheckPassed,
      isQrCheckPassed: isQrCheckPassed ?? this.isQrCheckPassed,
      activities:
          activities ?? this.activities.map((e) => e.copyWith()).toList(),
    );
  }
}
