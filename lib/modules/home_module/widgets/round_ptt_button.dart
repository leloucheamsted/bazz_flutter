import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class RoundPttButton extends GetView<HomeController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final streamingState = controller.txState$.value.state;
      final isPttDisabled = HomeController.to.isPttDisabled;

      final color = () {
        if (isPttDisabled) return AppTheme().colors.disabledButton;

        switch (streamingState) {
          case StreamingState.preparing:
            return Colors.amber;
          case StreamingState.sending:
            return AppColors.pttTransmitting;
          case StreamingState.receiving:
            return AppColors.pttReceiving;
          case StreamingState.cleaning:
            return AppTheme().colors.disabledButton;
          default:
            return AppColors.pttIdle;
        }
      }();

      return Listener(
          onPointerDown: (_) {
            if (!HomeController.to.canTalk || HomeController.to.isPttKeyPressed$) return;
              controller.onPttPress();
          },
          onPointerUp: (_) {
            if (HomeController.to.isPttKeyPressed$) return;
            controller.onPttRelease();
          },
          child: CircularIconButton(
            buttonSize: 50,
            color: color,
            elevation: 3,
            onTap: () {},
            child: HomeController.to.isInRecordingMode ? const Padding(
              padding: EdgeInsets.only(top: 3),
              child: Icon(
                LineAwesomeIcons.microphone,
                color: AppColors.brightText,
                size: 30,
              ),
            ) : SvgPicture.asset('assets/images/mic_broadcast_icon.svg', color: AppColors.brightText, width: 33),
          ));
    });
  }
}
