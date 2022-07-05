import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/flutter_map.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/src/map/flutter_map_state.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_controller.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_marker.dart';
import 'package:bazz_flutter/modules/home_module/views/map/plugins/zoombuttons_plugin_option.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/src/layer/marker_layer.dart'
    as mk;
import 'package:bazz_flutter/modules/home_module/flutter_map/src/geo/latlng_bounds.dart'
    as bd;
import 'package:bazz_flutter/modules/home_module/flutter_map/src/layer/marker_layer.dart'
    as ml;

class FlutterMapStateEx extends FlutterMapState {
  FlutterMapStateEx(MapController mapController) : super(mapController);
}

// ignore: must_be_immutable
class FlutterMapEx extends StatefulWidget {
  // FlutterMapEx({super.key, this.controller, MapOptions? options})
  //      : mapController = mapController ?? MapController(),
  //      super(
  //           FlutterMapController: FlutterMapController,
  //           options: options,
  //           key: key);
  final MapController? controller;
  MapOptions options;

  var layers;

  var nonRotatedLayers;

  var children;

  var nonRotatedChildren;
  FlutterMapEx({
    Key? key,
    required this.options,
    this.layers = const [],
    this.nonRotatedLayers = const [],
    this.children = const [],
    this.nonRotatedChildren = const [],
    MapController? mapController,
  })  : controller = mapController ?? MapController(),
        super(key: key);
  @override
  // ignore: no_logic_in_create_state
  FlutterMapState createState() => FlutterMapState(controller!);
}

/// In here we are encapsulating all the logic required to get marker icons from url images
/// and to show clusters using the [Fluster] package.
class FlutterMapHelper {
  static Widget createCoordinateStatus(
      BuildContext context, FlutterMapController controller) {
    return Positioned(
      bottom: 10,
      left: 10,
      right: 10,
      child: Container(
          color: Colors.black54.withOpacity(0.65),
          child: Row(
            children: [
              const SizedBox(
                width: 5,
              ),
              Text(
                "Coordinate:",
                style: AppTypography.subtitle4TextStyle
                    .copyWith(fontSize: 10.0, color: AppColors.primaryAccent),
              ),
              const SizedBox(
                width: 5,
              ),
              if (controller.currentSelectedLocation != null)
                SizedBox(
                    width: 100,
                    child: Text(
                      "${controller.currentSelectedLocation.latitude.toStringAsPrecision(7)},${controller.currentSelectedLocation.longitude.toStringAsPrecision(7)}",
                      style: AppTypography.subtitle4TextStyle
                          .copyWith(fontSize: 8.0),
                    )),
              if (controller.currentSelectedLocation == null)
                Text(
                  "0.0,0.0",
                  style:
                      AppTypography.subtitle4TextStyle.copyWith(fontSize: 8.0),
                ),
              const SizedBox(
                width: 40,
              ),
              Text(
                "Selected:",
                style: AppTypography.subtitle4TextStyle
                    .copyWith(fontSize: 10.0, color: AppColors.primaryAccent),
              ),
              const SizedBox(
                width: 5,
              ),
              if (controller.currentLocation != null)
                SizedBox(
                    width: 100,
                    child: Text(
                      "${controller.currentLocation.latitude.toStringAsPrecision(7)},${controller.currentLocation.longitude.toStringAsPrecision(7)}",
                      style: AppTypography.subtitle4TextStyle
                          .copyWith(fontSize: 8.0),
                    )),
              if (controller.currentLocation == null)
                Text(
                  "0.0,0.0",
                  style:
                      AppTypography.subtitle4TextStyle.copyWith(fontSize: 8.0),
                ),
            ],
          )),
    );
  }

