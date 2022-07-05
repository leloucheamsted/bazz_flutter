import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/widgets/custom_app_bar.dart';
import 'package:bazz_flutter/modules/home_module/widgets/notifications_drawer.dart';
import 'package:bazz_flutter/modules/shift_module/shift_service.dart';
import 'package:bazz_flutter/modules/user_profile_module/user_profile_controller.dart';
import 'package:bazz_flutter/shared_widgets/tello_divider.dart';
import 'package:bazz_flutter/shared_widgets/loader.dart';
import 'package:bazz_flutter/shared_widgets/primary_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';

class UserProfilePage extends GetView<UserProfileController> {
  const UserProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme().colors.mainBackground,
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final simSerial = Session.user!.deviceCard.deviceDetails.simSerialNumber;
    final itemNumber = Session.user!.deviceCard.deviceDetails.itemNumber;
    final deviceName = Session.user!.deviceCard.deviceDetails.name;
    final imei = Session.user!.deviceCard.deviceDetails.imei;
    final infoBoxes = [
      _buildInfoBox(
          " AppLocalizations.of(context).supervisorName",
          Session.shift != null
              ? '${Session.shift?.supFirstName} ${Session.shift?.supFirstName}'
              : "---".capitalize!,
          context),
      _buildInfoBox("AppLocalizations.of(context).zone",
          Session.shift!.zoneTitle!, context),
      if (simSerial != null)
        _buildInfoBox("AppLocalizations.of(context).simNumber.capitalize",
            simSerial, context),
      if (itemNumber != null)
        _buildInfoBox("AppLocalizations.of(context).itemNumber.capitalize",
            itemNumber, context),
      if (deviceName != null)
        _buildInfoBox("AppLocalizations.of(context).deviceName.capitalize",
            deviceName, context),
      if (imei != null) _buildInfoBox('imei'.capitalize!, imei, context),
    ];
    return SafeArea(
      child: Stack(
        children: [
          Column(
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
                              height: 50,
                              width: 50,
                              color: AppTheme().colors.tabBarBackground,
                              child: Session.user!.avatar != ""
                                  ? CachedNetworkImage(
                                      imageUrl: Session.user!.avatar)
                                  : const FittedBox(
                                      child: Icon(
                                      Icons.account_circle,
                                      color: AppColors.primaryAccent,
                                    )),
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextOneLine(
                                  '${Session.user!.firstName.capitalize} ${Session.user!.lastName.capitalize}',
                                  style: AppTheme().typography.tabTitleStyle,
                                ),
                                Text(
                                  Session.user!.role.title.capitalize!,
                                  style: AppTheme().typography.subtitle2Style,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const TelloDivider(),
                    Expanded(
                      child: ListView.separated(
                        itemBuilder: (_, i) => Column(
                          children: [
                            infoBoxes[i],
                            if (i + 1 == infoBoxes.length) const TelloDivider(),
                          ],
                        ),
                        separatorBuilder: (_, __) => const TelloDivider(),
                        itemCount: infoBoxes.length,
                      ),
                      // child: Container(height: 300, color: Colors.black),
                    ),
                    FractionallySizedBox(
                      widthFactor: 0.7,
                      child: PrimaryButton(
                        text: "AppLocalizations.of(context).ok",
                        onTap: controller.onConfirmPressed,
                        icon: null as Icon,
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                ),
              ),
              GetX<ShiftService>(
                builder: (_) {
                  if (controller.loadingState == ViewState.loading) {
                    Loader.show(context, themeData: null as ThemeData);
                  } else {
                    Loader.hide();
                  }
                  return const SizedBox();
                },
                dispose: (_) => Loader.hide(),
              ),
            ],
          ),
          NotificationsDrawer(controller: HomeController.to),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String title, String value, BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(15),
      color: value == null
          ? AppColors.danger.withOpacity(0.5)
          : AppTheme().colors.listItemBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: AppTheme().typography.reportEntryNameStyle,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: TextOneLine(
              value,
              textAlign: TextAlign.right,
              style: AppTheme().typography.reportEntryValueStyle,
            ),
          ),
        ],
      ),
    );
  }
}
