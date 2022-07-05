import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_controller.dart';
import 'package:bazz_flutter/modules/message_history/message_history_controller.dart';
import 'package:bazz_flutter/modules/message_history/message_history_page.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

import '../home_controller.dart';

typedef OnClose = void Function();
typedef OnPlay = void Function();
typedef OnPaused = void Function();
typedef OnPlayerReady = void Function();

// ignore: must_be_immutable
class HistoryAudioPlayer extends GetView<MessageHistoryController> {
  late OnClose? onClose;
  late OnPlay? onPlay;
  late OnPaused? onPaused;
  late OnPlayerReady? onPlayerReady;

  HistoryAudioPlayer(
      {this.onClose, this.onPlay, this.onPaused, this.onPlayerReady});

  @override
  Widget build(BuildContext context) {
    final isMessageHistoryVisible =
        Get.currentRoute == AppRoutes.messageHistory;
    final mapActive = HomeController.to.currentBottomNavTab == BottomNavTab.map;
    return Stack(
      children: [
        Container(
          height: mapActive ? 65 : 55,
          margin: const EdgeInsets.only(
              top: LayoutConstants.trackSeekerThumbRadius),
          padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
          decoration: BoxDecoration(
            color: AppTheme().colors.tabBarBackground,
            boxShadow: const [
              BoxShadow(
                color: Colors.black12,
                blurRadius: 3,
              ),
            ],
            border: mapActive
                ? Border.all(
                    color: AppColors.playActiveButton,
                  )
                : Border.all(color: Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  if (isMessageHistoryVisible)
                    Obx(() {
                      final currTrackIndex = controller.currentTrackIndex;
                      final isLast = currTrackIndex ==
                          controller.filteredAudioMessages.length - 1;
                      final isConnecting = controller.isConnecting();
                      final isDisabled =
                          controller.filteredAudioMessages.isEmpty ||
                              isLast ||
                              isConnecting ||
                              controller.isSeeking();

                      return buildPlayerButton(
                        color: isDisabled
                            ? AppTheme().colors.disabledButton
                            : AppColors.playActiveButton,
                        child: const FaIcon(
                          FontAwesomeIcons.angleDoubleLeft,
                          color: AppColors.brightText,
                          size: 16,
                        ),
                        onTap: isDisabled ? null! : () => controller.playPrev(),
                        onLongTap: controller.goToLast,
                        size: const Size(35, 35),
                      );
                    }),
                  if (isMessageHistoryVisible)
                    const SizedBox(width: 8)
                  else
                    const SizedBox(width: 12),
                  Obx(() {
                    final isDisabled =
                        controller.filteredAudioMessages.isEmpty ||
                            controller.isConnecting() ||
                            controller.isSeeking();
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        buildPlayerButton(
                          color: isDisabled
                              ? AppTheme().colors.disabledButton
                              : AppColors.playActiveButton,
                          child: controller.isConnecting()
                              ? const Icon(
                                  Icons.hourglass_top_rounded,
                                  color: AppColors.brightText,
                                  size: 20,
                                )
                              : FaIcon(
                                  controller.isPlaying()
                                      ? FontAwesomeIcons.pause
                                      : FontAwesomeIcons.play,
                                  color: Colors.white,
                                  size: 18,
                                ),
                          onTap: isDisabled
                              ? null!
                              : () {
                                  if (controller.isStopped) {
                                    onPlay?.call();
                                    controller
                                        .play(controller.currentTrackIndex);
                                  } else if (controller.isPaused) {
                                    controller.resume();
                                    onPlay?.call();
                                  } else if (controller.isPlaying()) {
                                    controller.pause();
                                    onPaused?.call();
                                  }
                                },
                        ),
                        if (controller.isConnecting())
                          const SizedBox(
                            height: 42,
                            width: 42,
                            child: CircularProgressIndicator(
                              backgroundColor: AppColors.brightBackground,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryAccent),
                              strokeWidth: 3,
                            ),
                          )
                      ],
                    );
                  }),
                  const SizedBox(width: 8),
                  if (isMessageHistoryVisible) ...[
                    Obx(() {
                      final currTrackIndex = controller.currentTrackIndex;
                      final isFirst = currTrackIndex == 0;
                      final isConnecting = controller.isConnecting();
                      final isDisabled =
                          controller.filteredAudioMessages.isEmpty ||
                              isFirst ||
                              isConnecting ||
                              controller.isSeeking();

                      return buildPlayerButton(
                        color: isDisabled
                            ? AppTheme().colors.disabledButton
                            : AppColors.playActiveButton,
                        child: const FaIcon(
                          FontAwesomeIcons.angleDoubleRight,
                          color: AppColors.brightText,
                          size: 16,
                        ),
                        onTap: isDisabled ? null! : () => controller.playNext(),
                        onLongTap: controller.goToFirst,
                        size: const Size(35, 35),
                      );
                    }),
                    const SizedBox(width: 8),
                  ],
                  Obx(() {
                    if (controller.currentTrack!() != null &&
                        !mapActive &&
                        Session.isSupervisor) {
                      return CircularIconButton(
                        onTap: () async {
                          await controller.showPlayerOnMap();
                          TelloLogger()
                              .i("call onPlayerReady?.call $onPlayerReady");
                          FlutterMapController.to.onPlayerReadyHandler();
                          //onPlayerReady?.call();
                        },
                        buttonSize: 40,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Icon(
                              Icons.location_searching_outlined,
                              color: AppTheme().colors.primaryButton,
                              size: 33,
                            ),
                            Icon(Icons.play_arrow_rounded,
                                color: AppTheme().colors.primaryButton,
                                size: 23)
                          ],
                        ),
                      );
                    } else {
                      return Container();
                    }
                  }),
                  if (!isMessageHistoryVisible)
                    CircularIconButton(
                      buttonSize: 42,
                      onTap: () {
                        HomeController.to.gotoBottomNavTab(BottomNavTab.ptt);
                        Get.toNamed(AppRoutes.messageHistory);
                      },
                      child: const Icon(Icons.history_rounded,
                          color: AppColors.primaryAccent, size: 40),
                    ),
                ],
              ),
              Obx(() {
                final duration =
                    controller.currentTrack!().fileDuration.seconds;
                final String durationString = duration != null
                    ? '${duration.inMinutes.toString().padLeft(2, '0')}:${duration.inSeconds.toString().padLeft(2, '0')}'
                    : '';
                final createdAt = controller.currentTrack!() != null
                    ? dateTimeFromSeconds(controller.currentTrack!().createdAt,
                            isUtc: true)!
                        .toLocal()
                    : null;
                return controller.currentTrack!() != null
                    ? Flexible(
                        child: IntrinsicWidth(
                          child: Row(
                            children: [
                              AudioMessageItem.buildStatusAvatar(
                                controller.currentTrack!(),
                                () => controller.showUserInfo(
                                  controller.currentTrack!().owner,
                                  controller.currentTrack!().ownerPosition!,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Flexible(
                                child: SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      TextOneLine(
                                        controller
                                            .currentTrack!().owner.fullName!,
                                        style:
                                            AppTheme().typography.bgTitle2Style,
                                      ),
                                      Row(
                                        children: [
                                          /* Row(
                                            children: [
                                              const FaIcon(
                                                FontAwesomeIcons.calendarAlt,
                                                color: AppColors.lightText,
                                                size: 10,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                '${createdAt.day.toString().padLeft(2, '0')}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}',
                                                style: AppTypography.bodyText4TextStyle
                                                    .copyWith(color: AppColors.lightText,fontSize: 12, fontWeight: FontWeight.w600),
                                                overflow: TextOverflow.ellipsis,
                                                maxLines: 1,
                                              ),
                                            ],
                                          ),*/
                                          // const SizedBox(width: 10),
                                          Row(
                                            children: [
                                              const FaIcon(
                                                FontAwesomeIcons.clock,
                                                color: AppColors.greyIcon,
                                                size: 10,
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                '${DateFormat(AppSettings().fullTimeFormat).format(createdAt!)},  $durationString',
                                                style: AppTheme()
                                                    .typography
                                                    .subtitle1Style
                                                    .copyWith(fontSize: 13),
                                              ),
                                            ],
                                          ),
                                        ],
                                      )
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 2),
                            ],
                          ),
                        ),
                      )
                    : Stack(children: [
                        Text(
                          " AppLocalizations.of(context).noAudioMessages.toUpperCase()",
                          textAlign: TextAlign.center,
                          style: AppTheme().typography.subtitle1Style,
                        )
                      ]);
              }),
            ],
          ),
        ),
        Positioned(
          child: SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackShape: CustomTrackShape(),
              thumbShape: ThumbShape(),
              overlayShape: const OverlayShape(),
              overlayColor: AppColors.primaryAccent.withOpacity(0.1),
              thumbColor: AppColors.primaryAccent,
              activeTrackColor: AppColors.primaryAccent,
              inactiveTrackColor: Colors.transparent,
            ),
            child: Obx(() {
              return controller.isPlaying() || controller.isPaused
                  ? Slider(
                      max: controller.currentTrack!().fileDuration.toDouble(),
                      value: controller.currentProgress().toDouble(),
                      onChanged: (newVal) {
                        controller.setNewPosition(newVal.toInt());
                      },
                      onChangeStart: (_) => controller.isSeeking(true),
                    )
                  : const SizedBox();
            }),
          ),
        ),
        Obx(() {
          // ignore: avoid_unnecessary_containers
          if (controller.isFetchingLocations) {
            return Column(children: [
              const SizedBox(
                height: 8,
              ),
              Container(
                  height: 55,
                  color: Colors.black54,
                  child: SpinKitWave(
                    color: AppColors.brightText,
                    itemCount: 10,
                    size: 30,
                  ))
            ]);
          } else {
            return Container();
          }
        }),
        if (mapActive)
          Positioned(
            right: -3,
            top: 5,
            child: CircularIconButton(
              onTap: () {
                TelloLogger().i("close player $onClose");
                onClose?.call();
              },
              buttonSize: 25,
              child: Icon(Icons.close,
                  color: AppTheme().colors.primaryButton, size: 15),
            ),
          ),
      ],
    );
  }

  static Widget buildPlayerButton({
    required Color color,
    required Widget child,
    VoidCallback? onTap,
    VoidCallback? onLongTap,
    Size size = const Size(42, 42),
    bool withCounter = false,
  }) {
    return ObxValue<RxBool>(
      (isPressed) {
        return GestureDetector(
          onTapDown: (_) {
            if (onTap != null) {
              isPressed.toggle();
            }
          },
          onTapUp: (_) {
            if (onTap != null) {
              isPressed.toggle();
              onTap();
            }
          },
          onTapCancel: () {
            if (onTap != null) {
              isPressed.toggle();
            }
          },
          onLongPress: onLongTap,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: size.width,
                height: size.height,
                child: Neumorphic(
                  duration: Duration.zero,
                  padding: const EdgeInsets.all(10),
                  style: NeumorphicStyle(
                    depth: 0,
                    shape: isPressed.value
                        ? NeumorphicShape.concave
                        : NeumorphicShape.convex,
                    boxShape: const NeumorphicBoxShape.circle(),
                    color: color,
                  ),
                ),
              ),
              child,
              if (withCounter &&
                  MessageHistoryController.to.filteredAudioMessages.isNotEmpty)
                Obx(() {
                  final total =
                      MessageHistoryController.to.filteredAudioMessages.length;
                  final current =
                      MessageHistoryController.to.currentTrackIndex + 1;
                  return Positioned(
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          vertical: 1, horizontal: 2),
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryAccent,
                        borderRadius: BorderRadius.all(Radius.circular(3)),
                      ),
                      child: Text('$current/$total',
                          style: AppTheme()
                              .typography
                              .buttonTextStyle
                              .copyWith(fontSize: 8)),
                    ),
                  );
                }),
            ],
          ),
        );
      },
      false.obs,
    );
  }
}

class CustomTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    // final double trackHeight = sliderTheme.trackHeight;
    final double trackLeft = offset.dx;
    // final double trackTop = offset.dy + (parentBox.size.height - trackHeight) / 3;
    final double trackWidth = parentBox.size.width;
    return Rect.fromLTWH(
        trackLeft, LayoutConstants.trackSeekerThumbRadius, trackWidth, 1);
  }
}

class ThumbShape extends RoundSliderThumbShape {
  const ThumbShape({
    double enabledThumbRadius = LayoutConstants.trackSeekerThumbRadius,
    double? disabledThumbRadius,
    double elevation = 1.0,
    double pressedElevation = 5.0,
  }) : super(
          enabledThumbRadius: enabledThumbRadius,
          disabledThumbRadius: disabledThumbRadius,
          elevation: elevation,
          pressedElevation: pressedElevation,
        );
}

class OverlayShape extends RoundSliderOverlayShape {
  const OverlayShape(
      {double overlayRadius = LayoutConstants.trackSeekerThumbRadius})
      : super(overlayRadius: overlayRadius);
}
