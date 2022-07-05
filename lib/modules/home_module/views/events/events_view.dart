import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/incoming_event.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/views/events/create_new_event_drawer.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_controller.dart';
import 'package:bazz_flutter/modules/home_module/widgets/round_sos_button.dart';
import 'package:bazz_flutter/modules/media_uploading/media_upload_service.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/event_handling_service.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:bazz_flutter/shared_widgets/loader.dart';
import 'package:bazz_flutter/shared_widgets/primary_button.dart';
import 'package:bazz_flutter/shared_widgets/section_divider.dart';
import 'package:bazz_flutter/shared_widgets/system_dialog.dart';
import 'package:bazz_flutter/shared_widgets/tello_divider.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:expandable/expandable.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_multi_formatter/utils/unfocuser.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class EventsView extends GetView<EventHandlingService> {
  @override
  Widget build(BuildContext context) {
    return Unfocuser(
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Obx(
                  () {
                    final sortedEvents =
                        HomeController.to.activeGroup.sortedEvents;
                    return sortedEvents.isNotEmpty
                        ? NotificationListener<ScrollNotification>(
                            onNotification: (ScrollNotification scroll) {
                              controller.onScroll(scroll);
                              return null!;
                            },
                            child: ListView.separated(
                              controller: ScrollController(
                                  initialScrollOffset: controller.scrollOffset),
                              itemBuilder: (_, i) {
                                final event = sortedEvents[i];
                                return Column(
                                  children: [
                                    if (i == 0)
                                      TitledDivider(
                                        text: event.isNotConfirmed$
                                            ? " AppLocalizations.of(context).unconfirmed.capitalize"
                                            : "AppLocalizations.of(context).unresolved.capitalize",
                                        textColor: AppColors.lightText,
                                        dividerColor:
                                            AppTheme().colors.dividerLight,
                                        dividerTitleBg:
                                            AppTheme().colors.mainBackground,
                                      ),
                                    if (event.isNotConfirmed$)
                                      _buildCollapsedEvent(event, context)
                                    else if (Session.isGuard &&
                                        event.isNotPrivate)
                                      _buildCollapsedEvent(event, context)
                                    else
                                      ExpandableEvent(
                                          index: i,
                                          event: event,
                                          key: UniqueKey()),
                                    if (i + 1 == sortedEvents.length)
                                      const TelloDivider(),
                                  ],
                                );
                              },
                              separatorBuilder: (_, i) {
                                final prevEvent = sortedEvents[i];
                                final nextEvent = sortedEvents[i + 1];
                                if (prevEvent.isNotConfirmed$ &&
                                    nextEvent.isConfirmed$()) {
                                  return TitledDivider(
                                    text:
                                        "AppLocalizations.of(context).unresolved.capitalize",
                                    textColor: AppColors.lightText,
                                    dividerColor:
                                        AppTheme().colors.dividerLight,
                                    dividerTitleBg:
                                        AppTheme().colors.mainBackground,
                                  );
                                } else {
                                  return const TelloDivider();
                                }
                              },
                              itemCount: sortedEvents.length,
                            ),
                          )
                        : Center(
                            child: Text(
                            "AppLocalizations.of(context).noEvents",
                            style: AppTheme().typography.subtitle1Style,
                          ));
                  },
                ),
              ),
              _buildUserEventsBottomPanel(),
            ],
          ),
          CreateNewEventDrawer(controller),
          Obx(() {
            if (controller.loadingState == ViewState.loading) {
              Loader.show(context, themeData: null as ThemeData);
            } else {
              Loader.hide();
            }
            return const SizedBox();
          }),
        ],
      ),
    );
  }

  Widget _buildUserEventsBottomPanel() {
    return KeyboardVisibilityBuilder(builder: (context, visible) {
      if (visible) return const SizedBox();

      return Container(
        height: 65,
        decoration: BoxDecoration(
          color: AppTheme().colors.newEventDrawer,
          boxShadow: const [
            BoxShadow(
              color: Colors.black26,
              spreadRadius: 2,
              blurRadius: 3,
            ),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 5),
        child: Row(
          children: [
            Expanded(
              child: _buildUserEventsList(),
            ),
            VerticalDivider(
                color: AppTheme().colors.divider, indent: 5, endIndent: 5),
            const RoundSosButton(),
          ],
        ),
      );
    });
  }

  Widget _buildUserEventsList() {
    if (Session.isGuard) return const SizedBox();

    return GetBuilder<EventHandlingService>(
        id: 'userEventsList',
        builder: (controller) {
          return ListView.separated(
            scrollDirection: Axis.horizontal,
            itemBuilder: (context, i) {
              final event = controller.userEvents[i];
              return GestureDetector(
                onTap: () {
                  controller.onNewEventTap(event);
                },
                // Yes, we need this Container to make the tap area rectangular
                child: Container(
                  width: 50,
                  color: Colors.transparent,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Obx(() {
                        final isSelected =
                            event == controller.currentUserEvent$;
                        return Container(
                          height: 38,
                          width: 38,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                width: 2,
                                color: isSelected
                                    ? Colors.white
                                    : Colors.transparent,
                              )),
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
                        );
                      }),
                      const SizedBox(height: 3),
                      Text(
                        event.title.capitalizeFirst!,
                        textAlign: TextAlign.center,
                        style: AppTheme().typography.memberNameStyle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            },
            separatorBuilder: (context, i) => const SizedBox(width: 3),
            itemCount: controller.userEvents.length,
          );
        });
  }

  Widget _buildCollapsedEvent(IncomingEvent event, BuildContext context) {
    final eventDateTime =
        dateTimeFromSeconds(event.createdAt!, isUtc: true)!.toLocal();
    final reportedAtString =
        "AppLocalizations.of(context).reportedSOSat.toLowerCase().replaceFirst(RegExp(' sos'), '').capitalizeFirst";
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
      color: AppTheme().colors.listItemBackground2,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (event.isPrivate) ...[
                      SizedBox(
                        width: 22,
                        height: 22,
                        child:
                            SvgPicture.asset('assets/images/private_icon.svg'),
                      ),
                      const SizedBox(width: 5),
                    ],
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
                    const SizedBox(width: 5),
                    Text(
                      event.title.toUpperCase(),
                      style: AppTheme().typography.eventTitleStyle,
                    ),
                    if (Session.isSupervisor || event.isPrivate) ...[
                      Text(' - ', style: AppTheme().typography.eventTitleStyle),
                      Text(
                        event.statusTitle.capitalize!,
                        style: AppTheme()
                            .typography
                            .listItemTitleStyle
                            .copyWith(color: event.statusColor),
                      ),
                    ]
                  ],
                ),
                Row(
                  children: [
                    Text(
                      "{AppLocalizations.of(context).priority.toUpperCase()} - ",
                      style: AppTheme().typography.eventTitleStyle,
                    ),
                    Text(
                      event.priorityTitle.capitalize!,
                      style: AppTheme()
                          .typography
                          .eventTitleStyle
                          .copyWith(color: event.priorityColor),
                    ),
                  ],
                ),
                TextOneLine(
                  event.ownerTitle.capitalize!,
                  style: AppTheme().typography.listItemTitleStyle,
                ),
                TextOneLine(
                  '$reportedAtString ${DateFormat(AppSettings().dateTimeFormat).format(eventDateTime)}',
                  style: AppTheme().typography.subtitle2Style,
                ),
              ],
            ),
          ),
          Obx(() {
            if (event.isConfirmed$() || HomeController.to.isOffline)
              return const SizedBox();
            return PrimaryButton(
              height: 40,
              text: "AppLocalizations.of(context).confirm",
              onTap: () => controller.confirmEvent(event),
              icon: null as Icon,
            );
          })
        ],
      ),
    );
  }
}

