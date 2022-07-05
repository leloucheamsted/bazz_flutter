import 'dart:io';

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/modules/auth_module/auth_controller.dart';
import 'package:bazz_flutter/modules/settings_module/settings_controller.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/shared_widgets/bazz_text_input.dart';
import 'package:bazz_flutter/shared_widgets/loader.dart';
import 'package:bazz_flutter/shared_widgets/primary_button.dart';
import 'package:bazz_flutter/shared_widgets/slide_to_act.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_multi_formatter/utils/unfocuser.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class LoginPage extends GetView<AuthController> {
  const LoginPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Unfocuser(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            color: AppTheme().colors.mainBackground,
            alignment: Alignment.topCenter,
            child: FractionallySizedBox(
              heightFactor: 0.7,
              child: ClipPath(
                clipper: ArcClipper(),
                child: Image(
                  fit: BoxFit.cover,
                  image:
                      CachedNetworkImageProvider(AppSettings().loginPageImage),
                  color: Colors.black38,
                  colorBlendMode: BlendMode.darken,
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 10,
            child: Image(
              image: CachedNetworkImageProvider(AppSettings().siteLogo),
              height: 65,
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
                            const SizedBox(height: 30),
                            Obx(() {
                              final usernameFocusNode = FocusNode();
                              final passwordFocusNode = FocusNode();
                              return Container(
                                padding:
                                    const EdgeInsets.fromLTRB(15, 10, 15, 10),
                                decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                      color: controller.canUserLogIn
                                          ? AppColors.primaryAccent
                                          : AppColors.dark1,
                                      blurRadius: 20,
                                    )
                                  ],
                                  color: AppTheme().colors.mainBackground,
                                ),
                                child: controller.isOnline.isFalse
                                    ? _buildOfflineBody(context)
                                    : _buildOnlineBody(context,
                                        usernameFocusNode, passwordFocusNode),
                              );
                            }),
                            GetX(
                              builder: (_) {
                                if (controller.currentState == ViewState.lock) {
                                  return const SizedBox();
                                }
                                controller.currentState =
                                    controller.loadingState;
                                //TODO: fix rebuilding and hiding Loader every time keyboard hides or shows
                                if (controller.loadingState ==
                                    ViewState.loading) {
                                  Loader.show(context,
                                      themeData: null as ThemeData);
                                } else if (controller.loadingState ==
                                    ViewState.lock) {
                                  Loader.hide();
                                  Loader.show(context,
                                      text:
                                          "AppLocalizations.of(context).deviceIsLocked",
                                      progressIndicator:
                                          createLockWidget(context),
                                      showLogo: true,
                                      screenKeeper: true,
                                      opacity: 1.0,
                                      themeData: null as ThemeData);
                                } else {
                                  Loader.hide();
                                }
                                return const SizedBox();
                              },
                              //dispose: (_) => Loader.hide(),
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

  Widget _buildOnlineBody(BuildContext context, FocusNode usernameFocusNode,
      FocusNode passwordFocusNode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          !controller.enableNfcLogin
              ? "AppLocalizations.of(context).loginWithUserName"
              : "AppLocalizations.of(context).loginWithUserNameOrBadge",
          style: AppTheme().typography.authCaptionStyle,
        ),
        if (controller.enableNfcLogin)
          Text(
            "AppLocalizations.of(context).attachYourBadgeTitle",
            style: AppTheme().typography.authCaptionStyle,
          ),
        if (!controller.loginWithNFCCode) const SizedBox(height: 15),
        if (!controller.loginWithNFCCode)
          BazzTextInput(
            controller: controller.usernameController,
            focusNode: usernameFocusNode,
            placeholder: "AppLocalizations.of(context).userName",
            height: 50,
            prefixIcon: const Icon(FontAwesomeIcons.user),
            onEditingComplete: passwordFocusNode.requestFocus,
            textInputAction: TextInputAction.next,
          ),
        if (!controller.loginWithNFCCode) const SizedBox(height: 15),
        if (!controller.loginWithNFCCode)
          BazzTextInput(
            controller: controller.passwordController,
            focusNode: passwordFocusNode,
            togglePasswordVisibility: controller.togglePasswordVisibility,
            isPasswordVisible: controller.isPasswordVisible,
            placeholder: " AppLocalizations.of(context).enterPassword",
            height: 50,
            prefixIcon: const Icon(FontAwesomeIcons.keyboard),
            inputType: TextInputType.visiblePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => passwordFocusNode.unfocus(),
          ),
        if (controller.loginWithNFCCode) const SizedBox(height: 15),
        if (controller.loginWithNFCCode)
          const Icon(
            FontAwesomeIcons.idCardAlt,
            color: AppColors.brightIcon,
            size: 100,
          ),
        if (controller.loginWithNFCCode) const SizedBox(height: 15),
        if (controller.loadingState == ViewState.error)
          Column(
            children: [
              const SizedBox(height: 15),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      size: 18, color: AppColors.danger),
                  const SizedBox(width: 5),
                  Expanded(
                    child: Text(
                      controller.errorMessage,
                      style: AppTheme().typography.errorTextStyle,
                    ),
                  ),
                ],
              ),
            ],
          )
        else
          const SizedBox(),
        const SizedBox(height: 15),
        if (!controller.loginWithNFCCode)
          FractionallySizedBox(
            widthFactor: 0.7,
            child: PrimaryButton(
              text: "AppLocalizations.of(context).login",
              onTap:
                  controller.canUserLogIn ? controller.onLogInPressed : null!,
              icon: null as Icon,
            ),
          )
        else
          FractionallySizedBox(
            widthFactor: 0.7,
            child: PrimaryButton(
              text: " AppLocalizations.of(context).loginWithCardCode",
              onTap:
                  controller.canUserLogIn ? controller.onLogInPressed : null!,
              icon: null as Icon,
            ),
          ),
        if (AppSettings().isNotCustomer && AppSettings().faceDetectionForLogin)
          Stack(
            alignment: Alignment.center,
            children: [
              Divider(
                height: 20,
                color: AppTheme().colors.divider,
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5),
                color: AppTheme().colors.mainBackground,
                child: Text('OR',
                    style: AppTypography.text4BaseStyle.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.coolGray,
                    )),
              ),
            ],
          ),
        if (AppSettings().isNotCustomer && AppSettings().faceDetectionForLogin)
          FractionallySizedBox(
            widthFactor: 0.7,
            child: PrimaryButton(
              text: "AppLocalizations.of(context).loginByYourFaceScan",
              onTap: controller.canUserFaceScan
                  ? controller.onFaceScanPressed
                  : null!,
              color: AppColors.secondaryAccent,
              icon: const Image(
                image: AssetImage('assets/images/scan_ico.png'),
                height: 17,
                width: 17,
              ),
            ),
          ),
        const SizedBox(height: 5),
        _buildBottomDetailsRow(),
      ],
    );
  }

  Widget _buildOfflineBody(BuildContext context) {
    return Column(
      children: [
        Text(
          "AppLocalizations.of(context).noInternet.capitalize",
          style: AppTheme().typography.bgTitle1Style,
        ),
        const SizedBox(height: 5),
        Text(
          '{AppLocalizations.of(context).waitingForNetwork}...',
          style: AppTheme().typography.bgText3Style,
        ),
        const SizedBox(height: 15),
        SvgPicture.asset(
          'assets/images/no_network.svg',
          color: AppColors.greyIcon,
          width: 80,
        ),
        const SizedBox(height: 5),
        _buildBottomDetailsRow(),
      ],
    );
  }

  Widget _buildBottomDetailsRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Image(
          image: AssetImage('assets/images/tello_text_logo.png'),
          height: 30,
        ),
        Obx(() {
          final version = AppSettings().appVersion;
          return Text(
            'V$version',
            style: AppTheme().typography.appVersionStyle,
          );
        }),
        Stack(
          children: [
            Padding(
                padding: const EdgeInsets.fromLTRB(0, 3, 5, 0),
                child: GestureDetector(
                    onTap: () {
                      SettingsController.to!.askForTechnicianCode(
                          () => Get.toNamed(AppRoutes.settings)!);
                    },
                    child: Icon(
                      LineAwesomeIcons.cog,
                      color: AppTheme().colors.icon,
                      size: 35,
                    ))),
            Obx(() {
              if (AppSettings().updatesCounter > 0) {
                return Positioned(
                  top: 2,
                  right: 2,
                  child: Container(
                    alignment: Alignment.center,
                    height: 13,
                    width: 13,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      '${AppSettings().updatesCounter}',
                      style: AppTypography.badgeCounterTextStyle,
                    ),
                  ),
                );
              } else {
                return Container();
              }
            }),
          ],
        )
      ],
    );
  }

  Widget createLockWidget(BuildContext context) {
    final GlobalKey<SlideActionState> _key = GlobalKey();
    TelloLogger().i("createLockWidget ====> ");
    return Padding(
      padding: EdgeInsets.fromLTRB(10, Get.height - 170, 10, 20),
      child: SlideAction(
        key: _key,
        onSubmit: () {
          Future.delayed(const Duration(seconds: 1), () {
            _key.currentState!.reset();
            controller.loadingState = ViewState.idle;
            controller.currentState = ViewState.idle;
          });
        },
        sliderButtonIcon:
            const Icon(FontAwesomeIcons.lock, color: AppColors.brightIcon),
        submittedIcon:
            const Icon(FontAwesomeIcons.unlock, color: AppColors.dark3),
        innerColor: AppColors.dark3,
        outerColor: AppColors.paleGray,
        textSize: 18,
        text: "AppLocalizations.of(context).slideToUnlock",
        child: null as Widget,
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
