import 'dart:io';

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/modules/media_uploading/choose_media/choose_media_controller.dart';
import 'package:bazz_flutter/modules/media_uploading/media_upload_service.dart';
import 'package:bazz_flutter/modules/media_uploading/preview_media/preview_media_controller.dart';
import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_viewer/video_viewer.dart';

class PreviewMediaPage extends GetView<PreviewMediaController> {
  const PreviewMediaPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final parentEventId = ChooseMediaController.to.currentPickingEventId;
    final media = MediaUploadService.to.allMediaByEventId[parentEventId] ?? [];
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: GetBuilder<PreviewMediaController>(
          builder: (_) {
            return Column(
              children: [
                Expanded(
                  child: Stack(
                    children: [
                      if (controller.selectedMedia != null)
                        controller.selectedMedia!.isVideo
                            ? Center(
                                child: VideoViewer(
                                  key: UniqueKey(),
                                  controller: VideoViewerController()
                                    ..showAndHideOverlay(true),
                                  source: {
                                    "1": VideoSource(
                                      video: VideoPlayerController.file(
                                          File(controller.selectedMedia!.path)),
                                    ),
                                  },
                                  style: VideoViewerStyle(
                                    settingsStyle: SettingsMenuStyle(
                                        paddingBetweenMainMenuItems: 10),
                                  ),
                                ),
                              )
                            : Center(
                                child: InteractiveViewer(
                                  child: Image.file(
                                    File(controller.selectedMedia!.path),
                                    fit: BoxFit.contain,
                                    errorBuilder: (_, e, s) =>
                                        const Icon(Icons.broken_image),
                                    frameBuilder: (BuildContext context,
                                        Widget? child,
                                        int? frame,
                                        bool wasSynchronouslyLoaded) {
                                      if (wasSynchronouslyLoaded) {
                                        return child!;
                                      }
                                      return AnimatedOpacity(
                                        opacity: frame == null ? 0 : 1,
                                        duration:
                                            const Duration(milliseconds: 500),
                                        curve: Curves.easeOut,
                                        child: child,
                                      );
                                    },
                                  ),
                                ),
                              )
                      else
                        Center(
                          child: Text(
                            'No media available',
                            style: AppTypography.subtitle7TextStyle
                                .copyWith(fontWeight: FontWeight.w500),
                          ),
                        ),
                      Positioned(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              highlightColor: Colors.transparent,
                              icon: const Icon(Icons.arrow_back,
                                  color: AppColors.brightText),
                              onPressed: () {
                                Get.back(closeOverlays: true);
                              },
                            ),
                            CircularIconButton(
                              color: AppColors.primaryAccent.withOpacity(0.8),
                              buttonSize: 50,
                              onTap: controller.onActionButtonTap,
                              child: Icon(
                                ChooseMediaController.to.isCameraOnly
                                    ? Icons.save_rounded
                                    : Icons.cloud_upload_outlined,
                                color: AppColors.brightText,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (media.isNotEmpty)
                  Container(
                    height: 100,
                    padding: const EdgeInsets.only(top: 10),
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemBuilder: (_, i) {
                        final currentMedia = MediaUploadService
                            .to.allMediaByEventId[parentEventId]![i];
                        final mediaFile = File(currentMedia.path);
                        final thumbnailFile = File(currentMedia.thumbPath);
                        final noFile = !mediaFile.existsSync();
                        if (noFile) return const SizedBox();

                        return GestureDetector(
                          onTap: () => controller.setCurrentMedia(currentMedia),
                          child: Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: currentMedia.path ==
                                        controller.selectedMedia!.path
                                    ? AppColors.primaryAccent
                                    : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            child: currentMedia.isImage
                                ? Stack(
                                    children: [
                                      Image.file(
                                        thumbnailFile,
                                        frameBuilder: (context, child, frame,
                                            wasSynchronouslyLoaded) {
                                          if (wasSynchronouslyLoaded) {
                                            return child;
                                          }
                                          return AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 250),
                                            child: frame != null
                                                ? child
                                                : const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 5),
                                                    child: Center(
                                                        child:
                                                            CircularProgressIndicator()),
                                                  ),
                                          );
                                        },
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: CircularIconButton(
                                          buttonSize: 20,
                                          onTap: () =>
                                              controller.deleteMedia(i),
                                          child: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: AppColors.error,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  )
                                : Stack(
                                    alignment: Alignment.center,
                                    children: [
                                      Image.file(
                                        thumbnailFile,
                                        fit: BoxFit.cover,
                                        errorBuilder: (_, e, s) =>
                                            const Icon(Icons.broken_image),
                                        frameBuilder: (BuildContext context,
                                            Widget? child,
                                            int? frame,
                                            bool wasSynchronouslyLoaded) {
                                          if (wasSynchronouslyLoaded) {
                                            return child!;
                                          }
                                          return AnimatedSwitcher(
                                            duration: const Duration(
                                                milliseconds: 250),
                                            child: frame != null
                                                ? child
                                                : const Padding(
                                                    padding:
                                                        EdgeInsets.symmetric(
                                                            horizontal: 5),
                                                    child: Center(
                                                        child:
                                                            CircularProgressIndicator()),
                                                  ),
                                          );
                                        },
                                      ),
                                      Positioned(
                                        child: ClipOval(
                                          child: Container(
                                            alignment: Alignment.center,
                                            height: 30,
                                            width: 30,
                                            color: Colors.black38,
                                            child: const Icon(
                                              Icons.play_arrow_rounded,
                                              color: Colors.white,
                                              size: 20,
                                            ),
                                          ),
                                        ),
                                      ),
                                      Positioned(
                                        top: 0,
                                        right: 0,
                                        child: CircularIconButton(
                                          buttonSize: 20,
                                          onTap: () =>
                                              controller.deleteMedia(i),
                                          child: const Icon(
                                            Icons.delete_outline_rounded,
                                            color: AppColors.error,
                                            size: 20,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                          ),
                        );
                      },
                      separatorBuilder: (_, i) => const SizedBox(
                        width: 3,
                      ),
                      itemCount: MediaUploadService
                          .to
                          .allMediaByEventId[
                              ChooseMediaController.to.currentPickingEventId]!
                          .length,
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }
}
