import 'dart:io';

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/modules/auth_module/change_password/change_password_controller.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/shared_widgets/bazz_text_input.dart';
import 'package:bazz_flutter/shared_widgets/loader.dart';
import 'package:bazz_flutter/shared_widgets/primary_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_multi_formatter/utils/unfocuser.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class ChangePasswordPage extends GetView<ChangePasswordController> {
  const ChangePasswordPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final password1FocusNode = FocusNode();
    final password2FocusNode = FocusNode();
    return Unfocuser(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: AppTheme().colors.mainBackground,
            alignment: Alignment.topCenter,
            child: FractionallySizedBox(
              heightFactor: 0.6,
              child: ClipPath(
                clipper: ArcClipper(),
                child: const Image(
                  fit: BoxFit.cover,
                  image: AssetImage('assets/images/login_guard.jpg'),
                  color: Colors.black38,
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
          ),
          Scaffold(
            backgroundColor: Colors.transparent,
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final bottomNavBarHeight = Platform.isAndroid ? 50 : 0;
                  return SingleChildScrollView(
                    padding:
                        const EdgeInsets.all(LayoutConstants.compactPadding),
                    child: ConstrainedBox(
                      // TODO: implement a plugin for getting Android bottom nav bar height, here is the example:
                      //  https://github.com/magnatronus/flutter-displaymetrics/blob/master/android/app/src/main/java/com/example/devicedetect/MainActivity.java
                      constraints: BoxConstraints(
                          minHeight:
                              constraints.maxHeight - bottomNavBarHeight),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: IconButton(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 15),
                                icon: const Icon(Icons.arrow_back,
                                    color: AppColors.brightText),
                                onPressed: () {
                                  Get.back();
                                },
                              ),
                            ),
                            const Spacer(),
                            const Align(
                              child: Image(
                                image: AssetImage('assets/images/logo.png'),
                                height: 65,
                              ),
                            ),
                            const SizedBox(height: 50),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: const BoxDecoration(
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 20,
                                  )
                                ],
                                borderRadius:
                                    BorderRadius.all(Radius.circular(5)),
                                color: AppColors.brightBackground,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    LocalizationService()
                                        .of()
                                        .changeYourPassword
                                        .capitalize,
                                    style: AppTypography.subtitle2TextStyle
                                        .copyWith(
                                      fontWeight: FontWeight.w500,
                                      color: AppColors.secondaryText,
                                    ),
                                  ),
                                  const SizedBox(height: 15),
                                  BazzTextInput(
                                    controller: controller.newPwdController,
                                    focusNode: password1FocusNode,
                                    placeholder: LocalizationService()
                                        .of()
                                        .newPassword
                                        .capitalize,
                                    textStyle: AppTypography.bodyText2TextStyle
                                        .copyWith(color: AppColors.darkText),
                                    height: 50,
                                    prefixIcon:
                                        const Icon(FontAwesomeIcons.keyboard),
                                    inputType: TextInputType.visiblePassword,
                                    textInputAction: TextInputAction.next,
                                    onEditingComplete:
                                        password2FocusNode.requestFocus,
                                  ),
                                  const SizedBox(height: 15),
                                  BazzTextInput(
                                    controller:
                                        controller.confirmNewPwdController,
                                    focusNode: password2FocusNode,
                                    placeholder: LocalizationService()
                                        .of()
                                        .confirmNewPassword
                                        .capitalize,
                                    textStyle: AppTypography.bodyText2TextStyle
                                        .copyWith(color: AppColors.darkText),
                                    height: 50,
                                    prefixIcon:
                                        const Icon(FontAwesomeIcons.keyboard),
                                    inputType: TextInputType.visiblePassword,
                                    onSubmitted: (_) =>
                                        password2FocusNode.unfocus(),
                                  ),
                                  const SizedBox(height: 15),
                                  Obx(() => PrimaryButton(
                                        text:
                                            LocalizationService().of().proceed,
                                        onTap: controller.canProceed()
                                            ? controller.onProceedPressed
                                            : null!,
                                        icon: null as Icon,
                                      )),
                                  // const SizedBox(height: 30),
                                ],
                              ),
                            ),
                            GetX<ChangePasswordController>(
                              builder: (_) {
                                //TODO: fix rebuilding and hiding Loader every time keyboard hides or shows
                                if (controller.loadingState() ==
                                    ViewState.loading) {
                                  Loader.show(context,
                                      themeData: null as ThemeData);
                                } else {
                                  Loader.hide();
                                }
                                return const SizedBox();
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ArcClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(0, size.height - 10);
    path.quadraticBezierTo(
        size.width / 2, size.height + 50, size.width, size.height - 10);
    path.lineTo(size.width, 0);
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) {
    return false;
  }
}
