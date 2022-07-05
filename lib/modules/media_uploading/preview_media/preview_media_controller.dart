import 'dart:io';

import 'package:bazz_flutter/modules/media_uploading/choose_media/choose_media_controller.dart';
import 'package:bazz_flutter/modules/media_uploading/media_upload_service.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';

class PreviewMediaController extends GetxController {
  static PreviewMediaController get to => Get.find();

  UploadableMedia? selectedMedia;

  @override
  void onInit() {
    _selectMedia();
    super.onInit();
  }

  void _selectMedia() {
    final availableMedia = MediaUploadService
        .to.allMediaByEventId[ChooseMediaController.to.currentPickingEventId];
    if (availableMedia != null && availableMedia.isNotEmpty) {
      selectedMedia = availableMedia.first;
    } else {
      selectedMedia = ChooseMediaController.to.tempMedia;
    }
  }

  @override
  Future<void> onClose() async {
    if (ChooseMediaController.to.isCameraOnly) {
      final targetFile = File(selectedMedia!.path);
      if (await targetFile.exists()) targetFile.delete();
    }
    super.onClose();
  }

  // ignore: use_setters_to_change_properties
  void setCurrentMedia(UploadableMedia media) {
    if (media.id == selectedMedia!.id) return;

    selectedMedia = media;
    update();
  }

  Future<void> onActionButtonTap() async {
    if (ChooseMediaController.to.isCameraOnly) {
      await ImageGallerySaver.saveFile(selectedMedia!.path);
      Get.back(closeOverlays: true);
    } else {
      Get.until((route) =>
          route.settings.name == AppRoutes.shiftActivities ||
          route.settings.name == AppRoutes.shiftActivitiesStats ||
          route.isFirst);
      MediaUploadService.to
          .uploadAllMediaForId(ChooseMediaController.to.currentPickingEventId!);
    }
  }

  void deleteMedia(int index) {
    MediaUploadService.to
        .deleteSingle(ChooseMediaController.to.currentPickingEventId!, index);
    _selectMedia();
    update();
  }
}
