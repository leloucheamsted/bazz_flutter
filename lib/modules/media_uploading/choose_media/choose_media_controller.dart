import 'dart:async';
import 'dart:io';

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/modules/media_uploading/media_upload_service.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:camera/camera.dart';
import 'package:get/get.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:image_pickers/image_pickers.dart' as pickers;
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:path_provider/path_provider.dart';

class ChooseMediaController extends GetxController {
  static ChooseMediaController get to => Get.find();

  CameraController? cameraController;
  List<CameraDescription>? cameras;
  CameraDescription? currentCamera;

  late Rx<Future>? cameraInitFuture$;
  Completer? startVideoRecordingComplete;

  Rx<CameraStatus> cameraStatus = CameraStatus.idle.obs;
  String? currentPickingEventId;

  ///used in cameraOnly mode
  UploadableMedia? tempMedia;

  bool get isCameraOnly => currentPickingEventId == null;

  @override
  Future<void> onInit() async {
    currentPickingEventId ??= Get.arguments as String;
    cameras = await availableCameras();

    //FIXME: if we choose back camera during init, it won't init for some reason
    currentCamera = cameras!.firstWhere((CameraDescription camera) =>
        camera.lensDirection == CameraLensDirection.back);

    cameraController = CameraController(currentCamera!, ResolutionPreset.medium,
        imageFormatGroup: ImageFormatGroup.jpeg);

    cameraInitFuture$!(cameraController!.initialize());

    super.onInit();
  }

  @override
  void onClose() {
    cameraController?.dispose();
    super.onClose();
  }

  Future<void> onGalleryTap(pickers.GalleryMode galleryMode) async {
    final media =
        MediaUploadService.to.allMediaByEventId[currentPickingEventId] ?? [];
    final assets = await pickers.ImagePickers.pickerPaths(
      galleryMode: galleryMode,
      selectCount: AppSettings().maxMediaToAdd - media.length,
      showGif: false,
    );
    final List<UploadableMedia> mediaToAdd = [];
    if (assets != null) {
      for (final asset in assets) {
        //TODO: generate proper thumbnail of a smaller size, currently it's the original image
        final media = UploadableMedia(
          path: asset.path!,
          thumbPath: asset.thumbPath,
          parentEventId: currentPickingEventId!,
        );
        mediaToAdd.add(media);
      }
    }

    MediaUploadService.to.addAllMedia(currentPickingEventId!, mediaToAdd);
  }

  Future<void> startRecording() async {
    if (cameraStatus().isPreparing ||
        cameraStatus().isRecording ||
        !_canAddMedia()) return;

    try {
      cameraStatus(CameraStatus.preparing);
      startVideoRecordingComplete = Completer();
      await cameraController!.startVideoRecording();
      cameraStatus(CameraStatus.recording);
      //If a recording is too short, will get an error in stopRecording(), hence the delay. You can play with it
      await 1.seconds.delay();
      startVideoRecordingComplete!.complete();
    } catch (e, s) {
      cameraStatus(CameraStatus.idle);
      TelloLogger()
          .e('ChooseMediaController startRecording() error: $e', stackTrace: s);
    }
  }

  Future<void> stopRecording() async {
    try {
      await startVideoRecordingComplete!.future;
      cameraStatus(CameraStatus.preparing);
      final video = await cameraController!.stopVideoRecording();
      if (isCameraOnly) {
        tempMedia = UploadableMedia(
          path: video.path,
          parentEventId: currentPickingEventId!,
        );
      } else {
        final tempDir = await getTemporaryDirectory();
        final thumbnailPath = '${tempDir.path}/thumbnail_of_${video.name}';
        final thumbnailData = await VideoThumbnail.thumbnailData(
          video: video.path,
          maxHeight: 100,
        );
        File(thumbnailPath).writeAsBytesSync(thumbnailData!);
        await ImageGallerySaver.saveFile(video.path);
        MediaUploadService.to.addAllMedia(currentPickingEventId!, [
          UploadableMedia(
            path: video.path,
            thumbPath: thumbnailPath,
            parentEventId: currentPickingEventId!,
          )
        ]);
      }
    } catch (e, s) {
      TelloLogger()
          .e('ChooseMediaController stopRecording() error: $e', stackTrace: s);
    } finally {
      cameraStatus(CameraStatus.idle);
    }

    Get.toNamed(AppRoutes.previewMedia);
  }

  Future<void> takePicture() async {
    if (cameraStatus().isPreparing ||
        cameraStatus().isRecording ||
        !_canAddMedia()) return;

    final picture = await cameraController!.takePicture();

    if (isCameraOnly) {
      tempMedia = UploadableMedia(
        path: picture.path,
        parentEventId: currentPickingEventId!,
      );
    } else {
      await ImageGallerySaver.saveFile(picture.path);
      MediaUploadService.to.addAllMedia(currentPickingEventId!, [
        UploadableMedia(
          path: picture.path,
          thumbPath: picture.path,
          parentEventId: currentPickingEventId!,
        )
      ]);
    }
    Get.toNamed(AppRoutes.previewMedia);
  }

  bool _canAddMedia() {
    if (isCameraOnly) return true;

    final allMediaByEventId =
        MediaUploadService.to.allMediaByEventId[currentPickingEventId] ?? [];

    if (allMediaByEventId.length < AppSettings().maxMediaToAdd) {
      return true;
    } else {
      Get.showSnackbar(
        GetBar(
          backgroundColor: AppColors.error,
          message:
              'You can add only ${AppSettings().maxMediaToAdd} items in total!',
        ),
      );
      return false;
    }
  }

  Future<void> flipCamera() async {
    await cameraController!.dispose();
    CameraDescription nextCamera;
    nextCamera = cameras!.firstWhere((CameraDescription camera) =>
        currentCamera!.lensDirection == CameraLensDirection.back
            ? camera.lensDirection == CameraLensDirection.front
            : camera.lensDirection == CameraLensDirection.back);

    cameraController = CameraController(
      nextCamera,
      ResolutionPreset.high,
    );

    cameraInitFuture$!(cameraController!.initialize());
    currentCamera = nextCamera;
  }
}

enum CameraStatus {
  idle,
  preparing,
  recording,
}

extension CameraStatusExt on CameraStatus {
  bool get isIdle => this == CameraStatus.idle;
  bool get isPreparing => this == CameraStatus.preparing;
  bool get isRecording => this == CameraStatus.recording;
}
