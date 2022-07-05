import 'package:bazz_flutter/modules/home_module/home_repo.dart';
import 'package:bazz_flutter/modules/shift_module/shift_service.dart';
import 'package:get/get.dart';

class ShiftProfilePositionBinding extends Bindings {
  @override
  void dependencies() {
    //TODO: put it only if a user is entering a shift
    // We dispose it manually in HomeController
    Get.put(ShiftService(HomeRepository()),permanent: true);
  }
}
