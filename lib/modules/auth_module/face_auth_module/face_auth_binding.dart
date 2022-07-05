import 'package:get/get.dart';
import 'package:get/get_instance/get_instance.dart';
import 'face_auth_controller.dart';

class FaceAuthBinding extends Bindings {
  @override
  void dependencies() {
    // Get.put(AuthController());
    Get.put(FaceAuthController());
  }
}
