import 'package:android_device_info/android_device_info.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/services_address.dart';
import 'package:bazz_flutter/modules/settings_module/settings_controller.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/background_service.dart';
import 'package:bazz_flutter/services/data_connection_checker.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/networking_client.dart';
import 'package:bazz_flutter/shared_widgets/system_dialog.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sim_data/sim_data.dart';
import 'package:uuid/uuid.dart';

import '../../general/general_repo.dart';

class DomainController extends GetxController {
  final domainController = TextEditingController();
  final simSerialController = TextEditingController();
  static bool isPrivateDevice = false;
  final _loadingState = ViewState.idle.obs;
  final _isPasswordVisible = false.obs;

  bool get isPasswordVisible => _isPasswordVisible.value;

  ViewState get loadingState => _loadingState.value;
  String errorMessage = '';

  late String _simSerial;

  final _canUserProceed = false.obs;

  bool get canUserProceed =>
      _canUserProceed.value && loadingState != ViewState.loading;

  late bool showSimInput;

  void togglePasswordVisibility() => _isPasswordVisible.toggle();

  @override
  Future<void> onInit() async {
    domainController.addListener(_inputListener);

    const String apiBaseUrl = String.fromEnvironment('apiBaseUrl',
        defaultValue: 'https://api.dev.bazzptt.com');
    showSimInput =
        const String.fromEnvironment('showSimInput', defaultValue: 'true')
            .parseBool();
    DomainController.isPrivateDevice =
        const String.fromEnvironment('isPrivateDevice', defaultValue: 'false')
            .parseBool();
    domainController.text = apiBaseUrl;

    if (GetPlatform.isAndroid) {
      TelloLogger().i('Read Sim Number from card');
      SimData? simData;
      try {
        simData = await SimDataPlugin.getSimData();
      } catch (e, s) {
        TelloLogger().e('Error getting sim data', stackTrace: s);
      }
      if (simData != null &&
          simData.cards != null &&
          !simData.cards.isBlank! &&
          simData.cards[0].serialNumber.isNotEmpty) {
        _simSerial = simData.cards[0].serialNumber;
        simSerialController.text = _simSerial;
      } else {
        final networkInfo = await AndroidDeviceInfo().getNetworkInfo();
        _simSerial = networkInfo["wifiMAC"] != null
            ? networkInfo["wifiMAC"] as String
            : null!;
        _simSerial = Uuid().v1();
        simSerialController.text = _simSerial;
      }
    }
    super.onInit();
  }

  void _inputListener() {
    _canUserProceed.value =
        domainController.text.length >= AppSettings().userNameMinLen;
  }

  Future<void> onProceedToLogin() async {
    _loadingState(ViewState.loading);
    try {
      DataConnectionChecker().serviceAddress = null as AddressCheckOptions2;
      final connected = await DataConnectionChecker().isConnectedToInternet;
      TelloLogger().i("onProceedToLogin connectivityStatus == $connected");
      if (!connected) {
        _loadingState(ViewState.error);
        errorMessage = "No Internet Connection";
        return;
      }

      final String domainAddress = domainController.text;

      NetworkingClient2.init(domainAddress);
      if (simSerialController.text.trim().isNotEmpty) {
        _simSerial = simSerialController.text;
      }
      final data = await GeneralRepository().fetchSettings(_simSerial);
      if (data['status']['code'] != null) {
        final code = data['status']['code'] as int;
        if (code == 99) {
          _loadingState(ViewState.error);
          errorMessage = data['status']['message'] as String;
          return;
        }
      }
      AppSettings()
        ..baseUrl = domainAddress
        ..simSerial = _simSerial
        ..store(data);
      ServiceAddress().tryInit(AppSettings());
      DataConnectionChecker().checkInterval =
          Duration(seconds: AppSettings().pingIntervalSec.toInt());
      SettingsController.to!.loadSystemSettings();
      LocalizationService().saveLocale(Locale(AppSettings().languageCode, ''));
      TelloLogger()
          .i("ServiceAddress().backendURL ${ServiceAddress().baseUrl}");
      NetworkingClient.init(
        ServiceAddress().baseUrl,
      );
      // if (!DomainController.isPrivateDevice) {
      //   if (AppSettings().enableMobileKioskMode) {
      //     BackgroundService.instance().startApplicationPin();
      //   } else {
      //     BackgroundService.instance().stopApplicationPin();
      //   }
      //   if (AppSettings().enableMobileScreenLock) {
      //     BackgroundService.instance().activateScreenLock();
      //   }
      // }
      Get.toNamed(AppRoutes.login);
      _loadingState(ViewState.success);
    } on DioError catch (e, s) {
      _loadingState(ViewState.error);
      errorMessage = e.message;
      if (e.type == DioErrorType.cancel && e.error != null) {
        //TODO: localize error messages
        if (e.error is TelloError) {
          errorMessage = e.error.message as String;
        } else if (e.error is WrongTimeError) {
          _loadingState(ViewState.error);
          errorMessage = e.error.message as String;
          await SystemDialog.showConfirmDialog(
            dismissible: false,
            message: e.error.message as String,
          );
        }
      }
      TelloLogger().e('onProceedToLogin error: $e', stackTrace: s);
    } catch (e, s) {
      _loadingState(ViewState.error);
      errorMessage = "INVALID DOMAIN NAME";
      TelloLogger().e('onProceedToLogin error: $e', stackTrace: s);
    }
  }

  @override
  void onClose() {
    domainController.dispose();
    simSerialController.dispose();
    super.onClose();
  }
}
