import 'dart:io';
import 'dart:isolate';
import 'dart:ui';

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/auth_module/auth_service.dart';
import 'package:bazz_flutter/modules/auth_module/domain_module/domain_controller.dart';
import 'package:bazz_flutter/modules/general/general_repo.dart';
import 'package:bazz_flutter/modules/settings_module/settings_controller.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/activity_recognition_service.dart';
import 'package:bazz_flutter/services/data_connection_checker.dart';
import 'package:bazz_flutter/services/data_usage_service.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/networking_client.dart';
import 'package:bazz_flutter/services/path_service.dart';
import 'package:bazz_flutter/services/pointer_service.dart';
import 'package:bazz_flutter/services/session_service.dart';
import 'package:cross_connectivity/cross_connectivity.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_downloader/flutter_downloader.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:wifi_iot/wifi_iot.dart';

import 'app_retain_widget.dart';
import 'models/app_settings.dart';
import 'models/services_address.dart';
import 'services/background_service.dart';
import 'services/keyboard_service.dart';

Directory temporaryDirectory = Directory('path');

// ignore: avoid_void_async
Future<void> main() async {
  String initialRoute = AppRoutes.domain;
  try {
    TelloLogger().i("#######################START BAZZ MOBILE################");
    ConnectivitySettings.init(lookupDuration: const Duration(seconds: 10));
    WidgetsFlutterBinding.ensureInitialized();
    await FlutterDownloader.initialize(
      debug: !kReleaseMode,
    );
    FlutterDownloader.registerCallback(downloadCallback);
    await GetStorage.init();
    await GetStorage.init(StorageKeys.messageUploadQueueBox);
    await GetStorage.init(StorageKeys.rPointVisitsUploadQueueBox);
    await GetStorage.init(StorageKeys.offlineEventsBox);
    await GetStorage.init(StorageKeys.readOfflineChatMessagesBox);

    LocalizationService().loadCurrentLocale();
    await StoragePaths().init();
    SessionService.restoreSession();
    AppSettings().tryRestore();
    ServiceAddress().tryInit(AppSettings());

    if (ServiceAddress().initialized) {
      NetworkingClient.init(ServiceAddress().baseUrl);
      NetworkingClient2.init(ServiceAddress().baseUrl);
      final isOnline = await DataConnectionChecker().isConnectedToInternet;
      final isOffline = !isOnline;

      if (isOnline) {
        try {
          final settingsFetched = await AppSettings().tryUpdate();

          if (Session.hasAuthToken && settingsFetched) {
            final userInfoData = await GeneralRepository().getUserInfo();
            final respCode = userInfoData['status']['code'] as int;
            if (respCode == 3 || respCode == 4) Session.wipeSession();
          }
        } catch (e, s) {
          TelloLogger().e("main() fetchSettings() error: $e", stackTrace: s);
        }
      }

      final hasSavedGroups = GetStorage().hasData(StorageKeys.groups);
      final hasSavedActiveGroup = GetStorage().hasData(StorageKeys.activeGroup);
      final hasSavedAdminUsers = GetStorage().hasData(StorageKeys.adminUsers);

      if (Session.hasNoToken) {
        initialRoute = AppRoutes.login;
      } else if (isOffline &&
          (!hasSavedGroups || !hasSavedActiveGroup || !hasSavedAdminUsers)) {
        initialRoute = AppRoutes.login;
      } else {
        initialRoute = AppRoutes.home;
      }
    }

    await checkPermissions();
    SystemChrome.setEnabledSystemUIOverlays([]);

    await Get.putAsync(() => SettingsController().init());

    if (Platform.isAndroid) {
      try {
        BackgroundService.instance().initializeBackgroundService();
      } catch (e, s) {
        TelloLogger().e(
          "Failed BackgroundService.instance().initializeBackgroundService() reason = $e",
          stackTrace: s,
        );
      }
    }
    //Wakelock.enable();
    if (!DomainController.isPrivateDevice) {
      await DataUsageService().init();
      if (Platform.isAndroid) {
        WiFiForIoTPlugin.setWiFiAPEnabled(false);
      }
      if (AppSettings().initialized) {
        if (AppSettings().enableMobileKioskMode) {
          BackgroundService.instance().startApplicationPin();
        } else {
          BackgroundService.instance().stopApplicationPin();
        }
        if (AppSettings().enableMobileScreenLock) {
          BackgroundService.instance().activateScreenLock();
        }
      }
    }
    temporaryDirectory = await getTemporaryDirectory();
  } catch (e, s) {
    MyApp.errorMessage = e.toString();
    TelloLogger().e("Error Loading The Main APP reason $e", stackTrace: s);
  } finally {
    runApp(MyApp(initialRoute: initialRoute));
    Keyboard.init();
    Pointer.init();
  }

  try {
    ActivityRecognitionService().init();
  } catch (e, s) {
    TelloLogger()
        .e("Error ActivityRecognitionService().init() = $e", stackTrace: s);
  }
  TelloLogger().i(
      "callServicesHandler #######################COMPLETE BAZZ MOBILE################");
}

