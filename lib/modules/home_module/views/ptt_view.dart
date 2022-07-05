import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/home_module/widgets/big_round_ptt_button.dart';
import 'package:bazz_flutter/modules/home_module/widgets/big_round_sos_button.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/widgets/history_audio_player.dart';
import 'package:bazz_flutter/modules/home_module/widgets/ptt_button.dart';
import 'package:bazz_flutter/modules/home_module/widgets/sos_button.dart';
import 'package:bazz_flutter/modules/home_module/widgets/status_chip.dart';
import 'package:bazz_flutter/modules/home_module/widgets/transport_stats_page.dart';
import 'package:bazz_flutter/modules/network_jitter/network_jitter_service.dart';
import 'package:bazz_flutter/modules/network_jitter/ui/network_jitter_chart_page.dart';
import 'package:bazz_flutter/modules/network_jitter/ui/network_jitter_o_meter.dart';
import 'package:bazz_flutter/modules/settings_module/settings_controller.dart';
import 'package:circular_menu/circular_menu.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:get/get.dart';

class PttView extends GetView<HomeController> {
  void _incrementEnter(PointerEvent details) {}

  @override
  Widget build(BuildContext context) {
    final pttBody = Stack(
      children: [
        if (MediaQuery.of(context).orientation == Orientation.portrait)
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              //const SizedBox(),
              Flexible(
                flex: GeneralUtils.isSmallScreen() ? 7 : 3,
                child: Padding(
                    padding: GeneralUtils.isSmallScreen()
                        ? const EdgeInsets.fromLTRB(0, 45, 0, 0)
                        : const EdgeInsets.fromLTRB(0, 70, 0, 0),
                    child: const PTTButton()),
              ),
              Flexible(child: Container()),
              //const SizedBox(),
            ],
          )
        else
          Positioned(
            bottom: 10,
            left: (Get.width / 2) - 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: const [
                BigRoundPttButton(),
                SizedBox(
                  width: 50,
                ),
                BigRoundSosButton(),
              ],
            ),
          ),
        Obx(() {
          final streamingState = HomeController.to.txState$.value.state;
          final isPttDisabled = HomeController.to.isPttDisabled;

          final color = () {
            if (isPttDisabled) return AppTheme().colors.disabledButton;

            switch (streamingState) {
              case StreamingState.preparing:
                return Colors.amber;
              case StreamingState.sending:
                return AppColors.pttTransmitting;
              case StreamingState.receiving:
                return AppColors.pttReceiving;
              case StreamingState.cleaning:
                return AppTheme().colors.disabledButton;
              default:
                return AppColors.pttIdle;
            }
          }();

          if (HomeController.to.isRecordingOfflineMessage ||
              streamingState == StreamingState.sending) {
            return Positioned(
              bottom: 1,
              left: (Get.width / 2) - 55,
              child: Text(
                HomeController.to.isRecordingOfflineMessage
                    ? LocalizationService().of().recording.toUpperCase()
                    : streamingState == StreamingState.sending
                        ? LocalizationService().of().broadcasting.toUpperCase()
                        : '',
                textAlign: TextAlign.center,
                style: AppTypography.caption2TextStyle
                    .copyWith(color: color, fontSize: 14),
              ),
            );
          } else {
            return Container();
          }
        }),
        Positioned(
          top: 45,
          left: 13,
          child: Obx(() {
            return controller.servicesInitialized$() &&
                    (SettingsController.to!.showNetworkJitter)
                ? Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: Colors.blueGrey.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: GestureDetector(
                      onTap: () => Get.to(() => const NetworkJitterChartPage()),
                      child: NetworkJitterOMeter(NetworkJitterController.to!),
                    ))
                : const SizedBox();
          }),
        ),
        Obx(() {
          if (!controller.showPtt() &&
              controller.localVideoDisplay.value &&
              AppSettings().videoModeEnabled) {
            return Positioned(
              bottom: 10,
              left: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme().colors.mainBackground,
                  shape: BoxShape.circle,
                  boxShadow: const [
                    BoxShadow(
                      color: AppColors.pttTransmitting,
                      blurRadius: 1,
                      spreadRadius: 1,
                    ),
                  ],
                  border: Border.all(
                      color: AppTheme().colors.mainBackground, width: 2),
                ),
                height: 120,
                width: 120,
                child: ClipOval(
                  child: Container(
                    height: 120,
                    width: 120,
                    color: AppTheme().colors.mainBackground,
                    child: GetBuilder<HomeController>(
                        id: 'localVideoDisplayId',
                        builder: (_) {
                          return FutureBuilder(builder: (context, snapshot) {
                            return Container(
                                width: 90.0,
                                height: 120.0,
                                decoration:
                                    const BoxDecoration(color: Colors.black54),
                                child: RTCVideoView(controller.localRenderer));
                          });
                        },
                        dispose: (_) {}),
                  ),
                ),
              ),
            );
          } else {
            return Container();
          }
        }),
        Obx(() {
          if (!controller.showPtt() && AppSettings().videoModeEnabled) {
            return Positioned(
                bottom: 5,
                left: 5,
                child: CircularIconButton(
                  color: AppColors.secondaryButton,
                  buttonSize: 50,
                  onTap: () {
                    controller.switchCamera();
                  },
                  child: const Icon(
                    Icons.switch_camera_outlined,
                    color: AppColors.brightIcon,
                    size: 30,
                  ),
                ));
          } else {
            return Container();
          }
        }),
        if (AppSettings().videoModeEnabled)
          Positioned(
            bottom: 10,
            left: (Get.width / 2) - 41,
            child: Container(
                width: 82,
                height: 35,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(5)),
                  color: AppColors.primaryAccent.withOpacity(0.2),
                ),
                child: Obx(() {
                  return Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          controller.setShowPtt(val: true);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5)),
                            color: !controller.showPtt()
                                ? Colors.transparent
                                : AppColors.primaryAccent,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: Text(
                            'PTT',
                            style: controller.showPtt()
                                ? AppTheme().typography.buttonTextStyle
                                : AppTheme()
                                    .typography
                                    .buttonTextStyle
                                    .copyWith(color: AppColors.primaryAccent),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          controller.setShowPtv(val: false);
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5)),
                            color: controller.showPtt()
                                ? Colors.transparent
                                : AppColors.primaryAccent,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: Text(
                            'PTV',
                            style: !controller.showPtt()
                                ? AppTheme().typography.buttonTextStyle
                                : AppTheme()
                                    .typography
                                    .buttonTextStyle
                                    .copyWith(color: AppColors.primaryAccent),
                          ),
                        ),
                      ),
                    ],
                  );
                })),
          ),
        Obx(() {
          if (controller.groups.length > 1 &&
              (Session.isSupervisor || Session.isManager)) {
            return Positioned(
              top: 10,
              left: (Get.width / 2) - 55,
              child: Container(
                  height: 35,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.all(Radius.circular(5)),
                    color: AppColors.primaryAccent.withOpacity(0.2),
                  ),
                  child: Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          controller.removeAllGroup();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5)),
                            color: controller.isAllGroupSelected
                                ? Colors.transparent
                                : AppColors.primaryAccent,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: Text(
                            LocalizationService().of().group.toUpperCase(),
                            style: !controller.isAllGroupSelected
                                ? AppTheme().typography.buttonTextStyle
                                : AppTheme()
                                    .typography
                                    .buttonTextStyle
                                    .copyWith(color: AppColors.primaryAccent),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          controller.setAllGroup();
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5)),
                            color: !controller.isAllGroupSelected
                                ? Colors.transparent
                                : AppColors.primaryAccent,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: Text(
                            LocalizationService().of().all.toUpperCase(),
                            style: controller.isAllGroupSelected
                                ? AppTheme().typography.buttonTextStyle
                                : AppTheme()
                                    .typography
                                    .buttonTextStyle
                                    .copyWith(color: AppColors.primaryAccent),
                          ),
                        ),
                      ),
                    ],
                  )),
            );
          } else {
            return Container();
          }
        }),
        Positioned(
          top: 10,
          left: 10,
          child: SizedBox(
            height: 30,
            child: Obx(() {
              if (controller.servicesNotInitialized$) return const SizedBox();

              Color color;
              String text;
              if (controller.isMediaOnline && controller.isOnline$.value) {
                final jitter = NetworkJitterController.to?.jitter$ ?? 0;
                color = jitter > 100
                    ? AppColors.error
                    : jitter > 30
                        ? AppColors.pttIdle
                        : AppColors.primaryAccent;
                text = "AppLocalizations.of(context).online";
              } else {
                color = AppColors.offline;
                text = "AppLocalizations.of(context).offline";
              }
              // return Padding(
              //     padding: const EdgeInsets.symmetric(horizontal: 20),
              //     child: StatusChip(color: color, text: text);
              // );
              return StatusChip(color: color, text: text);
            }),
          ),
        ),
        if (MediaQuery.of(context).orientation == Orientation.portrait)
          Positioned(
              bottom: 2,
              right: 2,
              child: SizedBox(
                width: Get.width * 0.25,
                height: Get.width * 0.25,
                child: SosButton(),
              ))
        else
          Container(),
        Positioned(
          top: 10,
          right: 10,
          child: CircularIconButton(
            color: AppColors.secondaryButton,
            buttonSize: 50,
            onTap: () {
              Get.toNamed(AppRoutes.chooseMedia);
            },
            child: const Icon(
              Icons.camera_alt_outlined,
              color: AppColors.brightIcon,
              size: 30,
            ),
          ),
        ),
        /* if (AppSettings().enableVideoChatService)
        Obx(() => Positioned(
                bottom: -15,
                left: -15,
                child: PortalEntry(
                  visible: controller.isAdminUsersPopupOpen(),
                  portal: _buildAdminUsersPopup(),
                  portalAnchor: const Alignment(-1.0, -1),
                  childAnchor: Alignment.topRight,
                  closeDuration: const Duration(milliseconds: 100),
                  child: ObxValue<RxBool>(
                    (isPressed) {
                      return Listener(
                        onPointerDown: (_) {
                          isPressed(true);
                        },
                        onPointerUp: (_) {
                          isPressed(false);
                        },
                        child: Stack(children: [
                          SizedBox(
                              height: 100,
                              width: 100,
                              child: Center(
                                  child: GestureDetector(
                                    onTap: ()=>   controller.openVideoPeerToAdminUser(),
                                      child: Container(
                                height: 52,
                                width: 52,
                                decoration: BoxDecoration(
                                  color: AppColors.error,
                                  shape: BoxShape.circle,
                                  boxShadow: controller.adminUsers.isEmpty
                                      ? null
                                      : [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 2,
                                            spreadRadius: isPressed() ? 1 : 2,
                                          ),
                                        ],
                                  border: Border.all(color: AppTheme().colors.mainBackground, width: 2),
                                ),
                                child: const Icon(Icons.video_call, color: AppColors.brightIcon, size: 32),
                              )))),
                          if (controller.activeAdminUser?.avatar?.isNotEmpty ?? false)
                            Positioned(
                                top: 0,
                                left: 50,
                                child: ClipOval(
                                    child: Container(
                                        color: AppTheme().colors.selectedLI,
                                        child: GestureDetector(
                                          behavior: HitTestBehavior.opaque,
                                          onTap: () async{
                                            await controller.fetchAdminUsersList();
                                            Logger().log("controller.isAdminUsersPopupOpen");
                                            controller.isAdminUsersPopupOpen.toggle();
                                          },
                                          child: SizedBox(
                                              height: 42,
                                              width: 42,
                                              child: controller.activeAdminUser?.avatar?.isNotEmpty ?? false
                                                  ? CachedNetworkImage(imageUrl: controller.activeAdminUser.avatar)
                                                  : null),
                                        )))),
                        ]),
                      );
                    },
                    false.obs,
                  ),
                  //),
                ),
              )),*/
        /*if (!AppSettings().enableVideoChatService)
          Positioned(
            bottom: 10,
            left: 10,
            child: CircularIconButton(
              color: AppColors.error,
              buttonSize: 50,
              onTap: controller.openVideoPeerToAdminUser,
              child: const Icon(Icons.video_call, color: AppColors.brightIcon, size: 36),
            ),
          )
        else
          Container(),*/
        Obx(() => SettingsController.to!.showTransportStats
            ? const Positioned(bottom: 1, left: 1, child: TransportStatsPage())
            : Container()),
      ],
    );
    return Column(
      children: [
        //TimerAndStatusBar(controller: controller),
        Expanded(
          child: pttBody,
        ),
        HistoryAudioPlayer(),
      ],
    );
  }

  Widget _buildAdminUsersPopup() {
    TelloLogger().i("_buildAdminUsersPopup");
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: Get.height * 0.6,
        maxWidth: Get.width * 0.5,
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: controller.isAdminUsersPopupOpen() ? 1 : 0,
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme().colors.popupBg,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                spreadRadius: 2,
                blurRadius: 3,
              ),
            ],
            borderRadius: const BorderRadius.all(Radius.circular(7)),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            itemBuilder: (_, i) {
              final admin = controller.adminUsers[i];
              return GestureDetector(
                onTap: () {
                  controller.isAdminUsersPopupOpen(false);
                  controller.activeAdminUser = admin;
                },
                child: SizedBox(
                  height: 45,
                  child: Row(
                    children: [
                      ClipOval(
                        child: Container(
                          height: Get.height >
                                  AppSettings().highResolutionDeviceDensity
                              ? 44
                              : 40,
                          width: Get.height >
                                  AppSettings().highResolutionDeviceDensity
                              ? 44
                              : 40,
                          color: AppTheme().colors.selectedLI,
                          child: FittedBox(
                              child: admin.avatar != null &&
                                      admin.avatar.isNotEmpty
                                  ? CachedNetworkImage(imageUrl: admin.avatar)
                                  : const Icon(
                                      Icons.account_circle,
                                      color: AppColors.primaryAccent,
                                    )),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                admin.fullName!,
                                style: AppTheme()
                                    .typography
                                    .listItemTitleStyle
                                    .copyWith(height: 1.2),
                                maxLines: 1,
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) => const Divider(),
            itemCount: controller.adminUsers.length,
          ),
        ),
      ),
    );
  }
}
