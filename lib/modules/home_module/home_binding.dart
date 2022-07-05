import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/alert_check/alert_check_service.dart';
import 'package:bazz_flutter/modules/chat/chat_controller.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/home_repo.dart';
import 'package:bazz_flutter/modules/home_module/sos_service.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_controller.dart';
import 'package:bazz_flutter/modules/media_uploading/media_upload_service.dart';
import 'package:bazz_flutter/modules/message_history/message_history_controller.dart';
import 'package:bazz_flutter/modules/message_history/message_upload_service.dart';
import 'package:bazz_flutter/modules/p2p_video/video_chat_controller.dart';
import 'package:bazz_flutter/modules/shift_module/shift_service.dart';
import 'package:bazz_flutter/modules/synchronization/sync_service.dart';
import 'package:get/get.dart';

class HomeBinding extends Bindings {
  @override
  Future<void> dependencies() async {
    //FIXME: changing order breaks the app, because they depend on each other
    // We dispose it manually in HomeController
    if (Session.hasShiftStarted!)
      Get.put(ShiftService(HomeRepository()), permanent: true);
    Get.put(HomeController());
    Get.put(MessageUploadService());
    Get.put(SyncService());
    if (Session.isSupervisor || Session.isCustomer) Get.put(ChatController());
    if (!Session.user!.isCustomer! && AppSettings().enableVideoChatService)
      Get.put(VideoChatController());
    if (Session.isSupervisor) Get.put(FlutterMapController());
    Get.put(SosService());
    Get.put(MessageHistoryController());
    if (Session.hasShiftStarted! && Session.shift!.alertCheckConfig != null) {
      Get.put(AlertCheckService());
    }
    Get.put(MediaUploadService());
  }
}
