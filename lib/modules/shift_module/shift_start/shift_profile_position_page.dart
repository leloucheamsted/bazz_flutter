import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/shift_module/shift_service.dart';
import 'package:bazz_flutter/shared_widgets/tello_divider.dart';
import 'package:bazz_flutter/shared_widgets/loader.dart';
import 'package:bazz_flutter/shared_widgets/primary_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class ShiftProfilePositionPage extends GetView<ShiftService> {
  const ShiftProfilePositionPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final Widget body = _buildBody(context);
    return Scaffold(
      backgroundColor: AppTheme().colors.mainBackground,
      appBar: AppBar(
        backgroundColor: AppTheme().colors.appBar,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.brightText),
          onPressed: () => controller.goBackToLoginPage(),
        ),
        title: Text(
          " AppLocalizations.of(context).shiftProfileSelectPosition",
          style: AppTheme().typography.appbarTextStyle,
        ),
      ),
      body: body,
    );
  }

  Widget _buildBody(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 3,
                )
              ],
              color: AppTheme().colors.tabBarBackground,
            ),
            child: Row(
              children: [
                ClipOval(
                  child: Container(
                    height: 50,
                    width: 50,
                    color: AppTheme().colors.tabBarBackground,
                    child: Session.user!.avatar != ""
                        ? CachedNetworkImage(imageUrl: Session.user!.avatar)
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
                const SizedBox(width: 10),
                PrimaryButton(
                  horizontalPadding: 10,
                  icon: const Icon(FontAwesomeIcons.satellite,
                      color: AppColors.brightIcon),
                  text: "AppLocalizations.of(context).position,",
                  onTap: () {
                    controller.fetchSuggestedPositionsByLocation();
                  },
                )
              ],
            ),
          ),
          const TelloDivider(),
          Expanded(
            child: GetBuilder<ShiftService>(
                id: 'availablePositionsSelection',
                builder: (_) {
                  if (controller.positionsInRange.isNotEmpty) {
                    return ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (_, i) => Column(
                        children: [
                          _buildPositionInfoBox(
                              context, controller.positionsInRange[i]),
                          if (i + 1 == controller.positionsInRange.length)
                            const TelloDivider(),
                        ],
                      ),
                      separatorBuilder: (_, __) => const TelloDivider(),
                      itemCount: controller.positionsInRange.length,
                    );
                  } else {
                    return Align(
                        child: Text(
                      " AppLocalizations.of(context).noPosition",
                      style: AppTheme().typography.bgTitle2Style,
                    ));
                  }
                }),
          ),
          const SizedBox(height: 5),
          Align(
            child: Text(
              '{AppLocalizations.of(context).startYourAssignmentAs.capitalizeFirst}:',
              style: AppTheme().typography.bgText3Style,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(5),
            child: Row(
              children: [
                Expanded(
                    child: PrimaryButton(
                  icon: const Icon(Icons.qr_code, color: AppColors.brightIcon),
                  text: " AppLocalizations.of(context).position",
                  onTap: () {
                    controller.displayPositionByQRCode();
                  },
                )),
                const SizedBox(
                  width: 5,
                ),
                Expanded(
                  child: PrimaryButton(
                    //icon: const Icon(Icons.verified_user_outlined, color: AppColors.brightIcon),
                    // text: Session.user.isSupervisor
                    //     ? AppLocalizations.of(context).supervisor
                    //     : AppLocalizations.of(context).user,
                    text: Session.user!.isSupervisor!
                        ? "AppLocalizations.of(context).supervisor"
                        : " AppLocalizations.of(context).user",
                    onTap:
                        controller.isBusy ? null! : controller.continueAsUser,
                    color: AppColors.secondaryButton, icon: null as Icon,
                  ),
                ),
              ],
            ),
          ),
          GetX<ShiftService>(
            builder: (_) {
              if (controller.loadingState == ViewState.loading) {
                Loader.show(context, themeData: null as ThemeData);
              } else if (controller.loadingState == ViewState.initialize) {
                Loader.hide();
                Loader.show(context,
                    text: "AppLocalizations.of(context).initializingServices",
                    progressIndicator:
                        SpinKitHourGlass(color: AppColors.loadingIndicator),
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
    );
  }

  Widget _buildPositionInfoBox(BuildContext context, RxPosition pos) {
    return Container(
      padding: const EdgeInsets.all(5),
      color: AppTheme().colors.listItemBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ClipOval(
            child: Container(
              height: 50,
              width: 50,
              color: AppTheme().colors.mainBackground,
              child: pos.imageSrc.isNotEmpty
                  ? CachedNetworkImage(imageUrl: pos.imageSrc)
                  : const FittedBox(
                      child: Icon(
                      Icons.house_outlined,
                      color: AppColors.primaryAccent,
                    )),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
              child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Column(children: [
                    Text(
                      pos.title,
                      style: AppTheme().typography.listItemTitleStyle,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                    Obx(() {
                      if (pos.worker() != null) {
                        return TextOneLine(
                          pos.worker().fullName!,
                          style: AppTheme().typography.subtitle2Style,
                        );
                      } else {
                        return TextOneLine(
                          "--",
                          style: AppTheme().typography.subtitle2Style,
                        );
                      }
                    }),
                  ]))),
          const SizedBox(width: 5),
          Obx(() {
            if (pos.worker() != null && pos.worker().id != Session.user!.id) {
              return Text("AppLocalizations.of(context).notAvailable",
                  style: AppTheme()
                      .typography
                      .subtitle2Style
                      .copyWith(color: AppColors.danger));
            } else {
              return PrimaryButton(
                text: " AppLocalizations.of(context).start",
                onTap: controller.isBusy
                    ? null!
                    : () {
                        controller.selectAvailablePosition(pos);
                      },
                icon: null as Icon,
              );
            }
          }),
        ],
      ),
    );
  }
}
