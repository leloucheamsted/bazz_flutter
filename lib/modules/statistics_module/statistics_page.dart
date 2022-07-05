import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/widgets/custom_app_bar.dart';
import 'package:bazz_flutter/modules/home_module/widgets/notifications_drawer.dart';
import 'package:bazz_flutter/modules/statistics_module/statistics_controller.dart';
import 'package:bazz_flutter/services/data_connection_checker.dart';
import 'package:bazz_flutter/services/data_usage_service.dart';
import 'package:bazz_flutter/services/statistics_service.dart';
import 'package:bazz_flutter/shared_widgets/tello_divider.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

class StatisticsPage extends GetView<StatisticsController> {
  const StatisticsPage({Key? key}) : super(key: key);

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
          Obx(() {
            return Column(
              children: [
                CustomAppBar(withBackButton: true),
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
                            FontAwesomeIcons.chartLine,
                            color: AppColors.brightIcon,
                          ),
                        ),
                      ),
                      const SizedBox(width: 15),
                      Expanded(
                        child: Text(
                          " AppLocalizations.of(context).deviceStatistics.capitalize",
                          style: AppTheme().typography.subtitle1Style,
                        ),
                      ),
                    ],
                  ),
                ),
                const TelloDivider(),
                Expanded(
                    child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        child: Column(
                          children: [
                            createEntry(
                                FontAwesomeIcons.signInAlt,
                                AppColors.primaryAccent,
                                "AppLocalizations.of(context).incomingPTTDuration",
                                Duration(
                                        seconds: StatisticsService()
                                            .incomingPTTStreamInSeconds)
                                    .toString()),
                            const TelloDivider(),
                            createEntry(
                                FontAwesomeIcons.signOutAlt,
                                AppColors.primaryAccent,
                                "AppLocalizations.of(context).outgoingPTTDuration",
                                Duration(
                                        seconds: StatisticsService()
                                            .outgoingPTTStreamInSeconds)
                                    .toString()),
                            const TelloDivider(),
                            createEntry(
                                FontAwesomeIcons.signInAlt,
                                AppColors.darkRed,
                                " AppLocalizations.of(context).totalIncomingPTTDuration,",
                                Duration(
                                        seconds: StatisticsService()
                                            .totalIncomingPTTStreamInSeconds)
                                    .toString()),
                            const TelloDivider(),
                            createEntry(
                                FontAwesomeIcons.signOutAlt,
                                AppColors.darkRed,
                                "AppLocalizations.of(context).outgoingPTTDuration",
                                Duration(
                                        seconds: StatisticsService()
                                            .totalOutgoingPTTStreamInSeconds)
                                    .toString()),
                            const TelloDivider(),
                            createEntry(
                                FontAwesomeIcons.microphone,
                                AppColors.primaryAccent,
                                "AppLocalizations.of(context).audioPttData",
                                getStreamSize(
                                    StatisticsService().totalPTTBytesSent +
                                        StatisticsService()
                                            .totalPTTBytesReceived,
                                    1)),
                            const TelloDivider(),
                            createEntry(
                                FontAwesomeIcons.recordVinyl,
                                AppColors.primaryAccent,
                                " AppLocalizations.of(context).audioRecordingData",
                                getStreamSize(
                                    StatisticsService().totalPTTRecordingSent +
                                        StatisticsService()
                                            .totalPTTRecordingReceived,
                                    1)),
                            const TelloDivider(),
                            createEntry(
                                FontAwesomeIcons.signal,
                                AppColors.primaryAccent,
                                "AppLocalizations.of(context).offlinePeriod",
                                Duration(
                                        seconds: DataConnectionChecker()
                                            .disconnectDurationInSeconds)
                                    .toString()),
                            const TelloDivider(),
                            createEntry(
                                FontAwesomeIcons.database,
                                AppColors.primaryAccent,
                                "  AppLocalizations.of(context).dataUsageInShift",
                                " ${DataUsageService().totalDataUsage.toString()} Mb"),
                            const TelloDivider(),
                            createEntry(
                                FontAwesomeIcons.database,
                                AppColors.primaryAccent,
                                " AppLocalizations.of(context).dataUsageInShift",
                                " ${DataUsageService().totalStorageDataUsage.toString()} Mb"),
                          ],
                        ))),
              ],
            );
          }),
          NotificationsDrawer(controller: HomeController.to),
        ],
      ),
    );
  }

  Widget createEntry(
      IconData icon, Color iconColor, String title, String text) {
    return Container(
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
              child: Icon(icon, color: iconColor),
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Text(
              title,
              style: AppTheme().typography.subtitle2Style,
            ),
          ),
          Text(
            text,
            style: AppTheme().typography.subtitle2Style,
          ),
        ],
      ),
    );
  }
}
