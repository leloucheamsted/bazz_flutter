import 'package:get/get.dart';

import 'device_outputs_controller.dart';

class DeviceOutputsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(DeviceOutputsController(), permanent: true);
  }
}
