import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:custom_timer/custom_timer.dart';
import 'package:flutter/material.dart';
import 'package:get/get_state_manager/src/rx_flutter/rx_obx_widget.dart';
import 'package:bazz_flutter/services/statistics_service.dart';

class TalkTimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final streamingState = HomeController.to.txState$().state;
      return HomeController.to.isRecordingOfflineMessage ||
              streamingState == StreamingState.receiving ||
              streamingState == StreamingState.sending
          ? SizedBox(
              width: 70,
              child: CustomTimer(
                begin: const Duration(),
                end: const Duration(seconds: 3600),
                //onBuildAction: CustomTimerAction.auto_start,
                builder: (remaining) {
                  StatisticsService().updatePTTStreamTime(1, streamingState);
                  return Text(
                    "${remaining.minutes}:${remaining.seconds}",
                    style: AppTypography.appBarTimerTextStyle,
                  );
                },
              ),
            )
          : const SizedBox();
    });
  }
}
