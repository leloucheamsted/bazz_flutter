import 'dart:io';

import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/services_address.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/widgets/bottom_nav_bar.dart';
import 'package:bazz_flutter/modules/home_module/widgets/custom_app_bar.dart';
import 'package:bazz_flutter/modules/home_module/widgets/notifications_drawer.dart';
import 'package:bazz_flutter/modules/settings_module/settings_controller.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/shared_widgets/android_data_usage.dart';
import 'package:bazz_flutter/shared_widgets/bazz_text_input.dart';
import 'package:bazz_flutter/shared_widgets/tello_divider.dart';
import 'package:bazz_flutter/shared_widgets/material_bazz_text_input.dart';
import 'package:bazz_flutter/shared_widgets/primary_button.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_multi_formatter/utils/unfocuser.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';
import 'package:percent_indicator/linear_percent_indicator.dart';

class SettingsPage extends GetView<SettingsController> {
  const SettingsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isStandalone = !Get.isRegistered<HomeController>();
    if (isStandalone) {
      return Scaffold(
        backgroundColor: AppTheme().colors.mainBackground,
        appBar: AppBar(
          backgroundColor: AppTheme().colors.appBar,
          title: Text(
            "AppLocalizations.of(context).settings",
            style: AppTypography.subtitle1TextStyle,
          ),
        ),
        body: Column(
          children: [
            Container(
              color: AppTheme().colors.tabBarBackground,
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  const TelloDivider(height: 2),
                  TabBar(
                    indicatorColor: AppColors.primaryAccent,
                    controller: controller.tabController2,
                    indicator: BoxDecoration(
                      color: AppTheme().colors.selectedTab,
                      border: const Border(
                          bottom: BorderSide(
                              width: 2, color: AppColors.primaryAccent)),
                    ),
                    tabs: [
                      Tab(
                        child: Stack(children: [
                          Padding(
                              padding: const EdgeInsets.only(
                                  right: 5, top: 10, left: 5, bottom: 2),
                              child: Text(
                                "AppLocalizations.of(context).updates",
                                style: AppTheme().typography.tabTitle2Style,
                              )),
                          Obx(() {
                            if (AppSettings().updatesCounter > 0) {
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  alignment: Alignment.center,
                                  height: 13,
                                  width: 13,
                                  decoration: const BoxDecoration(
                                    color: AppColors.sos,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    '${AppSettings().updatesCounter}',
                                    style: AppTypography.badgeCounterTextStyle,
                                  ),
                                ),
                              );
                            }
                            return Container();
                          }),
                        ]),
                      ),
                      Tab(
                        child: Text(
                          "AppLocalizations.of(context).general",
                          style: AppTheme().typography.tabTitle2Style,
                        ),
                      ),
                      // const ListSeparator(),
                    ],
                  ),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                physics: const NeverScrollableScrollPhysics(),
                controller: controller.tabController2,
                children: [
                  _buildUpdatesDetails(context),
                  _buildGeneralDetails(context)
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Unfocuser(
        child: Scaffold(
          backgroundColor: AppTheme().colors.mainBackground,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    CustomAppBar(withBackButton: true),
                    Container(
                      color: AppTheme().colors.tabBarBackground,
                      child: Stack(
                        alignment: Alignment.bottomCenter,
                        children: [
                          const TelloDivider(height: 2),
                          TabBar(
                            controller: controller.tabController,
                            isScrollable: true,
                            indicator: BoxDecoration(
                              color: AppTheme().colors.selectedTab,
                              border: const Border(
                                  bottom: BorderSide(
                                      width: 2,
                                      color: AppColors.primaryAccent)),
                            ),
                            onTap: (index) async {
                              if (index == 5) {
                                await controller.initDataUsage();
                              }
                            },
                            tabs: [
                              Tab(
                                child: Text(
                                  "AppLocalizations.of(context).info",
                                  style: AppTheme().typography.tabTitle2Style,
                                ),
                              ),
                              Tab(
                                child: Text(
                                  "AppLocalizations.of(context).device",
                                  style: AppTheme().typography.tabTitle2Style,
                                ),
                              ),
                              Tab(
                                child: Text(
                                  " AppLocalizations.of(context).settings",
                                  style: AppTheme().typography.tabTitle2Style,
                                ),
                              ),
                              Tab(
                                child: Stack(children: [
                                  Padding(
                                      padding: const EdgeInsets.only(
                                          right: 5,
                                          top: 10,
                                          left: 5,
                                          bottom: 2),
                                      child: Text(
                                        " AppLocalizations.of(context).updates",
                                        style: AppTheme()
                                            .typography
                                            .tabTitle2Style,
                                      )),
                                  Obx(() {
                                    if (AppSettings().updatesCounter > 0) {
                                      return Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          alignment: Alignment.center,
                                          height: 13,
                                          width: 13,
                                          decoration: const BoxDecoration(
                                            color: AppColors.sos,
                                            shape: BoxShape.circle,
                                          ),
                                          child: Text(
                                            '${AppSettings().updatesCounter}',
                                            style: AppTypography
                                                .badgeCounterTextStyle,
                                          ),
                                        ),
                                      );
                                    } else {
                                      return Container();
                                    }
                                  }),
                                ]),
                              ),
                              Tab(
                                child: Text(
                                  "AppLocalizations.of(context).general",
                                  style: AppTheme().typography.tabTitle2Style,
                                ),
                              ),
                              Tab(
                                child: Text(
                                  "AppLocalizations.of(context).dataUsage",
                                  style: AppTheme().typography.tabTitle2Style,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        physics: const NeverScrollableScrollPhysics(),
                        controller: controller.tabController,
                        children: [
                          _buildInfoDetails(context),
                          _buildDeviceDetails(context),
                          _buildSettingsDetails(context),
                          _buildUpdatesDetails(context),
                          _buildGeneralDetails(context),
                          _buildDataUsageDetails(context)
                        ],
                      ),
                    ),
                  ],
                ),
                NotificationsDrawer(controller: HomeController.to),
              ],
            ),
          ),
          bottomNavigationBar: BottomNavBar(key: UniqueKey()),
        ),
      );
    }
  }

