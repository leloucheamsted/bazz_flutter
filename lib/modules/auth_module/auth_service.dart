import 'dart:ui';

import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/auth_module/auth_repo.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/shared_widgets/system_dialog.dart';
import 'package:get/get.dart';

class AuthService extends GetxService {
  static AuthService get to => Get.find();

  static Future<void> throwToLogin(String message,
      [VoidCallback? callback]) async {
    await SystemDialog.showConfirmDialog(
      dismissible: false,
      title: LocalizationService().of().logout,
      message: message,
      confirmButtonText: LocalizationService().of().ok,
      confirmCallback: callback ?? () => AuthService.to.logOut(locally: true),
    );
  }

  Future<void> logOut({bool locally = false}) async {
    try {
      if (!locally) await AuthRepository().logOut();
      await Session.wipeSession();
      AppSettings().resetIsUpdatedCompleter();
      if (Get.currentRoute != AppRoutes.login) Get.offAllNamed(AppRoutes.login);
    } catch (e, s) {
      TelloLogger().e('error logging out: $e', stackTrace: s);
      rethrow;
    }
  }
}
