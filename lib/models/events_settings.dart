import 'dart:convert';

import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/icon_config.dart';

class EventsSettings {
  String sosTypeConfigId;
  List<EventTypeConfig> eventTypeConfigs;

  EventsSettings.fromMap(Map<String, dynamic> map, {bool listFromJson = false})
      : sosTypeConfigId = map['sosTypeConfigId'] as String,
        eventTypeConfigs = (listFromJson
                ? json.decode(map['typeConfigs'] as String) as List<dynamic>
                : map['typeConfigs'] as List<dynamic>)
            .map((m) => EventTypeConfig.fromMap(m as Map<String, dynamic>))
            .toList();

  Map<String, dynamic> toMap() {
    return {
      'sosTypeConfigId': sosTypeConfigId,
      'typeConfigs': json.encode(eventTypeConfigs.map((m) => m.toMap()).toList()),
    };
  }

  void update(EventsSettings newSettings) {
    for (final newCfg in newSettings.eventTypeConfigs) {
      if (eventTypeConfigs.any((cfg) => cfg.typeId == newCfg.typeId)) {
        continue;
      } else {
        eventTypeConfigs.add(newCfg);
      }
    }
  }

  /// For each icon we check and set if we have this icon in assets folder
  Future<void> processIcons() async {
    assert(eventTypeConfigs != null);
    if (eventTypeConfigs == null) return;

    final futures = <Future<bool>>[];

    for (final cfg in eventTypeConfigs) {
      if (cfg.details.icon.iconAssetNotExists) futures.add(cfg.details.icon.setIconAssetExists(forEvents: true));
    }

    await Future.wait(futures);
  }
}

class EventTypeConfig {
  final String typeId, name;
  final int order;
  final EventTypeDetails details;
  final EventTypePolicy policy;

  bool get isSos => typeId == AppSettings().eventSettings.sosTypeConfigId;

  bool get isNotSos => !isSos;

  EventTypeConfig.fromMap(Map<String, dynamic> map)
      : typeId = map['id'] as String,
        name = map['name'] as String,
        order = map['order'] as int,
        details = EventTypeDetails.fromMap(map['details'] as Map<String, dynamic>),
        policy = EventTypePolicy.fromMap(map['policy'] as Map<String, dynamic>);

  Map<String, dynamic> toMap() {
    return {
      'id': typeId,
      'name': name,
      'order': order,
      'details': details.toMap(),
      'policy': policy.toMap(),
    };
  }
}

class EventTypeDetails {
  final String description;
  final bool isSystem;
  final IconConfig icon, mapIcon;

  EventTypeDetails.fromMap(Map<String, dynamic> map)
      : description = map['description'] != null ? map['description'] as String : '',
        isSystem = map['isSystem'] as bool,
        icon = IconConfig.fromMap(map['icon'] as Map<String, dynamic>),
        mapIcon = IconConfig.fromMap(map['mapIcon'] as Map<String, dynamic>);

  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'isSystem': isSystem,
      'icon': icon.toMap(),
      'mapIcon': mapIcon.toMap(),
    };
  }
}

class EventTypePolicy {
  final bool canCreate, showOnMap, drawPath, canCreatePrivate;

  EventTypePolicy.fromMap(Map<String, dynamic> map)
      : canCreate = map['canCreate'] as bool,
        canCreatePrivate = map['allowCreatePrivate'] as bool,
        showOnMap = map['showOnMap'] as bool,
        drawPath = map['drawPath'] as bool;

  Map<String, dynamic> toMap() {
    return {
      'canCreate': canCreate,
      'allowCreatePrivate': canCreatePrivate,
      'showOnMap': showOnMap,
      'drawPath': drawPath,
    };
  }
}
