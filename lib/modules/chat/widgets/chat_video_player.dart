import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:video_viewer/video_viewer.dart';

///This is meant to be put in Get.dialog
class ChatVideoPlayer extends StatelessWidget {
  final Map<String, VideoSource> src;

  const ChatVideoPlayer(this.src, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: Get.back,
      child: Scaffold(
        backgroundColor: Colors.black26,
        body: SafeArea(
          child: Center(
            child: VideoViewer(
              source: src,
              style: VideoViewerStyle(
                settingsStyle:
                    SettingsMenuStyle(paddingBetweenMainMenuItems: 10),
              ),
              autoPlay: true,
            ),
          ),
        ),
      ),
    );
  }
}
