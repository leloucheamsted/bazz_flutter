import 'package:bazz_flutter/app_theme.dart';
import 'package:flutter_audio_manager/flutter_audio_manager.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/widgets/custom_app_bar.dart';
import 'package:bazz_flutter/modules/home_module/widgets/notifications_drawer.dart';
import 'package:bazz_flutter/modules/device_outputs_module/device_outputs_controller.dart';
import 'package:bazz_flutter/shared_widgets/tello_divider.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class DeviceOutputsPage extends GetView<DeviceOutputsController> {
  const DeviceOutputsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme().colors.mainBackground,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Obx(() => Column(
                children: [
                  CustomAppBar(withBackButton: true),
                  Expanded(
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          color: AppTheme().colors.tabBarBackground,
                          child: Row(
                            children: [
                              ClipOval(
                                child: Container(
                                  height: 60,
                                  width: 60,
                                  color: AppTheme().colors.selectedTab,
                                  child: const Icon(
                                    FontAwesomeIcons.volumeUp,
                                    color: AppColors.brightIcon,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  "AppLocalizations.of(context).selectDeviceOutput.capitalize",
                                  style: AppTheme().typography.subtitle1Style,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const TelloDivider(),
                        Container(
                          padding: const EdgeInsets.all(15),
                          color: AppTheme().colors.listItemBackground,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ClipOval(
                                child: Container(
                                  height: 50,
                                  width: 50,
                                  color: AppTheme().colors.tabBarBackground,
                                  child: const Icon(
                                    FontAwesomeIcons.speakerDeck,
                                    color: AppColors.primaryAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  "AppLocalizations.of(context).speakers",
                                  style: AppTheme().typography.subtitle2Style,
                                ),
                              ),
                              GestureDetector(
                                onTap: controller.changeToSpeaker,
                                child: ClipOval(
                                  child: Container(
                                    height: 36,
                                    width: 36,
                                    color: AppTheme().colors.tabBarBackground,
                                    child: Icon(
                                      controller.selectedDevice ==
                                              AudioPort.speaker
                                          ? Icons.radio_button_checked
                                          : Icons.radio_button_unchecked,
                                      color: AppColors.primaryAccent,
                                      size: 36,
                                    ),
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                        const TelloDivider(),
                        Container(
                          padding: const EdgeInsets.all(15),
                          color: AppTheme().colors.listItemBackground,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ClipOval(
                                child: Container(
                                  height: 50,
                                  width: 50,
                                  color: AppTheme().colors.tabBarBackground,
                                  child: Icon(
                                    FontAwesomeIcons.headphones,
                                    color: controller.hasHeadphone
                                        ? AppColors.primaryAccent
                                        : AppColors.coolGray,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  " AppLocalizations.of(context).headphone",
                                  style: AppTheme().typography.subtitle2Style,
                                ),
                              ),
                              if (controller.hasHeadphone)
                                GestureDetector(
                                  onTap: controller.changeToHeadphone,
                                  child: ClipOval(
                                    child: Container(
                                      height: 36,
                                      width: 36,
                                      color: AppTheme().colors.tabBarBackground,
                                      child: Icon(
                                        controller.selectedDevice ==
                                                AudioPort.headphones
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: AppColors.primaryAccent,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                )
                            ],
                          ),
                        ),
                        const TelloDivider(),
                        Container(
                          padding: const EdgeInsets.all(15),
                          color: AppTheme().colors.listItemBackground,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              ClipOval(
                                child: Container(
                                  height: 50,
                                  width: 50,
                                  color: AppTheme().colors.tabBarBackground,
                                  child: Icon(
                                    FontAwesomeIcons.bluetooth,
                                    color: controller.hasHeadphone
                                        ? AppColors.primaryAccent
                                        : AppColors.coolGray,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 15),
                              Expanded(
                                child: Text(
                                  " AppLocalizations.of(context).bluetooth",
                                  style: AppTheme().typography.subtitle2Style,
                                ),
                              ),
                              if (controller.hasBluetooth)
                                GestureDetector(
                                  onTap: controller.changeToBluetooth,
                                  child: ClipOval(
                                    child: Container(
                                      height: 36,
                                      width: 36,
                                      color: AppTheme().colors.tabBarBackground,
                                      child: Icon(
                                        controller.selectedDevice ==
                                                AudioPort.bluetooth
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: AppColors.primaryAccent,
                                        size: 36,
                                      ),
                                    ),
                                  ),
                                )
                            ],
                          ),
                        )
                      ],
                    ),
                  ),
                ],
              )),
          NotificationsDrawer(controller: HomeController.to),
        ],
      ),
    );
  }
}
