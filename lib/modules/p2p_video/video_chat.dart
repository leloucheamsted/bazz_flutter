import 'dart:core';

import 'package:bazz_flutter/modules/p2p_video/video_chat_controller.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/p2p_video_signaling.dart';
import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:get/get.dart';

import '../../app_theme.dart';

class VideoChatView extends GetView<VideoChatController> {
  const VideoChatView({Key? key}) : super(key: key);

  Widget buildCurrentUserDisplay(BuildContext context) {
    return controller.currentUser != null &&
            controller.callState == VideoSignalingState.CallStateIdle
        ? Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Row(mainAxisAlignment: MainAxisAlignment.center, children: [
              Text("AppLocalizations.of(context).startCallWith",
                  style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
              const SizedBox(
                width: 5,
              ),
              Text(controller.currentUser.fullName!,
                  style: const TextStyle(
                      fontSize: 14.0,
                      color: Colors.blueAccent,
                      fontWeight: FontWeight.w600)),
              const SizedBox(
                width: 15,
              ),
              FloatingActionButton(
                onPressed: () {
                  controller.invitePeer(controller.currentUser);
                },
                tooltip: " AppLocalizations.of(context).hangup",
                backgroundColor: AppColors.primaryAccent,
                child: const Icon(
                  Icons.video_call_outlined,
                  size: 30,
                ),
              ),
              const SizedBox(
                width: 15,
              ),
              FloatingActionButton(
                onPressed: () {
                  controller.hangUp();
                },
                tooltip: "AppLocalizations.of(context).hangup",
                backgroundColor: AppColors.error,
                child: const Icon(
                  Icons.call_end_outlined,
                  size: 30,
                ),
              ),
            ]),
            const SizedBox(
              height: 10,
            ),
          ])
        : Container();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: avoid_unnecessary_containers
    return Obx(
      () => Column(children: <Widget>[
        Expanded(
            child: Stack(
          children: [
            Positioned(
                left: 0.0,
                right: 0.0,
                top: 0.0,
                bottom: 0.0,
                child: Container(
                    margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(5.0),
                        child: Container(
                          width: MediaQuery.of(context).size.width,
                          //height: Get.height/3,
                          decoration:
                              const BoxDecoration(color: Colors.black87),
                          child: controller.connected
                              ? Stack(
                                  children: <Widget>[
                                    Positioned(
                                        // ignore: sized_box_for_whitespace
                                        child: Container(
                                            width: MediaQuery.of(context)
                                                .size
                                                .width,
                                            //height: Get.height/2,
                                            child: RTCVideoView(
                                                controller.remoteRenderer))),
                                    Positioned(
                                        right: 60,
                                        top: 15,
                                        child: Text(controller.currentPeerName,
                                            style: const TextStyle(
                                                fontSize: 16.0,
                                                color: Colors.white,
                                                fontWeight: FontWeight.w600))),
                                  ],
                                )
                              : Center(
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                      const Icon(
                                        Icons.no_photography_outlined,
                                        color: AppColors.brightText,
                                        size: 30,
                                      ),
                                      const SizedBox(width: 20),
                                      if (controller.callState ==
                                              VideoSignalingState
                                                  .ConnectionClosed ||
                                          controller.callState ==
                                              VideoSignalingState
                                                  .ConnectionError)
                                        Text(
                                          "AppLocalizations.of(context).noConnection",
                                          style: AppTheme()
                                              .typography
                                              .buttonTextStyle
                                              .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 30),
                                        )
                                      else
                                        Text(
                                          " AppLocalizations.of(context).noVideo",
                                          style: AppTheme()
                                              .typography
                                              .buttonTextStyle
                                              .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 30),
                                        ),
                                    ])),
                        )))),
            StatefulDragArea(
              offsetY: 340,
              offsetX: 0,
              child: ClipRRect(
                  borderRadius: BorderRadius.circular(10.0),
                  child: Container(
                    width: 90.0,
                    height: 120.0,
                    decoration: const BoxDecoration(color: Colors.black54),
                    child: controller.connected
                        ? RTCVideoView(controller.localRenderer)
                        : Container(),
                  )),
            ),
            Positioned(
              top: 12,
              right: 12,
              child: CircularIconButton(
                color: AppColors.brightBackground,
                onTap: () => {expendVideoView(context, "Video")},
                buttonSize: 35,
                child: const Icon(
                  Icons.fullscreen,
                  size: 25,
                  color: AppColors.primaryAccent,
                ),
              ),
            ),
            Positioned(
              bottom: 50,
              left: 100,
              child: controller.callState ==
                          VideoSignalingState.CallStateIncoming ||
                      controller.callState ==
                          VideoSignalingState.CallStateOutgoing ||
                      controller.callState ==
                          VideoSignalingState.CallStateConnected
                  ? SizedBox(
                      width: 200.0,
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            FloatingActionButton(
                              onPressed: controller.switchCamera,
                              backgroundColor: AppColors.secondaryButton,
                              child: const Icon(
                                Icons.switch_camera_outlined,
                                size: 30,
                              ),
                            ),
                            FloatingActionButton(
                              onPressed: controller.hangUp,
                              tooltip: "AppLocalizations.of(context).hangup",
                              backgroundColor: AppColors.error,
                              child: const Icon(
                                Icons.call_end_outlined,
                                size: 30,
                              ),
                            ),
                            if (controller.callState ==
                                VideoSignalingState.CallStateIncoming)
                              FloatingActionButton(
                                onPressed: controller.pickUp,
                                tooltip: "AppLocalizations.of(context).pickup",
                                backgroundColor:
                                    AppTheme().colors.primaryButton,
                                child: const Icon(
                                  Icons.call_outlined,
                                  size: 30,
                                ),
                              ),
                          ]))
                  : controller.callState == VideoSignalingState.CallStateBusy
                      ? SizedBox(
                          width: 200.0,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                FloatingActionButton(
                                  onPressed: controller.hangUp,
                                  tooltip:
                                      "AppLocalizations.of(context).cancel",
                                  backgroundColor: AppColors.error,
                                  child: const Icon(
                                    Icons.close_outlined,
                                    color: Colors.black54,
                                  ),
                                ),
                                Container(
                                  height: 56,
                                  width: 56,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: AppTheme().colors.primaryButton,
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.white,
                                        blurRadius: 1,
                                        spreadRadius: 1,
                                      ),
                                    ],
                                  ),
                                  child: const Center(
                                      child: Text("Busy",
                                          style: AppTypography
                                              .groupUnitTitleStyle)),
                                ),
                              ]))
                      : Container(),
            )
          ],
        ))
      ]),
    );
  }

  void expendVideoView(BuildContext context, String text) {
    Get.dialog(
      Scaffold(
        backgroundColor: Colors.black26,
        body: SafeArea(
          child: Center(
            child: InteractiveViewer(
                child: Expanded(
                    child: Stack(
              children: [
                Positioned(
                    left: 0.0,
                    right: 0.0,
                    top: 0.0,
                    bottom: 0.0,
                    child: Container(
                        margin: const EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                        child: ClipRRect(
                            borderRadius: BorderRadius.circular(0.0),
                            child: Container(
                              width: MediaQuery.of(context).size.width,
                              //height: Get.height/3,
                              decoration:
                                  const BoxDecoration(color: Colors.black87),
                              child: controller.connected
                                  ? Stack(
                                      children: <Widget>[
                                        Positioned(
                                            // ignore: sized_box_for_whitespace
                                            child: Container(
                                                width: MediaQuery.of(context)
                                                    .size
                                                    .width,
                                                //height: Get.height/2,
                                                child: RTCVideoView(controller
                                                    .remoteRenderer))),
                                        //Positioned(left: 30, bottom: 20, child: buildCurrentUserDisplay(context)),
                                        Positioned(
                                            right: 30,
                                            top: 20,
                                            child: Text(
                                                controller.currentPeerName,
                                                style: const TextStyle(
                                                    fontSize: 16.0,
                                                    color: Colors.white,
                                                    fontWeight:
                                                        FontWeight.w600))),
                                      ],
                                    )
                                  : Center(
                                      child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                          const Icon(
                                            Icons.no_photography_outlined,
                                            color: AppColors.brightText,
                                            size: 30,
                                          ),
                                          const SizedBox(width: 20),
                                          if (controller.callState ==
                                                  VideoSignalingState
                                                      .ConnectionClosed ||
                                              controller.callState ==
                                                  VideoSignalingState
                                                      .ConnectionError)
                                            Text(
                                              "AppLocalizations.of(context).noConnection",
                                              style: AppTheme()
                                                  .typography
                                                  .buttonTextStyle
                                                  .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 30),
                                            )
                                          else
                                            Text(
                                              " AppLocalizations.of(context).noVideo",
                                              style: AppTheme()
                                                  .typography
                                                  .buttonTextStyle
                                                  .copyWith(
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      fontSize: 30),
                                            ),
                                        ])),
                            )))),
                Positioned(
                  top: 12,
                  right: 12,
                  child: CircularIconButton(
                    color: AppColors.brightBackground,
                    onTap: () => {Get.back()},
                    buttonSize: 35,
                    child: const Icon(
                      Icons.close_fullscreen_sharp,
                      size: 25,
                      color: AppColors.lightText,
                    ),
                  ),
                ),
                StatefulDragArea(
                  offsetY: 0,
                  offsetX: 0,
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(10.0),
                      child: Container(
                        width: 90.0,
                        height: 120.0,
                        decoration: const BoxDecoration(color: Colors.black54),
                        child: controller.connected
                            ? RTCVideoView(controller.localRenderer)
                            : Container(),
                      )),
                ),
                Positioned(
                  bottom: 50,
                  left: 100,
                  child: controller.callState ==
                              VideoSignalingState.CallStateIncoming ||
                          controller.callState ==
                              VideoSignalingState.CallStateOutgoing ||
                          controller.callState ==
                              VideoSignalingState.CallStateConnected
                      ? SizedBox(
                          width: 200.0,
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                FloatingActionButton(
                                  onPressed: controller.switchCamera,
                                  backgroundColor: AppColors.secondaryButton,
                                  child:
                                      const Icon(Icons.switch_camera_outlined),
                                ),
                                FloatingActionButton(
                                  onPressed: controller.hangUp,
                                  tooltip:
                                      " AppLocalizations.of(context).hangup",
                                  backgroundColor: AppColors.error,
                                  child: const Icon(Icons.call_end_outlined),
                                ),
                                if (controller.callState ==
                                    VideoSignalingState.CallStateIncoming)
                                  FloatingActionButton(
                                    onPressed: controller.pickUp,
                                    tooltip:
                                        "AppLocalizations.of(context).pickup",
                                    backgroundColor:
                                        AppTheme().colors.primaryButton,
                                    child: const Icon(Icons.call_outlined),
                                  ),
                              ]))
                      : controller.callState ==
                              VideoSignalingState.CallStateBusy
                          ? SizedBox(
                              width: 200.0,
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    FloatingActionButton(
                                      onPressed: controller.hangUp,
                                      tooltip:
                                          "AppLocalizations.of(context).cancel",
                                      backgroundColor: AppColors.error,
                                      child: const Icon(
                                        Icons.close_outlined,
                                        color: Colors.black54,
                                      ),
                                    ),
                                    Container(
                                      height: 56,
                                      width: 56,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: AppTheme().colors.primaryButton,
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.white,
                                            blurRadius: 1,
                                            spreadRadius: 1,
                                          ),
                                        ],
                                      ),
                                      child: const Center(
                                          child: Text("Busy",
                                              style: AppTypography
                                                  .groupUnitTitleStyle)),
                                    ),
                                  ]))
                          : Container(),
                )
              ],
            ))),
          ),
        ),
      ),
    );
  }
}

