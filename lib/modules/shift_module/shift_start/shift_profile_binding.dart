import 'package:bazz_flutter/modules/home_module/home_repo.dart';
import 'package:bazz_flutter/modules/shift_module/shift_service.dart';
import 'package:get/get.dart';

class ShiftProfileBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ShiftService(HomeRepository()), permanent: true);
  }
}
