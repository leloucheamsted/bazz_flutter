import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RoundSosButton extends StatelessWidget {
  const RoundSosButton(
      {Key? key, this.semiTransparent = false, this.diameter = 50})
      : super(key: key);

  final bool semiTransparent;
  final double diameter;

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final sosDisabled = HomeController.to.isSosDisabled;
      return Listener(
        onPointerDown: (_) {
          if (HomeController.to.isSosKeyPressed$) return;
          HomeController.to.onSosPress();
        },
        onPointerUp: (_) {
          if (HomeController.to.isSosKeyPressed$) return;
          HomeController.to.onSosRelease();
        },
        child: SizedBox(
          height: diameter,
          width: diameter,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              visualDensity: VisualDensity.compact,
              shape: const CircleBorder(),
              shadowColor: sosDisabled
                  ? null
                  : semiTransparent
                      ? AppColors.error.withOpacity(
                          semiTransparent && !HomeController.to.isSosPressed$
                              ? 0.5
                              : 1)
                      : HomeController.to.isSosPressed$
                          ? AppColors.darkError
                          : AppColors.error,
              // enabledMouseCursor: sosDisabled
              //     ? AppTheme()
              //         .colors
              //         .disabledButton
              //         .withOpacity(semiTransparent ? 0.5 : 1)
              //     : null,
              //  splashColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
            ),
            onPressed: sosDisabled ? null : () {},
            child: Text(
              'SOS',
              style: AppTheme().typography.buttonTextStyle,
            ),
          ),
        ),
      );
    });
  }
}
