import 'dart:async';

import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/device_model.dart' as deviceModel;
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/shift_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/modules/auth_module/auth_repo.dart';
import 'package:bazz_flutter/modules/auth_module/auth_service.dart';
import 'package:bazz_flutter/modules/general/general_repo.dart';
import 'package:bazz_flutter/modules/settings_module/settings_controller.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/data_connection_checker.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/networking_client.dart';
import 'package:bazz_flutter/shared_widgets/system_dialog.dart';
import 'package:bazz_flutter/utils/back_button_locker.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:nfc_manager/nfc_manager.dart';
import 'package:screen/screen.dart';

const MethodChannel _channelScreenLock =
    MethodChannel('com.bazzptt/screenlock');

class AuthController extends GetxController {
  static AuthController get to => Get.find();
  ViewState _currentState = ViewState.idle;

  ViewState get currentState => _currentState;

  set currentState(ViewState state) => _currentState = state;

  final _loadingState = ViewState.idle.obs;

  ViewState get loadingState => _loadingState.value;

  set loadingState(ViewState state) => _loadingState.value = state;
  String errorMessage = '';

  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final _canUserLogIn = false.obs;
  final _canUserFaceScan = false.obs;
  final _loginWithNFCCode = false.obs;
  final _isPasswordVisible = false.obs;

  bool get canUserLogIn =>
      _canUserLogIn.value && loadingState != ViewState.loading;

  bool get canUserFaceScan => _canUserFaceScan.value;

  bool get loginWithNFCCode => _loginWithNFCCode.value;

  bool get isPasswordVisible => _isPasswordVisible.value;

  final RxString _nfcIdentifier$ = "".obs;

  final RxBool _enableNfcLogin$ = false.obs;

  bool get enableNfcLogin => _enableNfcLogin$.value;

  final RxBool isOnline = true.obs;

  Timer? _onlineTimer;

  @override
  Future<void> onInit() async {
    TelloLogger().i("AuthController onInit() start");

    isOnline.value = await DataConnectionChecker().isConnectedToInternet;
    _onlineTimer = Timer.periodic(const Duration(seconds: 3), (timer) async {
      isOnline.value = await DataConnectionChecker().isConnectedToInternet;
      if (isOnline.isFalse || AppSettings().updateCompleted) return;
      AppSettings().tryUpdate();
      SettingsController.to
          ?.setLoggerEnabled(!AppSettings().loggerConfig.isRemote);
    });

    if (isOnline() && AppSettings().updateNotCompleted) {
      try {
        if (AppSettings().updateNotCompleted) {
          AppSettings().tryUpdate();
          SettingsController.to
              ?.setLoggerEnabled(!AppSettings().loggerConfig.isRemote);
        }
        if (Session.user != null) await AuthService.to.logOut();
      } catch (e, s) {
        TelloLogger()
            .e("AuthController: error during onInit(): $e", stackTrace: s);
      }
    }
    DataConnectionChecker().serviceAddress = AddressCheckOptions2(
        AppSettings().baseUrl,
        method: "ping",
        timeout: DataConnectionChecker.DEFAULT_INTERVAL);

    final bool isAvail = await NfcManager.instance.isAvailable();
    _enableNfcLogin$.value = AppSettings().isNfcLoginEnabled && isAvail;

    _channelScreenLock.setMethodCallHandler((call) async {
      TelloLogger()
          .i("_channelScreenLock.setMethodCallHandler == $loadingState");
      if (loadingState == ViewState.idle || loadingState == ViewState.success) {
        _loadingState(ViewState.lock);
      } else if (loadingState == ViewState.lock) {
        await Screen.setBrightness(0.01);
      }
    });
    usernameController.addListener(_inputListener);
    passwordController.addListener(_inputListener);
    startNFCReaderStream();
    super.onInit();
  }

  @override
  Future<void> onClose() async {
    _onlineTimer?.cancel();
    usernameController.dispose();
    passwordController.dispose();
    final bool isAvail = await NfcManager.instance.isAvailable();
    if (_enableNfcLogin$.value && isAvail) {
      NfcManager.instance.stopSession();
    }
    super.onClose();
  }

  void togglePasswordVisibility() => _isPasswordVisible.toggle();

