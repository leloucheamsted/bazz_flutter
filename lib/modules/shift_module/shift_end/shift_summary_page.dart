import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/shift_end_message.dart';
import 'package:bazz_flutter/models/shift_summary.dart';
import 'package:bazz_flutter/modules/auth_module/auth_service.dart';
import 'package:bazz_flutter/shared_widgets/primary_button.dart';
import 'package:bazz_flutter/shared_widgets/tello_divider.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter_svg/svg.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class ShiftSummaryPage extends StatelessWidget {
  const ShiftSummaryPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme().colors.mainBackground,
      appBar: AppBar(
        backgroundColor: AppTheme().colors.appBar,
        title: Text(
          " AppLocalizations.of(context).shiftSummary",
          style: AppTheme().typography.appbarTextStyle,
        ),
        leading: const SizedBox(),
        centerTitle: true,
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final shiftSummary = Get.arguments as ShiftSummary;
    final shiftStartDateTime =
        dateTimeFromSeconds(shiftSummary.createdAt!, isUtc: true);
    final shiftEndDateTime =
        dateTimeFromSeconds(shiftSummary.closedAt!, isUtc: true);
    final shiftEndMessage = Session.shift!.shiftEndMessages!.firstWhere(
        (m) => m.ratingRange.contains(shiftSummary.rating),
        orElse: () => "null" as ShiftEndMessage);
    final ratingColorHex = AppSettings()
        .ratingColorSettings
        .firstWhere((cfg) => cfg.ratingRange.contains(shiftSummary.rating))
        .color;
    final ratingColor = HexColor.fromHex(ratingColorHex);

    final infoBoxes = [
      _buildInfoBox(
        " AppLocalizations.of(context).startTime.capitalize,",
        DateFormat(AppSettings().timeFormat)
            .format(shiftStartDateTime!.toLocal()),
        Icons.calendar_today_outlined,
      ),
      _buildInfoBox(
        " AppLocalizations.of(context).endTime.capitalize",
        DateFormat(AppSettings().timeFormat)
            .format(shiftEndDateTime!.toLocal()),
        FontAwesomeIcons.calendarDay,
      ),
      _buildInfoBox(
        " AppLocalizations.of(context).plannedDuration",
        humanizeDuration(seconds: shiftSummary.plannedDuration)!,
        FontAwesomeIcons.clock,
      ),
      _buildInfoBox(
        " AppLocalizations.of(context).actualDuration",
        humanizeDuration(
            seconds:
                (dateTimeToSeconds(shiftEndDateTime) - shiftSummary.createdAt!)
                    .round())!,
        Icons.timelapse_outlined,
        shiftEndedForcefully: shiftSummary.forcedShiftEnd,
      ),
    ];
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
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
                        "Session.user.role.title.capitalize",
                        style: AppTheme().typography.subtitle2Style,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const TelloDivider(),
          ListView.separated(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemBuilder: (_, i) => Column(
              children: [
                infoBoxes[i],
                if (i + 1 == infoBoxes.length) const TelloDivider(),
              ],
            ),
            separatorBuilder: (_, __) => const TelloDivider(),
            itemCount: infoBoxes.length,
          ),
          _buildRating(shiftSummary.rating, ratingColor, shiftEndMessage),
          const Spacer(),
          const SizedBox(height: 5),
          FractionallySizedBox(
            widthFactor: 0.7,
            child: PrimaryButton(
              text: "AppLocalizations.of(context).finish",
              onTap: () => AuthService.to.logOut(locally: true),
              icon: null as Icon,
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }

  Widget _buildInfoBox(String title, String value, IconData icon,
      {bool shiftEndedForcefully = false}) {
    return Container(
      padding: const EdgeInsets.all(15),
      color: shiftEndedForcefully
          ? AppColors.danger.withOpacity(0.7)
          : AppTheme().colors.listItemBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          FaIcon(
            icon,
            color: AppColors.greyIcon,
            size: 20,
          ),
          const SizedBox(width: 20),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextOneLine(
                title,
                style: AppTheme().typography.reportEntryNameStyle,
              ),
              if (shiftEndedForcefully)
                TextOneLine(
                  "  AppLocalizations.of(Get.context).shiftDurationExpire",
                  style: AppTheme().typography.bgText4Style,
                ),
            ],
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

  Widget _buildRating(
      int rating, Color ratingColor, ShiftEndMessage endMessage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 7),
      color: AppTheme().colors.listItemBackground,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextOneLine(
                    "{AppLocalizations.of(Get.context).yourRating.toUpperCase()}:  ",
                    style: AppTheme()
                        .typography
                        .bgTitle1Style
                        .copyWith(fontSize: 20, fontWeight: FontWeight.w500),
                  ),
                  TextOneLine(
                    rating.toString(),
                    textAlign: TextAlign.right,
                    style: AppTheme()
                        .typography
                        .bgTitle1Style
                        .copyWith(fontSize: 22, color: ratingColor),
                  ),
                ],
              ),
              TextOneLine(
                endMessage.message,
                style: AppTheme().typography.bgText2Style,
              ),
            ],
          ),
          const SizedBox(width: 15),
          if (endMessage.icon.iconAssetExists)
            SvgPicture.asset(
              'assets/images/${endMessage.icon.id}.svg',
              width: 65,
              color: ratingColor,
            )
          else
            SvgPicture.network(
              endMessage.icon.url,
              width: 65,
            ),
        ],
      ),
    );
  }
}
