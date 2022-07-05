import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/shift_module/shift_service.dart';
import 'package:bazz_flutter/shared_widgets/primary_button.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:bazz_flutter/shared_widgets/loader.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class ShiftProfilePage extends GetView<ShiftService> {
  const ShiftProfilePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme().colors.mainBackground,
      appBar: AppBar(
        title: Text(
          " AppLocalizations.of(context).shiftProfile",
          style: AppTypography.subtitle1TextStyle,
        ),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final infoBoxes = [
      _buildInfoBox(" AppLocalizations.of(context).zone",
          Session.shift!.zoneTitle!, FontAwesomeIcons.mapMarkedAlt, context),
      _buildInfoBox("AppLocalizations.of(context).activeGroup,",
          Session.shift!.groupTitle!, FontAwesomeIcons.users, context),
      _buildInfoBox(" AppLocalizations.of(context).position",
          Session.shift!.positionTitle!, FontAwesomeIcons.userShield, context),
      _buildInfoBox(
          "AppLocalizations.of(context).shiftDuration",
          humanizeDuration(seconds: Session.shift!.duration)!,
          FontAwesomeIcons.calendar,
          context),
      _buildInfoBox(
          " AppLocalizations.of(context).supervisorName",
          '{Session.shift?.supFirstName} {Session.shift?.supLastName}'
              .capitalize!,
          Icons.supervised_user_circle_sharp,
          context),
    ];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(
            horizontal: LayoutConstants.compactPadding, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 3,
                  )
                ],
                borderRadius: BorderRadius.all(Radius.circular(5)),
                color: AppColors.brightBackground,
              ),
              child: Row(
                children: [
                  ClipOval(
                      child: Container(
                    height: 50,
                    width: 50,
                    color: AppTheme().colors.mainBackground,
                    child: Session.user!.avatar != ""
                        ? CachedNetworkImage(imageUrl: Session.user!.avatar)
                        : const FittedBox(
                            child: Icon(
                            Icons.account_circle,
                            color: AppColors.primaryAccent,
                          )),
                  )),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${Session.user!.firstName.capitalize} ${Session.user!.lastName.capitalize}',
                          style: AppTypography.headline6TextStyle
                              .copyWith(fontSize: 20),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          Session.user!.role.title.capitalize!,
                          style: AppTypography.subtitle3TextStyle,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            ListView.separated(
              physics: const NeverScrollableScrollPhysics(),
              shrinkWrap: true,
              itemBuilder: (_, i) => infoBoxes[i],
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemCount: infoBoxes.length,
            ),
            Obx(() => controller.loadingState == ViewState.error
                ? Column(
                    children: [
                      const SizedBox(height: 15),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.warning_amber_rounded,
                              size: 16, color: AppColors.error),
                          const SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              controller.errorMessage,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.error),
                            ),
                          ),
                        ],
                      ),
                    ],
                  )
                : Container()),
            const Spacer(),
            PrimaryButton(
              text: "AppLocalizations.of(context).startNow",
              onTap: () async {
                await controller.onShiftStartPressed();
              },
              icon: null as Icon,
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
      ),
    );
  }

  Widget _buildInfoBox(
      String title, String value, IconData icon, BuildContext context) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(5)),
      child: Container(
        padding: const EdgeInsets.all(15),
        color: value == null ? AppColors.error : AppColors.brightBackground,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            FaIcon(
              icon,
              color: AppColors.shiftSummaryIconColor,
              size: 15,
            ),
            const SizedBox(width: 20),
            Text(
              title,
              style: AppTypography.bodyText8TextStyle,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: AppTypography.subtitle5TextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
