import 'dart:typed_data';

import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/chat/widgets/chat_video_player.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/widgets/custom_app_bar.dart';
import 'package:bazz_flutter/modules/home_module/widgets/group_member.dart';
import 'package:bazz_flutter/modules/home_module/widgets/notifications_drawer.dart';
import 'package:bazz_flutter/modules/shift_activities/models/reporting_point.dart';
import 'package:bazz_flutter/modules/shift_activities/models/shift_activity_task.dart';
import 'package:bazz_flutter/modules/shift_activities/models/tour.dart';
import 'package:bazz_flutter/modules/shift_activities/shift_activities_page.dart';
import 'package:bazz_flutter/modules/shift_activities/shift_activities_service.dart';
import 'package:bazz_flutter/modules/shift_activities/shift_activities_stats/shift_activities_stats_controller.dart';
import 'package:bazz_flutter/modules/shift_activities/widgets/tour_map.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:bazz_flutter/shared_widgets/loader.dart';
import 'package:bazz_flutter/shared_widgets/tello_divider.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:video_thumbnail/video_thumbnail.dart';
import 'package:video_viewer/domain/entities/video_source.dart';
import 'package:video_viewer/video_viewer.dart';

class ShiftActivitiesStatsPage extends GetView<ShiftActivitiesStatsController> {
  const ShiftActivitiesStatsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const verticalCaptionWidth = 20.0;
    return Portal(
      child: Scaffold(
        backgroundColor: AppTheme().colors.mainBackground,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  CustomAppBar(
                    withBackButton: true,
                    title: " AppLocalizations.of(context)"
                    // .shiftActivitiesStats
                    // .capitalize
                    ,
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
                    child: Row(
                      children: [
                        Expanded(
                          child: controller.positions?.isEmpty ?? true
                              ? const SizedBox()
                              : SizedBox(
                                  height: 70,
                                  child: GetBuilder<
                                          ShiftActivitiesStatsController>(
                                      id: 'positionsList',
                                      builder: (controller) {
                                        return ListView.separated(
                                          scrollDirection: Axis.horizontal,
                                          itemBuilder: (_, i) {
                                            final position =
                                                controller.positions![i];
                                            final isPositionSelected =
                                                controller.selectedPosition ==
                                                    position;
                                            return GestureDetector(
                                              onTap: () => controller
                                                  .selectPosition(position),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(3),
                                                decoration: BoxDecoration(
                                                  border: Border(
                                                    bottom: BorderSide(
                                                      color: isPositionSelected
                                                          ? AppColors
                                                              .primaryAccent
                                                          : AppTheme()
                                                              .colors
                                                              .mainBackground,
                                                      width: 3,
                                                    ),
                                                  ),
                                                ),
                                                child:
                                                    GroupMember.buildPosition(
                                                  position: position,
                                                  onTap: () {},
                                                ),
                                              ),
                                            );
                                          },
                                          separatorBuilder: (_, __) =>
                                              const SizedBox(width: 5),
                                          itemCount:
                                              controller.positions!.length,
                                        );
                                      }),
                                ),
                        ),
                      ],
                    ),
                  ),
                  GetBuilder<ShiftActivitiesStatsController>(
                    id: 'positionTours',
                    builder: (controller) {
                      if (controller.selectedPosition == null) {
                        return Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "AppLocalizations.of(context)",
                                // .noPositionsWithTours
                                // .capitalize
                                // ,
                                style: AppTypography.bodyText2TextStyle
                                    .copyWith(fontSize: 14),
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
                      if (Session.shift?.positionId ==
                          controller.selectedPosition?.id) {
                        return GetBuilder<ShiftActivitiesService>(
                          id: 'ShiftActivitiesPage',
                          builder: (_) {
                            return ShiftActivitiesPage.buildShiftActivitiesBody(
                                context);
                          },
                        );
                      }
                      final tabs =
                          controller.tours.asMap().entries.map((entry) {
                        final tour = entry.value;
                        final tabColor = tour.isNotStarted
                            ? AppColors.rPointNotStarted
                            : tour.isFinished
                                ? AppColors.rPointFinished
                                : AppColors.rPointInProgress;
                        return Tab(
                          child: Row(
                            children: [
                              Container(
                                width: 15,
                                height: 15,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: tabColor,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                'Tour ${entry.key + 1}',
                                style: AppTheme().typography.tabTitle2Style,
                              ),
                            ],
                          ),
                        );
                      }).toList();
                      final tabsContent = controller.tours
                          .fold<List<List<ReportingPoint>>>(
                              [],
                              (result, tour) => result
                                ..add(tour.path
                                    .map((tp) => tp.reportingPoint)
                                    .toList()));

                      if (controller.unplannedRPoints.isNotEmpty) {
                        tabs.insert(
                          0,
                          Tab(
                            child: Row(
                              children: [
                                Container(
                                  width: 15,
                                  height: 15,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.rPointFinished,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Unplanned',
                                  style: AppTheme().typography.tabTitle2Style,
                                ),
                              ],
                            ),
                          ),
                        );
                        tabsContent.insert(0, controller.unplannedRPoints);
                      }
                      return DefaultTabController(
                        length: controller.tabsLength,
                        child: Expanded(
                          child: Column(
                            children: [
                              if (tabs.isNotEmpty)
                                TabBar(
                                  isScrollable: true,
                                  indicator: BoxDecoration(
                                    color: AppTheme().colors.selectedTab,
                                    border: const Border(
                                        bottom: BorderSide(
                                            width: 2,
                                            color: AppColors.primaryAccent)),
                                  ),
                                  tabs: tabs,
                                ),
                              Expanded(
                                child: tabsContent.isNotEmpty
                                    ? TabBarView(
                                        physics:
                                            const NeverScrollableScrollPhysics(),
                                        children: tabsContent.map((rPoints) {
                                          final tour =
                                              controller.tours.firstWhere(
                                            (tour) =>
                                                tour.tourId ==
                                                rPoints.first.tourId,
                                            orElse: () => null!,
                                          );
                                          return _buildTabWithRPoints(
                                              rPoints, tour);
                                        }).toList(),
                                      )
                                    : Center(
                                        child: Text(
                                          "",
                                          // HomeController.to.isOnline
                                          //     ? AppLocalizations.of(context)
                                          //         .noReportingPoints
                                          //     : AppLocalizations.of(context)
                                          //         .waitingForNetwork
                                          //         .capitalizeFirst,
                                          style: AppTheme()
                                              .typography
                                              .bgText3Style,
                                        ),
                                      ),
                              ),
                              Obx(() {
                                return ShiftActivitiesPage.buildBottomButtons(
                                  isMapVisible: Session.hasShiftStarted!
                                      ? ShiftActivitiesService.to!
                                          .isMapVisible()
                                      : controller.isMapVisible(),
                                  mapToggleCallback: Session.hasShiftStarted!
                                      ? ShiftActivitiesService
                                          .to!.toggleMapVisibility
                                      : controller.toggleMapVisibility,
                                );
                              }),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
              NotificationsDrawer(controller: HomeController.to),
              Obx(() {
                if (controller.loadingState() == ViewState.loading) {
                  Loader.show(context, themeData: null as ThemeData);
                } else {
                  Loader.hide();
                }
                return const SizedBox();
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabWithRPoints(List<ReportingPoint> rPoints, Tour tour) {
    return Obx(() {
      final isMapVisible = Session.hasShiftStarted!
          ? ShiftActivitiesService.to!.isMapVisible()
          : controller.isMapVisible();
      return isMapVisible
          ? TourMap(rPoints: rPoints)
          : Column(
              children: [
                if (tour != null) _buildToursTime(tour),
                Expanded(
                  child: ListView.separated(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: EdgeInsets.zero,
                    itemBuilder: (context, index) {
                      return Column(
                        children: [
                          if (index == 0) const TelloDivider(),
                          ExpandableRPointStatItem(
                            key: UniqueKey(),
                            rPoint: rPoints[index],
                          ),
                          if (index + 1 == rPoints.length) const TelloDivider(),
                        ],
                      );
                    },
                    separatorBuilder: (_, __) => const TelloDivider(),
                    itemCount: rPoints.length,
                  ),
                ),
              ],
            );
    });
  }
}

Widget _buildToursTime(Tour tour) {
  const Icon clockIcon = Icon(
    Icons.access_time,
    color: AppColors.white,
    size: 20,
  );
  var startedAt = tour.startedAt != null
      ? "${DateFormat(AppSettings().timeFormat).format(dateTimeFromSeconds(tour.startedAt!, isUtc: true)!.toLocal())}"
      : "-:-";
  var endetAt = tour.endedAt != null
      ? "${DateFormat(AppSettings().timeFormat).format(dateTimeFromSeconds(tour.endedAt!, isUtc: true)!.toLocal())}"
      : "-:-";
  return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
      color: AppTheme().colors.listItemBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  clockIcon,
                  const SizedBox(width: 5),
                  clockIcon,
                ],
              ),
              const SizedBox(width: 5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "{AppLocalizations.of(Get.context).startTime.capitalize}:",
                    style: AppTheme().typography.chatQuoteTitleStyle,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "{AppLocalizations.of(Get.context).endTime.capitalize}:",
                    style: AppTheme().typography.chatQuoteTitleStyle,
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${tour.timeRule!.fromTime}",
                    style: AppTheme().typography.chatQuoteTitleStyle,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "${tour.timeRule!.toTime}",
                    style: AppTheme().typography.chatQuoteTitleStyle,
                  ),
                ],
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                children: [
                  clockIcon,
                  const SizedBox(width: 5),
                  clockIcon,
                ],
              ),
              const SizedBox(width: 5),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "AppLocalizations.of(Get.context).startedAt.capitalize",
                    style: AppTheme().typography.chatQuoteTitleStyle,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    "AppLocalizations.of(Get.context).endedAt.capitalize",
                    style: AppTheme().typography.chatQuoteTitleStyle,
                  ),
                ],
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    startedAt,
                    style: AppTheme().typography.chatQuoteTitleStyle,
                  ),
                  const SizedBox(width: 5),
                  Text(
                    endetAt,
                    style: AppTheme().typography.chatQuoteTitleStyle,
                  ),
                ],
              ),
            ],
          ),
        ],
      ));
}