  Widget _buildDeviceDetails(BuildContext context) {
    final infoBoxes = [
      _buildInfoBox(
        "AppLocalizations.of(context).deviceDensity",
        Get.pixelRatio.toString(),
      ),
      _buildInfoBox(
        " AppLocalizations.of(context).phoneNumber",
        controller.telephonyInfo.line1Number.toString(),
      ),
      _buildInfoBox(
        "AppLocalizations.of(context).deviceIME",
        controller.telephonyInfo.imei.toString(),
      ),
      _buildInfoBox(
        "AppLocalizations.of(context).simCard",
        controller.telephonyInfo.simSerialNumber.toString(),
      ),
      _buildInfoBox(
        " AppLocalizations.of(context).operatorName",
        controller.telephonyInfo.simOperatorName.toString(),
      ),
      _buildInfoBox(
        "AppLocalizations.of(context).batteryTechnology",
        controller.batteryInfo.batteryTechnology.toString(),
      ),
      _buildInfoBox(
        "AppLocalizations.of(context).batteryVoltage",
        controller.batteryInfo.batteryVoltage.toString(),
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            physics: const ClampingScrollPhysics(),
            itemBuilder: (_, i) => Column(
              children: [
                infoBoxes[i],
                if (i + 1 == infoBoxes.length) const TelloDivider(),
              ],
            ),
            separatorBuilder: (_, __) => const TelloDivider(),
            itemCount: infoBoxes.length,
          ),
        )
      ],
    );
  }

  Widget _buildSettingsDetails(BuildContext context) {
    return SingleChildScrollView(
      physics: const ClampingScrollPhysics(),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 15),
            child: Column(
              children: [
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: TextOneLine(
                          "AppLocalizations.of(context).enableLogging",
                          style: AppTheme().typography.reportEntryNameStyle,
                        ),
                      ),
                      Theme(
                        data: ThemeData(
                          unselectedWidgetColor:
                              AppTheme().colors.checkboxBorder, // Your color
                        ),
                        child: Checkbox(
                          checkColor: Colors.white,
                          activeColor: AppColors.secondaryButton,
                          value: controller.loggerEnabled,
                          onChanged: null,
                          // onChanged: controller.setLoggerEnabled,
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: TextOneLine(
                          "AppLocalizations.of(context).showNetworkJitter.capitalize",
                          style: AppTheme().typography.reportEntryNameStyle,
                        ),
                      ),
                      Theme(
                        data: ThemeData(
                          unselectedWidgetColor:
                              AppTheme().colors.checkboxBorder, // Your color
                        ),
                        child: Checkbox(
                          value: controller.showNetworkJitter,
                          checkColor: Colors.white,
                          activeColor: AppColors.secondaryButton,
                          onChanged: null,
                          //onChanged: controller.setShowNetworkJitter,
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: TextOneLine(
                          " AppLocalizations.of(context).showTransportStats.capitalize",
                          style: AppTheme().typography.reportEntryNameStyle,
                        ),
                      ),
                      Theme(
                        data: ThemeData(
                          unselectedWidgetColor:
                              AppTheme().colors.checkboxBorder, // Your color
                        ),
                        child: Checkbox(
                          value: controller.showTransportStats,
                          checkColor: Colors.white,
                          activeColor: AppColors.secondaryButton,
                          onChanged: null,
                          // onChanged: controller.setTransportStats,
                        ),
                      ),
                    ],
                  ),
                ),
                Obx(
                  () => Row(
                    children: [
                      Expanded(
                        child: TextOneLine(
                          "AppLocalizations.of(context).darkTheme.capitalize",
                          style: AppTheme().typography.reportEntryNameStyle,
                        ),
                      ),
                      Theme(
                        data: ThemeData(
                          unselectedWidgetColor:
                              AppTheme().colors.checkboxBorder, // Your color
                        ),
                        child: Checkbox(
                          value: controller.isDarkTheme,
                          checkColor: Colors.white,
                          activeColor: AppColors.secondaryButton,
                          onChanged: null,
                          // onChanged: controller.!setIsDarkTheme,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const TelloDivider(),
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Text(
                  LocalizationService().of().changeLanguage,
                  style: AppTheme().typography.reportEntryNameStyle,
                ),
              ),
              DropdownButton<Locale>(
                dropdownColor: AppTheme().colors.popupBg,
                iconDisabledColor: AppColors.greyIcon,
                iconEnabledColor: AppColors.greyIcon,
                underline: Divider(color: AppTheme().colors.divider, height: 1),
                items: LocalizationService().supportedLocales().map((locale) {
                  return DropdownMenuItem<Locale>(
                    value: locale,
                    child: Text(
                      locale.languageCode,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                      style: AppTheme().typography.reportEntryValueStyle,
                    ),
                  );
                }).toList(),
                value: LocalizationService().supportedLocales().firstWhere(
                    (element) =>
                        element.languageCode == Get.locale!.languageCode,
                    orElse: () => null!),
                onChanged: (item) {
                  controller.changeLanguage(item!);
                },
              )
            ],
          ),
          const TelloDivider(),
          BazzMaterialTextInput(
            inputType: TextInputType.number,
            controller: controller.pttKeyCodeController,
            placeholder: "AppLocalizations.of(context).pttKeyCode",
            height: 45,
            prefixIcon: const Icon(FontAwesomeIcons.phone),
          ),
          const TelloDivider(),
          BazzMaterialTextInput(
            inputType: TextInputType.number,
            controller: controller.sosKeyCodeController,
            placeholder: " AppLocalizations.of(context).sosKeyCode",
            height: 45,
            prefixIcon: const Icon(FontAwesomeIcons.bell),
          ),
          const TelloDivider(),
          BazzMaterialTextInput(
            inputType: TextInputType.number,
            controller: controller.switchUpKeyCodeController,
            placeholder: "AppLocalizations.of(context).channelSwitchUp",
            height: 45,
            prefixIcon: const Icon(FontAwesomeIcons.arrowUp),
          ),
          const TelloDivider(),
          BazzMaterialTextInput(
            inputType: TextInputType.number,
            controller: controller.switchDownKeyCodeController,
            placeholder: "AppLocalizations.of(context).channelSwitchDown,",
            height: 45,
            prefixIcon: const Icon(FontAwesomeIcons.arrowDown),
          ),
          const TelloDivider(),
          const SizedBox(height: 10),
          PrimaryButton(
            text: "AppLocalizations.of(context).defaultReset",
            onTap: controller.resetSettingsToDefault,
            icon: const Icon(LineAwesomeIcons.alternate_undo,
                color: AppColors.brightText),
          ),
        ],
      ),
    );
  }

  Widget _buildUpdatesDetails(BuildContext context) {
    final infoBoxes = [
      _buildInfoBox(
        "AppLocalizations.of(context).currentVersion",
        AppSettings().appVersion,
      ),
      _buildInfoBox(
        "AppLocalizations.of(context).availableVersion",
        "${AppSettings().clientVersion}-${AppSettings().clientBuildNumber}",
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListView.separated(
          padding: EdgeInsets.zero,
          shrinkWrap: true,
          physics: const ClampingScrollPhysics(),
          itemBuilder: (_, i) => Column(
            children: [
              infoBoxes[i],
              if (i + 1 == infoBoxes.length) const TelloDivider(),
            ],
          ),
          separatorBuilder: (_, __) => const TelloDivider(),
          itemCount: infoBoxes.length,
        ),
        Obx(() {
          if (AppSettings().updatesCounter > 0) {
            return Padding(
              padding: const EdgeInsets.only(top: 10),
              child: FractionallySizedBox(
                widthFactor: 0.7,
                child: PrimaryButton(
                  text: "AppLocalizations.of(context).downloadNewVersion",
                  onTap: () {
                    controller.downloadNewVersion();
                  },
                  color: AppColors.secondaryButton, icon: null as Icon,
                  // ignore: prefer_if_elements_to_conditional_expressions
                ),
              ),
            );
          } else {
            return Container();
          }
        }),
        Obx(() {
          return (controller.isDownloading)
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: LinearPercentIndicator(
                    lineHeight: 25.0,
                    percent:
                        (controller.downloadProgress.toDouble() / 100.0) > 1.0
                            ? 1.0
                            : (controller.downloadProgress.toDouble() / 100.0),
                    center: controller.downloadProgress != null
                        ? Text("${controller.downloadProgress}%")
                        : const Text(""),
                    linearStrokeCap: LinearStrokeCap.butt,
                    progressColor: AppTheme().colors.progressBar,
                  ),
                )
              : const SizedBox();
        }),
        Obx(() {
          return (controller.isComplete)
              ? Padding(
                  padding: const EdgeInsets.fromLTRB(10, 10, 10, 0),
                  child: Text(
                    "AppLocalizations.of(context).newBazzAPKIsAvail",
                    style: AppTheme().typography.bgText3Style,
                  ))
              : const SizedBox();
        }),
        Obx(() {
          return (controller.isComplete)
              ? Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: FractionallySizedBox(
                    widthFactor: 0.7,
                    child: PrimaryButton(
                      text: "AppLocalizations.of(context).openAPKFolder",
                      onTap: controller.installVersion,
                      color: AppColors.danger, icon: null as Icon,
                      // ignore: prefer_if_elements_to_conditional_expressions
                    ),
                  ),
                )
              : const SizedBox();
        }),
      ],
    );
  }

  Widget _buildDataUsageDetails(BuildContext context) {
    return GetBuilder<HomeController>(
        id: 'dataUsageSettings',
        builder: (_) {
          return Center(
              child: Platform.isAndroid
                  ? Android(dataUsage: controller.dataUsage, size: Get.size)
                  : Container());
        });
    /*  return Obx(() {
      return Center(
          child: Platform.isAndroid
              ? Android(dataUsage: controller.dataUsage, size: size)
              : Container());
    });*/
  }

  Widget _buildGeneralDetails(BuildContext context) {
    final infoBoxes = [
      Obx(() => FractionallySizedBox(
            widthFactor: 0.7,
            child: PrimaryButton(
              text: controller.appPinned
                  ? "AppLocalizations.of(context).unpinDevice"
                  : "AppLocalizations.of(context).pinDevice",
              onTap: () {
                if (controller.appPinned) {
                  controller.unpinDevice();
                } else {
                  controller.pinDevice();
                }
              },
              icon: controller.appPinned
                  ? const Icon(LineAwesomeIcons.lock_open,
                      color: AppColors.brightText)
                  : const Icon(LineAwesomeIcons.lock,
                      color: AppColors.brightText),
              // ignore: prefer_if_elements_to_conditional_expressions
            ),
          )),
      FractionallySizedBox(
        widthFactor: 0.7,
        child: PrimaryButton(
          text: "AppLocalizations.of(context).resetMobileApp",
          onTap: () {
            controller.resetApp();
          },
          icon: const Icon(LineAwesomeIcons.alternate_undo,
              color: AppColors.brightText),
          // ignore: prefer_if_elements_to_conditional_expressions
        ),
      ),
      FractionallySizedBox(
        widthFactor: 0.7,
        child: PrimaryButton(
          text: "AppLocalizations.of(context).showSystemLog",
          onTap: controller.openLogConsole,
          color: AppColors.secondaryButton,
          icon:
              const Icon(LineAwesomeIcons.scroll, color: AppColors.brightText),
          // ignore: prefer_if_elements_to_conditional_expressions
        ),
      ),
      FractionallySizedBox(
        widthFactor: 0.7,
        child: PrimaryButton(
          text: "AppLocalizations.of(context).networkSettings",
          onTap: () {
            controller.openNetworkSettings();
          },
          color: AppColors.secondaryButton,
          icon: const Icon(LineAwesomeIcons.cog, color: AppColors.brightText),
          // ignore: prefer_if_elements_to_conditional_expressions
        ),
      ),
      Obx(
        () => FractionallySizedBox(
          widthFactor: 0.7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              /* GestureDetector(
                onTap: () {
                  controller.keyCodeIsTracking$.value = !controller.keyCodeIsTracking$.value;
                  controller.keyboardDownKeyValue$.value = "";
                  controller.keyboardUpKeyValue$.value = "";
                },
                child: controller.keyCodeIsTracking$.value
                    ? const Icon(
                        FontAwesomeIcons.stopCircle,
                        color: AppColors.error,
                        size: 30,
                      )
                    : const Icon(FontAwesomeIcons.playCircle, color: AppColors.secondaryButton, size: 30),
                // ignore: prefer_if_elements_to_conditional_expressions
              ),
              const SizedBox(width: 15),*/
              Text(
                'Key Down : ${controller.keyboardDownKeyValue$.value}',
                style: AppTheme().typography.reportEntryNameStyle,
              ),
              const SizedBox(height: 10),
              Text(
                'Key up : ${controller.keyboardUpKeyValue$.value}',
                style: AppTheme().typography.reportEntryNameStyle,
              ),
            ],
          ),
        ),
      )
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: LayoutConstants.compactPadding, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 5),
          // ignore: sized_box_for_whitespace
          Expanded(
            child: ListView.separated(
              padding: EdgeInsets.zero,
              physics: const ClampingScrollPhysics(),
              itemBuilder: (_, i) => infoBoxes[i],
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemCount: infoBoxes.length,
            ),
          )
        ],
      ),
    );
  }

  Widget _buildInfoDetails(BuildContext context) {
    final infoBoxes = [
      _buildInfoBox(
        "AppLocalizations.of(context).backendVersion",
        AppSettings().version,
      ),
      _buildInfoBox(
        "AppLocalizations.of(context).backendAPIAddress",
        ServiceAddress().baseUrl,
      ),
      _buildInfoBox(
        " AppLocalizations.of(context).backendWebsocketAddress",
        ServiceAddress().webSocketAddress!,
      ),
      _buildInfoBox(
        " AppLocalizations.of(context).backendWebsocketPort",
        ServiceAddress().wwsPort.toString(),
      ),
      _buildInfoBox(
        " AppLocalizations.of(context).mediaSoapAddress,",
        ServiceAddress().webSocketAddress!,
      ),
      _buildInfoBox(
        " AppLocalizations.of(context).videoServerAddress",
        ServiceAddress().webSocketVideoAddress,
      ),
      _buildInfoBox(
        "AppLocalizations.of(context).videoServerPort",
        ServiceAddress().wwsVideoPort.toString(),
      ),
      _buildInfoBox(
        "AppLocalizations.of(context).videoServerAddress",
        ServiceAddress().webSocketChatAddress,
      ),
      _buildInfoBox(
        "AppLocalizations.of(context).videoServerPort",
        ServiceAddress().wwsChatPort.toString(),
      ),
      _buildInfoBox(
        "AppLocalizations.of(context).deviceSettings",
        '2.0',
      ),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Expanded(
          child: ListView.separated(
            padding: EdgeInsets.zero,
            physics: const ClampingScrollPhysics(),
            itemBuilder: (_, i) => Column(
              children: [
                infoBoxes[i],
                if (i + 1 == infoBoxes.length) const TelloDivider(),
              ],
            ),
            separatorBuilder: (_, __) => const TelloDivider(),
            itemCount: infoBoxes.length,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoBox(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(10),
      color: AppTheme().colors.listItemBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTheme().typography.reportEntryNameStyle,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTheme().typography.reportEntryValueStyle,
            ),
          ),
        ],
      ),
    );
  }
}
