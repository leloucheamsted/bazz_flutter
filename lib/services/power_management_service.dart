import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/modules/auth_module/domain_module/domain_controller.dart';
import 'package:bazz_flutter/modules/location_tracking/location_service.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:eventify/eventify.dart';
import 'package:geolocator/geolocator.dart';
import 'package:screen/screen.dart';

class PowerManagementService extends EventEmitter {
  static final PowerManagementService _singleton = PowerManagementService._();

  factory PowerManagementService() => _singleton;

  PowerManagementService._();

  bool _needToRestorePower = false;

  Future<void> managePowerConsumptionService(int batteryPercentage,
      {required bool isDeviceCharging}) async {
    if (DomainController.isPrivateDevice ||
        HomeController.to.currentState == ViewState.lock) {
      return;
    }
    late int locationPeriod;
    late LocationAccuracy desiredAccuracy;
    if (isDeviceCharging) {
      await Screen.setBrightness(1.0);
      locationPeriod = AppSettings().locationUpdatePeriod;
      desiredAccuracy = LocationAccuracy.best;
    } else {
      if (batteryPercentage < 50 &&
          batteryPercentage > 30 &&
          !isDeviceCharging) {
        locationPeriod = 7;
        desiredAccuracy = LocationAccuracy.high;
        await Screen.setBrightness(AppSettings().screenBrightness - 0.1);
        _needToRestorePower = true;
      } else if (batteryPercentage <= 30 &&
          batteryPercentage > 20 &&
          !isDeviceCharging) {
        locationPeriod = 10;
        desiredAccuracy = LocationAccuracy.medium;
        await Screen.setBrightness(AppSettings().screenBrightness - 0.2);
        _needToRestorePower = true;
      } else if (batteryPercentage <= 20 && !isDeviceCharging) {
        locationPeriod = 15;
        desiredAccuracy = LocationAccuracy.low;
        await Screen.setBrightness(AppSettings().screenBrightness - 0.3);
        _needToRestorePower = true;
      } else if (_needToRestorePower && (batteryPercentage >= 50)) {
        await Screen.setBrightness(AppSettings().screenBrightness);
        locationPeriod = AppSettings().locationUpdatePeriod;
        desiredAccuracy = LocationAccuracy.best;
        _needToRestorePower = false;
      }
    }

    if (locationPeriod != null &&
        locationPeriod != LocationService().locationUpdatePeriod) {
      LocationService().pause();
      LocationService().start(
          locationUpdatePeriod: locationPeriod,
          desiredAccuracy: desiredAccuracy);
    }
  }
}
