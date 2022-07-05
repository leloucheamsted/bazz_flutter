import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/widgets/status_chip.dart';
import 'package:bazz_flutter/modules/shift_activities/shift_activities_service.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:custom_timer/custom_timer.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:localization/localization.dart';

class TimerAndStatusBar extends StatelessWidget {
  const TimerAndStatusBar({Key? key, required this.controller})
      : super(key: key);

  final HomeController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: const BoxDecoration(
        color: AppColors.brightBackground,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 3,
          )
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Obx(() {
              return controller.servicesInitialized$()
                  ? !Session.user!.isCustomer!
                      ? _buildShiftTimer(context)
                      : const SizedBox()
                  : const SizedBox();
            }),
          ),
          VerticalDivider(
            width: 1,
            thickness: 1,
            color: Colors.black.withOpacity(.05),
          ),
          Obx(() {
            Color color;
            String text;
            if (controller.isOnline) {
              color = AppColors.primaryAccent;
              text = "LocalJsonLocalization.of(context).online";
            } else {
              color = AppColors.offline;
              text = "AppLocalizations.of(context).offline";
            }
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: StatusChip(color: color, text: text),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildShiftTimer(BuildContext context) {
    return ObxValue<RxBool>(
      (isDurationShown) {
        final currentActivityTimer =
            ShiftActivitiesService.instance?.currentActivityTimer;
        return GestureDetector(
          onTap: () => isDurationShown.toggle(),
          behavior: HitTestBehavior.opaque,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        isDurationShown()
                            ? " AppLocalizations.of(context).shiftDuration"
                            : "AppLocalizations.of(context).endsIn",
                        style: AppTypography.bodyText2TextStyle
                            .copyWith(fontSize: 10),
                      ),
                      if (isDurationShown())
                        Text(
                          humanizeDuration(seconds: Session.shift!.duration) ??
                              '--:--:--',
                          style: AppTypography.timerTextStyle
                              .copyWith(fontSize: 13),
                        )
                      else if (controller.shiftTimer != null &&
                          controller.shiftTimer!.isActive)
                        CustomTimer(
                          begin: controller.shiftTimer!.duration -
                              controller.shiftTimer!.elapsed,
                          end: const Duration(),
                          //  onChangeState: CustomTimer.,
                          builder: (remaining) {
                            return Text(
                              "${remaining.hours}:${remaining.minutes}:${remaining.seconds}",
                              style: AppTypography.timerTextStyle
                                  .copyWith(fontSize: 13),
                            );
                          },
                        )
                      else
                        Text(
                          '--:--:--',
                          style: AppTypography.timerTextStyle
                              .copyWith(fontSize: 13),
                        )
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    children: [
                      Text(
                        //TODO: modify depending on the current activity
                        'Start Shift',
                        style: AppTypography.bodyText2TextStyle
                            .copyWith(fontSize: 10),
                      ),
                      if (currentActivityTimer != null &&
                          currentActivityTimer.isActive)
                        CustomTimer(
                          begin: currentActivityTimer.duration -
                              currentActivityTimer.elapsed,
                          end: const Duration(),
                          //onChangeState: CustomTimer.auto_start,
                          builder: (remaining) {
                            return Text(
                              "${remaining.hours}:${remaining.minutes}:${remaining.seconds}",
                              style: AppTypography.timerTextStyle
                                  .copyWith(fontSize: 13),
                            );
                          },
                        )
                      else
                        Text(
                          '--:--:--',
                          style: AppTypography.timerTextStyle
                              .copyWith(fontSize: 13),
                        )
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
      false.obs,
    );
  }
}
