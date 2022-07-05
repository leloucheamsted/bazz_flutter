import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/incoming_event.dart';
import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/modules/chat/chat_controller.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_controller.dart';
import 'package:bazz_flutter/modules/home_module/widgets/bordered_icon_button.dart';
import 'package:bazz_flutter/modules/home_module/widgets/status_chip.dart';
import 'package:bazz_flutter/modules/p2p_video/video_chat_controller.dart';
import 'package:bazz_flutter/modules/shift_activities/models/reporting_point.dart';
import 'package:bazz_flutter/modules/shift_activities/widgets/rpoint_visits_tabs_widget.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/shared_widgets/battery_indicator.dart';
import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:latlong/latlong.dart' as flutter_cor;
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:intl/intl.dart' as intl;
// import 'package:latlong/latlong.dart' as flutter_cor;
import 'package:signal_strength_indicator/signal_strength_indicator.dart';

class InfoWindowShape extends ShapeBorder {
  const InfoWindowShape({required this.width});

  final double width;

  @override
  EdgeInsetsGeometry get dimensions => EdgeInsets.zero;

  // @override
  // Path getInnerPath(Rect rect,
  //         {Key? key, required TextDirection textDirection}) =>
  //     null as ShapeBorder getOuterPath(Path Function(Rect, {TextDirection? textDirection});
  // final double borderRadius = 5;

  // @override
  // Path getOuterPath(Rect rect, {required TextDirection textDirection}) {
  //   final startX = rect.topLeft.dx;
  //   final endY = rect.bottomLeft.dy;
  //   return Path.combine(
  //     PathOperation.union,
  //     Path()
  //       ..addRRect(RRect.fromRectAndRadius(rect, Radius.circular(borderRadius)))
  //       ..close(),
  //     Path()
  //       ..moveTo(startX + width / 2 - 10, endY)
  //       ..lineTo(startX + width / 2, endY + 10)
  //       ..lineTo(startX + width / 2 + 10, endY)
  //       ..close(),
  //   );
  // }

  // //@override
  // @override
  // void paint(Canvas canvas, Rect rect,
  //     {required TextDirection textDirection}) {}

  //@override
  @override
  ShapeBorder scale(double t) => this;

  @override
  Path getInnerPath(Rect rect, {TextDirection? textDirection}) {
    // TODO: implement getInnerPath
    throw UnimplementedError();
  }

  @override
  Path getOuterPath(Rect rect, {TextDirection? textDirection}) {
    // TODO: implement getOuterPath
    throw UnimplementedError();
  }

  @override
  void paint(Canvas canvas, Rect rect, {TextDirection? textDirection}) {
    // TODO: implement paint
  }
}

class EntityDetailsInfo {
  static const _posStatusString = {
    PositionStatus.active: 'active',
    PositionStatus.inactive: 'inactive',
    PositionStatus.outOfRange: 'out of range',
  };

  static LatLng getWindowLatLng(
      {required RxPosition pos, required RxUser user, bool static = false}) {
    late LatLng windowLatLng;

    if (pos != null) {
      windowLatLng = (static
          ? pos.coordinates.toMapLatLng()
          : pos.workerLocation().toMapLatLng()) as LatLng;
    } else if (user != null) {
      windowLatLng = user.location().coordinates!.toMapLatLng() as LatLng;
    }
    return windowLatLng;
  }

  static LatLng getWindowMapLatLng(
      {RxPosition? pos, RxUser? user, bool static = false}) {
    late LatLng windowLatLng;

    if (pos != null) {
      windowLatLng = (static
          ? pos.coordinates.toMapLatLng()
          : pos.workerLocation().toMapLatLng()) as LatLng;
    } else if (user != null) {
      windowLatLng = user.location().coordinates?.toMapLatLng() as LatLng;
    }
    return windowLatLng;
  }