void downloadCallback(String id, DownloadTaskStatus status, int progress) {
  TelloLogger().i("MAIN downloadCallback $id $status $progress");
  final SendPort? sendPort2 =
      IsolateNameServer.lookupPortByName('downloader_send_port2');
  if (sendPort2 != null) {
    TelloLogger().i("MAIN downloadCallback sendPort2");
    sendPort2.send([id, status, progress]);
    return;
  }
  final SendPort? sendPort =
      IsolateNameServer.lookupPortByName('downloader_send_port');
  sendPort?.send([id, status, progress]);
}

Future<void> checkPermissions() async {
  await [
    Permission.locationAlways,
    Permission.activityRecognition,
    Permission.microphone,
    Permission.phone,
    Permission.camera,
    Permission.storage
  ].request();
}

class MyApp extends StatelessWidget {
  static String errorMessage = "";
  final String initialRoute;

  const MyApp({required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    /*SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);*/
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      TelloLogger().i('SystemChannels> $msg');

      switch (msg) {
        case "AppLifecycleState.paused":
          TelloLogger().i(
              "#######################@@@@@@@@@@@@@@@@@@@@@@AppLifecycleState.paused STEP TO CLOSE 2 ################");
          break;
        case "AppLifecycleState.inactive":
          TelloLogger().i(
              "########################@@@@@@@@@@@@@@@@@@@@@@AppLifecycleState.inactive STEP TO CLOSE 3 #################");
          break;
        case "AppLifecycleState.resumed":
          TelloLogger().i(
              "########################@@@@@@@@@@@@@@@@@@@@@@AppLifecycleState.resumed##########");
          break;
        case "AppLifecycleState.detached":
          TelloLogger().i(
              "#########################@@@@@@@@@@@@@@@@@@@@@@AppLifecycleState.detached##############");
          break;
        default:
      }

      return null;
    });
    if (MyApp.errorMessage.isNotEmpty) {
      return MaterialApp(
          home: Scaffold(
        appBar: AppBar(title: const Text('TELLO APP')),
        body: SafeArea(
          child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              child: Column(children: [
                Image.asset('assets/images/tello_text_logo.png'),
                const SizedBox(height: 20),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 3,
                          )
                        ],
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        color: AppColors.brightBackground,
                      ),
                      child: Row(
                        children: [
                          ClipOval(
                              child: Container(
                                  height: 50,
                                  width: 50,
                                  color: AppTheme().colors.mainBackground,
                                  child: Image.asset(
                                      'assets/images/tello_logo.png'))),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Tello Mobile App Error',
                                  style: AppTypography.headline6TextStyle
                                      .copyWith(fontSize: 20),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: const BoxDecoration(
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black12,
                            blurRadius: 3,
                          )
                        ],
                        borderRadius: BorderRadius.all(Radius.circular(5)),
                        color: AppColors.brightBackground,
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  MyApp.errorMessage,
                                  style: AppTypography.headline6TextStyle
                                      .copyWith(fontSize: 20),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ])),
        ),
      ));
    } else {
      final widget = AppRetainWidget(
        child: GetMaterialApp(
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          supportedLocales: LocalizationService().supportedLocales(),
          locale: Get.locale,
          title: 'Tello App',
          initialRoute: initialRoute,
          initialBinding: BindingsBuilder(() {
            Get.lazyPut(() => AuthService());
          }),
          getPages: AppPages.pages,
          theme: ThemeData(
            fontFamily: 'Poppins',
            primaryColorBrightness: Brightness.dark,
          ),
          debugShowCheckedModeBanner: false,
          defaultTransition: Transition.fadeIn,
        ),
      );

      return widget;
    }
  }
}
