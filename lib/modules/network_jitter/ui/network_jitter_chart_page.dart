import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/modules/home_module/widgets/custom_app_bar.dart';
import 'package:bazz_flutter/modules/network_jitter/network_jitter_service.dart';
import 'package:bazz_flutter/modules/network_jitter/ui/network_jitter_o_meter.dart';
import 'package:bazz_flutter/services/data_usage_service.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class NetworkJitterChartPage extends GetView<NetworkJitterController> {
  const NetworkJitterChartPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme().colors.mainBackground,
      body: Column(
        children: [
          CustomAppBar(
              withBackButton: true,
              title: "AppLocalizations.of(context).networkJitter"),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                      horizontal: LayoutConstants.compactPadding, vertical: 10)
                  .copyWith(right: 10),
              child: Obx(() {
                if (controller.jitter$ == null) {
                  return Center(
                    child: Text(
                      "AppLocalizations.of(context).collectingData",
                      style: AppTheme().typography.bgTitle2Style,
                    ),
                  );
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: buildJitterChart(),
                    ),
                    Divider(color: AppTheme().colors.divider),
                    Row(children: [
                      Align(
                          child:
                              NetworkJitterOMeter(NetworkJitterController.to!)),
                      const SizedBox(
                        width: 15,
                      ),
                      Text(
                        '{AppLocalizations.of(context).dataUsage}: ',
                        style: AppTypography.title3BaseStyle
                            .copyWith(color: AppColors.primaryAccent),
                      ),
                      Obx(() => Text(
                            "${DataUsageService().totalDataUsage}/Mb",
                            style: AppTheme().typography.bgText3Style,
                          ))
                    ]),
                  ],
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  LineChart buildJitterChart() {
    return LineChart(
      LineChartData(
        lineTouchData: LineTouchData(
          getTouchedSpotIndicator:
              (LineChartBarData barData, List<int> spotIndexes) {
            return spotIndexes.map((index) {
              return TouchedSpotIndicatorData(
                FlLine(
                  color: Colors.red,
                  strokeWidth: 2,
                ),
                FlDotData(),
              );
            }).toList();
          },
        ),
        gridData: FlGridData(
          show: true,
          getDrawingHorizontalLine: (value) {
            return FlLine(
              color: AppColors.graphBorder,
              strokeWidth: 0.7,
            );
          },
          getDrawingVerticalLine: (value) {
            return FlLine(
              color: AppColors.graphBorder,
              strokeWidth: 0.7,
            );
          },
        ),
        clipData: FlClipData.all(),
        titlesData: FlTitlesData(
          topTitles: SideTitles(showTitles: false) as AxisTitles,
          rightTitles: SideTitles(showTitles: false) as AxisTitles,
          bottomTitles: SideTitles(
            showTitles: true,
            reservedSize: 17,
            interval: 5,
            // getTextStyles: (value) => AppTheme().typography.subtitle2Style,
            // margin: 5,
          ) as AxisTitles,
          leftTitles: SideTitles(
            showTitles: true,
            interval: 10,
            // getTextStyles: (value) => AppTheme().typography.subtitle2Style,
            reservedSize: 20,
            //margin: 8,
          ) as AxisTitles,
        ),
        borderData: FlBorderData(
            show: true, border: Border.all(color: AppColors.graphBorder)),

        //  axisTitleData: FlAxisTitleData(
        //    bottomTitle: AxisTitle(
        //      showTitle: true,
        //      margin: 0,
        //      titleText: 'minutes',
        //      textStyle: const TextStyle(color: AppColors.secondaryText, fontSize: 10),
        //     ) ,
        //   ) ,
        minX: 0,
        maxX: 60,
        minY: 0,
        maxY: controller.highestValue > 300
            ? 300.0
            : controller.highestValue.toDouble(),
        lineBarsData: [
          LineChartBarData(
            color: AppColors.jitterChartLine,
            spots: controller.jitterLog$.asMap().entries.map((entry) {
              return FlSpot(
                entry.key > 0 ? entry.key / 6 : 0,
                entry.value.toDouble(),
              );
            }).toList(),
            isCurved: true,
            // colors: gradientColors,
            barWidth: 1,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
          ),
          LineChartBarData(
            color: AppColors.latencyChartLine,
            spots: controller.latencies.asMap().entries.map((entry) {
              return FlSpot(
                entry.key > 0 ? entry.key / 6 : 0,
                entry.value.toDouble(),
              );
            }).toList(),
            isCurved: true,
            // colors: gradientColors,
            barWidth: 1,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
          ),
        ],
      ),
    );
  }
}
