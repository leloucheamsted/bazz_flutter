import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class EventParameters {
  late EventSpeedLimitParams speedLimitParams;
  late EventDeviceOfflineParams deviceOfflineParams;

  bool get isEmpty => speedLimitParams == null && deviceOfflineParams == null;

  bool get isNotEmpty => !isEmpty;
}

class EventSpeedLimitParams {
  final double speedAccuracy, userSpeed;
  final int speedLimit, speedUpdatedAt;

  EventSpeedLimitParams.fromMap(Map<String, dynamic> map)
      : speedAccuracy = double.tryParse(map["speedAccuracy"].toString()) ?? 0.0,
        speedLimit = map['speedLimit'] as int,
        userSpeed = double.tryParse(map["userSpeed"].toString()) ?? 0.0,
        speedUpdatedAt = map['speedUpdatedAt'] as int;

  Map<String, dynamic> toMap() {
    return {
      'speedAccuracy': speedAccuracy,
      'speedLimit': speedLimit,
      'userSpeed': userSpeed,
      'speedUpdatedAt': speedUpdatedAt,
    };
  }

  String get stringify {
    final timeString = DateFormat(AppSettings().dateTimeFormat)
        .format(dateTimeFromSeconds(speedUpdatedAt)!);
    final diff = ((userSpeed - speedLimit) * 3.6).round();
    return LocalizationService().of().speedLimitEventDetails(
          speedLimit.toString(),
          diff.toString(),
          (speedAccuracy * 3.6).toString(),
          timeString,
        );
  }
}

class EventDeviceOfflineParams {
  final OfflineReason offlineReason;
  final int offlineAt, offlineTimeout;

  EventDeviceOfflineParams.fromMap(Map<String, dynamic> map)
      : offlineReason = OfflineReason.values[map['offlineReason'] as int],
        offlineAt = map['offlineAt'] as int,
        offlineTimeout = map['offlineTimeout'] as int;

  Map<String, dynamic> toMap() {
    return {
      'offlineReason': offlineReason.index,
      'offlineAt': offlineAt,
      'offlineTimeout': offlineTimeout,
    };
  }

  Map<OfflineReason, String> offlineReasonDict = {
    OfflineReason.batteryStatus: LocalizationService().of().lowBatteryLevel,
    OfflineReason.dataUsage: LocalizationService().of().reachedNetworkDataLimit,
    OfflineReason.deviceUnexpectedShutdown:
        LocalizationService().of().unexpectedDeviceShutdown,
    OfflineReason.networkAvailability: LocalizationService().of().noNetwork,
  };

  String get stringify =>
      '${LocalizationService().of().possibleOfflineReason.capitalizeFirst} - ${offlineReasonDict[offlineReason]?.capitalizeFirst}';
}
