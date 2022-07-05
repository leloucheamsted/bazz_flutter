import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/base_event.dart';
import 'package:bazz_flutter/models/event_details.dart';
import 'package:bazz_flutter/models/event_parameters.dart';
import 'package:bazz_flutter/models/location.dart';
import 'package:bazz_flutter/modules/media_uploading/media_upload_service.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

///We always check the ownerPositionId first
class IncomingEvent extends BaseEvent {
  String ownerId,
      ownerFirstName = 'Undefined',
      ownerLastName = 'Undefined',
      ownerPositionTitle = 'Undefined';
  RxBool isConfirmed$ = false.obs;
  RxBool isPostponed$ = false.obs;
  EventSeverity severity;
  EventPriority priority;
  String priorityTitle = "Undefined";
  Color priorityColor = Colors.grey;
  Rx<EventStatus> status;
  Rx<EventResolveStatus> resolveStatus = EventResolveStatus.treated.obs;
  List<String> imageUrls = [];
  List<String> videoUrls = [];
  List<UploadableMedia> deferredUploadMedia = [];
  EventDetails eventDetails;
  bool isPostponedCheckboxDisabled = false;
  EventParameters eventParameters = EventParameters();
  bool isExpanded = false;
  bool isPrivate = false;

  bool get isNotPrivate => !isPrivate;

  String get ownerTitle => ownerPositionTitle != 'Undefined'
      ? ownerPositionTitle
      : '$ownerFirstName $ownerLastName';

  bool get hasDeferredUploadMedia => deferredUploadMedia.isNotEmpty;

  bool get hasNoDeferredUploadMedia => !hasDeferredUploadMedia;

  String get statusTitle => status() == EventStatus.open
      ? "AppLocalizations.of(Get.context).statusOpen"
      : "AppLocalizations.of(Get.context).statusOngoing";

  Color get statusColor =>
      status() == EventStatus.open ? AppColors.primaryAccent : AppColors.orange;

  bool get isJustified$ => resolveStatus() == EventResolveStatus.justified;

  bool get isNotConfirmed$ => !isConfirmed$();

  bool get isSystem => config.details.isSystem;

  bool get isNotSystem => !isSystem;

  bool get hasLocation => location != null;

  bool get hasNoLocation => !hasLocation;

  bool get showOnMap => config.policy.showOnMap;

  bool get doNotShowOnMap => !showOnMap;

  IncomingEvent.fromMap(Map<String, dynamic> map)
      : ownerId = map['event']['ownerId'] as String,
        ownerFirstName = map['owner'] != null
            ? map['owner']['profile']['firstName'] as String
            : 'Undefined',
        ownerLastName = map['owner'] != null
            ? map['owner']['profile']['lastName'] as String
            : 'Undefined',
        ownerPositionTitle = map['ownerPosition'] != null
            ? map['ownerPosition']['title'] as String
            : 'Undefined',
        isConfirmed$ = map['isConfirmed'] as bool != null
            ? (map['isConfirmed'] as bool).obs
            : false.obs,
        isPrivate = map['event']['isPrivate'] as bool,
        severity = EventSeverity.values[map['event']['severity'] as int],
        priority = EventPriority.values[map['event']['priority'] as int],
        status = EventStatus.values[map['event']['status'] as int].obs,
        eventDetails = EventDetails.fromMap(
            map['event']['eventDetails'] as Map<String, dynamic>),
        super(
          id: map['event']['eventId'] as String,
          groupId: map['event']['groupId'] as String,
          ownerPositionId: map['event']['ownerPositionId'] as String,
          location: map['event']['location'] != null
              ? Location.fromMap(
                  map['event']['location'] as Map<String, dynamic>)
              : null,
          createdAt: map['event']['createdAt'] as int,
          typeId: map['event']['typeId'] as String,
        ) {
    processEventPriority(priority);
    isPostponed$.value = map['event']['isPostponed'] != null
        ? map['event']['isPostponed'] as bool
        : false;
    isPostponedCheckboxDisabled = isPostponed$.value;

    final speedLimitParams =
        map['event']['eventParameters']['speedLimitParameters'];
    final deviceOfflineParams =
        map['event']['eventParameters']['deviceOfflineParameters'];
    if (speedLimitParams != null) {
      eventParameters.speedLimitParams = EventSpeedLimitParams.fromMap(
          speedLimitParams as Map<String, dynamic>);
    }
    if (deviceOfflineParams != null) {
      eventParameters.deviceOfflineParams = EventDeviceOfflineParams.fromMap(
          deviceOfflineParams as Map<String, dynamic>);
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'event': {
        'eventId': id,
        'ownerId': ownerId,
        'groupId': groupId,
        'typeId': typeId,
        'ownerPositionId': ownerPositionId,
        'isPrivate': isPrivate,
        'severity': severity.index,
        'priority': priority.index,
        'status': status().index,
        'eventDetails': eventDetails.toMap(),
        'isPostponed': isPostponed$(),
        'location': location?.toMap(),
        'createdAt': createdAt,
        'eventParameters': {
          'speedLimitParameters': eventParameters.speedLimitParams.toMap(),
          'deviceOfflineParameters':
              eventParameters.deviceOfflineParams.toMap(),
        },
      },
      'owner': {
        'profile': {
          'firstName': ownerFirstName,
          'lastName': ownerLastName,
        },
      },
      'ownerPosition': {
        'title': ownerPositionTitle,
      },
      'isConfirmed': isConfirmed$(),
    };
  }

  void processEventPriority(EventPriority priority) {
    switch (priority) {
      case EventPriority.low:
        priorityTitle = "AppLocalizations.of(Get.context).low";
        priorityColor = AppColors.secondaryAccent;
        break;
      case EventPriority.medium:
        priorityTitle = " AppLocalizations.of(Get.context).medium";
        priorityColor = AppColors.sandyYellow;
        break;
      case EventPriority.high:
        priorityTitle = "AppLocalizations.of(Get.context).high";
        priorityColor = AppColors.orange;
        break;
      case EventPriority.immediate:
        priorityTitle = " AppLocalizations.of(Get.context).immediate";
        priorityColor = AppColors.danger;
        break;
      default:
    }
  }
}