class StatefulDragArea extends StatefulWidget {
  final Widget? child;
  final int? offsetX;
  final int? offsetY;

  const StatefulDragArea({Key? key, this.child, this.offsetY, this.offsetX})
      : super(key: key);

  @override
  _DragAreaStateStateful createState() => _DragAreaStateStateful();
}

class _DragAreaStateStateful extends State<StatefulDragArea> {
  Offset position = const Offset(20, 20);

  void updatePosition(DraggableDetails details) {
    setState(() {
      TelloLogger().i("Position Offset ${details.offset} ${Get.height}");
      if ((details.offset.dy - widget.offsetY!) < 20 ||
          (details.offset.dx - widget.offsetX!) < 20) {
        position = const Offset(20.0, 20.0);
      } else if ((details.offset.dy) + 160 > Get.height ||
          (details.offset.dx - widget.offsetX!) + 90 > Get.width) {
        position = const Offset(20.0, 20.0);
      } else {
        position = Offset(details.offset.dx - widget.offsetX!,
            details.offset.dy - widget.offsetY!);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          left: position.dx,
          top: position.dy,
          child: Draggable(
            feedback: widget.child!,
            childWhenDragging: Opacity(
              opacity: .3,
              child: widget.child,
            ),
            onDragEnd: (details) => {updatePosition(details)},
            child: widget.child!,
          ),
        )
      ],
    );
  }
}
