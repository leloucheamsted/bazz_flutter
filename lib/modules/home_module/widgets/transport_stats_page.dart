import 'dart:ui';

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/widgets/custom_app_bar.dart';
import 'package:bazz_flutter/modules/settings_module/media_settings.dart';
import 'package:bazz_flutter/shared_widgets/tello_divider.dart';
import 'package:bazz_flutter/shared_widgets/primary_button.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:bazz_flutter/shared_widgets/vertical_tabs.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:get/get.dart';

class TransportDetailsPage extends StatefulWidget {
  const TransportDetailsPage({Key? key}) : super(key: key);

  @override
  _TransportDetailsPageState createState() => _TransportDetailsPageState();
}

class _TransportDetailsPageState extends State<TransportDetailsPage> {
  final tabController = TabController(vsync: HomeController.to, length: 4);
  static RxBool audioDisplay$ = true.obs;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme().colors.mainBackground,
      body: Column(
        children: [
          CustomAppBar(
              withBackButton: true,
              title: "AppLocalizations.of(context).showTransportStats"),
          Container(
            color: AppTheme().colors.tabBarBackground,
            child: Stack(
              alignment: Alignment.bottomCenter,
              children: [
                const TelloDivider(height: 2),
                TabBar(
                  controller: tabController,
                  isScrollable: true,
                  indicator: BoxDecoration(
                    color: AppTheme().colors.selectedTab,
                    border: const Border(
                        bottom: BorderSide(
                            width: 2, color: AppColors.primaryAccent)),
                  ),
                  onTap: (index) async {},
                  tabs: [
                    Tab(
                      child: Text(
                        "AppLocalizations.of(context).producerInfo",
                        style: AppTheme().typography.tabTitle2Style,
                      ),
                    ),
                    Tab(
                      child: Text(
                        " AppLocalizations.of(context).consumerInfo",
                        style: AppTheme().typography.tabTitle2Style,
                      ),
                    ),
                    Tab(
                      child: Text(
                        "AppLocalizations.of(context).deviceInfo",
                        style: AppTheme().typography.tabTitle2Style,
                      ),
                    ),
                    Tab(
                      child: Text(
                        " AppLocalizations.of(context).routerInfo",
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
              controller: tabController,
              children: [
                _buildProducerInfo(context),
                _buildConsumerInfo(context),
                _buildDeviceInfo(context),
                _buildRouterInfo(context),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProducerInfo(BuildContext context) {
    return Expanded(
        child: Obx(() => Padding(
                padding: const EdgeInsets.fromLTRB(0.0, 4.0, 0.0, 0.0),
                child: VerticalTabs(
                  backgroundColor: AppTheme().colors.mainBackground,
                  tabBackgroundColor: AppTheme().colors.mainBackground,
                  selectedTabBackgroundColor: AppTheme().colors.selectedTab,
                  tabTextStyle: AppTheme().typography.inputTextStyle,
                  selectedTabTextStyle: AppTheme().typography.inputTextStyle,
                  tabsWidth: 150,
                  tabs: const <Tab>[
                    Tab(child: Text('Constraints')),
                    Tab(child: Text('kind')),
                    Tab(child: Text('Track Id')),
                    Tab(child: Text('Stream Id')),
                    Tab(child: Text('Sdp Offer')),
                    Tab(child: Text('Local Id')),
                    Tab(child: Text('Media Section Id')),
                    Tab(child: Text('Local Sdp Object')),
                    Tab(child: Text('Mid')),
                    Tab(child: Text('Cname')),
                    Tab(child: Text('Encodings')),
                    Tab(child: Text('Offer Media Object')),
                    Tab(child: Text('Reuse Mid')),
                    Tab(child: Text('Rtp Parameters')),
                    Tab(child: Text('Remote Rtp Parameters')),
                    Tab(child: Text('Sdp Codec Options')),
                    Tab(child: Text('Sdp Answer'))
                  ],
                  contents: <Widget>[
                    tabsContent('Constraints',
                        HomeController.to.producerInfo.constraints.toString()),
                    tabsContent('Kind', HomeController.to.producerInfo.kind!),
                    tabsContent(
                        'TrackId', HomeController.to.producerInfo.trackId!),
                    tabsContent(
                        'StreamId', HomeController.to.producerInfo.streamId!),
                    tabsContent(
                        'SdpOffer', HomeController.to.producerInfo.sdpOffer!),
                    tabsContent(
                        'LocalId', HomeController.to.producerInfo.localId!),
                    tabsContent(
                        'MediaSectionId',
                        HomeController.to.producerInfo.mediaSectionId
                            .toString()),
                    tabsContent(
                        'LocalSdpObject',
                        HomeController.to.producerInfo.localSdpObject
                            .toString()),
                    tabsContent(
                        'Mid', HomeController.to.producerInfo.mid.toString()),
                    tabsContent('Cname',
                        HomeController.to.producerInfo.cname.toString()),
                    tabsContent('Encodings',
                        HomeController.to.producerInfo.encodings.toString()),
                    tabsContent(
                        'OfferMediaObject',
                        HomeController.to.producerInfo.offerMediaObject
                            .toString()),
                    tabsContent('ReuseMid',
                        HomeController.to.producerInfo.reuseMid.toString()),
                    tabsContent(
                        'RtpParameters',
                        HomeController.to.producerInfo.sdpSendingRtpParameters
                            .toString()),
                    tabsContent(
                        'RemoteRtpParameters',
                        HomeController
                            .to.producerInfo.sdpSendingRemoteRtpParameters
                            .toString()),
                    tabsContent(
                        'SdpCodecOptions',
                        HomeController.to.producerInfo.sdpCodecOptions
                            .toString()),
                    tabsContent(
                        'SdpAnswer', HomeController.to.producerInfo.sdpAnswer!),
                  ],
                  indicatorSide: 0 as IndicatorSide,
                  onSelect: (int tabIndex) {},
                )) //Text(HomeController.to.producerOffer, style: AppTheme().typography.inputTextStyle))
            ));
  }

  Widget _buildConsumerInfo(BuildContext context) {
    return Expanded(
        child: Obx(() => Padding(
                  padding: const EdgeInsets.fromLTRB(0.0, 4.0, 0.0, 0.0),
                  child: VerticalTabs(
                    backgroundColor: AppTheme().colors.mainBackground,
                    tabBackgroundColor: AppTheme().colors.mainBackground,
                    selectedTabBackgroundColor: AppTheme().colors.selectedTab,
                    tabTextStyle: AppTheme().typography.inputTextStyle,
                    selectedTabTextStyle: AppTheme().typography.inputTextStyle,
                    tabsWidth: 150,
                    tabs: const <Tab>[
                      Tab(child: Text('Kind')),
                      Tab(child: Text('Track Id')),
                      Tab(child: Text('Local Id')),
                      Tab(child: Text('Cname')),
                      Tab(child: Text('Mid')),
                      Tab(child: Text('Remote Sdp')),
                      Tab(child: Text('Sdp Answer')),
                      Tab(child: Text('Rtp Parameters')),
                      Tab(child: Text('Answer Media Object')),
                      Tab(child: Text('Encodings')),
                      Tab(child: Text('Local Sdp Object')),
                    ],
                    contents: <Widget>[
                      tabsContent('Kind', HomeController.to.consumerInfo.kind!),
                      tabsContent(
                          'TrackId', HomeController.to.consumerInfo.trackId!),
                      tabsContent(
                          'LocalId', HomeController.to.consumerInfo.localId!),
                      tabsContent(
                          'Mid', HomeController.to.consumerInfo.mid.toString()),
                      tabsContent('Cname',
                          HomeController.to.consumerInfo.cname.toString()),
                      tabsContent('remoteSdp',
                          HomeController.to.consumerInfo.remoteSdp!),
                      tabsContent('SdpAnswer',
                          HomeController.to.consumerInfo.sdpAnswer!),
                      tabsContent(
                          'RtpParameters',
                          HomeController.to.consumerInfo.rtpParameters
                              .toString()),
                      tabsContent(
                          'answerMediaObject',
                          HomeController.to.consumerInfo.answerMediaObject
                              .toString()),
                      tabsContent('Encodings',
                          HomeController.to.consumerInfo.encodings.toString()),
                      tabsContent(
                          'LocalSdpObject',
                          HomeController.to.consumerInfo.localSdpObject
                              .toString()),
                    ],
                    indicatorSide: 0 as IndicatorSide,
                    onSelect: (int tabIndex) {},
                  ),
                ) //Text(HomeController.to.producerOffer, style: AppTheme().typography.inputTextStyle))
            ));
  }

  Widget tabsContent(String caption, [String description = '']) {
    return SingleChildScrollView(
      scrollDirection: Axis.vertical,
      child: Container(
          margin: const EdgeInsets.all(2),
          padding: const EdgeInsets.all(2),
          color: AppTheme().colors.mainBackground,
          child: Column(
            children: <Widget>[
              Text(
                caption,
                style: AppTheme().typography.inputTextStyle,
              ),
              Divider(
                height: 2,
                color: AppTheme().colors.divider,
              ),
              Text(
                description,
                style: AppTheme().typography.inputTextStyle,
              ),
            ],
          )),
    );
  }

  Widget _buildDeviceInfo(BuildContext context) {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Obx(() => Text(
            HomeController.to.deviceDetails.deviceNativeRtpCapabilities
                    ?.toString() ??
                "---",
            style: AppTheme().typography.inputTextStyle)));
  }

  Widget _buildRouterInfo(BuildContext context) {
    return SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Obx(() => Text(
            HomeController.to.deviceDetails.mediaRouterRtpCapabilities
                    ?.toString() ??
                "---",
            style: AppTheme().typography.inputTextStyle)));
  }
}

class TransportStatsPage extends StatefulWidget {
  const TransportStatsPage({Key? key}) : super(key: key);

  @override
  _TransportStatsPageState createState() => _TransportStatsPageState();
}

class _TransportStatsPageState extends State<TransportStatsPage> {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
        height: 150,
        width: Get.width,
        child: Column(children: [
          SizedBox(
              width: Get.width - 10,
              height: 125,
              child: Obx(() {
                return _TransportDetailsPageState.audioDisplay$.value
                    ? buildTransportStatsChartAudio()
                    : buildTransportStatsChartVideo();
              })),
          const SizedBox(
            height: 5,
          ),
          Row(children: [
            PrimaryButton(
              height: 20,
              onTap: () {
                Get.to(() => const TransportDetailsPage());
              },
              text: "AppLocalizations.of(context).details",
              icon: null as Icon,
            ),
            SizedBox(
              width: 10,
            ),
            if (MediaSettings().videoModeEnabled)
              Obx(() {
                return _TransportDetailsPageState.audioDisplay$.value
                    ? PrimaryButton(
                        height: 20,
                        onTap: () {
                          _TransportDetailsPageState.audioDisplay$.value =
                              !_TransportDetailsPageState.audioDisplay$.value;
                        },
                        text: "AppLocalizations.of(context).audio",
                        icon: null as Icon,
                      )
                    : PrimaryButton(
                        height: 20,
                        onTap: () {
                          _TransportDetailsPageState.audioDisplay$.value =
                              !_TransportDetailsPageState.audioDisplay$.value;
                        },
                        text: "AppLocalizations.of(context).video",
                        icon: null as Icon,
                      );
              })
          ]),
        ]));
  }

  LineChart buildTransportStatsChartAudio() {
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
            interval: 10,
            // getTextStyles: (value) => AppTheme().typography.subtitle2Style,
            // margin: 5,
          ) as AxisTitles,
          leftTitles: SideTitles(
            showTitles: true,
            interval: 2000,
            // getTextStyles: (value) => AppTheme().typography.subtitle2Style,
            reservedSize: 20,
            // margin: 8,
          ) as AxisTitles,
        ),
        borderData: FlBorderData(
            show: true, border: Border.all(color: AppColors.graphBorder)),
        // axisTitleData: FlAxisTitleData(
        //   bottomTitle: AxisTitle(
        //     showTitle: false,
        //     margin: 0,
        //     titleText: 'minutes',
        //     textStyle:
        //         const TextStyle(color: AppColors.secondaryText, fontSize: 10),
        //  ),
        // ),
        minX: 0,
        maxX: 60,
        minY: 0,
        maxY: 4000,
        lineBarsData: [
          LineChartBarData(
            color: Colors.lightGreenAccent,
            spots: HomeController.to.mediaTrackStatsAudioList$.isNotEmpty
                ? HomeController.to.mediaTrackStatsAudioList$
                    .asMap()
                    .entries
                    .map((entry) {
                    return FlSpot(
                      entry.key > 0 ? entry.key / 6 : 0,
                      entry.value.isProducer!
                          ? entry.value.bytesSent! / 1024
                          : entry.value.bytesReceived! / 1024,
                    );
                  }).toList()
                : [FlSpot(0, 0)],
            isCurved: true,
            // colors: gradientColors,
            barWidth: 1,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
          ),
          LineChartBarData(
            color: Colors.blueAccent,
            spots: HomeController.to.mediaTrackStatsAudioList$.isNotEmpty
                ? HomeController.to.mediaTrackStatsAudioList$
                    .asMap()
                    .entries
                    .map((entry) {
                    return FlSpot(
                      entry.key > 0 ? entry.key / 6 : 0,
                      entry.value.isProducer!
                          ? entry.value.packetsSent!
                          : entry.value.packetsReceived!,
                    );
                  }).toList()
                : [FlSpot(0, 0)],
            isCurved: true,
            // colors: gradientColors,
            barWidth: 1,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
          ),
          LineChartBarData(
            color: Colors.redAccent,
            spots: HomeController.to.mediaTrackStatsAudioList$.isNotEmpty
                ? HomeController.to.mediaTrackStatsAudioList$
                    .asMap()
                    .entries
                    .map((entry) {
                    return FlSpot(
                      entry.key > 0 ? entry.key / 6 : 0,
                      entry.value.isProducer!
                          ? entry.value.packetsDiscardedOnSend!
                          : entry.value.googDecodeMs!,
                    );
                  }).toList()
                : [FlSpot(0, 0)],
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

  LineChart buildTransportStatsChartVideo() {
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
            interval: 10,
            // getTextStyles: (value) => AppTheme().typography.subtitle2Style,
            // margin: 5,
          ) as AxisTitles,
          leftTitles: SideTitles(
            showTitles: true,
            interval: 2000,
            //  getTextStyles: (value) => AppTheme().typography.subtitle2Style,
            reservedSize: 20,
            //  margin: 8,
          ) as AxisTitles,
        ),
        borderData: FlBorderData(
            show: true, border: Border.all(color: AppColors.graphBorder)),
        // axisTitleData: FlAxisTitleData(
        //   bottomTitle: AxisTitle(
        //     showTitle: false,
        //     margin: 0,
        //     titleText: 'minutes',
        //     textStyle:
        //         const TextStyle(color: AppColors.secondaryText, fontSize: 10),
        //   ) ,
        // ),
        minX: 0,
        maxX: 60,
        minY: 0,
        maxY: 4000,
        lineBarsData: [
          LineChartBarData(
            color: Colors.lightGreenAccent,
            spots: HomeController.to.mediaTrackStatsVideoList$.isNotEmpty
                ? HomeController.to.mediaTrackStatsVideoList$
                    .asMap()
                    .entries
                    .map((entry) {
                    return FlSpot(
                      entry.key > 0 ? entry.key / 6 : 0,
                      entry.value.isProducer!
                          ? entry.value.bytesSent! / 1024
                          : entry.value.bytesReceived! / 1024,
                    );
                  }).toList()
                : [FlSpot(0, 0)],
            isCurved: true,
            // colors: gradientColors,
            barWidth: 1,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
          ),
          LineChartBarData(
            color: Colors.blueAccent,
            spots: HomeController.to.mediaTrackStatsVideoList$.isNotEmpty
                ? HomeController.to.mediaTrackStatsVideoList$
                    .asMap()
                    .entries
                    .map((entry) {
                    return FlSpot(
                      entry.key > 0 ? entry.key / 6 : 0,
                      entry.value.isProducer!
                          ? entry.value.packetsSent!
                          : entry.value.packetsReceived!,
                    );
                  }).toList()
                : [FlSpot(0, 0)],
            isCurved: true,
            // colors: gradientColors,
            barWidth: 1,
            isStrokeCapRound: true,
            dotData: FlDotData(show: false),
          ),
          LineChartBarData(
            color: Colors.redAccent,
            spots: HomeController.to.mediaTrackStatsVideoList$.isNotEmpty
                ? HomeController.to.mediaTrackStatsVideoList$
                    .asMap()
                    .entries
                    .map((entry) {
                    return FlSpot(
                      entry.key > 0 ? entry.key / 6 : 0,
                      entry.value.isProducer!
                          ? entry.value.packetsDiscardedOnSend!
                          : entry.value.googDecodeMs!,
                    );
                  }).toList()
                : [FlSpot(0, 0)],
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
