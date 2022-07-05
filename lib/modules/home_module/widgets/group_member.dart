import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class GroupMember {
  static Widget buildPosition(
      {required RxPosition position,
      required VoidCallback onTap,
      bool isVideoContext = false}) {
    final iconColor = position.status() == PositionStatus.active
        ? AppColors.online
        : position.status() == PositionStatus.inactive
            ? AppColors.offline
            : AppColors.outOfRange;
    final avatar =
        position.worker().avatar != null && position.worker().avatar.isNotEmpty
            ? position.worker().avatar
            : null;
    return _buildMember(
        onTap: onTap,
        iconColor: iconColor,
        avatar: avatar!,
        isTransmitting: position.isTransmitting,
        sos: position.sos,
        title: position.title,
        isVideoActive: position.worker.value != null
            ? position.worker().isVideoActive
            : false.obs,
        isVideoConnected: position.worker.value != null
            ? position.worker().isVideoConnected
            : false.obs,
        user: position.worker.value,
        isVideoContext: isVideoContext);
  }

  static Widget buildUser(
      {RxUser? user, VoidCallback? onTap, bool isVideoContext = false}) {
    final iconColor = user!.isOnline() ? AppColors.online : AppColors.offline;
    final avatar =
        user.avatar != null && user.avatar.isNotEmpty ? user.avatar : null;

    return _buildMember(
        onTap: onTap!,
        iconColor: iconColor,
        avatar: avatar!,
        isTransmitting: user.isTransmitting,
        sos: user.sos,
        title: user.fullName,
        isVideoActive: user.isVideoActive,
        isVideoConnected: user.isVideoConnected,
        user: user,
        isVideoContext: isVideoContext);
  }

  static Widget _buildMember(
      {Color? iconColor,
      VoidCallback? onTap,
      String? avatar,
      String? title,
      RxBool? isTransmitting,
      RxBool? sos,
      RxBool? isVideoActive,
      RxBool? isVideoConnected,
      RxUser? user,
      bool isVideoContext = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.transparent,
        width: 70,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Obx(() {
              return Stack(
                children: [
                  Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      border: Border.all(width: 2, color: iconColor!),
                      shape: BoxShape.circle,
                      image: avatar != null
                          ? DecorationImage(
                              image: CachedNetworkImageProvider(avatar),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    width: 35,
                    height: 35,
                    child: avatar == null
                        ? FaIcon(
                            FontAwesomeIcons.userAlt,
                            color: iconColor,
                            size: 22,
                          )
                        : null,
                  ),
                  if (isVideoActive!() && isVideoContext)
                    Positioned(
                      child: Container(
                        height: 17,
                        width: 17,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.mapMarkerPath,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.white,
                              blurRadius: 1,
                              spreadRadius: 1.5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.video_call_outlined,
                          size: 14,
                          color: AppColors.brightText,
                        ),
                      ),
                    ),
                  if (isVideoConnected!() && isVideoContext)
                    Positioned(
                      child: Container(
                        height: 17,
                        width: 17,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.error,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.white,
                              blurRadius: 1,
                              spreadRadius: 1.5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.video_call_outlined,
                          size: 14,
                          color: AppColors.brightText,
                        ),
                      ),
                    ),
                  if (isTransmitting!())
                    Positioned(
                      child: Container(
                        height: 15,
                        width: 15,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.primaryAccent,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.white,
                              blurRadius: 1,
                              spreadRadius: 1.5,
                            ),
                          ],
                        ),
                        child: const Icon(
                          Icons.volume_up,
                          size: 12,
                          color: AppColors.brightText,
                        ),
                      ),
                    ),
                  if (sos!())
                    Positioned(
                      right: 0,
                      top: 2,
                      child: Container(
                        height: 13,
                        width: 13,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.sos,
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.white,
                              blurRadius: 1,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              );
            }),
            const SizedBox(height: 5),
            Expanded(
              child: Text(
                title!,
                textAlign: TextAlign.center,
                style: AppTheme().typography.memberNameStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