  void _setPasswordVisibility(bool isVisible) =>
      _isPasswordVisible.value = isVisible;

  void startNFCReaderStream() {
    if (_enableNfcLogin$.value) {
      _nfcIdentifier$.value = '' as String;
      TelloLogger().i("startNFCReaderStream Session");
      NfcManager.instance.startSession(onDiscovered: (NfcTag tag) async {
        TelloLogger().i("startNFCReaderStream ${tag.data}");
        _loginWithNFCCode.value = false;
        usernameController.text = "";
        passwordController.text = "";
        try {
          if (tag.data is Map<String, dynamic>) {
            final data = tag.data;
            final nfca = data["nfca"];
            final identifier = nfca["identifier"] as List<int>;
            final StringBuffer sb = StringBuffer();
            int index = 0;
            sb.write('[');
            for (final num in identifier) {
              index < (identifier.length - 1)
                  ? sb.write("$num,")
                  : sb.write("$num");
              index++;
            }
            sb.write(']');
            _loadingState(ViewState.idle);
            _nfcIdentifier$.value = sb.toString();
            _loginWithNFCCode.value = true;
            TelloLogger().i("startNFCReaderStream ${_nfcIdentifier$.value}");
            _canUserLogIn.value = true;
          }
        } catch (e, s) {
          _loadingState(ViewState.error);
          errorMessage = LocalizationService().of().failedReadingCardDetails;
        } finally {}
      });
    }
  }

  void _inputListener() {
    _canUserLogIn.value =
        usernameController.text.length >= AppSettings().userNameMinLen &&
            passwordController.text.length >= AppSettings().passwordMinLen;

    _canUserFaceScan.value =
        usernameController.text.length >= AppSettings().userNameMinLen &&
            passwordController.text.isEmpty;
  }

  Future<void> onFaceScanPressed() async {
    Get.toNamed(AppRoutes.faceAuth);
  }

  Future<void> performLogin({bool ignoreActiveSession = false}) async {
    Map<String, dynamic> data;
    try {
      TelloLogger().i(
          "Login with ignoreActiveSession = $ignoreActiveSession ${AppSettings().simSerial}");
      NetworkingClient().setBearerVersion();
      final bool loginWithUserNameAndPassword =
          usernameController.text.length >= AppSettings().userNameMinLen &&
              passwordController.text.length >= AppSettings().passwordMinLen;
      if (enableNfcLogin &&
          !loginWithUserNameAndPassword &&
          _nfcIdentifier$.value != null) {
        NfcManager.instance.stopSession();
        data = await AuthRepository().logInNfc(
            _nfcIdentifier$.value, AppSettings().simSerial,
            ignoreActiveSession: ignoreActiveSession, skipErrorDisplay: true);
      } else {
        data = await AuthRepository().logIn(usernameController.text,
            passwordController.text, AppSettings().simSerial,
            ignoreActiveSession: ignoreActiveSession, skipErrorDisplay: true);
      }
      loginIntoApp(data);
    } on DioError catch (e, s) {
      _inputListener();
      _loadingState(ViewState.idle);
      if (e.type == DioErrorType.cancel && e.error != null) {
        if (e.error is TelloError) {
          //TODO: localize error messages
          final TelloError bazzError = e.error as TelloError;
          TelloLogger().e("Bazz Error ${bazzError.code} ${bazzError.message}",
              stackTrace: s);

          if (bazzError.code == 99) {
            String serverVersions = "";
            if (bazzError.supportedVersions!.isNotEmpty) {
              bazzError.supportedVersions!.forEach((element) {
                serverVersions += "$element:";
              });
            } else {
              serverVersions = LocalizationService().of().unknownMsg;
            }

            final String message =
                "${LocalizationService().of().yourMobileVersionMsg} ${AppSettings().appVersion} ${LocalizationService().of().supportByServerVersionMsg} $serverVersions";
            SystemDialog.showConfirmDialog(
              title: LocalizationService().of().mobileVersionNotSupportedTitle,
              message: message,
              confirmButtonText: LocalizationService().of().ok,
              confirmCallback: () {
                Get.back();
                if (enableNfcLogin) {
                  _loginWithNFCCode.value = false;
                  _nfcIdentifier$.value = '' as String;
                  startNFCReaderStream();
                  _loadingState.value = ViewState.loading;
                }
              },
            );
          } else if (bazzError.code == 4) {
            SystemDialog.showConfirmDialog(
              title: LocalizationService().of().userAlreadyLoggedInTitle,
              message: LocalizationService().of().userAlreadyLoggedInMsg,
              confirmButtonText: LocalizationService().of().continueAsUser,
              cancelButtonText: LocalizationService().of().cancel,
              confirmCallback: () {
                Get.back();
                performLogin(ignoreActiveSession: true);
                _loadingState.value = ViewState.loading;
              },
              cancelCallback: () {
                Get.back();
                if (enableNfcLogin) {
                  _loginWithNFCCode.value = false;
                  _nfcIdentifier$.value = null as String;
                  startNFCReaderStream();
                }
              },
            );
          } else {
            _loadingState(ViewState.error);
            errorMessage = e.error.message as String;
            if (enableNfcLogin) {
              _loginWithNFCCode.value = false;
              _nfcIdentifier$.value = null as String;
              startNFCReaderStream();
            }
          }
        } else if (e.error is WrongTimeError) {
          _loadingState(ViewState.error);
          errorMessage = e.error.message as String;
          await SystemDialog.showConfirmDialog(
            dismissible: false,
            message: e.error.message as String,
          );
        }
      }

      TelloLogger().i(s.toString());

      return;
    } finally {}
  }

