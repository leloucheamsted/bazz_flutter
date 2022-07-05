import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/modules/chat/chat_controller.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/enums.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_portal/flutter_portal.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class MessageFooter extends StatelessWidget {
  const MessageFooter(this.msg, {Key? key}) : super(key: key);

  final ChatMessage msg;

  @override
  Widget build(BuildContext context) {
    final isAudioOrVideo = msg.messageType == MessageBaseType.image ||
        msg.messageType == MessageBaseType.video ||
        msg.messageType == MessageBaseType.pdf;
    final kbNotVisible = !KeyboardVisibilityProvider.isKeyboardVisible(context);
    return msg.isPending
        ? const Padding(
            padding: EdgeInsets.only(left: 5),
            child: Icon(
              Icons.access_time_outlined,
              size: 17,
              color: AppColors.lightText,
            ),
          )
        : msg.createdAt != null
            ? GestureDetector(
                onTap: msg.isOutgoing && kbNotVisible
                    ? () => ChatController.to
                        .toggleIsReceivedByPopupOpen(value: true, id: msg.id)
                    : null,
                child: Container(
                  padding: isAudioOrVideo
                      ? const EdgeInsets.symmetric(vertical: 1, horizontal: 6)
                      : null,
                  decoration: isAudioOrVideo
                      ? BoxDecoration(
                          color: Colors.black38,
                          borderRadius: BorderRadius.circular(8),
                        )
                      : null,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        DateFormat(AppSettings().timeFormat)
                            .format(msg.createdAt),
                        style: TextStyle(
                            color: isAudioOrVideo
                                ? Colors.white
                                : AppColors.lightText,
                            fontSize: 12),
                      ),
                      if (msg.isOutgoing)
                        GetBuilder<ChatController>(
                            id: 'received-by-icon${msg.id}',
                            builder: (controller) {
                              final iconColor = msg.didAllReceive &&
                                      msg.receivedBy
                                          .every((rcvr) => rcvr.hasRead)
                                  ? AppColors.primaryAccent
                                  : AppColors.lightText;

                              if (msg.isPrivate) {
                                return _buildCheckIcons(
                                    color: iconColor,
                                    isDouble: msg.didAllReceive);
                              }

                              return PortalTarget(
                                visible: controller.isReceivedByPopupOpen,
                                portalFollower: GestureDetector(
                                  behavior: HitTestBehavior.opaque,
                                  onTap: () =>
                                      controller.toggleIsReceivedByPopupOpen(
                                          value: false, id: msg.id),
                                ),
                                child: PortalTarget(
                                  visible: controller.isReceivedByPopupOpen,
                                  anchor: Alignment.topRight as Anchor,
                                  // : Alignment.bottomRight,
                                  closeDuration:
                                      const Duration(milliseconds: 100),
                                  portalFollower:
                                      _buildReceivedByPopup(controller),
                                  child: _buildCheckIcons(
                                      color: iconColor,
                                      isDouble: msg.didAnyReceive),
                                ),
                              );
                            }),
                    ],
                  ),
                ),
              )
            : const SizedBox();
  }

  Widget _buildCheckIcons({Color? color, bool isDouble = true}) {
    final checkIcon = Icon(Icons.check_rounded, size: 15, color: color);
    return Stack(
      children: [
        Padding(
          padding: EdgeInsets.only(
            left: 2,
            right: isDouble ? 5 : 0,
          ),
          child: checkIcon,
        ),
        if (isDouble)
          Positioned(
            right: 0,
            child: checkIcon,
          ),
      ],
    );
  }

  Widget _buildReceivedByPopup(ChatController controller) {
    return ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: Get.width * 0.88,
      ),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 100),
        opacity: controller.isReceivedByPopupOpen ? 1 : 0,
        child: Container(
          margin: const EdgeInsets.only(top: 7),
          padding: const EdgeInsets.fromLTRB(5, 5, 5, 5),
          decoration: BoxDecoration(
            color: AppTheme().colors.mainBackground,
            boxShadow: const [
              BoxShadow(
                color: Colors.black26,
                spreadRadius: 2,
                blurRadius: 3,
              ),
            ],
            borderRadius: const BorderRadius.all(Radius.circular(5)),
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...HomeController.to.activeGroup.members.users.map((u) {
                  final receiver = msg.receivedBy.firstWhere(
                      (receiver) => receiver.id == u.id,
                      orElse: () => null!);
                  final didReceive = receiver != null;
                  final hasRead = receiver.hasRead;
                  final iconColor =
                      hasRead ? AppColors.primaryAccent : AppColors.lightText;
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 70),
                    child: Padding(
                      padding: const EdgeInsets.only(right: 5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Stack(
                            children: [
                              Container(
                                alignment: Alignment.center,
                                height: 36,
                                width: 46,
                                child: FaIcon(
                                  FontAwesomeIcons.solidUserCircle,
                                  color: u.isOnline()
                                      ? AppColors.online
                                      : AppColors.offline,
                                  size: 35,
                                ),
                              ),
                              if (u.avatar != null && u.avatar.isNotEmpty)
                                Positioned(
                                  top: 4,
                                  left: 8,
                                  child: ClipOval(
                                    child: SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: CachedNetworkImage(
                                          imageUrl: u.avatar),
                                    ),
                                  ),
                                ),
                              Positioned(
                                right: 0,
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      height: 15,
                                      width: 15,
                                      decoration: const BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppColors.brightBackground,
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.white,
                                            blurRadius: 1,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (didReceive)
                                      _buildCheckIcons(color: iconColor)
                                    else
                                      const Icon(
                                        Icons.access_time_rounded,
                                        size: 15,
                                        color: AppColors.lightText,
                                      ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 5),
                          Text(
                            u.fullName!,
                            textAlign: TextAlign.center,
                            style: AppTheme().typography.memberNameStyle,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
                ...HomeController.to.activeGroup.members.positions.map((p) {
                  final receiver = msg.receivedBy.firstWhere(
                    (receiver) => receiver.positionId == p.id,
                    orElse: () => null!,
                  );
                  final didReceive = receiver != null;
                  final hasRead = receiver.hasRead;
                  final iconColor =
                      hasRead ? AppColors.primaryAccent : AppColors.lightText;
                  return ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 70),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Stack(
                          children: [
                            Container(
                              alignment: Alignment.center,
                              height: 36,
                              width: 46,
                              child: FaIcon(
                                FontAwesomeIcons.userCircle,
                                color: p.status() == PositionStatus.active
                                    ? AppColors.online
                                    : p.status() == PositionStatus.inactive
                                        ? AppColors.offline
                                        : AppColors.outOfRange,
                                size: 35,
                              ),
                            ),
                            if (p.worker().avatar != null &&
                                p.worker().avatar.isNotEmpty)
                              Positioned(
                                top: 4,
                                left: 8,
                                child: ClipOval(
                                  child: SizedBox(
                                      height: 30,
                                      width: 30,
                                      child: CachedNetworkImage(
                                          imageUrl: p.worker().avatar)),
                                ),
                              ),
                            Positioned(
                              right: 0,
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  Container(
                                    height: 15,
                                    width: 15,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.brightBackground,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Colors.white,
                                          blurRadius: 1,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (didReceive)
                                    _buildCheckIcons(color: iconColor)
                                  else
                                    const Icon(
                                      Icons.access_time_rounded,
                                      size: 15,
                                      color: AppColors.lightText,
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 5),
                        Text(
                          p.title,
                          textAlign: TextAlign.center,
                          style: AppTheme().typography.memberNameStyle,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  );
                }).toList()
              ],
            ),
          ),
        ),
      ),
    );
  }
}
