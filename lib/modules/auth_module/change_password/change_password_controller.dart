import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/auth_module/change_password/change_password_repo.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/utils/back_button_locker.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class ChangePasswordController extends GetxController {
  final _repo = ChangePasswordRepository();
  final loadingState = ViewState.idle.obs;

  final TextEditingController newPwdController = TextEditingController();
  final TextEditingController confirmNewPwdController = TextEditingController();

  final canProceed = false.obs;

  @override
  void onInit() {
    newPwdController.addListener(_inputListener);
    confirmNewPwdController.addListener(_inputListener);
    super.onInit();
  }

  @override
  void onClose() {
    newPwdController.dispose();
    confirmNewPwdController.dispose();
    super.onClose();
  }

  void _inputListener() {
    canProceed.value = newPwdController.text.isNotEmpty &&
        confirmNewPwdController.text == newPwdController.text;
  }

  Future<void> onProceedPressed() async {
    BackButtonLocker.lockBackButton();
    try {
      loadingState(ViewState.loading);
      await _repo.updatePassword(newPwdController.text);
      if (Session.user!.isCustomer!) {
        await Session.storeCurrentSession();
        Get.offAllNamed(AppRoutes.home);
      } else {
        Get.offAndToNamed(AppRoutes.shiftPositionProfile);
      }
    } catch (e, s) {
      TelloLogger().e('onLogInPressed error: $e', stackTrace: s);
      loadingState(ViewState.error);
    } finally {
      BackButtonLocker.unlockBackButton();
    }
  }
}