  static Widget createInitialPositionDetails({
    RxPosition? pos,
    bool static = false,
  }) {
    final workerLocation = pos?.workerLocation().toMapLatLng();
    final buttons = [
      if (workerLocation != null)
        BorderedIconButton(
          width: 50,
          fillColor: AppColors.secondaryButton,
          onTap: () => _showOnMap(workerLocation),
          child: const Icon(
            Icons.location_searching,
            color: AppColors.brightIcon,
          ),
        )
    ];

    if (buttons.isNotEmpty)
      FlutterMapController.to.displayTopActionButtons$(buttons);

    final infoWidget = Container(
      padding: const EdgeInsets.all(8),
      decoration: ShapeDecoration(
        color: AppTheme().colors.infoWindowBg,
        shape: const InfoWindowShape(
            width: LayoutConstants.flutterMapInfoWindowWidth),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(pos!.title, style: AppTheme().typography.listItemTitleStyle),
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: Center(
              child: Container(
                height: 100,
                width: 200,
                color: AppTheme().colors.mainBackground,
                child: pos.imageSrc != null
                    ? CachedNetworkImage(imageUrl: pos.imageSrc)
                    : FittedBox(
                        child: Icon(
                        Icons.home,
                        color: AppTheme().colors.icon,
                      )),
              ),
            ),
          ),
          Divider(color: AppTheme().colors.divider),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Owner',
                      style: AppTheme().typography.memberInfoWindowText2Style),
                  SizedBox(
                    width: 100,
                    child: Text(
                      pos.customer.value != null
                          ? pos.customer.value.fullName!
                          : '------ ',
                      style: pos.customer.value != null
                          ? AppTheme().typography.memberInfoWindowTextStyle
                          : AppTheme().typography.memberInfoWindowText2Style,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Emergency Phone',
                      style: AppTheme().typography.memberInfoWindowText2Style),
                  Text(
                    pos.customer.value != null
                        ? pos.customer.value.phone
                        : '------ ',
                    style: pos.customer.value != null
                        ? AppTheme().typography.memberInfoWindowTextStyle
                        : AppTheme().typography.memberInfoWindowText2Style,
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );

    return infoWidget;
  }

  ///CAUTION! Either RxPosition or RxUser with (or w/o) posInfoCard must be provided!
  static Widget createDetails({
    RxPosition? pos,
    RxUser? user,
    PositionInfoCard? posInfoCard,
    bool static = false,
    bool forMap = false,
  }) {
    assert(
        pos != null || (posInfoCard != null && user != null) || user != null);
    //TODO: display battery and network status

    //NULLABLE, because we can have a position w/o worker!
    final RxUser operator = user ?? pos!.worker();

    final avatar = operator.avatar;
    final fullName = operator.fullName ?? "---";
    final rating = operator.rating;
    final ratingColorHex = AppSettings()
        .ratingColorSettings
        .firstWhere((cfg) => cfg.ratingRange.contains(rating))
        .color;
    final ratingColor = HexColor.fromHex(ratingColorHex);
    final rateDecoration = BoxDecoration(
      shape: BoxShape.circle,
      color: ratingColor,
    );

    final hasGPSSignal = operator.hasGPSSignal;
    final int batteryLevel =
        operator.deviceCard.deviceState.value.batteryPercentage ?? 0;
    final int networkStrength =
        operator.deviceCard.deviceState.value.networkStrength ?? 0;
    final bool isCharging =
        operator.deviceCard.deviceState.value.isDeviceCharging ?? false;
    final bool networkNotAvailable =
        operator.deviceCard.deviceState.value.networkStrength == 0;
    final double networkStrengthPercentage = networkNotAvailable
        ? 0
        : (networkStrength /
            (user?.deviceCard.deviceState.value.mobileNetworkType ==
                    MobileNetworkType.GSM
                ? 5.0
                : 4.0));

    late DateTime shiftStartDateTime;
    late DateTime positionStatusUpdatedAt;
    final operatorOnlineUpdatedAt =
        dateTimeFromSeconds(operator.onlineUpdatedAt as int, isUtc: true);
    late DateTime alertnessStateUpdatedAt;
    late AlertCheckState alertnessState;
    late Color positionStatusColor;
    late Color operatorStatusColor;
    late String positionStatusText;
    late String operatorStatusText;
    final operatorLocation = operator.location().coordinates?.toMapLatLng();
    late LatLng positionLocation;

    if (operator.isOnline()) {
      operatorStatusColor = AppColors.primaryAccent;
      operatorStatusText = "LocalizationService().of().online";
    } else {
      operatorStatusColor = AppColors.offline;
      operatorStatusText = "LocalizationService().of().offline";
    }

    if (pos != null) {
      positionStatusText = _posStatusString[pos.status()]!.capitalize!;
      positionStatusColor = pos.status() == PositionStatus.active
          ? AppColors.primaryAccent
          : pos.status() == PositionStatus.inactive
              ? AppColors.offline
              : AppColors.outOfRange;
      shiftStartDateTime = (pos.shiftStartedAt != null
          ? dateTimeFromSeconds(pos.shiftStartedAt, isUtc: true)
          : null)!;
      positionStatusUpdatedAt =
          dateTimeFromSeconds(pos.statusUpdatedAt, isUtc: true)!;
      alertnessStateUpdatedAt =
          dateTimeFromSeconds(pos.alertCheckStateUpdatedAt, isUtc: true)!;
      alertnessState = pos.alertCheckState();

      positionLocation = pos.coordinates.toMapLatLng() as LatLng;
    } else if (posInfoCard != null) {
      positionStatusText = _posStatusString[posInfoCard.status]!.capitalize!;
      positionStatusColor = posInfoCard.status == PositionStatus.active
          ? AppColors.primaryAccent
          : posInfoCard.status == PositionStatus.inactive
              ? AppColors.offline
              : AppColors.outOfRange;
      positionStatusUpdatedAt =
          dateTimeFromSeconds(posInfoCard.statusUpdatedAt, isUtc: true)!;
      alertnessStateUpdatedAt = dateTimeFromSeconds(
          posInfoCard.alertCheckStateUpdatedAt,
          isUtc: true)!;
      alertnessState = posInfoCard.alertCheckState;
    }

    final formattedStatusUpdatedAt = positionStatusUpdatedAt != null
        ? positionStatusUpdatedAt.isBefore(
                DateTime.now().toUtc().subtract(const Duration(days: 1)))
            ? intl.DateFormat(AppSettings().dateTimeFormatShort)
                .format(positionStatusUpdatedAt.toLocal())
            : intl.DateFormat(AppSettings().timeFormat)
                .format(positionStatusUpdatedAt.toLocal())
        : null;

    final formattedAlertnessStateUpdatedAt = alertnessStateUpdatedAt != null
        ? alertnessStateUpdatedAt.isBefore(
                DateTime.now().toUtc().subtract(const Duration(days: 1)))
            ? intl.DateFormat(AppSettings().dateTimeFormatShort)
                .format(alertnessStateUpdatedAt.toLocal())
            : intl.DateFormat(AppSettings().timeFormat)
                .format(alertnessStateUpdatedAt.toLocal())
        : null;

    final formattedUserOnlineUpdatedAt = operatorOnlineUpdatedAt != null
        ? operatorOnlineUpdatedAt.isBefore(
                DateTime.now().toUtc().subtract(const Duration(days: 1)))
            ? intl.DateFormat(AppSettings().dateTimeFormatShort)
                .format(operatorOnlineUpdatedAt.toLocal())
            : intl.DateFormat(AppSettings().timeFormat)
                .format(operatorOnlineUpdatedAt.toLocal())
        : null;

    final isOperatorMe = Session.user!.id == operator.id;

    final isVideoChatEnabled = AppSettings().enableVideoChatService &&
        Session.isSupervisor &&
        operator != null &&
        HomeController.to.isOnline &&
        !isOperatorMe &&
        operator.isOnline();

    final drawPathToggle = _buildDrawPathToggle(pos!, user!, forMap: forMap);
    final trackUserToggle = _buildTrackUserToggle(pos, user, forMap: forMap);
    final privateCallToggle = Session.isSupervisor && !isOperatorMe
        ? _buildPrivateCallToggle(operator, forMap: forMap)
        : null;
    final startVideoChatButton = isVideoChatEnabled
        ? _buildVideoChatButton(operator, forMap: forMap)
        : null;
    final startPrivateChatButton = !isOperatorMe && Session.isSupervisor
        ? _buildPrivateChatButton(operator, forMap: forMap)
        : null;

    if (forMap) {
      final showBaseOnMapButton = positionLocation != null
          ? BorderedIconButton(
              fillColor: AppColors.secondaryButton,
              width: 38,
              onTap: () => _showOnMap(positionLocation as flutter_cor.LatLng),
              child: const Icon(Icons.location_searching,
                  color: AppColors.brightIcon, size: 20),
            )
          : null;
      if (FlutterMapController.to.displayTopActionButtons) {
        FlutterMapController.to.displayTopActionButtons$([
          drawPathToggle,
          trackUserToggle,
          if (showBaseOnMapButton != null) showBaseOnMapButton,
          if (privateCallToggle != null) privateCallToggle,
          if (startVideoChatButton != null) startVideoChatButton,
          if (startPrivateChatButton != null) startPrivateChatButton,
        ]);
      }
    }

    final infoWidget = Container(
      padding: const EdgeInsets.all(LayoutConstants.compactPadding),
      decoration: forMap
          ? ShapeDecoration(
              color: AppTheme().colors.infoWindowBg,
              shape: const InfoWindowShape(
                  width: LayoutConstants.flutterMapInfoWindowWidth),
            )
          : BoxDecoration(
              color: AppTheme().colors.infoWindowBg,
            ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (Session.user!.isSupervisor!)
                _buildRate(rateDecoration, rating),
              if ((Session.user!.isSupervisor! || Session.user!.isCustomer!) &&
                  !forMap &&
                  (operatorLocation != null || positionLocation != null))
                CircularIconButton(
                  onTap: () {
                    // return _showOnMap((operator.hasActiveSession() as Object)
                    //     ? operatorLocation as LatLng
                    //     : positionLocation as flutter_cor.LatLng) as Object;
                  },
                  buttonSize: 30,
                  child: Icon(Icons.location_searching,
                      color: AppTheme().colors.icon),
                ),
              if (!forMap &&
                  (isVideoChatEnabled || !isOperatorMe) &&
                  operator != null)
                Row(
                  children: [
                    if (privateCallToggle != null) ...[
                      const SizedBox(width: 5),
                      privateCallToggle,
                    ],
                    if (startVideoChatButton != null) ...[
                      const SizedBox(width: 5),
                      startVideoChatButton,
                    ],
                    if (startPrivateChatButton != null) ...[
                      const SizedBox(width: 5),
                      startPrivateChatButton,
                      const SizedBox(width: 5),
                    ],
                  ],
                ),
              if (Session.isNotSupervisor && Session.isNotCustomer)
                const Spacer(),
              Row(
                children: [
                  buildBatteryIndicator(batteryLevel, isCharging),
                  const SizedBox(width: 5),
                  _buildNetworkIndicator(
                      networkStrengthPercentage, networkNotAvailable),
                ],
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Row(
              children: [
                GestureDetector(
                    onTap: () {
                      _showImage(avatar != null && avatar.isNotEmpty
                          ? CachedNetworkImage(imageUrl: avatar)
                          : const FittedBox(
                              child: Icon(
                              Icons.account_circle,
                              color: AppColors.primaryAccent,
                            )));
                    },
                    child: ClipOval(
                        child: Container(
                      height: 45,
                      width: 45,
                      color: AppTheme().colors.mainBackground,
                      child: avatar != null && avatar.isNotEmpty
                          ? CachedNetworkImage(imageUrl: avatar)
                          : const FittedBox(
                              child: Icon(
                              Icons.account_circle,
                              color: AppColors.primaryAccent,
                            )),
                    ))),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    fullName,
                    style: AppTheme()
                        .typography
                        .bgTitle2Style
                        .copyWith(height: 1.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 5),
                if (formattedUserOnlineUpdatedAt != null) ...[
                  const SizedBox(width: 5),
                  SizedBox(
                    width: forMap ? 70 : null,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        StatusChip(
                          color: operatorStatusColor,
                          text: operatorStatusText.capitalize as String,
                          showIndicator: false,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                        ),
                        if (forMap) const SizedBox(height: 2),
                        Text(
                          '${LocalizationService().of().since} $formattedUserOnlineUpdatedAt',
                          style: AppTheme()
                              .typography
                              .memberInfoWindowText2Style
                              .copyWith(height: forMap ? 1.25 : null),
                          textAlign: TextAlign.end,
                        )
                      ],
                    ),
                  ),
                ]
              ],
            ),
          ),
          Divider(height: 13, color: AppTheme().colors.divider),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService().of().position,
                      style: AppTheme().typography.memberInfoWindowText2Style,
                    ),
                    TextOneLine(
                      // ignore: unnecessary_string_interpolations
                      posInfoCard?.title ?? '${pos.title}',
                      style: posInfoCard?.title != null || pos.title != null
                          ? AppTheme().typography.memberInfoWindowTextStyle
                          : AppTheme().typography.memberInfoWindowText2Style,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Column(
                  children: [
                    Text(LocalizationService().of().gpsStatus,
                        style:
                            AppTheme().typography.memberInfoWindowText2Style),
                    TextOneLine(
                      // ignore: unnecessary_string_interpolations
                      hasGPSSignal
                          ? LocalizationService().of().hasSignal
                          : LocalizationService().of().noSignal,
                      style: AppTheme()
                          .typography
                          .memberInfoWindowTextStyle
                          .copyWith(
                            color: hasGPSSignal
                                ? AppColors.primaryAccent
                                : AppColors.danger,
                          ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 3),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(LocalizationService().of().startedAt.capitalize,
                        style:
                            AppTheme().typography.memberInfoWindowText2Style),
                    Text(
                      shiftStartDateTime != null
                          ? intl.DateFormat(AppSettings().timeFormat)
                              .format(shiftStartDateTime.toLocal())
                          : '------ ',
                      style: shiftStartDateTime != null
                          ? AppTheme().typography.memberInfoWindowTextStyle
                          : AppTheme().typography.memberInfoWindowText2Style,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!forMap) Divider(height: 13, color: AppTheme().colors.divider),
          if (!forMap)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      LocalizationService().of().simNumber.capitalize,
                      style: AppTheme().typography.memberInfoWindowText2Style,
                    ),
                    TextOneLine(
                      operator.deviceCard.deviceDetails.simSerialNumber,
                      style: operator.deviceCard != null
                          ? AppTheme().typography.memberInfoWindowTextStyle
                          : AppTheme().typography.memberInfoWindowText2Style,
                    ),
                  ],
                ),
                const SizedBox(width: 3),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      LocalizationService().of().itemNumber.capitalize,
                      style: AppTheme().typography.memberInfoWindowText2Style,
                    ),
                    TextOneLine(
                      operator.deviceCard.deviceDetails.itemNumber,
                      style: operator.deviceCard != null
                          ? AppTheme().typography.memberInfoWindowTextStyle
                          : AppTheme().typography.memberInfoWindowText2Style,
                    ),
                  ],
                ),
              ],
            ),
          if (pos != null || posInfoCard != null) ...[
            Divider(height: 13, color: AppTheme().colors.divider),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    StatusChip(
                      color: positionStatusColor,
                      text: positionStatusText,
                      showIndicator: false,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                    ),
                    Text(
                      '${LocalizationService().of().since} $formattedStatusUpdatedAt',
                      style: AppTheme().typography.memberInfoWindowText2Style,
                    )
                  ],
                ),
                if (alertnessState == AlertCheckState.failed)
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      StatusChip(
                        color: AppColors.alertnessFailed,
                        text: LocalizationService().of().alertnessFailed,
                        showIndicator: false,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                      ),
                      Text(
                        '${LocalizationService().of().since} $formattedAlertnessStateUpdatedAt',
                        style: AppTheme().typography.memberInfoWindowText2Style,
                      )
                    ],
                  )
                else
                  const SizedBox(),
              ],
            )
          ],
        ],
      ),
    );

    return forMap
        ? Column(
            children: [
              const Spacer(),
              infoWidget,
            ],
          )
        : infoWidget;
  }

  static Widget createEventDetails(IncomingEvent event) {
    final timeCreateEvent =
        dateTimeFromSeconds(event.createdAt!, isUtc: true)!.toLocal();
    final infoWidget = Container(
      padding: const EdgeInsets.all(LayoutConstants.compactPadding),
      decoration: ShapeDecoration(
        color: AppTheme().colors.infoWindowBg,
        shape: const InfoWindowShape(
            width: LayoutConstants.flutterMapInfoWindowWidth),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                '{AppLocalizations.of(Get.context).type.capitalize}: ',
                style: AppTheme().typography.listItemTitleStyle,
              ),
              SizedBox(
                width: 22,
                height: 22,
                child: event.iconCfg.iconAssetExists
                    ? SvgPicture.asset(
                        'assets/images/events/${event.iconCfg.id}.svg')
                    : SvgPicture.network(
                        event.iconCfg.url,
                        placeholderBuilder: (_) {
                          return SvgPicture.asset(
                              'assets/images/events/default.svg');
                        },
                      ),
              ),
              const SizedBox(width: 3),
              Text(
                event.title.capitalize!,
                style: AppTheme().typography.listItemTitleStyle,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '{AppLocalizations.of(Get.context).time.capitalize}: ${intl.DateFormat(AppSettings().timeFormat).format(timeCreateEvent)}',
            style: AppTheme().typography.listItemTitleStyle,
          ),
          const SizedBox(height: 5),
          Text(
            '{AppLocalizations.of(Get.context).reporter.capitalize}: ${event.ownerTitle.capitalize}',
            style: AppTheme().typography.listItemTitleStyle,
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                '{AppLocalizations.of(Get.context).priority.capitalize}: ',
                style: AppTheme().typography.listItemTitleStyle,
              ),
              Text(
                event.priorityTitle.capitalize!,
                style: AppTheme()
                    .typography
                    .listItemTitleStyle
                    .copyWith(color: event.priorityColor),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Text(
                '{AppLocalizations.of(Get.context).status.capitalize}: ',
                style: AppTheme().typography.listItemTitleStyle,
              ),
              Text(
                event.statusTitle.capitalize!,
                style: AppTheme()
                    .typography
                    .listItemTitleStyle
                    .copyWith(color: event.statusColor),
              ),
            ],
          ),
          if (event.eventParameters.isNotEmpty) ...[
            const Divider(color: AppColors.paleGray, height: 8),
            Text(
              event.eventParameters.speedLimitParams.stringify,
              style: AppTheme().typography.bgText4Style,
            ),
          ]
        ],
      ),
    );

    return Column(
      children: [
        const Spacer(),
        infoWidget,
      ],
    );
  }

  static Widget createReportingPointDetails(ReportingPoint rPoint) {
    final infoWidget = Container(
      padding: const EdgeInsets.all(LayoutConstants.compactPadding),
      decoration: ShapeDecoration(
        color: AppTheme().colors.infoWindowBg,
        shape:
            const InfoWindowShape(width: LayoutConstants.rPointInfoWindowWidth),
      ),
      child: RPointVisitsTabsWidget(
        key: ValueKey<String>(rPoint.id),
        rPoint: rPoint,
      ),
    );

    return Column(
      children: [
        const Spacer(),
        infoWidget,
      ],
    );
  }

  static Future<void> _showOnMap(flutter_cor.LatLng location) async {
    if (Get.isBottomSheetOpen!) Get.back();
    if (Get.currentRoute != AppRoutes.mapTabFullscreen) {
      HomeController.to.gotoBottomNavTab(BottomNavTab.map);
    } else {
      FlutterMapController.to.hideInfoWindowFullScreen();
    }
    await FlutterMapController.to
        .animateToLatLngZoom(location, zoomLevel: 19.0, keepZoom: true);
  }

  static Future<void> _openVideoPeerToUser(RxUser user) async {
    if (Get.isBottomSheetOpen!) Get.back();
    HomeController.to.gotoBottomNavTab(BottomNavTab.videoChat);
    VideoChatController.to.currentUser = user;
    await VideoChatController.to.invitePeer(user);
  }

  static Stack _buildNetworkIndicator(
      double networkStrengthPercentage, bool networkNotAvailable) {
    return Stack(
      children: [
        SizedBox(
          height: 13,
          width: 16,
          child: SignalStrengthIndicator.bars(
            value: networkStrengthPercentage,
            size: 50,
            barCount: 5,
            activeColor: Colors.blue,
            inactiveColor: Colors.blue[100],
          ),
        ),
        if (networkNotAvailable)
          const Positioned(
            top: 2,
            left: 3,
            child: Icon(
              Icons.close,
              color: AppColors.danger,
              size: 12,
            ),
          )
      ],
    );
  }

  // ignore: avoid_positional_boolean_parameters
  static Stack buildBatteryIndicator(int batteryLevel, bool isCharging,
      {Color mainColor = Colors.blueGrey,
      double size = 10.0,
      double width = 16.0,
      double height = 16.0,
      Color fillColor = Colors.green}) {
    return Stack(children: [
      SizedBox(
        width: width,
        height: height,
        child: Center(
          child: BatteryIndicator(
            batteryFromPhone: false,
            showPercentNum: false,
            batteryLevel: batteryLevel,
            style: BatteryIndicatorStyle.values[1],
            mainColor: mainColor,
            size: size,
            ratio: 3.0,
            fillColor: fillColor,
          ),
        ),
      ),
      if (isCharging)
        Positioned(
            top: 4,
            left: 2,
            child: Icon(
              FontAwesomeIcons.bolt,
              color: AppTheme().colors.icon,
              size: 8,
            ))
      else
        Container(),
    ]);
  }

  static Widget _buildPrivateChatButton(RxUser operator,
      {bool forMap = false}) {
    if (forMap) {
      return BorderedIconButton(
        fillColor: AppTheme().colors.disabledButton,
        width: 38,
        onTap: () {
          ChatController.to.onStartPrivateChatTap(operator);
        },
        child: const Icon(
          Icons.mail,
          color: AppColors.primaryAccent,
          size: 20,
        ),
      );
    }

    return CircularIconButton(
      color: AppTheme().colors.mainBackground,
      buttonSize: 28,
      onTap: () {
        ChatController.to.onStartPrivateChatTap(operator);
        Get.back();
      },
      child: const Padding(
        padding: EdgeInsets.all(2.0),
        child: FittedBox(
          child: Icon(
            Icons.mail,
            color: AppColors.primaryAccent,
          ),
        ),
      ),
    );
  }

  static Widget _buildVideoChatButton(RxUser operator, {bool forMap = false}) {
    if (forMap) {
      return BorderedIconButton(
        width: 38,
        fillColor: AppTheme().colors.disabledButton,
        onTap: () {
          _openVideoPeerToUser(operator);
        },
        child: const Icon(
          Icons.video_call,
          color: AppColors.primaryAccent,
          size: 20,
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(2),
      child: GestureDetector(
        onTap: () {
          _openVideoPeerToUser(operator);
          Get.back();
        },
        child: ClipOval(
          child: Container(
            height: 28,
            width: 28,
            color: AppTheme().colors.mainBackground,
            child: const FittedBox(
                child: Icon(
              Icons.video_call,
              color: AppColors.primaryAccent,
            )),
          ),
        ),
      ),
    );
  }

  static Widget _buildPrivateCallToggle(RxUser operator,
      {bool forMap = false}) {
    if (forMap) {
      return Obx(
        () {
          return BorderedIconButton(
            fillColor: HomeController.to.privateCallInProgress
                ? AppColors.primaryAccent.withOpacity(0.5)
                : AppTheme().colors.disabledButton,
            width: 38,
            onTap: () {
              if (HomeController.to.privateCallUser == null) {
                HomeController.to
                    .startPrivateCall(operator, canClosePrivateCall: true);
              } else {
                HomeController.to.stopPrivateCall();
              }
            },
            child: Icon(
              HomeController.to.privateCallInProgress
                  ? Icons.mic_off
                  : Icons.mic,
              color: HomeController.to.privateCallInProgress
                  ? AppColors.error
                  : AppColors.primaryAccent,
              size: 20,
            ),
          );
        },
      );
    }

    return Obx(
      () {
        return GestureDetector(
          onTap: () {
            if (HomeController.to.privateCallUser == null) {
              HomeController.to
                  .startPrivateCall(operator, canClosePrivateCall: true);
            } else {
              HomeController.to.stopPrivateCall();
            }
            Get.back();
          },
          child: ClipOval(
            child: Container(
              height: 28,
              width: 28,
              color: AppTheme().colors.mainBackground,
              child: FittedBox(
                  child: HomeController.to.privateCallUser == null
                      ? const Icon(
                          Icons.mic,
                          color: AppColors.primaryAccent,
                        )
                      : const Icon(
                          Icons.mic_off,
                          color: AppColors.error,
                        )),
            ),
          ),
        );
      },
    );
  }

  static Widget _buildTrackUserToggle(RxPosition pos, RxUser user,
      {bool forMap = false}) {
    if (forMap) {
      return GetBuilder<FlutterMapController>(
        builder: (_) {
          return BorderedIconButton(
            width: 38,
            fillColor: user.tracking()
                ? AppColors.primaryAccent.withOpacity(0.5)
                : AppTheme().colors.disabledButton,
            onTap: () => FlutterMapController.to.toggleUserTracking(
              pos.worker().id,
              onPosition: pos != null,
            ),
            child: Icon(
              user.tracking() ? FontAwesomeIcons.lock : FontAwesomeIcons.unlock,
              size: 14,
              color:
                  user.tracking() ? AppColors.brightIcon : AppColors.coolGray2,
            ),
          );
        },
      );
    }
    return InkWell(
      onTap: () => FlutterMapController.to.toggleUserTracking(
        pos.worker().id,
        onPosition: pos != null,
      ),
      child: GetBuilder<FlutterMapController>(
        builder: (_) {
          return Container(
            color: user.tracking()
                ? AppColors.primaryAccent.withOpacity(0.2)
                : null,
            padding: const EdgeInsets.all(5),
            child: Icon(
              user.tracking() ? FontAwesomeIcons.lock : FontAwesomeIcons.unlock,
              size: 12,
              color: user.tracking()
                  ? AppColors.primaryAccent
                  : AppTheme().colors.disabledButton,
            ),
          );
        },
      ),
    );
  }

  static Widget _buildDrawPathToggle(RxPosition pos, RxUser user,
      {bool forMap = false}) {
    if (forMap) {
      return GetBuilder<FlutterMapController>(
        builder: (_) {
          return BorderedIconButton(
            width: 38,
            fillColor: user.drawingPath()
                ? AppColors.primaryAccent.withOpacity(0.5)
                : AppTheme().colors.disabledButton,
            onTap: () => FlutterMapController.to.togglePathDrawing(
              pos.worker().id,
              onPosition: pos != null,
            ),
            child: Icon(
              FontAwesomeIcons.route,
              size: 14,
              color: user.drawingPath()
                  ? AppColors.brightIcon
                  : AppColors.coolGray2,
            ),
          );
        },
      );
    }
    return InkWell(
      onTap: () => FlutterMapController.to.togglePathDrawing(
        pos.worker().id,
        onPosition: pos != null,
      ),
      child: GetBuilder<FlutterMapController>(
        builder: (_) {
          return Container(
            color: user.drawingPath()
                ? AppColors.primaryAccent.withOpacity(0.2)
                : null,
            padding: const EdgeInsets.all(5),
            child: Icon(
              FontAwesomeIcons.route,
              size: 12,
              color: user.drawingPath()
                  ? AppColors.primaryAccent
                  : AppTheme().colors.disabledButton,
            ),
          );
        },
      ),
    );
  }

  static Widget _buildRate(BoxDecoration rateDecoration, int rating) {
    return Container(
      alignment: Alignment.center,
      height: 22,
      width: 22,
      decoration: rateDecoration,
      child: Text(
        rating.toString(),
        style: AppTypography.badgeCounterTextStyle,
      ),
    );
  }

  static void _showImage(Widget child) {
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
            child: InteractiveViewer(child: child),
          ),
        ),
      ),
    ));
  }
}
