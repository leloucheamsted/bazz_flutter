import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/widgets/bordered_icon_button.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/notification_service.dart';
import 'package:bazz_flutter/services/notification_service.dart' as ns;
import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart' as intl;
import 'package:sliding_up_panel/sliding_up_panel.dart';

class NotificationsDrawer extends StatelessWidget {
  const NotificationsDrawer({Key? key, required this.controller})
      : super(key: key);

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return SlidingUpPanel(
      controller: controller.notificationsDrawerController,
      color: Colors.transparent,
      minHeight: 20,
      slideDirection: SlideDirection.DOWN,
      renderPanelSheet: false,
      backdropEnabled: true,
      maxHeight: Get.height * 0.85,
      onPanelOpened: controller.onNotificationsDrawerOpened,
      onPanelClosed: controller.onNotificationsDrawerClosed,
      panel: Container(
        decoration: ShapeDecoration(
          shape: TopDrawerShape(),
          color: Colors.black45,
        ),
        child: Column(
          children: [
            Obx(() {
              return controller.servicesInitialized$()
                  ? Expanded(
                      child: Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10.0),
                            height: 60,
                            color: Colors.black.withOpacity(0.7),
                            child: Row(
                              children: [
                                const Icon(Icons.info_outline_rounded,
                                    color: AppColors.brightText),
                                const SizedBox(width: 5),
                                Text(
                                  "AppLocalizations.of(context).notifications.capitalize",
                                  style:
                                      AppTypography.subtitle2TextStyle.copyWith(
                                    fontSize: 17,
                                    color: AppColors.brightText,
                                  ),
                                ),
                                const Spacer(),
                                Obx(() {
                                  return NotificationService
                                          .to.notificationGroups.isNotEmpty
                                      ? BorderedIconButton(
                                          onTap:
                                              NotificationService.to.clearAll,
                                          fillColor:
                                              AppColors.error.withOpacity(0.1),
                                          elevation: 0,
                                          highlightElevation: 0,
                                          borderRadius: 20,
                                          child: Row(
                                            children: [
                                              Text(
                                                " AppLocalizations.of(context).clearAll.capitalize",
                                                style: AppTypography
                                                    .subtitle3TextStyle
                                                    .copyWith(
                                                  color: AppColors.error,
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              const Icon(
                                                  Icons.clear_all_rounded,
                                                  color: AppColors.error),
                                            ],
                                          ),
                                        )
                                      : const SizedBox();
                                }),
                              ],
                            ),
                          ),
                          Obx(() {
                            final groups =
                                NotificationService.to.notificationGroups;
                            return groups.isNotEmpty
                                ? Expanded(
                                    child: Column(
                                      children: [
                                        ListView.separated(
                                          shrinkWrap: true,
                                          padding: const EdgeInsets.all(10.0),
                                          itemBuilder: (context, i) {
                                            final group = groups.elementAt(i);
                                            return _buildNotificationGroup(
                                                group, context);
                                          },
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(height: 5),
                                          itemCount: groups.length,
                                        ),
                                        const Spacer(),
                                      ],
                                    ),
                                  )
                                : Expanded(
                                    child: Center(
                                      child: const Text(
                                        "AppLocalizations.of(context).nothingHere.capitalize",
                                        style: const TextStyle(
                                            color: AppColors.brightText),
                                      ),
                                    ),
                                  );
                          }),
                        ],
                      ),
                    )
                  : const SizedBox();
            }),
            GetBuilder<HomeController>(
                id: 'notificationsDrawerArrow',
                builder: (controller) {
                  return Icon(
                    controller.notificationsDrawerController.isPanelOpen
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AppColors.brightIcon,
                  );
                }),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationGroup(
      ns.NotificationGroup group, BuildContext context) {
    return ExpandableNotifier(
      controller: group.expandableController,
      child: ScrollOnExpand(
        child: Expandable(
          collapsed: group.notifications.length == 1
              ? _buildNotificationItem(group.notifications.first, context)
              : Container(
                  decoration: BoxDecoration(
                    color: group.notifications.first.bgColor,
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Column(
                    children: [
                      _buildNotificationItem(
                          group.notifications.first, context),
                      InkWell(
                        onTap: () {
                          for (final group
                              in NotificationService.to.notificationGroups) {
                            group.expandableController.expanded = false;
                          }
                          group.expandableController.toggle();
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Text(
                            '{AppLocalizations.of(context).see.capitalize} '
                            '{group.notifications.length - 1} {AppLocalizations.of(context).more.capitalize}',
                            style: AppTypography.bodyText2TextStyle,
                          ),
                        ),
                      ),
                      // ValueListenableBuilder(
                      //   valueListenable: group.expandableController,
                      //   builder: (context, hasError, child) {
                      //     return InkWell(
                      //       onTap: group.expandableController.toggle,
                      //       child: Padding(
                      //         padding: const EdgeInsets.symmetric(vertical: 3),
                      //         child: Icon(
                      //           group.expandableController.expanded
                      //               ? Icons.keyboard_arrow_up_rounded
                      //               : Icons.keyboard_arrow_down_rounded,
                      //           color: AppColors.brightIcon,
                      //         ),
                      //       ),
                      //     );
                      //   },
                      // ),
                    ],
                  ),
                ),
          expanded: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: InkWell(
                      onTap: group.expandableController.toggle,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        child: Text(
                          "AppLocalizations.of(context).collapseGroup.capitalize",
                          style: AppTypography.bodyText5TextStyle
                              .copyWith(color: AppColors.brightText),
                        ),
                      ),
                    ),
                  ),
                  CircularIconButton(
                    buttonSize: 30,
                    color: const Color(0xffefd4d4),
                    onTap: () => NotificationService.to.removeGroup(group),
                    child: const Icon(Icons.clear_all_rounded,
                        color: AppColors.error),
                  ),
                ],
              ),
              const SizedBox(height: 5),
              Obx(() {
                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: Get.height * 0.4,
                  ),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemBuilder: (context, i) {
                      final notification = group.notifications[i];
                      return _buildNotificationItem(notification, context);
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 5),
                    itemCount: group.notifications.length,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNotificationItem(
      ns.Notification notification, BuildContext context) {
    TelloLogger().i(
        "_buildNotificationItem ${notification.title} ${notification.text}, ${notification.icon}");
    return InkWell(
      onTap: () {
        notification.callback?.call();
        NotificationService.to.removeNotifications([notification.id!]);
      },
      child: Container(
        height: 70,
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: notification.bgColor,
          borderRadius: BorderRadius.circular(5),
        ),
        child: Row(
          children: [
            notification.icon ?? const Icon(Icons.message, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextOneLine(
                    notification.title,
                    style: AppTypography.captionTextStyle,
                  ),
                  Text(
                    notification.text,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.brightText,
                      height: 1.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 5),
            notification.mainButton ?? Container(),
            GetBuilder<HomeController>(
                id: 'notificationTime',
                builder: (controller) {
                  final diffInMin = DateTime.now()
                      .difference(notification.messageTime)
                      .inMinutes;
                  return Text(
                    diffInMin > 59
                        ? intl.DateFormat(AppSettings().timeFormat)
                            .format(notification.messageTime)
                        : diffInMin > 0
                            ? '{diffInMin}m {AppLocalizations.of(context).ago}'
                            : "AppLocalizations.of(context).now",
                    style:
                        AppTypography.captionTextStyle.copyWith(fontSize: 10),
                  );
                }),
          ],
        ),
      ),
    );
  }
}

class TopDrawerShape extends ShapeBorder {
  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) => null!;
  final double borderRadius = 5;

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    final rectt =
        Rect.fromPoints(rect.topLeft, rect.bottomRight - const Offset(0, 20));
    return Path()
      ..addRect(rectt)
      ..moveTo(rectt.bottomCenter.dx, rect.bottomCenter.dy)
      ..addRRect(RRect.fromRectAndCorners(
        Rect.fromCenter(
            center: Offset(rectt.bottomCenter.dx, rectt.bottomCenter.dy),
            width: 40,
            height: 35),
        bottomLeft: const Radius.circular(5),
        bottomRight: const Radius.circular(5),
      ))
      ..close();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {}

  @override
  ShapeBorder scale(double t) => this;
}
