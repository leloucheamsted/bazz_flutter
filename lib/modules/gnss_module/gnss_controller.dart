import 'package:bazz_flutter/services/logger.dart';
import 'package:get/get.dart';
import 'package:eventify/eventify.dart' as evf;
import 'package:gnss_status/gnss_status.dart';
import 'package:gnss_status/gnss_status_model.dart';

class GnssController extends GetxController {
  static GnssController get to => Get.find();
  RxBool graphView$ = true.obs;
  bool get graphView => graphView$.value;

  set graphView(bool value) {
    graphView$(value);
  }

  @override
  Future<void> onInit() async {

    super.onInit();
  }

  @override
  Future<void> onClose() async {

  }
}