class ExpandableEvent extends StatefulWidget {
  const ExpandableEvent({
    Key? key,
    required this.index,
    required this.event,
  }) : super(key: key);

  final int index;
  final IncomingEvent event;

  @override
  _ExpandableEventState createState() => _ExpandableEventState();
}

class _ExpandableEventState extends State<ExpandableEvent> {
  final EventHandlingService? _eventHandlingService = EventHandlingService.to;
  final TextEditingController _commentController = TextEditingController();
  bool _isCommentValid = false;

  final _expandableController = ExpandableController();

  @override
  void initState() {
    _commentController.text = widget.event.comment!;
    _isCommentValid = _commentController.text.length > 10;
    _expandableController.expanded = widget.event.isExpanded;
    _commentController.addListener(() {
      widget.event.comment = _commentController.text;
      final oldIsCommentValid = _isCommentValid;
      _isCommentValid = _commentController.text.length > 10;
      if (oldIsCommentValid != _isCommentValid) setState(() {});
    });
    super.initState();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _expandableController.dispose();
    Loader.hide();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const inputBorder = OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.inputBorder),
      borderRadius: BorderRadius.all(Radius.circular(7)),
    );
    return ExpandableNotifier(
      controller: _expandableController,
      child: ScrollOnExpand(
        child: Container(
          padding: const EdgeInsets.fromLTRB(10, 4, 5, 4),
          color: AppTheme().colors.listItemBackground,
          child: Obx(() {
            final isCheckboxDisabled = widget.event.isPostponedCheckboxDisabled;
            return Expandable(
              collapsed: HomeController.to.isOnline &&
                      (Session.isSupervisor || widget.event.isPrivate)
                  ? GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleExpanded,
                      child: buildEventHeader(),
                    )
                  : buildEventHeader(),
              expanded: Column(
                children: [
                  if (HomeController.to.isOnline &&
                      (Session.isSupervisor || widget.event.isPrivate))
                    GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: _toggleExpanded,
                      child: buildEventHeader(),
                    )
                  else
                    buildEventHeader(),
                  Container(
                    padding: const EdgeInsets.only(right: 10),
                    height: 180,
                    child: Column(
                      children: [
                        const SizedBox(height: 5),
                        ClipRRect(
                          borderRadius:
                              const BorderRadius.all(Radius.circular(7)),
                          child: TextField(
                            controller: _commentController,
                            scrollPhysics:
                                const AlwaysScrollableScrollPhysics(),
                            style: AppTheme().typography.inputTextStyle,
                            decoration: InputDecoration(
                              hintText:
                                  "AppLocalizations.of(context).commentIsMandatory",
                              hintStyle: AppTheme().typography.inputTextStyle,
                              enabledBorder: inputBorder,
                              focusedBorder: inputBorder,
                              fillColor: AppTheme().colors.inputBg,
                              filled: true,
                              contentPadding: const EdgeInsets.all(5),
                            ),
                            keyboardType: TextInputType.multiline,
                            minLines: 4,
                            maxLines: 4,
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (widget.event.eventDetails.isPostponable)
                              Container(
                                margin: const EdgeInsets.only(left: 3),
                                height: 40,
                                child: Row(children: [
                                  Obx(() {
                                    final isPostponed =
                                        widget.event.isPostponed$.value;
                                    return Theme(
                                      data: ThemeData(
                                        unselectedWidgetColor:
                                            AppTheme().colors.checkboxBorder,
                                        disabledColor: AppColors.coolGray,
                                      ),
                                      child: Checkbox(
                                        checkColor: Colors.white,
                                        activeColor: AppColors.secondaryButton,
                                        value: isPostponed,
                                        onChanged: isCheckboxDisabled
                                            ? null
                                            : (isPostponed) {
                                                widget.event.isPostponed$
                                                    .value = isPostponed!;
                                              },
                                      ),
                                    );
                                  }),
                                  TextOneLine(
                                    "AppLocalizations.of(context).postpone.capitalizeFirst",
                                    style: AppTheme()
                                        .typography
                                        .bgText3Style
                                        .copyWith(
                                            color: isCheckboxDisabled
                                                ? AppColors.coolGray
                                                : null),
                                  ),
                                ]),
                              )
                            else
                              const SizedBox(),
                            SizedBox(
                              height: 40,
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  TextOneLine(
                                    "AppLocalizations.of(context).justify.capitalize",
                                    style: AppTheme()
                                        .typography
                                        .bgText3Style
                                        .copyWith(
                                            color: isCheckboxDisabled
                                                ? AppColors.coolGray
                                                : null),
                                  ),
                                  Obx(() {
                                    return Theme(
                                      data: ThemeData(
                                        unselectedWidgetColor:
                                            AppTheme().colors.checkboxBorder,
                                        disabledColor: AppColors.coolGray,
                                      ),
                                      child: Checkbox(
                                        checkColor: Colors.white,
                                        activeColor: AppColors.secondaryButton,
                                        value: widget.event.isJustified$,
                                        onChanged: (justified) {
                                          if (justified!) {
                                            widget.event.resolveStatus(
                                                EventResolveStatus.justified);
                                          } else {
                                            widget.event.resolveStatus(
                                                EventResolveStatus.treated);
                                          }
                                        },
                                      ),
                                    );
                                  }),
                                ],
                              ),
                            ),
                          ],
                        ),
                        GetBuilder<MediaUploadService>(
                            id: 'button${widget.event.id}',
                            builder: (controller) {
                              return Obx(() {
                                final media = controller
                                    .allMediaByEventId[widget.event.id];
                                final isOnline = HomeController.to.isOnline;
                                return PrimaryButton(
                                  height: 35,
                                  text:
                                      "AppLocalizations.of(context).resolve.capitalize",
                                  toUpperCase: false,
                                  color: isOnline
                                      ? AppTheme().colors.primaryButton
                                      : AppTheme().colors.disabledButton,
                                  onTap: isOnline &&
                                          widget.event.status() ==
                                              EventStatus.ongoing &&
                                          _isCommentValid &&
                                          (media == null ||
                                              media.every((m) => m.isUploaded))
                                      ? () => _eventHandlingService!
                                          .resolveEvent(widget.event,
                                              _commentController.text)
                                      : null!,
                                  icon: null as Icon,
                                );
                              });
                            }),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }

  void _toggleExpanded() {
    _expandableController.toggle();
    widget.event.isExpanded = _expandableController.expanded;
  }

  Widget buildEventHeader() {
    final sosDateTime =
        dateTimeFromSeconds(widget.event.createdAt!, isUtc: true)!.toLocal();
    final reportedAtString =
        "AppLocalizations.of(context).reportedSOSat.toLowerCase().replaceFirst(RegExp(' sos'), '').capitalizeFirst";
    const String yesLocation = "assets/images/yes_location.png";
    const String noLocation = "assets/images/no_location.png";
    String details = 'No additional info';
    final speedLimitParams = widget.event.eventParameters.speedLimitParams;
    final deviceOfflineParams =
        widget.event.eventParameters.deviceOfflineParams;
    if (speedLimitParams != null) details = speedLimitParams.stringify;
    if (deviceOfflineParams != null) details = deviceOfflineParams.stringify;

    return Stack(
      children: [
        Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (widget.event.isPrivate) ...[
                            SizedBox(
                              width: 22,
                              height: 22,
                              child: SvgPicture.asset(
                                  'assets/images/private_icon.svg'),
                            ),
                            const SizedBox(width: 5),
                          ],
                          SizedBox(
                            width: 22,
                            height: 22,
                            child: widget.event.iconCfg.iconAssetExists
                                ? SvgPicture.asset(
                                    'assets/images/events/${widget.event.iconCfg.id}.svg')
                                : SvgPicture.network(
                                    widget.event.iconCfg.url,
                                    placeholderBuilder: (_) {
                                      return SvgPicture.asset(
                                          'assets/images/events/default.svg');
                                    },
                                  ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            widget.event.title.toUpperCase(),
                            style: AppTheme().typography.eventTitleStyle,
                          ),
                          if (Session.isSupervisor ||
                              widget.event.isPrivate) ...[
                            Text(' - ',
                                style: AppTheme().typography.eventTitleStyle),
                            Expanded(
                              child: TextOneLine(
                                widget.event.statusTitle.capitalize!,
                                style: AppTheme()
                                    .typography
                                    .listItemTitleStyle
                                    .copyWith(color: widget.event.statusColor),
                              ),
                            ),
                          ]
                        ],
                      ),
                      Row(
                        children: [
                          Text(
                            "{AppLocalizations.of(context).priority.toUpperCase()} - ",
                            style: AppTheme().typography.eventTitleStyle,
                          ),
                          Text(
                            widget.event.priorityTitle.capitalize!,
                            style: AppTheme()
                                .typography
                                .eventTitleStyle
                                .copyWith(color: widget.event.priorityColor),
                          ),
                        ],
                      ),
                      TextOneLine(
                        widget.event.ownerTitle.capitalize!,
                        style: AppTheme().typography.listItemTitleStyle,
                      ),
                      TextOneLine(
                        '$reportedAtString ${DateFormat(AppSettings().dateTimeFormat).format(sosDateTime)}',
                        style: AppTheme().typography.subtitle2Style,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                if (widget.event.eventParameters.isNotEmpty) ...[
                  CircularIconButton(
                    buttonSize: 34,
                    onTap: () {
                      LayoutUtils.buildDescription(
                        details,
                        icon: const FaIcon(
                          LineAwesomeIcons.info,
                          color: AppColors.primaryAccent,
                        ),
                        title: 'Details',
                      );
                    },
                    color: AppColors.secondaryButton,
                    child: const FaIcon(
                      LineAwesomeIcons.info,
                      color: AppColors.brightIcon,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                if (HomeController.to.isOnline &&
                    (Session.isSupervisor || widget.event.isPrivate)) ...[
                  CircularIconButton(
                    buttonSize: 34,
                    onTap: () {
                      if (Get.isOverlaysOpen)
                        Get.until((_) => Get.isOverlaysClosed);
                      Get.toNamed(AppRoutes.chooseMedia,
                          arguments: widget.event.id);
                    },
                    color: AppColors.secondaryButton,
                    child: const FaIcon(
                      FontAwesomeIcons.photoVideo,
                      color: AppColors.brightIcon,
                      size: 17,
                    ),
                  ),
                  const SizedBox(width: 5),
                ],
                if (HomeController.to.isOnline && Session.isNotGuard)
                  CircularIconButton(
                    buttonSize: 34,
                    onTap: () {
                      widget.event.hasLocation
                          ? FlutterMapController.to.showEvent(widget.event)
                          : SystemDialog.showConfirmDialog(
                              title: widget.event.title.capitalize!,
                              confirmCallback: Get.back,
                              confirmButtonText:
                                  "AppLocalizations.of(context).ok.capitalize",
                              message:
                                  "AppLocalizations.of(context).eventMessageDialogLocation.capitalize",
                              height: 180,
                            );
                    },
                    color: widget.event.hasLocation
                        ? AppColors.secondaryButton
                        : AppTheme().colors.disabledButton,
                    child: Image.asset(
                        widget.event.hasLocation ? yesLocation : noLocation,
                        width: 20,
                        height: 20),
                  ),
              ],
            ),
            GetBuilder<MediaUploadService>(
                id: 'avgUploadProgress',
                builder: (controller) {
                  final allMedia =
                      controller.allMediaByEventId[widget.event.id];
                  if (allMedia == null || allMedia.isEmpty)
                    return const SizedBox();

                  return GestureDetector(
                    onTap: () =>
                        controller.buildUploadDetailsDialog(widget.event.id!),
                    child: Obx(() {
                      final media =
                          controller.allMediaByEventId[widget.event.id];
                      final avgUploadProgress = media!
                              .map((m) => m.uploadProgress())
                              .reduce((a, b) => a + b) /
                          media.length;

                      return Row(
                        children: [
                          Text(
                            LocalizationService()
                                .of()
                                .uploadingMedia
                                .capitalize,
                            style: AppTypography.bodyText2TextStyle,
                          ),
                          Expanded(
                            child: LinearPercentIndicator(
                              percent: avgUploadProgress,
                              lineHeight: 15.0,
                              padding:
                                  const EdgeInsets.only(left: 15, right: 10),
                              center: Text(
                                '${(avgUploadProgress * 100).truncate()}%',
                                style: AppTypography.bodyText4TextStyle
                                    .copyWith(color: AppColors.brightText),
                              ),
                              backgroundColor:
                                  AppColors.primaryAccent.withOpacity(0.2),
                              progressColor: AppColors.primaryAccent,
                            ),
                          ),
                          if (avgUploadProgress < 1)
                            CircularIconButton(
                              buttonSize: 40,
                              onTap: () {
                                controller.cancelAllForId(widget.event.id!);
                              },
                              child: const Icon(Icons.close_rounded,
                                  color: AppColors.error),
                            )
                          else
                            CircularIconButton(
                              buttonSize: 40,
                              onTap: null as VoidCallback,
                              child: Icon(Icons.check_rounded,
                                  color: AppColors.primaryAccent),
                            ),
                        ],
                      );
                    }),
                  );
                }),
          ],
        ),
        if (HomeController.to.isOnline &&
            (Session.isSupervisor || widget.event.isPrivate))
          Positioned(
            top: 0,
            right: 0,
            child: ValueListenableBuilder(
              valueListenable: _expandableController,
              builder: (context, hasError, child) {
                return Icon(
                  _expandableController.expanded
                      ? LineAwesomeIcons.caret_up
                      : LineAwesomeIcons.caret_down,
                  color: AppColors.lightText,
                  size: 15,
                );
              },
            ),
          ),
      ],
    );
  }
}
