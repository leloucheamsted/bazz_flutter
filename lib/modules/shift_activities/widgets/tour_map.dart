import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/flutter_map.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_controller.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_marker.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_polyline.dart';
import 'package:bazz_flutter/modules/home_module/views/map/plugins/storage_caching_tile_provider.dart';
import 'package:bazz_flutter/modules/home_module/views/map/plugins/zoombuttons_plugin_option.dart';
import 'package:bazz_flutter/modules/shift_activities/models/reporting_point.dart';
import 'package:bazz_flutter/modules/shift_activities/shift_activities_stats/shift_activities_stats_controller.dart';
import 'package:bazz_flutter/shared_widgets/entity_details_info.dart';
import 'package:bazz_flutter/utils/flutter_custom_info_window.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as mt;
import 'package:latlong/latlong.dart' show lg;

class TourMap extends StatefulWidget {
  const TourMap({Key? key, required this.rPoints}) : super(key: key);

  final List<ReportingPoint> rPoints;

  @override
  _TourMapState createState() => _TourMapState();
}

class _TourMapState extends State<TourMap> {
  LatLngBounds? _tourBounds;
  final customInfoWindowController = FlutterCustomInfoWindowController();
  final rPointMarkers = <FlutterMarker>[];
  final rPointPolylineMarkers = <FlutterMarker>[];
  final rPointPolylines = <FlutterPolyline>[];
  MapController mapController = MapController();

  @override
  void initState() {
    _tourBounds = GeoUtils.mapBoundsFromCoordinatesList(
        widget.rPoints.map((rp) => rp.location).toList());
    for (final point in widget.rPoints) {
      _drawReportingPointMarker(point);
    }
    drawPathRPointPolyline(widget.rPoints);
    super.initState();
  }

  @override
  void dispose() {
    customInfoWindowController.dispose();
    rPointPolylines.clear();
    rPointPolylineMarkers.clear();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // ignore: dead_code
    return Stack(children: [
      // Positioned.fill(
      //     //  child: FlutterMap(

      //     //  )
      // )
    ]);
  }

  Widget createLabel(String text) {
    return true
        // return needToShowLabel()
        ? Container(
            decoration: BoxDecoration(
              color: AppColors.brightBackground,
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 3,
                ),
              ],
              border: Border.all(
                color: AppTheme().colors.primaryButton,
              ),
              borderRadius: const BorderRadius.all(Radius.circular(3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(2),
              child: TextOneLine(
                text,
                style:
                    AppTypography.markerCaptionTextStyle.copyWith(fontSize: 12),
              ),
            ),
          )
        : Container();
  }

  void drawPathRPointPolyline(List<ReportingPoint> rPoints) {
    final List<ReportingPoint> rPointsCopy = rPoints
        .where((e) => e.visits!.isNotEmpty)
        .map((e) => e.copyWith())
        .toList();

    rPointsCopy.sort((a, b) {
      var start = a.visits!.first.startedAt;
      var end = b.visits!.first.startedAt;
      return start!.compareTo(end!);
    });

    for (int i = 0; i < rPointsCopy.length - 1; i++) {
      rPointPolylines.add(FlutterPolyline(
        color: AppColors.danger,
        points: [
          rPointsCopy[i].location.toMapLatLng(),
          rPointsCopy[i + 1].location.toMapLatLng()
        ],
        strokeWidth: 3,
      ));
      var triangleHeading = mt.SphericalUtil.computeHeading(
        mt.LatLng(
          rPointsCopy[i].location.latitude,
          rPointsCopy[i].location.longitude,
        ),
        mt.LatLng(
          rPointsCopy[i + 1].location.latitude,
          rPointsCopy[i + 1].location.longitude,
        ),
      );
      _drawRPointPolylineMarker(rPointsCopy[i + 1], triangleHeading.toDouble());
    }
  }

  void _drawRPointPolylineMarker(ReportingPoint point, double triangleHeading) {
    rPointPolylineMarkers.add(
      FlutterMarker(
        id: point.id,
        controller: mapController,
        width: 25,
        height: 25,
        point: point.location.toMapLatLng(),
        builder: (_) {
          return Transform.rotate(
            angle: GeoUtils.degreeToRadian(triangleHeading),
            child: LayoutBuilder(builder: (context, constraints) {
              return Image.asset('assets/images/arrow_up.png',
                  color: AppColors.danger);
            }),
          );
        },
      ),
    );
  }

  void _drawReportingPointMarker(ReportingPoint point) {
    rPointMarkers.add(
      FlutterMarker(
        id: point.id,
        controller: mapController,
        width: 120,
        height: 40,
        point: point.location.toMapLatLng(),
        anchorPos: AnchorPos.exactly(Anchor(102.5, 0)),
        builder: (_) {
          return GestureDetector(
            onTap: () {
              // We display map info window with visits only to a supervisor for other positions
              if (Session.isNotSupervisor ||
                  (Session.shift?.positionId ==
                      ShiftActivitiesStatsController.to.selectedPosition?.id))
                return;
              _showReportingPointInfoWindow(point);
            },
            child: LayoutBuilder(builder: (context, constraints) {
              const path = "assets/images";
              return Row(
                children: [
                  SvgPicture.asset(
                    point.isFinished
                        ? '$path/reporting_point_button_green.svg'
                        : point.isNotStarted
                            ? '$path/reporting_point_button_black.svg'
                            : '$path/reporting_point_button_yellow.svg',
                  ),
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxWidth: constraints.maxWidth - 40,
                    ),
                    child: createLabel(point.title),
                  ),
                  const Spacer(),
                ],
              );
            }),
          );
        },
      ),
    );
  }

  Future<void> _showReportingPointInfoWindow(ReportingPoint point) async {
    final String id = point.id;
    customInfoWindowController.hideInfoWindow!();
    final rPointLocation = point.location.toMapLatLng();
    if (rPointLocation == null) return;
    customInfoWindowController.addInfoWindow(
      EntityDetailsInfo.createReportingPointDetails(point),
      rPointLocation as mt.LatLng,
      43,
      -10,
      rPointMarkers.firstWhere((element) => element.id == id),
    );
  }
}
