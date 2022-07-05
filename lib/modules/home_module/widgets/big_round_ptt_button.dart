import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class BigRoundPttButton extends GetView<HomeController> {
  const BigRoundPttButton({Key? key, this.semiTransparent = false})
      : super(key: key);

  final bool semiTransparent;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final streamingState = controller.txState$.value.state;
      final broadcastingUser = HomeController.to.txState$.value.user;
      final isPttDisabled = HomeController.to.isPttDisabled;

      final color = () {
        if (isPttDisabled)
          return AppTheme()
              .colors
              .disabledButton
              .withOpacity(semiTransparent ? 0.5 : 1);

        switch (streamingState) {
          case StreamingState.preparing:
            return Colors.amber;
          case StreamingState.sending:
            return AppColors.pttTransmitting;
          case StreamingState.receiving:
            return AppColors.pttReceiving;
          case StreamingState.cleaning:
            return AppTheme()
                .colors
                .disabledButton
                .withOpacity(semiTransparent ? 0.5 : 1);
          default:
            return AppColors.pttIdle.withOpacity(semiTransparent ? 0.5 : 1);
        }
      }();

      return Listener(
          onPointerDown: (_) {
            if (!HomeController.to.canTalk ||
                HomeController.to.isPttKeyPressed$) return;
            controller.onPttPress();
          },
          onPointerUp: (_) {
            if (HomeController.to.isPttKeyPressed$) return;
            controller.onPttRelease();
          },
          child: Stack(
            children: [
              SizedBox(
                height: 70,
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    shape: const CircleBorder(),
                    shadowColor: color,
                    surfaceTintColor: Colors.transparent,
                    // disabledBackgroundColor: Colors.transparent,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (HomeController.to.isInRecordingMode)
                        const Padding(
                          padding: EdgeInsets.only(top: 3),
                          child: Icon(
                            LineAwesomeIcons.microphone,
                            color: AppColors.brightText,
                            size: 44,
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(bottom: 1),
                          child: SvgPicture.asset(
                            'assets/images/mic_broadcast_icon.svg',
                            color: AppColors.brightText,
                            width: 44,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (streamingState == StreamingState.receiving)
                Positioned(
                    left: 12,
                    top: 3,
                    child: ClipOval(
                      child: Container(
                        height: 65,
                        width: 65,
                        color: AppTheme().colors.mainBackground,
                        child: broadcastingUser!.avatar != null &&
                                broadcastingUser.avatar.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: broadcastingUser.avatar)
                            : const FittedBox(
                                child: Icon(
                                Icons.person,
                                color: AppColors.primaryAccent,
                              )),
                      ),
                    )),
            ],
          ));
    });
  }
}
