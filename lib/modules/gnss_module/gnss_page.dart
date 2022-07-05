import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/modules/gnss_module/gnss_controller.dart';
import 'package:bazz_flutter/modules/home_module/widgets/custom_app_bar.dart';
import 'package:bazz_flutter/shared_widgets/section_divider.dart';
import 'package:fl_chart/fl_chart.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:gnss_status/gnss_status.dart';
import 'package:gnss_status/gnss_status_model.dart';
import 'package:bazz_flutter/app_theme.dart';

class GnssPage extends GetView<GnssController> {
  const GnssPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme().colors.mainBackground,
      body: _buildBody(context),
    );
  }

  Widget _buildInfoBox(BuildContext context, String title, String value) {
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
          Container(
              width: 132,
              height: 35,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(5)),
                color: AppColors.primaryAccent.withOpacity(0.2),
              ),
              child: Obx(() => Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          controller.graphView = true;
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5)),
                            color: !controller.graphView
                                ? Colors.transparent
                                : AppColors.primaryAccent,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: Text(
                            "AppLocalizations.of(context).graph.toUpperCase()",
                            style: controller.graphView
                                ? AppTheme().typography.buttonTextStyle
                                : AppTheme()
                                    .typography
                                    .buttonTextStyle
                                    .copyWith(color: AppColors.primaryAccent),
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          controller.graphView = false;
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius:
                                const BorderRadius.all(Radius.circular(5)),
                            color: controller.graphView
                                ? Colors.transparent
                                : AppColors.primaryAccent,
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 8),
                          child: Text(
                            " AppLocalizations.of(context).details.toUpperCase()",
                            style: !controller.graphView
                                ? AppTheme().typography.buttonTextStyle
                                : AppTheme()
                                    .typography
                                    .buttonTextStyle
                                    .copyWith(color: AppColors.primaryAccent),
                          ),
                        ),
                      ),
                    ],
                  ))),
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

  BarChartGroupData makeGroupData(
    int x,
    double y, {
    Color barColor = AppColors.online,
    double width = 12,
    List<int> showTooltips = const [],
  }) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          fromY: y,
          color: barColor,
          width: width,
          toY: 0,
        ),
      ],
      showingTooltipIndicators: showTooltips,
    );
  }

  BarChartData mainBarData(BuildContext context, List<Status> data) {
    return BarChartData(
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
            tooltipBgColor: Colors.blueGrey,
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              return BarTooltipItem(
                "{AppLocalizations.of(context).satellite} {groupIndex + 1}",
                const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              );
            }),
        //touchCallback: (barTouchResponse) {
        // barTouchResponse.spot.touchedBarGroupIndex
        //  }
      ),
      titlesData: FlTitlesData(
        show: true,
        rightTitles: SideTitles(
          showTitles: true,
          interval: 5,
          //  margin: 10,
          // getTextStyles: (value) => const TextStyle(
          //     color: Colors.white,
          //     fontWeight: FontWeight.bold,
          //     fontSize: 14)),
        ) as AxisTitles
        //topTitles: SideTitles(showTitles: false) as AxisTitles,
        ,
        bottomTitles: SideTitles(
          showTitles: true,
          // getTextStyles: (value) => const TextStyle(
          // color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
          // margin: 16,
          // getTitles: (double value) {
          //   return "S - ${value.toInt()}";
          // },
        ) as AxisTitles,
        leftTitles: SideTitles(
          showTitles: false,
        ) as AxisTitles,
      ),
      borderData: FlBorderData(
          show: true,
          border: Border(
              bottom: BorderSide(width: 2, color: Colors.white.withOpacity(.5)),
              right:
                  BorderSide(width: 2, color: Colors.white.withOpacity(.5)))),
      barGroups: List.generate(data.length, (i) {
        final barColor =
            data[i].cn0DbHz < 14 ? AppColors.error : AppColors.online;
        return makeGroupData(i + 1, data[i].cn0DbHz, barColor: barColor);
      }),
      gridData: FlGridData(show: true),
    );
  }

  Widget _buildBody(BuildContext context) {
    return SafeArea(
      child: Column(children: [
        CustomAppBar(withBackButton: true),
        Expanded(
            child: Center(
          child: StreamBuilder<GnssStatusModel>(
            builder: (context, snapshot) {
              if (snapshot.data == null) {
                return SpinKitFadingCircle(color: AppColors.loadingIndicator);
              }
              final onlineSatellite = snapshot.data!.status
                  .where((element) => element.cn0DbHz > 0)
                  .length;
              final offlineSatellite = snapshot.data!.status
                  .where((element) => element.cn0DbHz == 0)
                  .length;
              final onlineData = snapshot.data!.status
                  .where((element) => element.cn0DbHz > 0)
                  .toList();
              if (controller.graphView) {
                return Column(children: [
                  _buildInfoBox(
                      context,
                      "AppLocalizations.of(context).satellites",
                      "{AppLocalizations.of(context).online} $onlineSatellite {AppLocalizations.of(context).offline} $offlineSatellite"),
                  const SizedBox(
                    height: 20,
                  ),
                  Expanded(
                      child: SizedBox(
                          width: Get.width - 30,
                          child: onlineData.isNotEmpty
                              ? BarChart(mainBarData(context, onlineData))
                              : Text(
                                  " AppLocalizations.of(context) .noOnlineSatellite",
                                  style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14),
                                ))),
                  const SizedBox(
                    height: 20,
                  ),
                ]);
              } //Column(
              else {
                return Column(children: [
                  _buildInfoBox(
                      context,
                      " AppLocalizations.of(context).satellites",
                      "{AppLocalizations.of(context).online} $onlineSatellite {AppLocalizations.of(context).offline} $offlineSatellite"),
                  const SizedBox(
                    height: 20,
                  ),
                  Expanded(
                      child: SizedBox(
                          width: Get.width - 30,
                          child: ListView.separated(
                            itemBuilder: (_, i) {
                              final item = snapshot.data!.status[i];
                              final title =
                                  "{AppLocalizations.of(context).satellite} ${i + 1}";

                              return Column(children: [
                                TitledDivider(
                                  indent: 0,
                                  text: title,
                                  textColor: item.cn0DbHz > 0
                                      ? AppColors.online
                                      : AppColors.offline,
                                  dividerColor: Colors.white,
                                  dividerTitleBg: Colors.black,
                                ),
                                Text(item.toJson().toString(),
                                    style: const TextStyle(
                                        color: AppColors.lightText))
                              ]);
                            },
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 5),
                            itemCount: snapshot.data!.status.length,
                          ))),
                  const SizedBox(
                    height: 20,
                  ),
                ]);
              }
            },
            stream: GnssStatus().gnssStatusEvents,
          ),
        ))
      ]),
    );
  }
}