class ExpandableRPointStatItem extends GetView<ShiftActivitiesStatsController> {
  const ExpandableRPointStatItem({Key? key, required this.rPoint})
      : super(key: key);

  final ReportingPoint rPoint;

  @override
  Widget build(BuildContext context) {
    return GetBuilder<ShiftActivitiesStatsController>(
        id: 'reportingPoint${rPoint.id}',
        builder: (controller) {
          final color = rPoint.isFinished
              ? AppColors.rPointFinished
              : rPoint.isNotStarted
                  ? AppColors.rPointNotStarted
                  : AppColors.rPointInProgress;
          final rPointHeader = buildStatsRPointHeader(
            color,
            () => LayoutUtils.buildDescription(rPoint.description),
          );
          return ExpandableNotifier(
            controller: rPoint.expandableController,
            child: Expandable(
              collapsed: rPoint.currentVisit.hasActivities
                  ? GestureDetector(
                      onTap: rPoint.expand,
                      child: rPointHeader,
                    )
                  : rPointHeader,
              expanded: rPoint.currentVisit.hasActivities
                  ? Column(
                      children: [
                        GestureDetector(
                          onTap: rPoint.collapse,
                          child: rPointHeader,
                        ),
                        Divider(
                            indent: 10,
                            endIndent: 10,
                            color: AppTheme().colors.dividerLight),
                        SizedBox(
                          height: Get.height * 0.3,
                          child: ListView.separated(
                            itemBuilder: (context, i) {
                              final activity =
                                  rPoint.currentVisit.activities[i];
                              return _buildActivityResultCard(
                                  activity, context, i);
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 5),
                            itemCount: rPoint.currentVisit.activities.length,
                          ),
                        )
                      ],
                    )
                  : const SizedBox(),
            ),
          );
        });
  }

