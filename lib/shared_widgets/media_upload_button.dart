import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/modules/media_uploading/media_upload_service.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/shared_widgets/badge_counter.dart';
import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:bazz_flutter/shared_widgets/system_dialog.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class MediaUploadButton extends StatelessWidget {
  const MediaUploadButton(
      {Key? key,
      required this.controller,
      required this.eventId,
      this.isMandatory = false})
      : super(key: key);

  final String eventId;
  final MediaUploadService controller;
  final bool isMandatory;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MediaUploadService>(
        id: 'button$eventId',
        builder: (controller) {
          return Obx(() {
            final allMedia = controller.allMediaByEventId[eventId] ?? [];
            final avgUploadProgress = allMedia.isNotEmpty
                ? allMedia
                        .map((m) => m.uploadProgress())
                        .reduce((a, b) => a + b) /
                    allMedia.length
                : 0.0;
            final isUploadDeferred = allMedia.any((m) => m.isUploadDeferred());
            return Stack(
              alignment: Alignment.center,
              children: [
                GestureDetector(
                  onTap: () {
                    if (!controller.isProcessingMedia$) return;
                    controller.buildUploadDetailsDialog(eventId);
                  },
                  child: CircularPercentIndicator(
                    radius: 50,
                    percent: avgUploadProgress,
                    progressColor: isUploadDeferred
                        ? AppTheme().colors.disabledButton
                        : AppColors.primaryAccent,
                    center: Text(
                      '${(avgUploadProgress * 100).truncate()}%',
                      style: AppTypography.bodyText4TextStyle.copyWith(
                        fontWeight: FontWeight.w600,
                        color: isUploadDeferred
                            ? AppTheme().colors.disabledButton
                            : AppColors.primaryAccent,
                      ),
                    ),
                    backgroundColor: isUploadDeferred
                        ? AppTheme().colors.disabledButton.withOpacity(0.2)
                        : AppColors.primaryAccent.withOpacity(0.2),
                  ),
                ),
                if (!controller.isProcessingMedia$)
                  CircularIconButton(
                    onTap: () {
                      if (Get.isOverlaysOpen)
                        Get.until((_) => Get.isOverlaysClosed);
                      Get.toNamed(AppRoutes.chooseMedia, arguments: eventId);
                    },
                    color: AppColors.secondaryButton,
                    buttonSize: 40,
                    child: const FaIcon(
                      FontAwesomeIcons.photoVideo,
                      color: AppColors.brightIcon,
                      size: 20,
                    ),
                  ),
                if (!controller.isProcessingMedia$ && allMedia.isNotEmpty) ...[
                  Positioned(
                    top: 0,
                    right: 0,
                    child: BadgeCounter(allMedia.length.toString()),
                  ),
                  Positioned(
                    bottom: 0,
                    left: 0,
                    child: CircularIconButton(
                      color: Colors.redAccent,
                      buttonSize: 22,
                      onTap: () {
                        SystemDialog.showConfirmDialog(
                            title:
                                LocalizationService().of().warning.capitalize,
                            message: LocalizationService()
                                .of()
                                .areYouSureYouWantToDelete,
                            confirmButtonText: LocalizationService().of().ok,
                            cancelButtonText: LocalizationService().of().cancel,
                            confirmCallback: () {
                              Get.back();
                              controller.deleteAllById(eventId);
                            },
                            cancelCallback: Get.back,
                            titleFillColor: null as Color);
                      },
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ],
                if (allMedia.isEmpty && isMandatory)
                  const Positioned(
                    top: 0,
                    right: 0,
                    child: Icon(FontAwesomeIcons.asterisk,
                        color: AppColors.danger, size: 10),
                  ),
              ],
            );
          });
        });
  }
}