  deviceModel.Device createDevice(Map<String, dynamic> data) {
    if (data['device'] != null) {
      final deviceMap = data['device'] as Map<String, dynamic>;

      if (deviceMap["keysConfig"] != null) {
        return deviceModel.Device.fromObsoleteResponse(deviceMap);
      } else {
        return deviceModel.Device.fromResponse(deviceMap);
      }
    }
    return null!;
  }

  Future<void> loginIntoApp(Map<String, dynamic> data) async {
    final authToken = data['token'] as String;
    final availablePosition = data['availablePosition'];
    final needChangePassword = data['needChangePassword'] as bool;
    Session.updateAndStoreSession(
      authToken: authToken,
      user: RxUser.fromMap(data['userCard'] as Map<String, dynamic>),
      //shift: availablePosition != null ? Shift.fromPosition(availablePosition as Map<String, dynamic>) : null,
      device: createDevice(data),
      groupCount: data['groupCount'] != null ? data['groupCount'] as int : 0,
      authenticationMethod: AuthenticationType.Password, shift: null as Shift,
    );
    NetworkingClient().setBearerToken(authToken);
    _loadingState(ViewState.success);
    _clearInputs();
    Session.user!.faceIdLoginEnabled =
        // ignore: avoid_bool_literals_in_conditional_expressions
        data['enabledFaceRecognition'] != null
            ? data['enabledFaceRecognition'] as bool
            : false;
    if (_enableNfcLogin$.value) {
      NfcManager.instance.stopSession();
      _loginWithNFCCode.value = false;
      _nfcIdentifier$.value = null!;
    }
    if (needChangePassword) {
      Get.toNamed(AppRoutes.changePassword);
    } else if (Session.user!.isCustomer!) {
      await Session.storeCurrentSession();
      Get.offAllNamed(AppRoutes.home);
    } else {
      Get.toNamed(AppRoutes.shiftPositionProfile);
    }
  }

  Future<void> onLogInPressed({bool ignoreActiveSession = false}) async {
    try {
      BackButtonLocker.lockBackButton();
      _loadingState(ViewState.loading);
      final connected = await DataConnectionChecker().isConnectedToInternet;
      if (!connected) {
        _loadingState(ViewState.error);
        errorMessage = DataConnectionChecker().toString();
        throw errorMessage;
      }

      await Session.wipeSession();
      await performLogin();
      _setPasswordVisibility(false);
    } catch (e, s) {
      TelloLogger().e('onLogInPressed error: $e', stackTrace: s);
      _loadingState(ViewState.error);
    } finally {
      if (errorMessage.isEmpty) {
        _loadingState(ViewState.idle);
      }
      BackButtonLocker.unlockBackButton();
    }
  }

  void _clearInputs() {
    usernameController.clear();
    passwordController.clear();
  }
}
