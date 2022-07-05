import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/shared_widgets/bazz_text_input.dart';
import 'package:bazz_flutter/shared_widgets/primary_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

import '../app_theme.dart';

// typedef SystemDialogCallback = Future<void> Function();

class SystemDialog {
  static Future<void> showConfirmDialog({
    String title = 'Error',
    String? message,
    String? confirmButtonText,
    VoidCallback? confirmCallback,
    ViewState loadingState = ViewState.idle,
    Color? titleFillColor,
    VoidCallback? cancelCallback,
    String cancelButtonText = "cancel",
    Widget? child,
    bool dismissible = true,
    double? height,
  }) async {
    if (Get.isBottomSheetOpen!) Get.back();

    return Get.generalDialog(
      barrierDismissible: dismissible,
      barrierLabel: 'BarrierLabel',
      pageBuilder: (_, __, ___) {
        return Center(
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(7)),
            child: SizedBox(
              width: Get.width * 0.8,
              height: height ?? Get.height * 0.33,
              // color: AppTheme().colors.mainBackground,
              child: Scaffold(
                backgroundColor: AppTheme().colors.mainBackground,
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 5),
                      color: titleFillColor ?? AppColors.danger,
                      child: TextOneLine(
                        title,
                        textAlign: TextAlign.center,
                        style: AppTheme().typography.dialogTitleStyle,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        child: Column(
                          children: [
                            Expanded(
                              child: child ??
                                  Align(
                                    child: Text(
                                      message ?? 'Message placeholder',
                                      textAlign: TextAlign.center,
                                      maxLines: 4,
                                      style: AppTheme().typography.bgText3Style,
                                    ),
                                  ),
                            ),
                            FittedBox(
                              child: loadingState == ViewState.loading
                                  ? SizedBox(
                                      height: 50,
                                      child: SpinKitCubeGrid(
                                        color: AppColors.loadingIndicator,
                                        size: 25,
                                      ))
                                  : Row(children: [
                                      PrimaryButton(
                                        height: 40,
                                        text: confirmButtonText ??
                                            LocalizationService().of().ok,
                                        toUpperCase: false,
                                        icon: const Icon(
                                          LineAwesomeIcons.check,
                                          color: AppColors.brightText,
                                          size: 20,
                                        ),
                                        onTap: confirmCallback ?? Get.back,
                                      ),
                                      if (cancelCallback != null)
                                        const SizedBox(
                                          width: 10,
                                        ),
                                      if (cancelCallback != null)
                                        PrimaryButton(
                                          height: 40,
                                          text: cancelButtonText,
                                          toUpperCase: false,
                                          color: AppColors.danger,
                                          icon: const Icon(
                                            LineAwesomeIcons.times_circle,
                                            color: AppColors.brightText,
                                            size: 20,
                                          ),
                                          onTap: cancelCallback,
                                        )
                                    ]),
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  static Future<void> showInputDialog({
    String title = 'Error',
    required String message,
    String? confirmButtonText,
    VoidCallback? confirmCallback,
    VoidCallback? togglePasswordVisibility,
    ViewState loadingState = ViewState.idle,
    Color? titleFillColor,
    VoidCallback? cancelCallback,
    String cancelButtonText = "cancel",
    String? placeholder,
    double? height,
    TextEditingController? textController,
    RxBool? isPasswordVisible,
  }) async {
    if (Get.isBottomSheetOpen!) Get.back();
    final usernameFocusNode = FocusNode();
    await Get.generalDialog(
      barrierDismissible: true,
      barrierLabel: 'BarrierLabel',
      pageBuilder: (_, __, ___) {
        return Center(
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(7)),
            child: Container(
              width: Get.width * 0.8,
              height: height ?? Get.height * 0.8,
              color: Colors.transparent,
              child: Scaffold(
                backgroundColor: Colors.transparent,
                body: Column(children: [
                  Container(
                    height: height ?? 200,
                    color: AppTheme().colors.mainBackground,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 5, vertical: 5),
                          color: titleFillColor ?? AppColors.sos,
                          child: TextOneLine(
                            title,
                            textAlign: TextAlign.center,
                            style: AppTheme().typography.dialogTitleStyle,
                          ),
                        ),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            child: Column(
                              children: [
                                Align(
                                  child: Text(
                                    message,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    style: AppTheme().typography.bgText3Style,
                                  ),
                                ),
                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                  child: Obx(() {
                                    return BazzTextInput(
                                        shadow: true,
                                        controller: textController,
                                        togglePasswordVisibility:
                                            togglePasswordVisibility,
                                        isPasswordVisible: isPasswordVisible!(),
                                        focusNode: usernameFocusNode,
                                        placeholder: placeholder,
                                        height: 50,
                                        inputType:
                                            TextInputType.visiblePassword,
                                        prefixIcon: const Icon(
                                            Icons.text_fields_rounded));
                                  }),
                                ),
                                FittedBox(
                                  child: loadingState == ViewState.loading
                                      ? SizedBox(
                                          height: 50,
                                          child: SpinKitCubeGrid(
                                            color: AppColors.loadingIndicator,
                                            size: 25,
                                          ))
                                      : Row(
                                          children: [
                                            PrimaryButton(
                                              height: 40,
                                              text: confirmButtonText ??
                                                  LocalizationService().of().ok,
                                              toUpperCase: false,
                                              icon: const Icon(
                                                LineAwesomeIcons.check,
                                                color: AppColors.brightText,
                                                size: 20,
                                              ),
                                              onTap:
                                                  confirmCallback ?? Get.back,
                                            ),
                                            if (cancelCallback != null)
                                              const SizedBox(
                                                width: 10,
                                              ),
                                            if (cancelCallback != null)
                                              PrimaryButton(
                                                height: 40,
                                                text: cancelButtonText,
                                                toUpperCase: false,
                                                color: AppColors.error,
                                                icon: const Icon(
                                                  LineAwesomeIcons.times_circle,
                                                  color: AppColors.brightText,
                                                  size: 20,
                                                ),
                                                onTap: cancelCallback,
                                              )
                                          ],
                                        ),
                                )
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                ]),
              ),
            ),
          ),
        );
      },
    );
  }
}
