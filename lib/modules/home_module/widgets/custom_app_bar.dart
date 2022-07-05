import 'dart:math';

import 'package:align_positioned/align_positioned.dart';
import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/alert_check/alert_check_button.dart';
import 'package:bazz_flutter/modules/alert_check/alert_check_service.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/widgets/talk_timer.dart';
import 'package:bazz_flutter/modules/location_tracking/location_service.dart';
import 'package:bazz_flutter/modules/message_history/message_upload_service.dart';
import 'package:bazz_flutter/modules/p2p_video/incoming_appbar_calls.dart';
import 'package:bazz_flutter/modules/settings_module/settings_controller.dart';
import 'package:bazz_flutter/modules/synchronization/sync_service.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/entities_history_tracking.dart';
import 'package:bazz_flutter/shared_widgets/entity_details_info.dart';
import 'package:bazz_flutter/shared_widgets/system_dialog.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:simple_animations/simple_animations.dart';

class CustomAppBar extends StatelessWidget {
  CustomAppBar({
    Key? key,
    this.withBackButton = false,
    this.title,
    this.onlyTitle = false,
    this.withSafeArea = true,
    this.withOpacity = false,
  }) : super(key: key);

  final bool withOpacity;
  final bool withSafeArea;
  final bool onlyTitle;
  final bool withBackButton;
  late String? title;
  final bool semiTransparent = false;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      //TODO: we don't need to rebuild the whole AppBar because of the single sos
      final sos = HomeController.to.activeGroup.hasSos;
      return withSafeArea
          ? SafeArea(
              child: createContainer(context, sos: sos),
            )
          : createContainer(context, sos: sos);
    });
  }

  Widget createContainer(BuildContext context, {bool? sos}) {
    return Obx(() {
      final streamingState = HomeController.to.txState$.value.state;
      final isPttDisabled = HomeController.to.isPttDisabled;

      final color = () {
        if (isPttDisabled)
          return AppTheme()
              .colors
              .disabledButton
              .withOpacity(semiTransparent ? 0.5 : 1);

        switch (streamingState) {
          case StreamingState.preparing:
            return Colors.amber;
          case StreamingState.sending:
            return AppColors.pttTransmitting;
          case StreamingState.receiving:
            return AppColors.pttReceiving;
          case StreamingState.cleaning:
            return AppTheme()
                .colors
                .disabledButton
                .withOpacity(semiTransparent ? 0.5 : 1);
          default:
            return AppColors.pttIdle.withOpacity(semiTransparent ? 0.5 : 1);
        }
      }();
      return Container(
          color: withOpacity
              ? AppTheme().colors.appBar.withOpacity(0.65)
              : AppTheme().colors.appBar,
          child: Container(
            decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(width: 1.2, color: color),
                ),
                color: color.withOpacity(0.05) //: AppTheme().colors.appBar,
                ),
            height: LayoutConstants.appBarHeight,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Row(
                  children: [
                    if (!onlyTitle)
                      Stack(children: [
                        IconButton(
                          icon: Icon(
                            withBackButton
                                ? Icons.arrow_back_rounded
                                : Icons.menu_rounded,
                            color: AppColors.brightText,
                          ),
                          onPressed: withBackButton
                              ? () => Get.back(closeOverlays: true)
                              : Scaffold.of(context).openDrawer,
                        ),
                        Obx(() {
                          if (AppSettings().updatesCounter > 0 &&
                              !withBackButton) {
                            return Positioned(
                              right: 0,
                              left: 18,
                              top: 5,
                              child: Container(
                                alignment: Alignment.center,
                                height: 15,
                                width: 15,
                                decoration: const BoxDecoration(
                                  color: AppColors.sos,
                                  shape: BoxShape.circle,
                                ),
                                child: Text(
                                  '${AppSettings().updatesCounter}',
                                  style: AppTypography.badgeCounterTextStyle,
                                ),
                              ),
                            );
                          } else {
                            return Container();
                          }
                        }),
                      ]),
                    if (onlyTitle) const SizedBox(width: 10),
                    Expanded(
                      child: FitHorizontally(
                        alignment: Alignment.centerLeft,
                        shrinkLimit: .8,
                        child: TextOneLine(
                          (title ?? Session.shift!.positionTitle) ??
                              Session.user!.fullName!,
                          style: AppTheme().typography.appbarTextStyle,
                        ),
                      ),
                    ),
                  ],
                ),
                Positioned(
                  bottom: 5,
                  right: 5,
                  child: Row(
                    children: [
                      //for testing purposes
                      // Checkbox(
                      //   visualDensity: VisualDensity.compact,
                      //   value: SettingsController.to.isDarkTheme,
                      //   onChanged: SettingsController.to.setIsDarkTheme,
                      // ),
                      Obx(() {
                        if (!HomeController.to.servicesInitialized$() ||
                            !HomeController.to.isOnline)
                          return const SizedBox();
                        return (SyncService.to.hasData$ ||
                                MessageUploadService.to.hasData$)
                            ? GestureDetector(
                                onTap: _showSyncStatistics,
                                child: _syncAnimIcon(),
                              )
                            : const SizedBox();
                      }),
                      if (Session.hasShiftStarted! &&
                          Get.isRegistered<AlertCheckService>())
                        Obx(() {
                          if (!AlertCheckService.to.alertCheckInProgress()) {
                            return const SizedBox();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(left: 3),
                            child: AlertCheckButton(),
                          );
                        }),
                    ],
                  ),
                ),
                if (!Session.user!.isCustomer!) IncomingCallsView(),
                PrivateCallView(),
                AlignPositioned(
                    alignment: Alignment.bottomCenter, child: TalkTimer()),
                Positioned(
                  top: 2,
                  right: 2,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      //FIXME: incorrect use of Obx
                      if (AppSettings().enableHistoryTracking)
                        Obx(() => GestureDetector(
                              onTap: () {
                                EntitiesHistoryTracking()
                                        .trackingIsOpened$
                                        .value =
                                    !EntitiesHistoryTracking().trackingIsOpened;
                              },
                              child: EntitiesHistoryTracking().trackingIsOpened
                                  ? const Icon(
                                      Icons.cancel,
                                      size: 20,
                                      color: AppColors.danger,
                                    )
                                  : const Icon(
                                      Icons.history_rounded,
                                      size: 20,
                                      color: AppColors.brightText,
                                    ),
                            )),
                      const SizedBox(width: 3),
                      Obx(() {
                        return GestureDetector(
                            onTap: () {
                              Get.toNamed(AppRoutes.gnss);
                            },
                            child: Icon(
                              FontAwesomeIcons.satellite,
                              color: LocationService().gnssEnabled
                                  ? AppColors.online
                                  : AppColors.error,
                              size: 16,
                            ));
                      }),
                      const SizedBox(width: 5),
                      Obx(() {
                        return EntityDetailsInfo.buildBatteryIndicator(
                            HomeController.to.batteryInfo != null
                                ? HomeController
                                    .to.batteryInfo.batteryPercentage as int
                                : 0,
                            // ignore: avoid_bool_literals_in_conditional_expressions
                            HomeController.to.batteryInfo != null
                                ? HomeController.to.batteryInfo.isDeviceCharging
                                    as bool
                                : false,
                            mainColor: AppColors.brightText,
                            fillColor: AppColors.brightText,
                            size: 14.0,
                            width: 20.0);
                      }),
                      Obx(() {
                        return Icon(
                          HomeController.to.isOnline
                              ? Icons.signal_cellular_4_bar
                              : Icons.signal_cellular_off,
                          color: HomeController.to.isOnline
                              ? AppColors.brightText
                              : AppColors.offline,
                          size: 20,
                        );
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ));
    });
  }

  void _showSyncStatistics() {
    SystemDialog.showConfirmDialog(
      title: 'Sync progress',
      height: 190,
      child: Obx(() {
        final messagesLeft$ = MessageUploadService.to.messagesLeft$;
        final rPointVisitsLeft$ = SyncService.to.rPointVisitsLeft$;
        final otherDataLeft$ = SyncService.to.otherDataLength$;
        final offlineEventsLeft$ = SyncService.to.offlineEventsLeft$;
        return Column(
          children: [
            SizedBox(
              height: 25,
              child: Row(
                children: [
                  Text('Audio messages:',
                      style: AppTheme().typography.bgText3Style),
                  const SizedBox(width: 5),
                  if (messagesLeft$ > 0)
                    Text('${messagesLeft$} left',
                        style: AppTheme().typography.bgText3Style)
                  else
                    const Icon(
                      Icons.check,
                      color: AppColors.primaryAccent,
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 25,
              child: Row(
                children: [
                  Text(
                    'Reporting point visits:',
                    style: AppTheme().typography.bgText3Style,
                  ),
                  const SizedBox(width: 5),
                  if (rPointVisitsLeft$ > 0)
                    Text(
                      '${rPointVisitsLeft$} left',
                      style: AppTheme().typography.bgText3Style,
                    )
                  else
                    const Icon(
                      Icons.check,
                      color: AppColors.primaryAccent,
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 25,
              child: Row(
                children: [
                  Text(
                    'Other data:',
                    style: AppTheme().typography.bgText3Style,
                  ),
                  const SizedBox(width: 5),
                  if (otherDataLeft$ > 0)
                    Text(
                      '${otherDataLeft$} left',
                      style: AppTheme().typography.bgText3Style,
                    )
                  else
                    const Icon(
                      Icons.check,
                      color: AppColors.primaryAccent,
                    ),
                ],
              ),
            ),
            SizedBox(
              height: 25,
              child: Row(
                children: [
                  Text(
                    'Events:',
                    style: AppTheme().typography.bgText3Style,
                  ),
                  const SizedBox(width: 5),
                  if (offlineEventsLeft$ > 0)
                    Text(
                      '${offlineEventsLeft$} left',
                      style: AppTheme().typography.bgText3Style,
                    )
                  else
                    const Icon(
                      Icons.check,
                      color: AppColors.primaryAccent,
                    ),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  LoopAnimation<int> _syncAnimIcon() {
    return LoopAnimation<int>(
      tween: IntTween(begin: 0, end: 360),
      curve: Curves.easeInOut,
      builder: (context, child, value) {
        return Transform.rotate(
          angle: value * pi / 180,
          child: child,
        );
      },
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.rotationY(pi),
        child: const Icon(Icons.sync_rounded, color: AppColors.brightText),
      ),
    );
  }
}
