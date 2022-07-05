import 'package:bazz_flutter/modules/shift_activities/shift_activities_stats/shift_activities_stats_controller.dart';
import 'package:get/get.dart';

class ShiftActivitiesStatsBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ShiftActivitiesStatsController());
  }
}