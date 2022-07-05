import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/audio_message.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/widgets/history_audio_player.dart';
import 'package:bazz_flutter/modules/home_module/widgets/bottom_nav_bar.dart';
import 'package:bazz_flutter/modules/home_module/widgets/custom_app_bar.dart';
import 'package:bazz_flutter/modules/home_module/widgets/notifications_drawer.dart';
import 'package:bazz_flutter/modules/message_history/message_history_controller.dart';
import 'package:bazz_flutter/shared_widgets/tello_divider.dart';
import 'package:bazz_flutter/shared_widgets/material_bazz_text_input.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';

class MessageHistoryPage extends GetView<MessageHistoryController> {
  @override
  Widget build(BuildContext context) {
    return Unfocuser(
      child: Scaffold(
        backgroundColor: AppTheme().colors.mainBackground,
        body: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  CustomAppBar(withBackButton: true),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    height: 50,
                    color: AppTheme().colors.tabBarBackground,
                    child: Row(
                      children: [
                        GetX(
                          builder: (_) {
                            return Expanded(
                              child: Text(
                                '{AppLocalizations.of(context).messageFrom} ${HomeController.to.activeGroup.title ?? '----'}',
                                style: AppTheme().typography.bgTitle2Style,
                              ),
                            );
                          },
                          dispose: (_) {
                            controller.searchInputCtrl.text = '';
                          },
                        ),
                        const SizedBox(width: 5),
                        _buildAllMissedSwitch(context)
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        BazzMaterialTextInput(
                          controller: controller.searchInputCtrl,
                          placeholder:
                              "AppLocalizations.of(context).searchMessages",
                          height: 45,
                          prefixIcon: const Icon(Icons.search_rounded),
                        ),
                        SizedBox(
                          height: 40,
                          child: TabBar(
                            indicatorColor: AppColors.primaryAccent,
                            controller: controller.tabController,
                            indicator: BoxDecoration(
                              color: AppTheme().colors.selectedTab,
                              border: const Border(
                                  bottom: BorderSide(
                                      width: 2,
                                      color: AppColors.primaryAccent)),
                            ),
                            tabs: [
                              Tab(
                                child: Text(
                                  'Group',
                                  style: AppTheme().typography.tabTitle2Style,
                                ),
                              ),
                              Tab(
                                child: Text(
                                  'Private',
                                  style: AppTheme().typography.tabTitle2Style,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const TelloDivider(),
                        Expanded(
                          child: TabBarView(
                            physics: const NeverScrollableScrollPhysics(),
                            controller: controller.tabController,
                            children: [
                              _buildAudioMessages(
                                context,
                                controller.itemScrollController,
                                controller.itemPositionsListener,
                              ),
                              // Center(
                              //   child: Text(
                              //     AppLocalizations.of(context).noAudioMessages.toUpperCase(),
                              //     textAlign: TextAlign.center,
                              //     style: AppTheme().typography.subtitle1Style,
                              //   ),
                              // ),
                              _buildAudioMessages(
                                context,
                                controller.itemScrollController2,
                                controller.itemPositionsListener2,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  HistoryAudioPlayer(),
                ],
              ),
              NotificationsDrawer(controller: HomeController.to),
            ],
          ),
        ),
        bottomNavigationBar: BottomNavBar(key: UniqueKey()),
      ),
    );
  }

  Widget _buildAudioMessages(BuildContext context,
      ItemScrollController scrollCtrl, ItemPositionsListener posLsnr) {
    return Obx(() {
      // Enable in case of freezing tab switching animation

      // if (controller.$isTabIndexChanging) {
      //   return const Center(
      //     child: SpinKitPouringHourglass(color: AppColors.loadingIndicator),
      //   );
      // }
      if (controller.filteredAudioMessages.isEmpty) {
        return Center(
          child: Text(
            "AppLocalizations.of(context).noAudioMessages.toUpperCase()",
            textAlign: TextAlign.center,
            style: AppTheme().typography.subtitle1Style,
          ),
        );
      }
      return ScrollablePositionedList.separated(
        itemBuilder: (_, i) {
          return Column(
            children: [
              AudioMessageItem(
                index: i,
                audioMessage: controller.filteredAudioMessages[i],
              ),
              if (i + 1 == controller.filteredAudioMessages.length)
                const TelloDivider(),
            ],
          );
        },
        itemCount: controller.filteredAudioMessages.length,
        separatorBuilder: (_, __) => const TelloDivider(),
        itemScrollController: scrollCtrl,
        itemPositionsListener: posLsnr,
      );
    });
  }

  Container _buildAllMissedSwitch(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(5)),
        color: AppColors.primaryAccent.withOpacity(0.2),
      ),
      child: Obx(() {
        return Row(
          children: [
            GestureDetector(
              onTap: () {
                controller.setShowMissed(false);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(5)),
                  color: controller.showMissed()
                      ? Colors.transparent
                      : AppColors.primaryAccent,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Text(
                  " AppLocalizations.of(context).all",
                  style: controller.showAll
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
                controller.setShowMissed(true);
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.all(Radius.circular(5)),
                  color: controller.showAll
                      ? Colors.transparent
                      : AppColors.primaryAccent,
                ),
                padding:
                    const EdgeInsets.symmetric(horizontal: 15, vertical: 10),
                child: Text(
                  " AppLocalizations.of(context).missed",
                  style: controller.showMissed()
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
      }),
    );
  }
}

class AudioMessageItem extends StatelessWidget {
  const AudioMessageItem({
    Key? key,
    required this.index,
    required this.audioMessage,
  }) : super(key: key);

  final int index;
  final AudioMessage audioMessage;

  @override
  Widget build(BuildContext context) {
    final duration = audioMessage.fileDuration.seconds;
    final createdAt =
        dateTimeFromSeconds(audioMessage.createdAt, isUtc: true)!.toLocal();
    final positionColor = audioMessage.ownerPosition == null
        ? AppColors.lightText
        : audioMessage.ownerPosition!.status == PositionStatus.active
            ? AppColors.online
            : audioMessage.ownerPosition!.status == PositionStatus.inactive
                ? AppColors.offline
                : AppColors.outOfRange;

    return Obx(() {
      final isSelected = MessageHistoryController.to.currentTrackIndex == index;
      return GestureDetector(
        onTap: () {
          if (!isSelected) MessageHistoryController.to.selectTrack(index);
        },
        child: Stack(
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(10, 13, 15, 13),
              color: isSelected
                  ? AppTheme().colors.selectedLI
                  : AppTheme().colors.listItemBackground,
              child: Row(
                children: [
                  buildStatusAvatar(
                    audioMessage,
                    () => MessageHistoryController.to.showUserInfo(
                      audioMessage.owner,
                      audioMessage.ownerPosition!,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextOneLine(
                          audioMessage.owner.fullName!,
                          style: AppTheme().typography.listItemTitleStyle,
                        ),
                        Row(
                          children: [
                            Row(
                              children: [
                                FaIcon(
                                  FontAwesomeIcons.shieldAlt,
                                  color: positionColor,
                                  size: 12,
                                ),
                                const SizedBox(width: 3),
                                SizedBox(
                                    width: 60,
                                    child: TextOneLine(
                                      audioMessage.ownerPosition?.title ??
                                          "AppLocalizations.of(context).noPosition",
                                      style:
                                          AppTheme().typography.subtitle2Style,
                                    )),
                                const SizedBox(width: 5),
                                /*const FaIcon(
                                  FontAwesomeIcons.calendarAlt,
                                  color: AppColors.lightText,
                                  size: 12,
                                ),
                                const SizedBox(width: 5),
                                TextOneLine(
                                  '${createdAt.day.toString().padLeft(2, '0')}.${createdAt.month.toString().padLeft(2, '0')}.${createdAt.year}',
                                  style: AppTypography.bodyText4TextStyle.copyWith(color: AppColors.lightText, fontSize: 12, fontWeight: FontWeight.w600),
                                ),*/
                              ],
                            ),
                            const SizedBox(width: 4),
                            const FaIcon(
                              FontAwesomeIcons.clock,
                              color: AppColors.lightText,
                              size: 10,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${DateFormat(AppSettings().fullTimeFormat).format(createdAt)},'
                              '  ${duration.inMinutes.toString().padLeft(2, '0')}:${duration.inSeconds.toString().padLeft(2, '0')}',
                              style: AppTheme()
                                  .typography
                                  .subtitle1Style
                                  .copyWith(fontSize: 13),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Obx(() {
                    final isDisabled =
                        MessageHistoryController.to.isConnecting();
                    final isCurrentMessage =
                        MessageHistoryController.to.currentTrack!().id ==
                            audioMessage.id;
                    Color buttonColor;
                    const buttonSize = Size(35, 35);

                    if (audioMessage.isPlaying() ||
                        MessageHistoryController.to.isPaused &&
                            isCurrentMessage) {
                      buttonColor = AppColors.playActiveButton;
                    } else if (isDisabled) {
                      buttonColor = AppTheme().colors.disabledButton;
                    } else {
                      buttonColor = AppTheme().colors.disabledButton;
                    }
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        HistoryAudioPlayer.buildPlayerButton(
                          color: buttonColor,
                          child: isSelected &&
                                  MessageHistoryController.to.isConnecting()
                              ? const Icon(
                                  Icons.hourglass_top_rounded,
                                  color: AppColors.brightText,
                                  size: 18,
                                )
                              : FaIcon(
                                  audioMessage.isPlaying()
                                      ? FontAwesomeIcons.pause
                                      : FontAwesomeIcons.play,
                                  color: Colors.white,
                                  size: 14,
                                ),
                          onTap: MessageHistoryController.to.isConnecting()
                              ? null!
                              : () {
                                  if (MessageHistoryController.to.isStopped ||
                                      !isCurrentMessage) {
                                    MessageHistoryController.to.play(index);
                                  } else if (isCurrentMessage &&
                                      MessageHistoryController.to.isPaused) {
                                    MessageHistoryController.to.resume();
                                  } else if (isCurrentMessage &&
                                      MessageHistoryController.to.isPlaying()) {
                                    MessageHistoryController.to.pause();
                                  }
                                },
                          size: buttonSize,
                        ),
                        if (isSelected &&
                            MessageHistoryController.to.isConnecting())
                          SizedBox(
                            height: buttonSize.height,
                            width: buttonSize.width,
                            child: const CircularProgressIndicator(
                              backgroundColor: AppColors.brightBackground,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  AppColors.primaryAccent),
                              strokeWidth: 3,
                            ),
                          )
                      ],
                    );
                  }),
                ],
              ),
            ),
            if (audioMessage.owner.id == Session.user!.id)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(
                  Icons.phone_forwarded_rounded,
                  size: 17,
                  color: AppColors.primaryAccent,
                ),
              ),
          ],
        ),
      );
    });
  }

  static Widget buildStatusAvatar(
      AudioMessage audioMessage, VoidCallback onTap) {
    Color statusColor;
    Image? alertnessFailedIcon;

    if (audioMessage.ownerPosition?.alertCheckState == AlertCheckState.failed) {
      alertnessFailedIcon = const Image(
        image: AssetImage('assets/images/alertness_failed_icon.png'),
        height: 18,
        width: 18,
      );
      statusColor = audioMessage.ownerPosition!.status == PositionStatus.active
          ? AppColors.online
          : audioMessage.ownerPosition!.status == PositionStatus.inactive
              ? AppColors.offline
              : AppColors.outOfRange;
    } else {
      statusColor =
          audioMessage.owner.isOnline() ? AppColors.online : AppColors.offline;
    }

    final avatar = audioMessage.owner.avatar;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              border: Border.all(width: 2, color: statusColor),
              shape: BoxShape.circle,
              image: avatar.isNotEmpty
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(avatar),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            width: 46,
            height: 35,
            child: avatar == null
                ? FaIcon(
                    FontAwesomeIcons.userAlt,
                    color: statusColor,
                    size: 22,
                  )
                : null,
          ),
          Obx(() {
            return audioMessage.isListened()
                ? Positioned(
                    child: Container(
                      height: 17,
                      width: 17,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.primaryAccent,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.white,
                            blurRadius: 1,
                            spreadRadius: 1.5,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.check,
                        size: 12,
                        color: AppColors.brightText,
                      ),
                    ),
                  )
                : const SizedBox();
          }),
          if (alertnessFailedIcon != null)
            Positioned(
              top: 0,
              right: 0,
              child: alertnessFailedIcon,
            ),
        ],
      ),
    );
  }
}
