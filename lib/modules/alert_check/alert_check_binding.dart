import 'package:bazz_flutter/modules/alert_check/alert_check_controller.dart';
import 'package:bazz_flutter/modules/alert_check/alert_check_repo.dart';
import 'package:get/get.dart';

class AlertCheckBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(AlertCheckController(AlertCheckRepository()));
  }
}