import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/modules/media_uploading/choose_media/choose_media_controller.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:bazz_flutter/shared_widgets/hawk_fab_menu.dart';
import 'package:camera/camera.dart';
import 'package:circular_countdown_timer/circular_countdown_timer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:image_pickers/image_pickers.dart' as pickers;
import 'package:flutter_spinkit/flutter_spinkit.dart';

class ChooseMediaPage extends GetView<ChooseMediaController> {
  const ChooseMediaPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final mainBody = SafeArea(
      child: Column(
        children: [
          Obx(() {
            return Expanded(
              child: Stack(
                children: [
                  FutureBuilder(
                      future: controller.cameraInitFuture$!(),
                      builder: (context, sn) {
                        return sn.connectionState == ConnectionState.done
                            ? Positioned.fill(
                                child:
                                    CameraPreview(controller.cameraController!))
                            : const SizedBox();
                      }),
                  Positioned(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          padding: const EdgeInsets.symmetric(horizontal: 15),
                          highlightColor: Colors.transparent,
                          icon: const Icon(Icons.arrow_back,
                              color: AppColors.brightText),
                          onPressed: () {
                            Get.back(closeOverlays: true);
                          },
                        ),
                        if (!controller.isCameraOnly)
                          IconButton(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            icon: const Icon(Icons.arrow_forward,
                                color: AppColors.brightText),
                            onPressed: () {
                              Get.toNamed(AppRoutes.previewMedia);
                            },
                          ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        const SizedBox(width: 50),
                        GestureDetector(
                          onLongPress: controller.startRecording,
                          onLongPressUp: controller.stopRecording,
                          child: CircularIconButton(
                            buttonSize: 75,
                            onTap: controller.takePicture,
                            child: Obx(() {
                              if (controller.cameraStatus().isIdle) {
                                return const Icon(
                                  Icons.panorama_fisheye_rounded,
                                  color: AppColors.brightText,
                                  size: 75,
                                );
                              }
                              if (controller.cameraStatus().isPreparing) {
                                return SpinKitFadingCircle(
                                  color: AppColors.loadingIndicator,
                                  size: 80,
                                );
                              }
                              return CircularCountDownTimer(
                                onComplete: controller.stopRecording,
                                isReverse: true,
                                isReverseAnimation: true,
                                duration: AppSettings().maxVideoDurationSec,
                                width: 80,
                                height: 80,
                                textFormat: CountdownTextFormat.S,
                                fillColor: AppColors.error,
                                backgroundColor:
                                    AppColors.error.withOpacity(0.3),
                                ringColor: Colors.transparent,
                                strokeWidth: 10,
                                textStyle: AppTypography.headline6TextStyle
                                    .copyWith(color: AppColors.brightText),
                              );
                            }),
                          ),
                        ),
                        CircularIconButton(
                          buttonSize: 50,
                          onTap: controller.flipCamera,
                          child: const Icon(
                            Icons.flip_camera_ios_outlined,
                            color: AppColors.brightText,
                            size: 30,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
          GestureDetector(
            onTap: Get.back,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Text(
                'Hold for video, tap for photo',
                style: AppTypography.bodyText2TextStyle.copyWith(fontSize: 14),
              ),
            ),
          ),
        ],
      ),
    );
    return Scaffold(
      backgroundColor: Colors.black,
      body: !controller.isCameraOnly
          ? HawkFabMenu(
              alignment: Alignment.bottomLeft,
              fabSize: 50,
              fabColor: Colors.transparent,
              icon: const FaIcon(
                FontAwesomeIcons.photoVideo,
                color: AppColors.brightText,
                size: 25,
              ),
              bottom: 43,
              left: 30,
              items: [
                HawkFabMenuItem(
                  label: 'Photo',
                  ontap: () =>
                      controller.onGalleryTap(pickers.GalleryMode.image),
                  icon: const Icon(
                    Icons.image_outlined,
                    color: AppColors.brightText,
                    size: 30,
                  ),
                  color: Colors.transparent,
                  labelBackgroundColor: Colors.lightBlue,
                  labelColor: Colors.white,
                ),
                HawkFabMenuItem(
                  label: 'Video',
                  ontap: () =>
                      controller.onGalleryTap(pickers.GalleryMode.video),
                  icon: const Icon(
                    Icons.video_collection_outlined,
                    color: AppColors.brightText,
                    size: 30,
                  ),
                  color: Colors.transparent,
                  labelBackgroundColor: Colors.lightBlue,
                  labelColor: Colors.white,
                ),
              ],
              body: mainBody,
            )
          : mainBody,
    );
  }
}
