import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/widgets/custom_app_bar.dart';
import 'package:bazz_flutter/modules/home_module/widgets/notifications_drawer.dart';
import 'package:bazz_flutter/modules/home_module/widgets/round_ptt_button.dart';
import 'package:bazz_flutter/modules/shift_activities/models/reporting_point.dart';
import 'package:bazz_flutter/modules/shift_activities/shift_activities_service.dart';
import 'package:bazz_flutter/modules/shift_activities/widgets/shift_activities_card.dart';
import 'package:bazz_flutter/modules/shift_activities/widgets/tour_map.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:bazz_flutter/shared_widgets/tello_divider.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import 'package:flutter_webrtc/utils.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class ShiftActivitiesPage extends GetView<ShiftActivitiesService> {
  const ShiftActivitiesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ShiftActivitiesService>(
      id: 'ShiftActivitiesPage',
      builder: (controller) {
        return Unfocuser(
          child: Scaffold(
            backgroundColor: AppTheme().colors.mainBackground,
            body: SafeArea(
              child: Stack(
                children: [
                  Column(
                    children: [
                      CustomAppBar(
                        withBackButton: true,
                        title:
                            "AppLocalizations.of(context).reportingPoints.capitalize",
                      ),
                      buildShiftActivitiesBody(context)
                    ],
                  ),
                  NotificationsDrawer(controller: HomeController.to),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  static Widget buildShiftActivitiesBody(BuildContext context) {
    final controller = ShiftActivitiesService.to;
    if (controller!.currentTour == null && controller.otherRPoints!.isEmpty) {
      return Expanded(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "AppLocalizations.of(context).noToursForCurrentPosition.capitalize",
              style: AppTypography.bodyText2TextStyle.copyWith(fontSize: 14),
            ),
            SizedBox(
              width: 100,
              height: 100,
              child: SvgPicture.asset(
                'assets/images/map_marker_not_defined_ico.svg',
              ),
            ),
          ],
        ),
      );
    }

    Future.delayed(const Duration(), controller.restoreUnfinishedRPoint);
    final reportingPoints =
        controller.currentTour!.path.map((tp) => tp.reportingPoint).toList();

    return Expanded(
      child: Column(children: [
        //we will need it later!
        // TimerAndStatusBar(controller: HomeController.to),
        TabBar(
          key: controller.guardTabBarKey,
          controller: controller.tabController,
          indicator: BoxDecoration(
            color: AppTheme().colors.selectedTab,
            border: const Border(
                bottom: BorderSide(width: 2, color: AppColors.primaryAccent)),
          ),
          tabs: [
            Tab(
              child: Text(
                'Tour ${controller.currentTourIndex + 1} of ${Session.shift!.tours!.length}',
                style: AppTheme().typography.tabTitle2Style,
              ),
            ),
            Tab(
              child: Text(
                'Others',
                style: AppTheme().typography.tabTitle2Style,
              ),
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            physics: const NeverScrollableScrollPhysics(),
            controller: controller.tabController,
            children: [
              _buildTabWithRPoints(controller, reportingPoints),
              _buildTabWithRPoints(controller, controller.otherRPoints!),
            ],
          ),
        ),
        Obx(() {
          return buildBottomButtons(
            isMapVisible: controller.isMapVisible(),
            qrBtnCallback: () => controller.onQrScanPressed(context),
            mapToggleCallback: controller.toggleMapVisibility,
          );
        }),
      ]),
    );
  }

  static Widget _buildTabWithRPoints(
      ShiftActivitiesService controller, List<ReportingPoint> rPoints) {
    if (rPoints.isEmpty) {
      return Center(
        child: Text(
          " AppLocalizations.of(Get.context).noReportingPoints",
          style: AppTheme().typography.bgText3Style,
        ),
      );
    }

    return Column(
      children: [
        const TelloDivider(),
        Expanded(
          child: Obx(() {
            return controller.isMapVisible()
                ? TourMap(rPoints: rPoints)
                : ListView.separated(
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          ExpandableRPointItem(
                            key: UniqueKey(),
                            rPoint: rPoints[index],
                            index: index,
                          ),
                          if (index + 1 == rPoints.length) const TelloDivider(),
                        ],
                      );
                    },
                    separatorBuilder: (_, __) => const TelloDivider(),
                    itemCount: rPoints.length,
                  );
          }),
        ),
      ],
    );
  }

  static Widget buildBottomButtons(
      {bool? isMapVisible,
      VoidCallback? qrBtnCallback,
      VoidCallback? mapToggleCallback}) {
    return KeyboardVisibilityBuilder(
      builder: (context, visible) => visible
          ? const SizedBox()
          : Padding(
              padding: const EdgeInsets.all(LayoutConstants.compactPadding),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  CircularIconButton(
                    elevation: 3,
                    buttonSize: 50,
                    color: AppColors.primaryAccent,
                    onTap: mapToggleCallback!,
                    child: Icon(
                      isMapVisible!
                          ? Icons.timeline_rounded
                          : LineAwesomeIcons.map_marker,
                      color: AppColors.brightIcon,
                      size: 35,
                    ),
                  ),
                  CircularIconButton(
                    elevation: 3,
                    buttonSize: 65,
                    color: qrBtnCallback != null
                        ? AppColors.secondaryButton
                        : AppTheme().colors.disabledButton,
                    onTap: qrBtnCallback!,
                    child: const Icon(
                      LineAwesomeIcons.qrcode,
                      color: AppColors.brightIcon,
                      size: 45,
                    ),
                  ),
                  RoundPttButton(),
                ],
              ),
            ),
    );
  }

//WE MAY NEED IT LATER, if we need a scrollable list of activities
// Widget _buildTourTab(int index) {
//   final reportingPoints = controller.mockedTours[index]['reportingPoints'] as List;
//   return Padding(
//     padding: const EdgeInsets.all(LayoutConstants.compactPadding),
//     child: ListView.separated(
//       padding: EdgeInsets.zero,
//       itemBuilder: (context, index) {
//         return ExpandableItem(
//           key: UniqueKey(),
//           reportingPoint: reportingPoints[index] as ReportingPoint,
//           index: index,
//         );
//       },
//       separatorBuilder: (_, __) => const SizedBox(height: 5),
//       itemCount: reportingPoints.length,
//     ),
//   );
// }
}

