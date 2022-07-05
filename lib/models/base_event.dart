import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/events_settings.dart';
import 'package:bazz_flutter/models/icon_config.dart';
import 'package:bazz_flutter/models/location.dart';
import 'package:flutter/material.dart';

abstract class BaseEvent {
  late String? id, typeId, comment = '';
  late String? groupId, ownerPositionId;
  int? createdAt;
  Location? location;

  late EventTypeConfig config;

  bool get hasNoConfig => config == null;

  String get title => config.name;

  String get description => config.details.description;

  IconConfig get iconCfg => config.details.icon;

  IconConfig get mapIconCfg => config.details.mapIcon;

  //FIXME: AppSettings().eventSettings can be null because we can create groups in fetchSuggestedPositions(), where we don't need events
  bool get isSos => typeId == AppSettings().eventSettings.sosTypeConfigId;

  bool get isNotSos => !isSos;

  BaseEvent({
    required this.typeId,
    this.id,
    this.groupId,
    this.ownerPositionId,
    this.createdAt,
    this.location,
    this.comment,
  }) {
    setConfigByTypeId(typeId!);
  }

  bool setConfigByTypeId(String typeId) {
    //FIXME: AppSettings().eventSettings can be null because we can create groups in fetchSuggestedPositions(), where we don't need events
    final targetConfig = AppSettings()
        .eventSettings
        .eventTypeConfigs
        .firstWhere((cfg) => cfg.typeId == typeId, orElse: () => null!);
    config = targetConfig;
    return targetConfig != null;
  }
}
