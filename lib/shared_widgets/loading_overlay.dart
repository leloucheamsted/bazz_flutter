import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/utils/back_button_locker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';

/// USE WITH CAUTION! Can cause errors when trying to display it while other widget is being built.
/// It also pushes new route in the Navigation stack.
class LoadingOverlay {
  static void showAndLock() {
    BackButtonLocker.lockBackButton();
    Get.dialog(
      Center(child: SpinKitCubeGrid(color: AppColors.loadingIndicator)),
      transitionDuration: const Duration(milliseconds: 100),
      barrierDismissible: false,
      barrierColor: AppColors.overlayBarrier,
      routeSettings: const RouteSettings(name: '/overlay'),
    );
  }

  static void hideAndUnlock() {
    BackButtonLocker.unlockBackButton();
    if (Get.isDialogOpen!) Get.back();
  }
}
