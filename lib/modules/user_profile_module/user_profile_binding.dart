import 'package:get/get.dart';

import 'user_profile_controller.dart';

class UserProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(UserProfileController(), permanent: true);
  }
}
