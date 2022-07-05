import 'package:get/get.dart';

import 'statistics_controller.dart';

class StatisticsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(StatisticsController(), permanent: true);
  }
}
