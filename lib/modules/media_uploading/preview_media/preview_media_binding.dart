import 'package:bazz_flutter/modules/media_uploading/preview_media/preview_media_controller.dart';
import 'package:get/get.dart';

class PreviewMediaBinding extends Bindings {
  @override
  void dependencies() {
    Get.put(PreviewMediaController());
  }
}