  static Future<Widget?> createFlutterMapWidget({
    Key? key,
    BuildContext? context,
    FlutterMapController? controller,
    bd.LatLngBounds? zoneBounds,
    bool fullscreenMap = false,
  }) async {
    TelloLogger().i("createFlutterMapWidget === > create");
    final layers = [
      /*TileLayerOptions(
            urlTemplate:
            'https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png',
            subdomains: ['a', 'b', 'c'],
            tileProvider: NonCachingNetworkTileProvider(),
          ),*/
      TileLayerOptions(
          tileProvider: controller!.tileProvider,
          urlTemplate: controller.layer.value,
          subdomains: ['a', 'b', 'c'],
          //retinaMode: true && Get.pixelRatio > 1.0,
          minZoom: AppSettings().minMapZoom,
          maxZoom: AppSettings().maxMapZoomLevel,
          maxNativeZoom: AppSettings().maxNativeMapZoomLevel,
          minNativeZoom: AppSettings().minNativeMapZoom,
          additionalOptions: {},
          errorImage: null as ImageProvider<Object>,
          placeholderImage: null as ImageProvider<Object>),
      PolygonLayerOptions(
          polygons: controller.polygons, rebuild: null as Stream<Null>),
      PolylineLayerOptions(
          polylines: controller.polylines, rebuild: null as Stream<Null>),
      CircleLayerOptions(
          circles: controller.circles, rebuild: null as Stream<Null>),
      MarkerLayerOptions(
          markers: controller.labelMarkers, rebuild: null as Stream<Null>),
      MarkerLayerOptions(
          markers: controller.eventMarkers, rebuild: null as Stream<Null>),
      MarkerLayerOptions(
          markers: controller.directionMarkers, rebuild: null as Stream<Null>),
      MarkerClusterLayerOptions(
        onClusterTap: (_) {
          final newVal = controller.mapController.state.zoom + 1;
          controller.mapController.state.move(_.point, newVal);
          controller.currentZoom = newVal;
        },
        maxClusterRadius: 50,
        disableClusteringAtZoom: AppSettings().maxMapZoomLevel.toInt(),
        size: const Size(40, 40),
        anchor: AnchorPos.align(AnchorAlign.center),
        fitBoundsOptions: FitBoundsOptions(
            padding: const EdgeInsets.all(20),
            zoom: AppSettings().minMapZoom,
            maxZoom: AppSettings().maxMapZoomLevel),
        markers: controller.markers.map((e) => e).toList(),
        onPolygonOptions: (_) {
          TelloLogger().i("onPolygonOptions");
          final Color markerColor = getColorForClusterMarkers(
              _.markers.map((e) => e.marker).toList());
          return PolygonOptions(
              borderColor: markerColor,
              color: Colors.white,
              borderStrokeWidth: 3);
        },
        polygonOptions: const PolygonOptions(
            borderColor: Colors.blueAccent,
            color: Colors.black12,
            borderStrokeWidth: 3),
        builder: (context, markers) {
          final String assetImage = getImageAssetForClusterMarkers(markers);
          /*return FloatingActionButton(
            heroTag: null,
            backgroundColor: markerColor,
            splashColor: Colors.orangeAccent,
            tooltip: "Click to zoom to cluster markers",
            child: Text(markers.length.toString()),
          );*/
          return ClipOval(
            child: Container(
                height: 40,
                width: 40,
                color: AppTheme().colors.tabBarBackground,
                child: Stack(
                  children: [
                    Image.asset(assetImage),
                    Center(
                        child: Text(
                      markers.length.toString(),
                      style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w400,
                          fontSize: 16),
                    ))
                  ],
                )),
          );
        },
        //computeSize: (
        // List<(mk.Marker)>  {  }),
        //  // ignore: avoid_types_as_parameter_names, non_constant_identifier_names
        //  onMarkersClustered: (List<(mk.Marker)> ) {  },
        //  onMarkerTap: (mk.Marker) =>{  },
        //   popupOptions: null as PopupOptions,
        //    spiderfyShapePositions: (int ,
        //    // ignore: non_constant_identifier_names
        //    Point<num> ) {  },
        // ),
      ),
    ];
    controller.mapController.layers = layers;
  }

  static String createClusterIndexMap(
      {bool? hasGreen, bool? hasRed, bool? hasGray, bool? hasBlack}) {
    var combination = "";
    if (hasGreen!) {
      combination += 'g';
    }
    if (hasRed!) {
      combination += 'r';
    }
    if (hasGray!) {
      combination += 'y';
    }
    if (hasBlack!) {
      combination += 'b';
    }
    TelloLogger().i(
        "createClusterIndexMap ===> assets/images/${combination}_cluster.png");
    return "assets/images/${combination}_cluster.png";
  }

  static String getImageAssetForClusterMarkers(markers) {
    markers.forEach((element) {
      TelloLogger().i(
          "getImageAssetForClusterMarkers === > ${(element as FlutterMarker).isEventMarker} ,, ${(element as FlutterMarker).id}");
    });

    final bool greenMode = markers.firstWhere(
            (marker) =>
                (marker as FlutterMarker) != null &&
                (marker as FlutterMarker).color == Colors.green,
            orElse: () => null!) !=
        null;
    final bool redMode = markers.firstWhere(
            (marker) =>
                (marker as FlutterMarker) != null &&
                (marker as FlutterMarker).color == Colors.red,
            orElse: () => null!) !=
        null;

    final bool greyMode = markers.firstWhere(
            (marker) =>
                (marker as FlutterMarker) != null &&
                (marker as FlutterMarker).color == Colors.grey,
            orElse: () => null!) !=
        null;

    final bool blackMode = markers.firstWhere(
            (marker) =>
                (marker as FlutterMarker) != null &&
                (marker as FlutterMarker).color == Colors.black,
            orElse: () => null!) !=
        null;

    return createClusterIndexMap(
        hasGreen: greenMode,
        hasRed: redMode,
        hasGray: greyMode,
        hasBlack: blackMode);
  }

  static Color getColorForClusterMarkers(markers) {
    Color markerColor = Colors.black;
    final bool greenMode = markers.firstWhere(
            (marker) =>
                (marker as FlutterMarker) != null &&
                (((marker as FlutterMarker).user != null &&
                        (marker as FlutterMarker).user.isOnline.value) ||
                    ((marker as FlutterMarker).position != null &&
                        (marker as FlutterMarker).position.status.value ==
                            PositionStatus.active)),
            orElse: () => null!) !=
        null;
    final bool redMode = markers.firstWhere(
            (marker) =>
                (marker as FlutterMarker) != null &&
                (((marker as FlutterMarker).position != null &&
                        (marker as FlutterMarker).position.status.value ==
                            PositionStatus.outOfRange) ||
                    (marker as FlutterMarker).isEventMarker),
            orElse: () => null!) !=
        null;

    final bool greyMode = markers.firstWhere(
            (marker) =>
                (marker as FlutterMarker) != null &&
                (((marker as FlutterMarker).user != null &&
                        !(marker as FlutterMarker).user.isOnline()) ||
                    ((marker as FlutterMarker).position.worker() != null &&
                        !(marker as FlutterMarker)
                            .position
                            .worker()
                            .isOnline
                            .value)),
            orElse: () => null!) !=
        null;

    if (redMode) {
      markerColor = Colors.red;
    } else if (greyMode) {
      markerColor = Colors.grey;
    } else if (greenMode) {
      markerColor = Colors.lightGreen;
    }
    return markerColor;
  }
}
