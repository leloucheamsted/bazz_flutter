import 'dart:convert';

import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/network_jitter/network_jitter_service.dart';
import 'package:bazz_flutter/services/battery_info_service.dart';
import 'package:bazz_flutter/services/data_usage_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/telephony_info_service.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:get_storage/get_storage.dart';

class DeviceState {
  DeviceState({
    this.batteryPercentage,
    this.networkStrength,
    this.isDeviceCharging,
    this.mobileNetworkType,
    this.jitter,
    this.latency,
    this.dataUsage = 0,
    this.generalDataUsage = 0,
    this.updatedAt,
  });

  final int? batteryPercentage,
      networkStrength,
      jitter,
      latency,
      dataUsage,
      generalDataUsage,
      updatedAt;
  final bool? isDeviceCharging;
  final MobileNetworkType? mobileNetworkType;

  factory DeviceState.fromMap(Map<String, dynamic> map) => DeviceState(
        batteryPercentage: map["batteryPercentage"] as int,
        networkStrength: map["networkStrength"] as int,
        isDeviceCharging: map["isDeviceCharging"] as bool,
        mobileNetworkType: MobileNetworkType.values[map["networkType"] as int],
        jitter: map["jitter"] as int,
        latency: map["latency"] as int,
        dataUsage: map["dataUsage"] as int,
        updatedAt: map["updatedAt"] != null ? map["updatedAt"] as int : 0,
      );

  Map<String, dynamic> toMap() => {
        "batteryPercentage": batteryPercentage,
        "networkStrength": networkStrength,
        "jitter": jitter,
        "latency": latency,
        "dataUsage": dataUsage,
        "generalDataUsage": generalDataUsage,
        "isDeviceCharging": isDeviceCharging,
        "networkType": mobileNetworkType!.index,
        "updatedAt": updatedAt,
      };

  // ignore: prefer_constructors_over_static_methods
  static DeviceState createEmpty() {
    return DeviceState(
      batteryPercentage: 0,
      networkStrength: 0,
      isDeviceCharging: false,
      mobileNetworkType: MobileNetworkType.WiFi,
      updatedAt: 0,
    );
  }

  static Future<DeviceState> createDeviceState() async {
    try {
      final TelephonyInfo telephonyInfo = await FltTelephonyInfo.info;
      final BatteryInfo batteryInfo = await BatteryInfo.create();
      final Map<String, dynamic>? map =
          await telephonyInfo.getConnectivityStatus();
      final isOnline = HomeController.to.isOnline;
      final jitter = isOnline ? NetworkJitterController.to?.jitter$ : null;
      final latency = isOnline ? NetworkJitterController.to?.latency : null;
      final dataUsage = DataUsageService().totalDataUsage > Int32.maxSize
          ? Int32.maxSize
          : DataUsageService().totalDataUsage;
      final generalDataUsage =
          DataUsageService().totalDataUsageAll > Int32.maxSize
              ? Int32.maxSize
              : DataUsageService().totalDataUsageAll;
      //TODO: remove type casting after DeviceState is fixed
      return DeviceState(
        batteryPercentage: batteryInfo.batteryPercentage as int,
        networkStrength: map!["networkStrength"] as int,
        jitter: jitter,
        latency: latency,
        dataUsage: dataUsage,
        generalDataUsage: generalDataUsage,
        isDeviceCharging: batteryInfo.isDeviceCharging as bool,
        mobileNetworkType: map["networkType"] as MobileNetworkType,
        updatedAt: dateTimeToSeconds(DateTime.now().toUtc()),
      );
    } catch (e, s) {
      TelloLogger().e('createDeviceState error: $e', stackTrace: s);
      return null!;
    }
  }

  DeviceState clone() {
    return DeviceState(
        batteryPercentage: batteryPercentage,
        networkStrength: networkStrength,
        jitter: jitter,
        latency: latency,
        dataUsage: dataUsage,
        isDeviceCharging: isDeviceCharging,
        mobileNetworkType: mobileNetworkType,
        updatedAt: updatedAt);
  }

  void save() {
    final combinedStates = [toMap()];

    final existingStatesString =
        GetStorage().read(StorageKeys.offlineDeviceStates);

    if (existingStatesString != null) {
      combinedStates.addAll(List<Map<String, dynamic>>.from(
          json.decode(existingStatesString as String) as List<dynamic>));
    }

    final combinedStatesString = json.encode(combinedStates);

    TelloLogger()
        .i('DeviceState save(): existingStatesString: $existingStatesString, '
            'combinedStates.length: ${combinedStates.length}');

    GetStorage().write(StorageKeys.offlineDeviceStates, combinedStatesString);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DeviceState &&
          runtimeType == other.runtimeType &&
          batteryPercentage == other.batteryPercentage &&
          jitter == other.jitter &&
          latency == other.latency &&
          dataUsage == other.dataUsage &&
          networkStrength == other.networkStrength &&
          isDeviceCharging == other.isDeviceCharging &&
          mobileNetworkType == other.mobileNetworkType;

  @override
  int get hashCode =>
      batteryPercentage.hashCode ^
      networkStrength.hashCode ^
      jitter.hashCode ^
      latency.hashCode ^
      dataUsage.hashCode ^
      updatedAt.hashCode ^
      isDeviceCharging.hashCode ^
      mobileNetworkType.hashCode;
}
