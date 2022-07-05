import 'package:bazz_flutter/modules/p2p_video/video_chat_controller.dart';
import 'package:get/get.dart';
import 'package:get/get_instance/get_instance.dart';

class VideoChatBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut(() => VideoChatController());
  }
}
