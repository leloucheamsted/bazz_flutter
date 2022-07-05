import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/chat/chat_controller.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/shift_activities/shift_activities_service.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/shared_widgets/badge_counter.dart';
import 'package:bazz_flutter/shared_widgets/system_dialog.dart';
import 'package:convex_bottom_bar/convex_bottom_bar.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:percent_indicator/circular_percent_indicator.dart';

class Style extends StyleHook {
  @override
  double get activeIconSize => 20;

  @override
  double get activeIconMargin => 3;

  @override
  double get iconSize => 20;

  @override
  TextStyle textStyle(Color color) {
    return TextStyle(
        fontSize: 8,
        color: color,
        fontWeight: FontWeight.w600,
        fontStyle: FontStyle.normal);
  }
}

class _TabItemBuilder extends DelegateBuilder {
  _TabItemBuilder();

  @override
  Widget build(BuildContext context, int index, bool active) {
    if (index == 2) {
      return Obx(() {
        final stdQrButton = Center(
          child: Container(
            width: 50,
            height: 50,
            padding: const EdgeInsets.all(10).copyWith(top: 7),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Session.isSupervisor || Session.hasShiftStarted!
                  ? AppColors.bottomNavBarMainButton
                  : AppTheme().colors.disabledButton,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black26,
                  blurRadius: 1.5,
                  spreadRadius: 1.5,
                ),
              ],
            ),
            child: SvgPicture.asset('assets/images/tours_checklist.svg',
                fit: BoxFit.scaleDown),
          ),
        );

        if (HomeController.to.servicesInitialized$.isFalse) return stdQrButton;

        final currentTour = ShiftActivitiesService.to?.currentTour;
        if (currentTour != null) {
          final color = currentTour.statusColor;
          final finishedCount = currentTour.path
              .where((tp) => tp.reportingPoint.isFinished)
              .length;
          final totalCount = currentTour.path.length;
          final progress = finishedCount / totalCount;
          return Center(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black26,
                        blurRadius: 1.5,
                        spreadRadius: 1.5,
                      ),
                    ],
                  ),
                  child: CircularPercentIndicator(
                    radius: 50,
                    percent: progress,
                    progressColor: color,
                    backgroundColor: AppTheme().colors.disabledButton,
                  ),
                ),
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                    border: Border.all(color: Colors.white),
                  ),
                  child: const Icon(
                    LineAwesomeIcons.qrcode,
                    size: 35,
                    color: AppColors.brightIcon,
                  ),
                ),
                if (currentTour != null)
                  Positioned(
                    top: 0,
                    child: BadgeCounter('$finishedCount/$totalCount'),
                  ),
              ],
            ),
          );
        } else {
          return stdQrButton;
        }
      });
    }

    IconData iconData;
    String title;

    bool buildEmpty = false;

    switch (index) {
      case 0:
        iconData = LineAwesomeIcons.home;
        title = "AppLocalizations.of(context).home";
        break;
      case 1:
        iconData = LineAwesomeIcons.alternate_map_marked;
        title = "AppLocalizations.of(context).map";
        if (Session.isNotSupervisor && Session.isNotCustomer) buildEmpty = true;
        break;
      case 3:
        if (Session.isNotSupervisor && Session.isNotCustomer) buildEmpty = true;
        iconData = LineAwesomeIcons.envelope;
        title = "AppLocalizations.of(context).chat";
        break;
      case 4:
        iconData = LineAwesomeIcons.bell;
        title = "AppLocalizations.of(context).events.capitalize";
        if (Session.user!.isCustomer!) buildEmpty = true;
        break;
      default:
        iconData = LineAwesomeIcons.question;
        title = 'No title';
    }

    return buildEmpty
        ? const SizedBox()
        : Container(
            color: active
                ? AppTheme().colors.bottomNavBarSelectedTab
                : Colors.transparent,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Icon(
                        iconData,
                        color: active
                            ? AppColors.brightIcon
                            : AppTheme().colors.bottomNavBarIconColor,
                        size: 18,
                      ),
                    ),
                    if (index == 3)
                      Obx(() {
                        if (HomeController.to.servicesInitialized$.isFalse)
                          return const SizedBox();

                        final totalUnseen = ChatController
                            .to.currentChatGroupContainer$.totalUnseen;
                        return Positioned(
                          top: 0,
                          right: 0,
                          child: BadgeCounter((totalUnseen).toString()),
                        );
                      }),
                    if (index == 4)
                      Obx(() {
                        if (HomeController.to.servicesInitialized$.isFalse)
                          return const SizedBox();

                        final eventsLength = HomeController
                            .to.activeGroup.roleDependentEvents$.length;

                        return Positioned(
                          top: 0,
                          right: 0,
                          child: BadgeCounter((eventsLength).toString()),
                        );
                      }),
                  ],
                ),
                Text(
                  title,
                  style: active
                      ? AppTheme().typography.bottomNavBarTitleStyle.copyWith(
                            fontWeight: FontWeight.w600,
                            color: AppColors.brightText,
                          )
                      : AppTheme().typography.bottomNavBarTitleStyle,
                ),
              ],
            ),
          );
  }

  @override
  bool fixed() {
    return true;
  }
}

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({
    Key? key,
    this.initialActiveIndex,
    this.primaryTabController,
    this.isPrimary = false,
  }) : super(key: key);

  final bool isPrimary;
  final int? initialActiveIndex;
  final TabController? primaryTabController;

  @override
  _BottomNavBarState createState() => _BottomNavBarState();
}

