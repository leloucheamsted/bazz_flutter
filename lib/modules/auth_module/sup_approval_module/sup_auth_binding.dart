import 'package:bazz_flutter/modules/auth_module/sup_approval_module/sup_auth_controller.dart';
import 'package:get/get.dart';

class SupervisorAuthBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(SupervisorAuthController());
  }
}