class ExpandableRPointItem extends StatefulWidget {
  const ExpandableRPointItem({
    Key? key,
    required this.rPoint,
    required this.index,
  }) : super(key: key);

  final int index;
  final ReportingPoint rPoint;

  @override
  _ExpandableRPointItemState createState() => _ExpandableRPointItemState();

  static Widget buildRPointHeader(
      ReportingPoint rPoint, Color color, VoidCallback onInfoTap) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 5, 10, 5),
      color: AppTheme().colors.listItemBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rPoint.title,
                  style: AppTheme().typography.bgTitle2Style,
                ),
                if (rPoint.visitsCounter > 1)
                  Text(
                    "AppLocalizations.of(Get.context).visitedTimes(rPoint.visitsCounter.toString()).capitalizeFirst",
                    style: AppTheme().typography.bgText4Style,
                  ),
              ],
            ),
          ),
          const SizedBox(width: 5),
          CircularIconButton(
            buttonSize: 35,
            color: AppColors.secondaryButton,
            onTap: null as VoidCallback,
            child: Padding(
              padding: const EdgeInsets.all(5.0),
              child: SvgPicture.asset('assets/images/sign_in_alt.svg',
                  color: AppColors.brightIcon),
            ),
          ),
          const SizedBox(
            width: 10,
          ),
          CircularIconButton(
            buttonSize: 35,
            color: color,
            onTap: onInfoTap,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: SvgPicture.asset('assets/images/rp_info_icon.svg',
                  color: AppColors.brightIcon),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableRPointItemState extends State<ExpandableRPointItem> {
  @override
  Widget build(BuildContext context) {
    return GetBuilder<ShiftActivitiesService>(
        id: 'reportingPoint${widget.rPoint.id}',
        builder: (controller) {
          final color = widget.rPoint.isFinished
              ? AppColors.rPointFinished
              : widget.rPoint.isNotStarted
                  ? AppColors.rPointNotStarted
                  : AppColors.rPointInProgress;
          return ExpandableNotifier(
            controller: widget.rPoint.expandableController,
            child: ScrollOnExpand(
              child: Expandable(
                collapsed: GestureDetector(
                  onTap: () {
                    ShiftActivitiesService.to!.onRPointOpen(widget.rPoint);
                  },
                  child: ExpandableRPointItem.buildRPointHeader(
                    widget.rPoint,
                    color,
                    () =>
                        LayoutUtils.buildDescription(widget.rPoint.description),
                  ),
                ),
                expanded: Column(
                  children: [
                    GestureDetector(
                      onTap: () => ShiftActivitiesService.to!
                          .onRPointClose(widget.rPoint),
                      child: ExpandableRPointItem.buildRPointHeader(
                        widget.rPoint,
                        color,
                        () => LayoutUtils.buildDescription(
                            widget.rPoint.description),
                      ),
                    ),
                    if (widget.rPoint.currentVisit != null) ...[
                      Divider(
                          indent: 10,
                          endIndent: 10,
                          color: AppTheme().colors.dividerLight),
                      ShiftActivitiesCard(
                        key: UniqueKey(),
                        activities: widget.rPoint.currentVisit.activities,
                        rPoint: widget.rPoint,
                      )
                    ],
                  ],
                ),
              ),
            ),
          );
        });
  }
}
