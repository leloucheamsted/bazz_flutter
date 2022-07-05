import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BigRoundSosButton extends StatelessWidget {
  const BigRoundSosButton({Key? key, this.semiTransparent = false})
      : super(key: key);

  final bool semiTransparent;

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
          height: 70,
          child: ElevatedButton(
            onPressed: sosDisabled ? null : () {},
            style: ElevatedButton.styleFrom(
              shape: const CircleBorder(),
              shadowColor: sosDisabled
                  ? null
                  : AppColors.error.withOpacity(
                      semiTransparent && !HomeController.to.isSosPressed$
                          ? 0.5
                          : 1),
              // disabledForegroundColor: sosDisabled
              //     ? AppTheme()
              //         .colors
              //         .disabledButton
              //         .withOpacity(semiTransparent ? 0.5 : 1)
              //     : null,
              // disabledBackgroundColor: Colors.transparent,
              surfaceTintColor: Colors.transparent,
            ),
            child: Text(
              'SOS',
              style: AppTheme()
                  .typography
                  .buttonTextStyle
                  .copyWith(fontSize: 22, fontWeight: FontWeight.w600),
            ),
          ),
        ),
      );
    });
  }
}
