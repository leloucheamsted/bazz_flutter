import 'package:get/get.dart';
import 'package:get/get_instance/get_instance.dart';
import 'domain_controller.dart';

class DomainBinding extends Bindings {
  @override
  void dependencies() {
    // Get.put(AuthController());
    Get.put(DomainController());
  }
}
