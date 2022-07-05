// ignore_for_file: import_of_legacy_library_into_null_safe

import 'dart:async';
import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/auth_module/auth_repo.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/shift_module/shift_repo.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/background_service.dart';
import 'package:bazz_flutter/services/battery_info_service.dart';
import 'package:bazz_flutter/services/keyboard_service.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/logger/logger_flutter.dart';
import 'package:bazz_flutter/services/snack_bar_display.dart';
import 'package:bazz_flutter/services/telephony_info_service.dart';
import 'package:bazz_flutter/shared_widgets/system_dialog.dart';
import 'package:bazz_flutter/utils/back_button_locker.dart';
import 'package:data_usage/data_usage.dart';
import 'package:device_info/device_info.dart';
import 'package:external_path/external_path.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intent/action.dart' as android_action;
import 'package:intent/intent.dart' as android_intent;
import '../../app_theme.dart';

typedef TechnicianCodeCallback = Future<void> Function();

class SettingsController extends GetxController
    with SingleGetTickerProviderMixin {
  static SettingsController? get to =>
      Get.isRegistered<SettingsController>() ? Get.find() : null;
  final _port = ReceivePort();
  final _loadingState = ViewState.idle.obs;

  RxInt downloadProgress$ = 0.obs;
  RxBool isDownloading$ = false.obs;
  RxBool isComplete$ = false.obs;
  RxBool loggerEnabled$ = true.obs;
  final RxBool _showNetworkJitter$ = false.obs;
  final RxBool _showTransportStats$ = false.obs;
  final RxBool _isDarkTheme$ = true.obs;
  final _isPasswordVisible = false.obs;
  late TabController tabController;
  late TabController tabController2;
  late Rx<TelephonyInfo> telephonyInfo$;
  late Rx<BatteryInfo> batteryInfo$;
  final TextEditingController technicianCodeController =
      TextEditingController();

  final List<StreamSubscription> _subscriptions = [];

  ViewState get loadingState => _loadingState.value;

  BatteryInfo get batteryInfo => batteryInfo$.value;

  int get downloadProgress => downloadProgress$.value;

  bool get isDownloading => isDownloading$.value;

  bool get loggerEnabled => loggerEnabled$.value;

  bool get showNetworkJitter => _showNetworkJitter$.value;

  bool get showTransportStats => _showTransportStats$.value;

  bool get isDarkTheme => _isDarkTheme$.value;

  bool get isPasswordVisible => _isPasswordVisible.value;

  bool get isComplete => isComplete$.value;

  TelephonyInfo get telephonyInfo => telephonyInfo$.value;

  StreamSubscription<int>? _keyDownSub;
  StreamSubscription<int>? _keyUpSub;
  TechnicianCodeCallback? currentCallBack;

  RxBool appPinned$ = true.obs;

  bool get appPinned => appPinned$.value;

  RxBool keyCodeIsTracking$ = false.obs;

  RxString keyboardDownKeyValue$ = "".obs;

  RxString keyboardUpKeyValue$ = "".obs;

  RxString availableNewVersionValue$ = "".obs;

  final dataUsage$ = <DataUsageModel>[].obs;

  List<DataUsageModel> get dataUsage => dataUsage$;

  bool _dataUsageInitialized = false;

  final TextEditingController pttKeyCodeController = TextEditingController();
  final TextEditingController sosKeyCodeController = TextEditingController();
  final TextEditingController switchDownKeyCodeController =
      TextEditingController();
  final TextEditingController switchUpKeyCodeController =
      TextEditingController();

  late int _osSDKInt;
  late String _osRelease;
  late String _deviceManufacturer;
  late String _deviceModel;

  int get osSDKInt => _osSDKInt;

  String get osRelease => _osRelease;

  String get deviceManufacturer => _deviceManufacturer;

  String get deviceModel => _deviceModel;

  Future<SettingsController> init() async {
    // ignore: avoid_bool_literals_in_conditional_expressions

    tabController2 = TabController(vsync: this, length: 2);
    tabController = TabController(vsync: this, length: 6);

    pttKeyCodeController.addListener(() {
      if (pttKeyCodeController.text.isNum) {
        Keyboard.setPttButtonCode(int.parse(pttKeyCodeController.text));
        GetStorage().write(StorageKeys.pttKeyCodeId, pttKeyCodeController.text);
      }
    });

    sosKeyCodeController.addListener(() {
      if (sosKeyCodeController.text.isNum) {
        Keyboard.setSOSButtonCode(int.parse(sosKeyCodeController.text));
        GetStorage().write(StorageKeys.sosKeyCodeId, sosKeyCodeController.text);
      }
    });

    switchDownKeyCodeController.addListener(() {
      if (switchDownKeyCodeController.text.isNum) {
        Keyboard.setSwitchDownButtonCode(
            int.parse(switchDownKeyCodeController.text));
        GetStorage().write(
            StorageKeys.switchDownKeyCodeId, switchDownKeyCodeController.text);
      }
    });

    switchUpKeyCodeController.addListener(() {
      if (switchUpKeyCodeController.text.isNum) {
        Keyboard.setSwitchUpButtonCode(
            int.parse(switchUpKeyCodeController.text));
        GetStorage().write(
            StorageKeys.switchUpKeyCodeId, switchUpKeyCodeController.text);
      }
    });
    if (Session.device != null) {
      pttKeyCodeController.text = Session.device!.pttKeyCode!.toString();
      sosKeyCodeController.text = Session.device!.sosKeyCode.toString();
      switchUpKeyCodeController.text =
          Session.device!.switchUpKeyCode.toString();
      switchDownKeyCodeController.text =
          Session.device!.switchDownKeyCode.toString();
    }

    _keyDownSub = Keyboard.keyboardDownKey$.listen((key) {
      keyboardDownKeyValue$.value = '$key';
    });

    _keyUpSub = Keyboard.keyboardUpKey$.listen((key) {
      keyboardUpKeyValue$.value = '$key';
    });

    if (Get.isRegistered<HomeController>()) {
      try {
        telephonyInfo$.value = await FltTelephonyInfo.info;
        TelloLogger().i("TELEPHONY INFO =  ${telephonyInfo.toString()}");
      } on PlatformException {}
    }

    try {
      batteryInfo$.value = await BatteryInfo.create();
    } on PlatformException {}

    loadSystemSettings();
    listenToSettings();

    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;
      _osRelease = androidInfo.version.release;
      _osSDKInt = androidInfo.version.sdkInt;
      _deviceManufacturer = androidInfo.manufacturer;
      _deviceModel = androidInfo.model;
      TelloLogger().i(
          'Android $_osRelease (SDK $_osSDKInt), $_deviceManufacturer $_deviceModel');
    }

    return this;
  }

  Future<void> initDataUsage() async {
    try {
      if (!_dataUsageInitialized) {
        await DataUsage.init();
        _dataUsageInitialized = true;
      }

      TelloLogger().i('initDataUsage');
      final dataUsages = await DataUsage.dataUsageAndroid(withAppIcon: true);

      dataUsage$.clear();
      dataUsage$.add(dataUsages.firstWhere(
          (element) => element.packageName == "com.bazzptt.bazz_flutter"));
      dataUsage$.addAll(dataUsages.where((element) =>
          (element.received! > 0 || element.sent! > 0) &&
          element.packageName != "com.bazzptt.bazz_flutter"));
    } catch (e, s) {
      TelloLogger().e('initDataUsage() error: $e', stackTrace: s);
    }
  }

  @override
  Future<void> onClose() async {
    _keyDownSub?.cancel();
    _keyUpSub?.cancel();
    clearSubscriptions();
  }

  void togglePasswordVisibility() => _isPasswordVisible.toggle();

  void _bindBackgroundIsolate() {
    IsolateNameServer.registerPortWithName(
        _port.sendPort, 'downloader_send_port2');
    _port.listen((dynamic data) {
      TelloLogger().i(" _port.listen");
      final String taskId = data[0] as String;
      final DownloadTaskStatus status = data[1] as DownloadTaskStatus;
      final int progress = data[2] as int;
      downloadCallback(taskId, status, progress);
    });
  }

  void _unbindBackgroundIsolate() {
    _port.close();
    IsolateNameServer.removePortNameMapping('downloader_send_port2');
  }

  Future<void> downloadCallback(
      String id, DownloadTaskStatus status, int progress) async {
    TelloLogger().i("downloadCallback");
    if (status == DownloadTaskStatus.failed) {
      isDownloading$.value = false;
      _unbindBackgroundIsolate();
      Get.showSnackbarEx(GetBar(
        backgroundColor: AppColors.error,
        message: 'Failed Downloading APK',
        titleText: Text(LocalizationService().of().systemInfo,
            style: AppTypography.captionTextStyle),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.brightIcon,
        ),
      ));
    }
    if (status == DownloadTaskStatus.complete) {
      _unbindBackgroundIsolate();
      isDownloading$.value = false;
      isComplete$.value = true;
    } else if (status == DownloadTaskStatus.running) {
      downloadProgress$.value = progress;
    }
  }

  Future<void> askForTechnicianCode(TechnicianCodeCallback callBack) async {
    currentCallBack = callBack;
    technicianCodeController.text = "";
    _isPasswordVisible(false);

    SystemDialog.showInputDialog(
      title: LocalizationService().of().technicianCodeTitle,
      message: LocalizationService().of().enterTechnicianCode,
      confirmButtonText: LocalizationService().of().ok,
      confirmCallback: checkTechnicianCode,
      cancelCallback: Get.back,
      cancelButtonText: LocalizationService().of().cancel,
      textController: technicianCodeController,
      togglePasswordVisibility: togglePasswordVisibility,
      isPasswordVisible: _isPasswordVisible,
    );
  }

  Future<void> resetApp() async {
    SystemDialog.showConfirmDialog(
      title: LocalizationService().of().restMobileAppTitle,
      message: LocalizationService().of().resetMobileAppMsg,
      confirmButtonText: LocalizationService().of().ok,
      confirmCallback: resetConfirmed,
      cancelButtonText: LocalizationService().of().cancel,
    );
  }

  Future<void> unpinDevice() async {
    BackgroundService.instance().stopApplicationPin();
    appPinned$.value = false;
  }

  Future<void> pinDevice() async {
    BackgroundService.instance().startApplicationPin();
    appPinned$.value = true;
  }

  Future<void> checkTechnicianCode() async {
    Get.back();
    final String techCode = AppSettings().technicianCode;
    if (technicianCodeController.text == techCode) {
      await currentCallBack!();
    } else {
      SystemDialog.showConfirmDialog(
        title: LocalizationService().of().technicianCodeTitle,
        message: LocalizationService().of().technicianCodeNotValid,
        confirmButtonText: LocalizationService().of().ok,
        cancelButtonText: LocalizationService().of().cancel,
      );
    }
    technicianCodeController.text = "";
    technicianCodeController.clear();
  }

  Future<void> openNewVersionFolder() async {
    try {
      await resetApp();
      final String directory =
          await ExternalPath.getExternalStoragePublicDirectory(
              ExternalPath.DIRECTORY_DOWNLOADS);
      android_intent.Intent()
        ..setAction(android_action.Action.ACTION_GET_CONTENT)
        ..setData(Uri.parse(directory))
        ..setType("*/*")
        ..startActivity();
      exit(0);
    } catch (e, s) {
      TelloLogger()
          .e('Failed openNewVersionFolder. Details: $e', stackTrace: s);
    } finally {
      Get.back();
    }
  }

  Future<void> resetConfirmed() async {
    if (Session.hasShift) {
      final resp = await ShiftRepository().closeShift(DateTime.now());
    } else if (Session.user != null) {
      await AuthRepository().logOut();
      await Session.wipeSession();
    }
    GetStorage().erase();
    Get.offAllNamed(AppRoutes.domain);
  }

  /*Future<void> uninstallVersion() async {
    BackButtonLocker.lockBackButton();
    try {
      if (Session.hasShift) {
        final resp = await ShiftRepository().closeShift(DateTime.now());
        */ /* if (resp?.data == null) {
          return;
        }*/ /*
      } else if (Session.user != null) {
        await AuthRepository().logOut();
        await Session.wipeSession();
      }
      await Future.delayed(const Duration(seconds: 5));
      final PackageInfo info = await PackageInfo.fromPlatform();

      android_intent.Intent()
        ..setAction(android_action.Action.ACTION_DELETE)
        ..setData(Uri.parse("package:${info.packageName}"))
        ..startActivityForResult().then((data) {
          Logger().log(data);
        }, onError: (e) {
          Logger().log(e);
        });
      //SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      exit(0);
    } catch (e) {
      Logger().log('Failed uninstall current version. Details: $e');
      BackButtonLocker.unlockBackButton();
    }
  }
*/
  Future<void> openNetworkSettings() async {
    BackgroundService.instance().stopApplicationPin();
    BackgroundService.instance().openNetworkSettings();
  }

