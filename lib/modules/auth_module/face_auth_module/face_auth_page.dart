import 'dart:io';
import 'dart:math' as math;

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/modules/auth_module/face_auth_module/face_painter.dart';
import 'package:bazz_flutter/shared_widgets/loader.dart';
import 'package:bazz_flutter/shared_widgets/primary_button.dart';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

import 'face_auth_controller.dart';

class FaceAuthPage extends GetView<FaceAuthController> {
  const FaceAuthPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final double mirror = math.pi;

    return Scaffold(
      backgroundColor: AppTheme().colors.mainBackground,
      appBar: AppBar(
        backgroundColor: AppTheme().colors.appBar,
        iconTheme: const IconThemeData(
          color: AppColors.brightText,
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(LayoutConstants.pagePadding),
        child: Column(
          children: [
            Text(
              controller.pictureTaken
                  ? "AppLocalizations.of(context).processingYourFace"
                  : controller.fromAlertCheck
                      ? "AppLocalizations.of(context).quizScanFace"
                      : " AppLocalizations.of(context).loginByYourFaceScan",
              style: AppTheme().typography.authCaptionStyle,
            ),
            const SizedBox(height: 10),
            Obx(() => controller.loadingState == ViewState.error
                ? Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded,
                          size: 18, color: AppColors.error),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          controller.errorMessage,
                          style: AppTheme().typography.errorTextStyle,
                        ),
                      ),
                    ],
                  )
                : const SizedBox()),
            const SizedBox(height: 10),
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12.0),
                child: Container(
                  decoration: const BoxDecoration(
                    borderRadius: BorderRadius.all(Radius.circular(10)),
                  ),
                  child: Obx(
                    () => FutureBuilder<void>(
                      future: controller.initializeControllerFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return Stack(
                            children: [
                              Obx(() => controller.pictureTaken
                                  ? Positioned.fill(
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.rotationY(mirror),
                                        child: Image.file(
                                            File(controller.imagePath!),
                                            fit: BoxFit.cover),
                                      ),
                                    )
                                  : Positioned.fill(
                                      child: CameraPreview(controller
                                          .cameraService.cameraController))),
                              Obx(() => CustomPaint(
                                    size: controller.imageSize,
                                    painter: FacePainter(
                                        face: controller.faceDetected,
                                        imageSize: controller.imageSize),
                                  )),
                            ],
                          );
                        } else {
                          return const Center(
                              child: CircularProgressIndicator());
                        }
                      },
                    ),
                  ),
                ),
              ),
            ),
            GetX<FaceAuthController>(
              builder: (_) {
                if (controller.loadingState == ViewState.loading) {
                  Loader.show(context, themeData: null as ThemeData);
                } else {
                  Loader.hide();
                }
                return const SizedBox();
              },
            ),
            const SizedBox(height: 20),
            Obx(() => PrimaryButton(
                  text: !controller.fromAlertCheck
                      ? "AppLocalizations.of(context).loginWithFace"
                      : " AppLocalizations.of(context).send",
                  onTap:
                      controller.bottomSheetEnabled ? controller.onShot : null!,
                  color: AppColors.secondaryAccent,
                  icon: const Image(
                    image: AssetImage('assets/images/scan_ico.png'),
                    height: 15,
                    width: 15,
                  ),
                ))
          ],
        ),
      ),
    );
  }
}