  Widget buildStatsRPointHeader(
    Color color,
    VoidCallback onInfoTap,
  ) {
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
                TextOneLine(
                  rPoint.title,
                  style: AppTheme().typography.bgTitle2Style,
                ),
                if (rPoint.visitsCounter > 1)
                  Text(
                    " AppLocalizations.of(Get.context)",
                    style: AppTheme().typography.bgText4Style,
                  ),
              ],
            ),
          ),
          if (rPoint.currentVisit != null) ...[
            const SizedBox(width: 5),
            if (rPoint.qrValidationRequired) ...[
              SvgPicture.asset(
                'assets/images/qrcode_rp_validation.svg',
                color: rPoint.currentVisit.isQrCheckPassed!
                    ? AppColors.primaryAccent
                    : AppColors.danger,
                width: 20,
              ),
              const SizedBox(width: 5),
            ],
            if (rPoint.geoValidationRequired) ...[
              SvgPicture.asset(
                'assets/images/street_view.svg',
                color: rPoint.currentVisit.isLocationCheckPassed!
                    ? AppColors.primaryAccent
                    : AppColors.danger,
                width: 20,
              ),
              const SizedBox(width: 5),
            ],
            Obx(() {
              return PortalTarget(
                visible: rPoint.isChooseVisitPopupOpen(),
                portalFollower: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => rPoint.isChooseVisitPopupOpen(false),
                ),
                child: PortalTarget(
                  visible: rPoint.isChooseVisitPopupOpen(),
                  //: _buildChooseVisitPopup(),
                  anchor: Alignment.center as Anchor,
                  // anchor: Alignment.bottomLeft,
                  closeDuration: const Duration(milliseconds: 100),
                  child: InkWell(
                    onTap: rPoint.visitsCounter > 1
                        ? rPoint.isChooseVisitPopupOpen.toggle
                        : null,
                    child: Container(
                      width: LayoutConstants.rPointVisitDateTimeWidth,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 3),
                      decoration: BoxDecoration(
                        borderRadius:
                            const BorderRadius.all(Radius.circular(7)),
                        border: Border.all(
                            color: AppColors.primaryAccent, width: 2),
                      ),
                      child: Text(
                        rPoint.currentVisit.finishDateTimeFormatted
                            .replaceFirst(RegExp('  '), '\n'),
                        style: AppTheme()
                            .typography
                            .bgText4Style
                            .copyWith(height: 1.2),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 5),
          ],
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

  Widget _buildChooseVisitPopup() {
    return ConstrainedBox(
      constraints: const BoxConstraints(
        maxHeight: 200,
        maxWidth: 140,
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: rPoint.isChooseVisitPopupOpen() ? 1 : 0,
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
              final visit = rPoint.visitsWithoutCurrent[i];
              return GestureDetector(
                onTap: () => controller.selectRPointVisit(rPoint, visit),
                child: SizedBox(
                  height: 30,
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          visit.finishDateTimeFormatted,
                          style: AppTheme().typography.bgText3Style,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (_, __) =>
                Divider(color: AppTheme().colors.dividerLight),
            itemCount: rPoint.visitsWithoutCurrent.length,
          ),
        ),
      ),
    );
  }

  Widget _buildActivityResultCard(
      ShiftActivityTask activityTask, BuildContext context, int i) {
    final activityResult = activityTask.result;
    final mediaList = activityResult.imageUrls! + activityResult.videoUrls!;
    return IntrinsicHeight(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 10),
            child: Row(
              children: [
                CircularIconButton(
                  buttonSize: 40,
                  onTap: () =>
                      LayoutUtils.buildDescription(activityTask.description),
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: SvgPicture.asset(
                      'assets/images/rp_info_icon.svg',
                      color: AppColors.primaryAccent,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    activityTask.name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTheme().typography.listItemTitleStyle,
                  ),
                ),
                const SizedBox(width: 5),
                if (activityResult.isOk != null)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      borderRadius: const BorderRadius.all(Radius.circular(5)),
                      color: activityResult.isOk!
                          ? AppColors.primaryAccent
                          : AppColors.danger,
                    ),
                    child: Text(
                      activityResult.isOk!
                          ? " AppLocalizations.of(context).passed.capitalize"
                          : " AppLocalizations.of(context).failed.capitalize",
                      style: AppTheme().typography.activityStatusTextStyle,
                    ),
                  ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 0),
            child: Text(activityResult.comment!,
                style: AppTheme().typography.bgText3Style),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(10, 5, 10, 10),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: mediaList.asMap().entries.map((e) {
                  final url = e.value;
                  final isLastItem = e.key + 1 == mediaList.length;
                  return url.isImageFileName
                      ? GestureDetector(
                          onTap: () => showImage(url),
                          child: Container(
                            margin: EdgeInsets.only(right: isLastItem ? 0 : 5),
                            height: 50,
                            width: 50,
                            child: CachedNetworkImage(
                              imageUrl: url,
                              fit: BoxFit.cover,
                            ),
                          ),
                        )
                      : GestureDetector(
                          onTap: () => playVideo(url),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Container(
                                margin:
                                    EdgeInsets.only(right: isLastItem ? 0 : 5),
                                height: 50,
                                width: 50,
                                child: FutureBuilder<Uint8List?>(
                                  future: VideoThumbnail.thumbnailData(
                                    video: url,
                                    maxHeight: 100,
                                  ),
                                  builder: (context, snapshot) {
                                    return snapshot.hasData
                                        ? Image.memory(snapshot.data!,
                                            fit: BoxFit.cover)
                                        : const Center(
                                            child: CircularProgressIndicator());
                                  },
                                ),
                              ),
                              Positioned(
                                child: ClipOval(
                                  child: Container(
                                    alignment: Alignment.center,
                                    height: 30,
                                    width: 30,
                                    color: Colors.black38,
                                    child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void showImage(String url) {
    Get.dialog(GestureDetector(
      onTap: Get.back,
      child: Scaffold(
        backgroundColor: Colors.black26,
        appBar: AppBar(
            backgroundColor: AppTheme().colors.appBar,
            title: Row(children: [
              Text(
                LocalizationService().of().viewImage,
                style: AppTypography.subtitleChatViewersTextStyle,
              )
            ])),
        body: SafeArea(
          child: Center(
            child: InteractiveViewer(
                child: CachedNetworkImage(
              imageUrl: url,
              fit: BoxFit.contain,
              placeholder: (_, __) {
                return Container(
                  height: 150,
                  width: 150,
                  color: Colors.black26,
                  child: Center(
                    child: SpinKitWave(
                      color: AppColors.loadingIndicator,
                      itemCount: 8,
                      size: 35,
                    ),
                  ),
                );
              },
              errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
            )),
          ),
        ),
      ),
    ));
  }

  void playVideo(String url) {
    Get.dialog(GestureDetector(
      onTap: Get.back,
      child: Scaffold(
        backgroundColor: Colors.black26,
        appBar: AppBar(
            backgroundColor: AppTheme().colors.appBar,
            title: Row(children: [
              Text(
                LocalizationService().of().videoPlayer,
                style: AppTypography.subtitleChatViewersTextStyle,
              )
            ])),
        body: SafeArea(
          child: Center(
            child: ChatVideoPlayer(
                {"1": VideoSource(video: VideoPlayerController.network(url))}),
          ),
        ),
      ),
    ));
    /* Get.dialog(
      ChatVideoPlayer({"1": VideoSource(video: VideoPlayerController.file(file))}),
    );*/
  }
}