class _BottomNavBarState extends State<BottomNavBar>
    with SingleTickerProviderStateMixin {
  final controller = HomeController.to;
  TabController? tabController;

  @override
  void initState() {
    tabController = widget.primaryTabController ??
        TabController(
          length: 5,
          vsync: this,
          initialIndex: controller.bottomNavBarController!.index,
        );
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return StyleProvider(
      style: Style(),
      child: ConvexAppBar.builder(
        key: widget.isPrimary ? controller.bottomNavBarKey : UniqueKey(),
        controller: tabController,
        count: 5,
        itemBuilder: _TabItemBuilder(),
        disableDefaultTabController: true,
        height: 46,
        top: -10,
        curveSize: 50,
        backgroundColor: AppTheme().colors.bottomNavBarBackground,
        cornerRadius: 0,
        initialActiveIndex:
            widget.initialActiveIndex ?? controller.bottomNavBarIndex,
        onTap: (int index) {
          switch (index) {
            case 0:
              controller.gotoBottomNavTab(BottomNavTab.values[index]);
              break;
            case 1:
              if (Session.isNotSupervisor && Session.isNotCustomer) break;
              controller.gotoBottomNavTab(BottomNavTab.values[index],
                  closeOtherRoutes: false);
              break;
            case 2:
              if (Session.isSupervisor) {
                if (Get.isOverlaysOpen) Get.until((_) => Get.isOverlaysClosed);
                Get.toNamed(AppRoutes.shiftActivitiesStats);
              } else if (Session.hasShiftStarted!) {
                if (Get.isOverlaysOpen) Get.until((_) => Get.isOverlaysClosed);
                if (ShiftActivitiesService.to!.currentTour != null) {
                  Get.toNamed(AppRoutes.shiftActivities);
                } else {
                  SystemDialog.showConfirmDialog(
                      title: LocalizationService().of().noTourTitle,
                      message: LocalizationService().of().noTourMsg,
                      confirmButtonText: LocalizationService().of().ok,
                      confirmCallback: () {
                        Get.back();
                      });
                }
              }
              _restorePrevTab();
              break;
            case 3:
              if (Session.isNotSupervisor && Session.isNotCustomer) break;
              controller.gotoBottomNavTab(BottomNavTab.values[index]);
              break;
            case 4:
              controller.gotoBottomNavTab(BottomNavTab.values[index]);
              break;
          }
        },
      ),
    );
  }

  ///We do this because the central QR tab is a button, leading to a different route,
  ///and it gets highlighted when pressed, and when we go back, we need to see the prev tab highlighted.
  void _restorePrevTab() {
    tabController!.index = tabController!.previousIndex;
    controller.bottomNavBarController!.index = tabController!.previousIndex;
    controller.bottomNavBarKey.currentState!
        .animateTo(tabController!.previousIndex);
  }

  Widget _buildBottomNavBarItem(String text, FaIcon icon, int index,
      {int? badgeCounter, VoidCallback? onPressed}) {
    return Expanded(
      child: Obx(() {
        return Material(
          color: controller.bottomNavBarIndex == index
              ? AppTheme().colors.selectedTab
              : AppColors.primaryAccent,
          child: InkWell(
            onTap: () {
              if (Get.currentRoute != AppRoutes.home) Get.back();
              controller.bottomNavBarIndex = index;
              controller.homeTabBarController!.animateTo(0);
              onPressed?.call();
            },
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.only(bottom: 2),
                  alignment: Alignment.center,
                  child: Stack(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 13),
                        child: icon,
                      ),
                      if (badgeCounter != null && badgeCounter > 0)
                        Positioned(
                          right: 0,
                          child: Container(
                            alignment: Alignment.center,
                            height: 15,
                            width: 15,
                            decoration: const BoxDecoration(
                              color: AppColors.sos,
                              shape: BoxShape.circle,
                            ),
                            child: Text(
                              '$badgeCounter',
                              style: AppTypography.badgeCounterTextStyle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                Text(text, style: AppTypography.bottomToolbarTextStyle),
              ],
            ),
          ),
        );
      }),
    );
  }
}
