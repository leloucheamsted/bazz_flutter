import 'package:get/get.dart';
import 'gnss_controller.dart';

class GnssBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(GnssController(), permanent: true);
  }
}
