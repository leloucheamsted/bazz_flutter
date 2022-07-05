import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/modules/media_uploading/media_upload_service.dart';
import 'package:bazz_flutter/services/event_handling_service.dart';
import 'package:bazz_flutter/shared_widgets/media_upload_button.dart';
import 'package:bazz_flutter/shared_widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_svg/parser.dart';
import 'package:get/get.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

class CreateNewEventDrawer extends StatelessWidget {
  const CreateNewEventDrawer(this.controller, {Key? key}) : super(key: key);

  final EventHandlingService controller;

  @override
  Widget build(BuildContext context) {
    return SlidingUpPanel(
      controller: controller.newEventDrawerController,
      defaultPanelState: controller.currentUserEvent$ != null
          ? PanelState.OPEN
          : PanelState.CLOSED,
      isDraggable: false,
      color: Colors.transparent,
      boxShadow: const [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 3,
          spreadRadius: 3,
        )
      ],
      minHeight: 0,
      slideDirection: SlideDirection.DOWN,
      maxHeight: 200,
      onPanelOpened: controller.onPanelOpened,
      onPanelClosed: controller.onPanelClosed,
      panel: Column(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              color: AppTheme().colors.newEventDrawer,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Obx(() {
                        if (controller.currentUserEvent$ == null)
                          return const SizedBox();

                        final iconId = controller.currentUserEvent$.iconCfg.id;
                        final iconUrl =
                            controller.currentUserEvent$.iconCfg.url;
                        return Row(
                          children: [
                            SizedBox(
                              height: 40,
                              width: 40,
                              child: controller
                                      .currentUserEvent$.iconCfg.iconAssetExists
                                  ? SvgPicture.asset(
                                      'assets/images/events/$iconId.svg')
                                  : SvgPicture.network(
                                      iconUrl,
                                      placeholderBuilder: (_) {
                                        return SvgPicture.asset(
                                            'assets/images/events/default.svg');
                                      },
                                    ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                                controller.currentUserEvent$.title
                                    .toUpperCase(),
                                style: AppTheme().typography.bgText3Style),
                          ],
                        );
                      }),
                      GetBuilder<EventHandlingService>(
                        id: 'mediaUploadButton',
                        builder: (controller) {
                          return controller.currentEventMediaUploadId != null
                              ? MediaUploadButton(
                                  controller: MediaUploadService.to,
                                  eventId:
                                      controller.currentEventMediaUploadId!,
                                )
                              : const SizedBox();
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  _buildTextInput(context),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      GetBuilder<MediaUploadService>(
                          id: 'button${controller.currentEventMediaUploadId}',
                          builder: (mediaUploadService) {
                            final allMedia =
                                mediaUploadService.allMediaByEventId[
                                    controller.currentEventMediaUploadId];
                            final isUploadDeferred =
                                allMedia?.any((m) => m.isUploadDeferred()) ??
                                    true;
                            final isAllMediaUploaded =
                                allMedia?.every((m) => m.isUploaded) ?? true;
                            return PrimaryButton(
                              height: 40,
                              text: "AppLocalizations.of(context).send",
                              onTap: isUploadDeferred || isAllMediaUploaded
                                  ? controller.sendEvent
                                  : null!,
                              icon: null as Icon,
                            );
                          }),
                      PrimaryButton(
                        height: 40,
                        color: AppColors.danger,
                        text: "AppLocalizations.of(context).cancel",
                        onTap: controller.onCancel,
                        icon: null as Icon,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // _buildDrawerPuller(),
        ],
      ),
    );
  }

  Widget _buildTextInput(BuildContext context) {
    const inputBorder = OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.inputBorder),
      borderRadius: BorderRadius.all(Radius.circular(7)),
    );
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(7)),
      child: TextField(
        enabled: true,
        controller: controller.newEventCommentController,
        scrollPhysics: const AlwaysScrollableScrollPhysics(),
        style: AppTheme().typography.inputTextStyle,
        decoration: InputDecoration(
          hintText: " AppLocalizations.of(context).yourComment.capitalize",
          hintStyle: AppTheme().typography.inputTextStyle,
          enabledBorder: inputBorder,
          focusedBorder: inputBorder,
          fillColor: AppTheme().colors.inputBg,
          filled: true,
          contentPadding: const EdgeInsets.all(5),
        ),
        keyboardType: TextInputType.multiline,
        minLines: 3,
        maxLines: 3,
      ),
    );
  }
}
