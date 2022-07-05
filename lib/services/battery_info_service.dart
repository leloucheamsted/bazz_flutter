import 'dart:async';

// import 'package:android_device_info/android_device_info.dart';
import 'package:android_device_info/android_device_info.dart';
import 'package:bazz_flutter/services/logger.dart';

//TODO: CAST TYPES!!!
class BatteryInfo {
  BatteryInfo._({
    this.batteryPercentage,
    this.isDeviceCharging,
    this.batteryTechnology,
    this.batteryTemperature,
    this.batteryVoltage,
    this.isBatteryPresent,
    this.batteryHealth,
    this.chargingSource,
  });

  dynamic batteryPercentage;
  dynamic isDeviceCharging;
  dynamic batteryTechnology;
  dynamic batteryTemperature;
  dynamic batteryVoltage;
  dynamic isBatteryPresent;
  dynamic batteryHealth;
  dynamic chargingSource;

  static Future<BatteryInfo> create() async {
    final data = await AndroidDeviceInfo().getBatteryInfo();
    return BatteryInfo._(
      batteryPercentage: data["batteryPercentage"],
      isDeviceCharging: data["isDeviceCharging"],
      batteryTechnology: data["batteryTechnology"],
      batteryTemperature: data["batteryTemperature"],
      batteryVoltage: data["batteryVoltage"],
      isBatteryPresent: data["isBatteryPresent"],
      batteryHealth: data["batteryHealth"],
      chargingSource: data["chargingSource"],
    );
  }

  @override
  String toString() {
    super.toString();
    return "{"
        "\nbatteryPercentage:$batteryPercentage,"
        "\nisDeviceCharging:$isDeviceCharging,"
        "\nbatteryTechnology:$batteryTechnology,"
        "\nbatteryTemperature:$batteryTemperature,"
        "\nbatteryVoltage:$batteryVoltage,"
        "\nisBatteryPresent:$isBatteryPresent,"
        "\nbatteryHealth:$batteryHealth,"
        "\nchargingSource:$chargingSource,"
        "\n}";
  }
}