/*
  Future<void> updateVersion() async {
    BackButtonLocker.lockBackButton();
    try {
      if (Session.hasShift) {
        final resp = await ShiftRepository().closeShift(DateTime.now());
        */
/* if (resp?.data == null) {
          return;
        }*/ /*

      } else if (Session.user != null) {
        await AuthRepository().logOut();
        await Session.wipeSession();
      }
      await Future.delayed(const Duration(seconds: 5));
      final PackageInfo info = await PackageInfo.fromPlatform();

      android_intent.Intent()
        ..setAction(android_action.Action.ACTION_DELETE)
        ..setData(Uri.parse("package:${info.packageName}"))
        ..startActivityForResult().then((data) {
          Logger().log(data);
        }, onError: (e) {
          Logger().log(e);
        });
      //SystemChannels.platform.invokeMethod('SystemNavigator.pop');
      exit(0);
    } catch (e) {
      Logger().log('Failed uninstall current version. Details: $e');
      BackButtonLocker.unlockBackButton();
    }
  }
*/

  Future<void> installVersion() async {
    BackButtonLocker.lockBackButton();
    try {
      SystemDialog.showConfirmDialog(
          title: LocalizationService().of().installingNewVersionTitle,
          message: LocalizationService().of().installingNewVersionMsg,
          confirmButtonText: LocalizationService().of().ok,
          cancelButtonText: LocalizationService().of().cancel,
          confirmCallback: openNewVersionFolder,
          cancelCallback: () => Get.back());
      /*if (Session.hasShift) {
        final resp = await ShiftRepository().closeShift(DateTime.now());
        */ /* if (resp?.data == null) {
          return;
        }*/ /*
      } else if (Session.user != null) {
        await AuthRepository().logOut();
        await Session.wipeSession();
      }
      final String directory = await ExtStorage.getExternalStoragePublicDirectory(ExtStorage.DIRECTORY_DOWNLOADS);
      //AppInstaller.installApk('$directory/bazz-app-release.apk');
      BackgroundService.instance().installAPK('$directory/bazz-app-release.apk');*/
    } catch (e, s) {
      TelloLogger()
          .e('Failed install current version. Details: $e', stackTrace: s);
      BackButtonLocker.unlockBackButton();
    }
  }

  Future<void> downloadNewVersion() async {
    if (isDownloading) return;
    if (AppSettings().apkUrl.isEmpty) {
      Get.showSnackbarEx(GetBar(
        backgroundColor: AppColors.error,
        message: LocalizationService().of().apkURlNotDefined,
        titleText: Text(LocalizationService().of().systemInfo,
            style: AppTypography.captionTextStyle),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.brightIcon,
        ),
      ));
      return;
    }

    BackButtonLocker.lockBackButton();
    isComplete$.value = false;
    isDownloading$.value = true;
    downloadProgress$.value = 0;
    _bindBackgroundIsolate();
    try {
      TelloLogger().i("Download APK from ${AppSettings().apkUrl}");
      final String directory =
          await ExternalPath.getExternalStoragePublicDirectory(
              ExternalPath.DIRECTORY_DOWNLOADS);
      final File apkFile = File.fromUri(Uri.parse(
          '$directory\bazz-app-release${AppSettings().clientVersion}-${AppSettings().clientBuildNumber}.apk'));
      final bool exists = await apkFile.exists();

      if (exists) {
        TelloLogger().i("APK FILE EXISTS");
        await apkFile.delete();
        TelloLogger().i("APK FILE HAS BEEN DELETED");
      }

      isDownloading$.value = true;
      await FlutterDownloader.enqueue(
        url: AppSettings().apkUrl,
        savedDir: directory,
        fileName: 'bazz-app-release.apk',
        showNotification: true,
        openFileFromNotification: true,
      );
    } catch (e, s) {
      TelloLogger().e('Failed download new version Details: $e', stackTrace: s);
      BackButtonLocker.unlockBackButton();
    }
  }

  void setLoggerEnabled(bool value) => loggerEnabled$(value);

  void setShowNetworkJitter(bool value) => _showNetworkJitter$(value);

  void setTransportStats(bool value) => _showTransportStats$(value);

  void setIsDarkTheme(bool value) {
    _isDarkTheme$(value);
    AppTheme().setTheme(isDark: value);
    Get.forceAppUpdate();
  }

  Future<void> changeLanguage(Locale value) async {
    LocalizationService().saveLocale(value);
  }

  Future<void> openLogConsole() async {
    const logConsole = LogConsole(
      showCloseButton: true,
      dark: true,
    );
    PageRoute route;
    if (Platform.isIOS) {
      route = CupertinoPageRoute(builder: (_) => logConsole);
    } else {
      route = MaterialPageRoute(builder: (_) => logConsole);
    }
    await Navigator.push(Get.context!, route);
  }

  void saveSystemSettings() {
    TelloLogger().i("saveSystemSettings");
    final data = {
      'loggerEnabled': loggerEnabled,
      'showNetworkJitter': showNetworkJitter,
      'isDarkTheme': isDarkTheme,
    };
    GetStorage().write(StorageKeys.systemSettingsId, data);
  }

  void loadSystemSettings() {
    final result = GetStorage().read(StorageKeys.systemSettingsId);
    if (result != null) {
      final data = result as Map<String, dynamic>;
      loggerEnabled$.value = data["loggerEnabled"] as bool;
      _showNetworkJitter$.value = data["showNetworkJitter"] != null
          ? data["showNetworkJitter"] as bool
          : AppSettings().showNetworkJitter;
      _isDarkTheme$.value = data["isDarkTheme"] != null
          ? data["isDarkTheme"] as bool
          : AppSettings().isDarkTheme;
    } else {
      resetSettingsToDefault();
    }
    AppTheme().setTheme(isDark: _isDarkTheme$());
  }

  void clearSubscriptions() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
  }

  void listenToSettings() {
    _subscriptions.add(loggerEnabled$.listen((val) {
      saveSystemSettings();
      TelloLogger().clearOutputEventBuffer();
    }));

    _subscriptions.add(_showNetworkJitter$.listen((val) {
      saveSystemSettings();
    }));

    _subscriptions.add(_isDarkTheme$.listen((val) {
      saveSystemSettings();
    }));
  }

  void resetSettingsToDefault() {
    GetStorage().remove(StorageKeys.pttKeyCodeId);
    GetStorage().remove(StorageKeys.sosKeyCodeId);
    GetStorage().remove(StorageKeys.switchUpKeyCodeId);
    GetStorage().remove(StorageKeys.switchDownKeyCodeId);

    if (Session.device != null && Session.device!.pttKeyCode! > 0) {
      Keyboard.setPttButtonCode(Session.device!.pttKeyCode!);
      pttKeyCodeController.text = Session.device!.pttKeyCode.toString();
    }

    if (Session.device != null && Session.device!.sosKeyCode! > 0) {
      Keyboard.setSOSButtonCode(Session.device!.sosKeyCode!);
      sosKeyCodeController.text = Session.device!.sosKeyCode!.toString();
    }

    if (Session.device != null && Session.device!.switchUpKeyCode! > 0) {
      Keyboard.setSwitchUpButtonCode(Session.device!.switchUpKeyCode!);
      switchUpKeyCodeController.text =
          Session.device!.switchUpKeyCode!.toString();
    }

    if (Session.device != null && Session.device!.switchDownKeyCode! > 0) {
      Keyboard.setSwitchDownButtonCode(Session.device!.switchDownKeyCode!);
      switchDownKeyCodeController.text =
          Session.device!.switchDownKeyCode!.toString();
    }

    loggerEnabled$.value = true;
    _showNetworkJitter$(AppSettings().showNetworkJitter);
    _isDarkTheme$(AppSettings().isDarkTheme);
    LocalizationService().restoreDefaultLocale();
  }
}
