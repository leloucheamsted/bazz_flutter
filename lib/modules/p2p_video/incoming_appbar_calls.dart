import 'dart:core';

import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/p2p_video/video_chat_controller.dart';
import 'package:bazz_flutter/services/p2p_video_signaling.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

import '../../app_theme.dart';

class IncomingCallsView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
          child: (VideoChatController.to.callState ==
                      VideoSignalingState.CallStateIncoming ||
                  VideoChatController.to.callState ==
                      VideoSignalingState.CallStateOutgoing ||
                  VideoChatController.to.callState ==
                      VideoSignalingState.CallStateConnected)
              ? Container(
                  width: Get.width,
                  height: 60,
                  decoration:
                      BoxDecoration(color: Colors.black87.withOpacity(0.9)),
                  child: Stack(children: [
                    Positioned(
                      left: 20,
                      top: 10,
                      child: HomeController.to.bottomNavBarIndex ==
                              BottomNavTab.videoChat.index
                          ? GestureDetector(
                              onTap: () {
                                HomeController.to
                                    .gotoBottomNavTab(BottomNavTab.videoChat);
                              },
                              child: Container(
                                height: 34,
                                width: 34,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: AppTheme().colors.primaryButton,
                                  boxShadow: const [
                                    BoxShadow(
                                      color: AppColors.brightIcon,
                                      blurRadius: 1,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(
                                  Icons.videocam,
                                  size: 24,
                                  color: AppColors.brightIcon,
                                ),
                              ),
                            )
                          : Container(),
                    ),
                    Positioned(
                        left: (Get.width / 2) - 50,
                        top: 10,
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  VideoChatController.to.hangUp();
                                },
                                child: Container(
                                  height: 34,
                                  width: 34,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppColors.error,
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.brightBackground,
                                        blurRadius: 1,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.call_end_outlined,
                                    size: 24,
                                    color: AppColors.brightIcon,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 40),
                              if (VideoChatController.to.callState ==
                                  VideoSignalingState.CallStateIncoming)
                                GestureDetector(
                                  onTap: () {
                                    VideoChatController.to.pickUp();
                                  },
                                  child: Container(
                                    height: 34,
                                    width: 34,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppTheme().colors.primaryButton,
                                      boxShadow: const [
                                        BoxShadow(
                                          color: AppColors.brightIcon,
                                          blurRadius: 1,
                                          spreadRadius: 1,
                                        ),
                                      ],
                                    ),
                                    child: const Icon(
                                      Icons.call_outlined,
                                      size: 24,
                                      color: AppColors.brightIcon,
                                    ),
                                  ),
                                ),
                            ]))
                  ]))
              : Container(),
        ));
  }
}

class PrivateCallView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() => Container(
        child: HomeController.to.privateCallUser != null
            ? Container(
                width: Get.width,
                height: 60,
                decoration:
                    BoxDecoration(color: Colors.black87.withOpacity(0.9)),
                child: Stack(children: [
                  Positioned(
                    right: 115,
                    top: 15,
                    child: Text(
                      "${HomeController.to.canClosePrivateCall ? "AppLocalizations.of(context).privateCallTo " : "AppLocalizations.of(context).privateCallFrom"} ${HomeController.to.privateCallUser.fullName}",
                      style: AppTypography.bodyText3TextStyle
                          .copyWith(fontWeight: FontWeight.w500, fontSize: 12),
                      maxLines: 1,
                    ),
                  ),
                  if (HomeController.to.canClosePrivateCall)
                    Positioned(
                      right: 115,
                      top: 35,
                      child: Text(
                        "[{AppLocalizations.of(context).user} {HomeController.to.privateCallUser.isOnline() ? AppLocalizations.of(context).online : AppLocalizations.of(context).offline}]",
                        style: AppTypography.bodyText3TextStyle.copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 11,
                            color: HomeController.to.privateCallUser.isOnline()
                                ? AppColors.online
                                : AppColors.offline),
                        maxLines: 1,
                      ),
                    ),
                  Positioned(
                      right: 60,
                      top: 15,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            GestureDetector(
                              onTap: () {
                                if (Session.isSupervisor &&
                                    HomeController.to.canClosePrivateCall) {
                                  HomeController.to.stopPrivateCall();
                                }
                              },
                              child: Container(
                                height: 30,
                                width: 30,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: HomeController.to.canClosePrivateCall
                                      ? AppColors.error
                                      : AppColors.secondaryButton,
                                  boxShadow: [
                                    BoxShadow(
                                      color: AppColors.brightBackground,
                                      blurRadius: 1,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: HomeController.to.canClosePrivateCall
                                    ? const Icon(
                                        Icons.call_end_outlined,
                                        size: 18,
                                        color: AppColors.brightIcon,
                                      )
                                    : const Icon(
                                        Icons.call,
                                        size: 18,
                                        color: AppColors.brightIcon,
                                      ),
                              ),
                            ),
                            const SizedBox(width: 20),
                          ]))
                ]))
            : Container()));
  }
}
