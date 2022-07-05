import 'dart:io';

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/modules/auth_module/auth_controller.dart';
import 'package:bazz_flutter/shared_widgets/bazz_text_input.dart';
import 'package:bazz_flutter/shared_widgets/loader.dart';
import 'package:bazz_flutter/shared_widgets/primary_button.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_multi_formatter/utils/unfocuser.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

import 'domain_controller.dart';

class DomainPage extends GetView<DomainController> {
  const DomainPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final domainFocusNode = FocusNode();
    final simSerialFocusNode = controller.showSimInput ? FocusNode() : null;
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
                  final bottomNavBarHeight = Platform.isAndroid ? 0 : 0;
                  return SingleChildScrollView(
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
                            const Spacer(),
                            const Align(
                              child: Image(
                                image: AssetImage(
                                    'assets/images/tello_text_logo_white.png'),
                                height: 60,
                              ),
                            ),
                            const SizedBox(height: 50),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 20, vertical: 10),
                              decoration: BoxDecoration(
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 20,
                                  )
                                ],
                                color: AppTheme().colors.mainBackground,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    "                                    AppLocalizations.of(context).defineSystemDomain",
                                    style:
                                        AppTheme().typography.authCaptionStyle,
                                  ),
                                  const SizedBox(height: 15),
                                  BazzTextInput(
                                    controller: controller.domainController,
                                    focusNode: domainFocusNode,
                                    maxLength: 256,
                                    placeholder:
                                        "AppLocalizations.of(context).domainName",
                                    height: 50,
                                    prefixIcon:
                                        const Icon(FontAwesomeIcons.server),
                                    textInputAction: controller.showSimInput
                                        ? TextInputAction.next
                                        : TextInputAction.done,
                                    onEditingComplete: controller.showSimInput
                                        ? simSerialFocusNode?.requestFocus
                                        : null,
                                    onSubmitted: controller.showSimInput
                                        ? null
                                        : (_) => domainFocusNode.unfocus(),
                                  ),
                                  if (controller.showSimInput)
                                    const SizedBox(height: 15),
                                  if (controller.showSimInput)
                                    Obx(() {
                                      return BazzTextInput(
                                        controller:
                                            controller.simSerialController,
                                        focusNode: simSerialFocusNode,
                                        placeholder:
                                            "AppLocalizations.of(context).enterSimCardNumber",
                                        height: 50,
                                        togglePasswordVisibility:
                                            controller.togglePasswordVisibility,
                                        isPasswordVisible:
                                            controller.isPasswordVisible,
                                        prefixIcon: const Icon(
                                            FontAwesomeIcons.simCard),
                                        inputType:
                                            TextInputType.visiblePassword,
                                        onSubmitted: (_) =>
                                            simSerialFocusNode!.unfocus(),
                                      );
                                    }),
                                  const SizedBox(height: 15),
                                  Obx(() => controller.loadingState ==
                                          ViewState.error
                                      ? Column(
                                          children: [
                                            Row(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                const Icon(
                                                    Icons.warning_amber_rounded,
                                                    size: 18,
                                                    color: AppColors.danger),
                                                const SizedBox(width: 5),
                                                Expanded(
                                                  child: Text(
                                                    controller.errorMessage,
                                                    style: AppTheme()
                                                        .typography
                                                        .errorTextStyle,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 15),
                                          ],
                                        )
                                      : const SizedBox()),
                                  Obx(() => FractionallySizedBox(
                                        widthFactor: 0.7,
                                        child: PrimaryButton(
                                          text:
                                              "AppLocalizations.of(context).proceed",
                                          onTap: controller.canUserProceed
                                              ? controller.onProceedToLogin
                                              : null!,
                                          icon: null as Icon,
                                        ),
                                      )),
                                  const SizedBox(height: 10),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Image(
                                        image: AssetImage(
                                            'assets/images/tello_text_logo.png'),
                                        height: 30,
                                      ),
                                      Text(
                                        'V${AppSettings().appVersion}',
                                        style: AppTheme()
                                            .typography
                                            .appVersionStyle,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            GetX<DomainController>(
                              builder: (_) {
                                if (controller.loadingState ==
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
