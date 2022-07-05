import 'package:bazz_flutter/modules/auth_module/change_password/change_password_controller.dart';
import 'package:get/get.dart';

class ChangePasswordBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ChangePasswordController());
  }
}