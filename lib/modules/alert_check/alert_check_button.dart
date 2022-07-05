import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/alert_check/alert_check_service.dart';
import 'package:bazz_flutter/modules/home_module/widgets/count_down_timer.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:custom_timer/custom_timer.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class AlertCheckButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 26,
      width: 26,
      child: Obx(() {
        return Stack(
          children: [
            Container(
                width: 26,
                height: 26,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.warning,
                )),
            if (AlertCheckService.to.isCheckSilent.isFalse)
              GetBuilder<AlertCheckService>(
                id: 'CountDownTimer',
                builder: (_) {
                  return CountDownTimer(
                    key: UniqueKey(),
                    duration: AlertCheckService.to.checkButtonTimeLeft,
                    onFinish: AlertCheckService.to.sendFailedAlertCheck,
                    onValueChanged: AlertCheckService.to.setCheckButtonTimeLeft,
                  );
                },
              ),
            GestureDetector(
                onTap: () {
                  if (Get.currentRoute != AppRoutes.alertCheck)
                    AlertCheckService.to.goToAlertCheckPage();
                },
                child: const Center(
                    child: FaIcon(
                  Icons.timer,
                  color: AppColors.brightText,
                  size: 18,
                )))
          ],
        );
      }),
    );
    // return Container(
    //   alignment: Alignment.center,
    //   child: RawMaterialButton(
    //     padding: const EdgeInsets.symmetric(horizontal: 10),
    //     shape: RoundedRectangleBorder(
    //       borderRadius: BorderRadius.circular(5.0),
    //     ),
    //     fillColor: AppColors.warning,
    //     onPressed: Get.currentRoute != AppRoutes.alertCheck ? AlertCheckService.to.goToAlertCheckPage : null,
    //     child: Row(
    //       mainAxisAlignment: MainAxisAlignment.center,
    //       children: [
    //         const Icon(
    //           Icons.alarm,
    //           color: AppColors.brightText,
    //           size: 17,
    //         ),
    //         const SizedBox(width: 10),
    //         Text(
    //           AppLocalizations.of(context).alertCheck,
    //           style: AppTheme().typography.buttonTextStyle.copyWith(fontWeight: FontWeight.w600),
    //         ),
    //         const SizedBox(width: 10),
    //         SizedBox(
    //           width: 45,
    //           child: Obx(() {
    //             //TODO: refactor this CustomTimer in favor of using external controller
    //             // for better sync of remaining time between pages
    //             return AlertCheckService.to.isCheckSilent.isFalse
    //                 ? CustomTimer(
    //                     from: AlertCheckService.to.checkButtonTimeLeft ??
    //                         Session.shift.alertCheckConfig.alertCheckTimeout.seconds,
    //                     to: const Duration(),
    //                     onBuildAction: CustomTimerAction.auto_start,
    //                     onFinish: AlertCheckService.to.sendFailedAlertCheck,
    //                     builder: (CustomTimerRemainingTime remaining) {
    //                       AlertCheckService.to.checkButtonTimeLeft = remaining.duration;
    //                       return Text(
    //                         "${remaining.minutes}:${remaining.seconds}",
    //                         maxLines: 1,
    //                         style: AppTypography.timerTextStyle.copyWith(color: AppColors.brightText),
    //                       );
    //                     },
    //                   )
    //                 : const SizedBox();
    //           }),
    //         ),
    //       ],
    //     ),
    //   ),
    // );
  }
}
