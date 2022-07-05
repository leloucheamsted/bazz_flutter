import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/modules/home_module/home_page.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_controller.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_helper.dart';
import 'package:bazz_flutter/modules/home_module/widgets/history_audio_player.dart';
import 'package:bazz_flutter/modules/home_module/widgets/bordered_icon_button.dart';
import 'package:bazz_flutter/modules/home_module/widgets/bottom_nav_bar.dart';
import 'package:bazz_flutter/modules/home_module/widgets/custom_app_bar.dart';
import 'package:bazz_flutter/modules/home_module/widgets/big_round_ptt_button.dart';
import 'package:bazz_flutter/modules/home_module/widgets/big_round_sos_button.dart';
import 'package:bazz_flutter/services/entities_history_tracking.dart';
import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:bazz_flutter/utils/flutter_custom_info_window.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:get/get.dart';

class FlutterMapFullscreenPage extends GetView<FlutterMapController> {
  final bool showBack;

  const FlutterMapFullscreenPage({this.showBack = true});

  @override
  Widget build(BuildContext context) {
    return Portal(
        child: GetX<FlutterMapController>(
      builder: (controller) {
        return Container(
          decoration: BoxDecoration(
            border: EntitiesHistoryTracking().trackingIsOpened
                ? Border.all(color: AppColors.error, width: 2)
                : Border.all(color: AppColors.error, width: 0),
          ),
          child: Scaffold(
            body: Stack(
              children: [
                Positioned.fill(
                  child: Stack(
                    children: [
                      GetBuilder<FlutterMapController>(
                          builder: (_) {
                            return FutureBuilder(
                                future: controller.zoneInit.future,
                                builder: (context, snapshot) {
                                  return FlutterMapHelper
                                      .createFlutterMapWidget(
                                    context: context,
                                    controller: controller,
                                    zoneBounds: controller.zoneBounds,
                                    fullscreenMap: true,
                                  ) as Widget;
                                });
                          },
                          dispose: (_) {}),
                      FlutterCustomInfoWindow(
                        key: UniqueKey(),
                        controller: controller.customInfoWindowController,
                        offsetLeft: GeneralUtils.isSmallScreen() ? 10 : 50,
                        offsetTop: GeneralUtils.isSmallScreen() ? 10 : 50,
                        height: 200,
                        width: LayoutConstants.flutterMapInfoWindowWidth,
                      ),
                    ],
                  ),
                ),
                CustomAppBar(
                  withOpacity: true,
                  onlyTitle: true,
                ),
                Positioned(
                  top: 60,
                  left: 10,
                  child: Obx(() {
                    return controller.topActionButtons$.isNotEmpty
                        ? Row(
                            children:
                                controller.topActionButtons$.map((button) {
                              return Row(
                                children: [
                                  button,
                                  if (button !=
                                      controller.topActionButtons$.last)
                                    const SizedBox(width: 5),
                                ],
                              );
                            }).toList(),
                          )
                        : Row(
                            children: [
                              Obx(() => BorderedIconButton(
                                    width: 50,
                                    fillColor: AppColors.secondaryButton,
                                    onTap: () {
                                      controller.onSwitchMapType(
                                          controller.mapType() == 'm'
                                              ? 's'
                                              : 'm');
                                    },
                                    child: Icon(
                                      controller.mapType.value == "s"
                                          ? Icons.satellite_outlined
                                          : Icons.map_outlined,
                                      size: 25,
                                      color: AppColors.brightBackground,
                                    ),
                                  )),
                              const SizedBox(width: 10),
                              Obx(() => BorderedIconButton(
                                  width: 50,
                                  fillColor: AppColors.secondaryButton,
                                  onTap: () {
                                    controller.showPerimeterTolerance$.value =
                                        !controller.showPerimeterTolerance;
                                  },
                                  child: controller.showPerimeterTolerance
                                      ? const Icon(
                                          Icons.blur_circular,
                                          size: 25,
                                          color: AppColors.brightText,
                                        )
                                      : const Icon(
                                          Icons.blur_off,
                                          size: 25,
                                          color: AppColors.brightText,
                                        ))),
                              const SizedBox(width: 10),
                              BorderedIconButton(
                                  width: 50,
                                  fillColor: AppColors.secondaryButton,
                                  onTap: () {
                                    controller.showCoordinateStatus$.value =
                                        !controller.showCoordinateStatus;
                                  },
                                  child: controller.showCoordinateStatus
                                      ? const Icon(
                                          Icons.location_searching,
                                          size: 25,
                                          color: AppColors.brightText,
                                        )
                                      : const Icon(
                                          Icons.location_disabled,
                                          size: 25,
                                          color: AppColors.brightText,
                                        )),
                            ],
                          );
                  }),
                ),
                /* if(!GeneralUtils.isSmallScreen())
                Positioned(
                  top: 65,
                  right: 10,
                  child: CircularIconButton(
                    color: AppColors.brightBackground,
                    onTap: Get.back,
                    buttonSize: 45,
                    child: const Icon(
                      Icons.close_fullscreen,
                      size: 25,
                      color: AppColors.primaryButton,
                    ),
                  ),
                ),*/
                Obx(() => Positioned(
                      bottom: controller.showPlayer$ ? 165 : 100,
                      right: 10,
                      child: CircularIconButton(
                        color: AppColors.brightBackground,
                        onTap: controller.showCurrentLocation,
                        buttonSize: 45,
                        child: Icon(
                          Icons.gps_fixed,
                          size: 25,
                          color: AppTheme().colors.primaryButton,
                        ),
                      ),
                    )),
                Obx(() => Positioned(
                      bottom: controller.showPlayer$ ? 165 : 100,
                      left: 10,
                      child: CircularIconButton(
                        color: AppColors.brightBackground,
                        onTap: controller.showCurrentZone,
                        buttonSize: 45,
                        child: Icon(
                          Icons.panorama_horizontal,
                          size: 25,
                          color: AppTheme().colors.primaryButton,
                        ),
                      ),
                    )),
                Obx(() => controller.showPlayer$
                    ? Positioned(
                        bottom: 95,
                        left: 10,
                        right: 10,
                        child: HistoryAudioPlayer(
                          onClose: controller.onCloseHandler,
                          onPlay: controller.onPlayHandler,
                          onPaused: controller.onPausedHandler,
                          onPlayerReady: controller.onPlayerReadyHandler,
                        ))
                    : const SizedBox()),
                Positioned(
                  bottom: 15,
                  left: 0,
                  right: 0,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: const [
                      BigRoundPttButton(semiTransparent: true),
                      BigRoundSosButton(semiTransparent: true),
                    ],
                  ),
                ),
                Obx(() => controller.showCoordinateStatus
                    ? FlutterMapHelper.createCoordinateStatus(
                        context, controller)
                    : Container()),
                Obx(() {
                  if (EntitiesHistoryTracking().trackingIsOpened) {
                    return HomePage.createPlaybackTopPanel(context);
                  } else {
                    return Container();
                  }
                }),
                Obx(() {
                  if (EntitiesHistoryTracking().trackingIsOpened) {
                    return HomePage.createPlaybackPlayer(context);
                  } else {
                    return Container();
                  }
                }),
              ],
            ),
            bottomNavigationBar: BottomNavBar(
              key: UniqueKey(),
              initialActiveIndex: 1,
            ),
          ),
        );
      },
      dispose: (_) {
        controller.onTap();
      },
    ));
  }
}
