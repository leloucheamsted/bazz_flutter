import 'package:bazz_flutter/modules/media_uploading/choose_media/choose_media_controller.dart';
import 'package:get/get.dart';

class ChooseMediaBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(ChooseMediaController());
  }
}