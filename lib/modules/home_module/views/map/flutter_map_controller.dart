import 'dart:async';
import 'dart:math' as math;

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/audio_locations_model.dart';
import 'package:bazz_flutter/models/audio_message.dart';
import 'package:bazz_flutter/models/coordinates_model.dart';
import 'package:bazz_flutter/models/group_model.dart';
import 'package:bazz_flutter/models/incoming_event.dart';
import 'package:bazz_flutter/models/location_details_model.dart';
import 'package:bazz_flutter/models/perimeter.dart';
import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/models/zone.dart' as zn;
import 'package:bazz_flutter/modules/home_module/flutter_map/flutter_map.dart';
import 'package:bazz_flutter/modules/home_module/flutter_map/plugin_api.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_circle.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_marker.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_polygon.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_polyline.dart';
import 'package:bazz_flutter/modules/home_module/views/map/plugins/api_osrm.dart';
import 'package:bazz_flutter/modules/home_module/views/map/plugins/storage_caching_tile_provider.dart';
import 'package:bazz_flutter/modules/home_module/views/map/plugins/tile_storage_caching_manager.dart';
import 'package:bazz_flutter/modules/home_module/widgets/history_audio_player.dart';
import 'package:bazz_flutter/modules/location_tracking/location_service.dart';
import 'package:bazz_flutter/modules/message_history/message_history_controller.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/snack_bar_display.dart';
import 'package:bazz_flutter/shared_widgets/entity_details_info.dart';
import 'package:bazz_flutter/utils/flutter_custom_info_window.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:eventify/eventify.dart' as evf;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:latlong/latlong.dart';
import 'package:maps_toolkit/maps_toolkit.dart' as map_tools;
import 'package:supercharged/supercharged.dart';
import 'package:vector_math/vector_math.dart' as math_vector;

class FlutterMapController extends GetxController {
  static FlutterMapController get to => Get.find();

  late OnClose onCloseHandler;
  late OnPlayerReady onPlayerReadyHandler;
  late OnPlay onPlayHandler;
  late OnPaused onPausedHandler;
  final customInfoWindowController = FlutterCustomInfoWindowController();
  String? _currentInfoWindowId;
  final _currentZoom = 10.0.obs;

  final RxBool _showPlayer$ = false.obs;

  bool get showPlayer$ => _showPlayer$.value;

  set showPlayer$(bool b) => _showPlayer$.value = b;

  double get currentZoom => _currentZoom.value;

  set currentZoom(double i) => _currentZoom.value = i;

  bool canChangeZoom = true;

  bool showingLabels = false;
  String? trackingUserId;

  final polygons = <FlutterPolygon>[];
  final markers = <FlutterMarker>[];
  final eventMarkers = <FlutterMarker>[];
  final labelMarkers = <FlutterMarker>[];
  final directionMarkers = <FlutterMarker>[];
  final polylines = <FlutterPolyline>[];
  final circles = <FlutterCircle>[];

  final topActionButtons$ = <Widget>[].obs;

  void displayTopActionButtons$(List<Widget> buttons) {
    topActionButtons$.addAllIf(() => topActionButtons$.isEmpty, buttons);
  }

  String? currentGroup;
  final subscriptions = <StreamSubscription>[];
  late StreamSubscription _activeGroupSub;

  late LatLng initialLatLngCameraZoom;
  late zn.Zone zone;
  late List<Coordinates> zoneInnerPerimeter;
  late List<Coordinates> zoneOuterPerimeter;
  late int zoneTolerance;
  late LatLngBounds zoneBounds;
  late StreamSubscription<int> _audioMessageSubscription;
  final double _labelWidth = 150.0;
  final double _initialPositionIconSize = 35.0;
  final double _eventMarkerIconSize = 40;
  final double _initialPositionMarkerHeight = 62.0;

  final double _markerIconSize = 42.0;
  final double _markerIconHeight = 67.0;
  RxBool showPerimeterTolerance$ = true.obs;

  final isOnline$ = false.obs;

  bool get showPerimeterTolerance => showPerimeterTolerance$.value;

  bool get isOnline => isOnline$.value;
  late StreamSubscription _isOnlineSub;
  late StreamSubscription _showToleranceSub;
  late evf.Listener locationUpdateSub;

  late Rx<LatLng>? currentLocation$;

  LatLng get currentLocation => currentLocation$!.value;

  set currentLocation(LatLng i) => currentLocation$!.value = i;

  RxBool showCoordinateStatus$ = false.obs;

  bool get showCoordinateStatus => showCoordinateStatus$.value;

  late Rx<LatLng> currentSelectedLocation$;

  LatLng get currentSelectedLocation => currentSelectedLocation$.value;

  set currentSelectedLocation(LatLng i) => currentSelectedLocation$.value = i;
  Rx<MapController> mapController$ = MapController().obs;

  MapController get mapController => mapController$.value;

  //TODO: define an enum for the view options
  late RxString mapType = "m".obs;

  //TODO: refactor it to the centralized place
  RxString layer = "${AppSettings().externalTileServerUrl}{z}/{x}/{y}.png".obs;
  final PopupController popupController = PopupController();
  Rx<StorageCachingTileProvider> tileProvider$ =
      StorageCachingTileProvider().obs;

  StorageCachingTileProvider get tileProvider => tileProvider$.value;

  Completer zoneInit = Completer();

  late RxPosition _selectedPosition;

  /// Used to draw a temporary position marker for outOfRange or alertnessFailed event, when a user
  /// clicks on one of them to see on the map. Gets disposed when a user leaves the map

  bool displayTopActionButtons = true;

  Completer mapCreated = Completer();

  final List<String> _routePolylines = [];

  @override
  Future<void> onInit() async {
    TelloLogger().i("flutter map onInit");
    TelloLogger().i("onInit map ===> ${layer.value}");
    await initMapController();
    _activeGroupSub = HomeController.to.activeGroup$.listen((aGroup) async {
      if (aGroup == null) return;

      await initZone(zoomToZone: false);
    });

    _showToleranceSub = showPerimeterTolerance$.listen((val) async {
      await initZone(zoomToZone: false);
    });

    initAudioMessageLocations();
    await initZone(zoomToZone: false);
    super.onInit();
  }

  Future<void> initMapController() async {
    await TileStorageCachingManager.cleanCache();
    mapController$.value = MapController();
    currentZoom = AppSettings().minMapZoom;
  }

  void updateMapLayout(
      {List<RxPosition>? positions, bool skipClusterCheck = false}) {
    update();
  }

  void initAudioMessageLocations() {
    onPlayerReadyHandler = () async {
      TelloLogger().i("onReadyHandler");
      await _buildHistoryMarkerDisplay();
    };

    onCloseHandler = () async {
      await _closeHistoryPlayer();
    };
  }

  Future<void> _closeHistoryPlayer() async {
    if (!showPlayer$) return;
    TelloLogger().i("onCloseHandler");
    _audioMessageSubscription.cancel();
    removeMessageHistoryPolyline('audioMessagePolygon');
    final AudioMessage currentAudioMessage =
        MessageHistoryController.to.currentTrack!.value;
    if (currentAudioMessage.ownerPosition != null) {
      markers.removeWhere((m) =>
          m.id ==
          '${currentAudioMessage.ownerPosition!.id}_worker_history_player');
    } else {
      markers.removeWhere(
          (m) => m.id == '${currentAudioMessage.owner.id}_history_player');
    }
    showPlayer$ = false;
    MessageHistoryController.to.stopPlayer();
    hideInfoWindowFullScreen();
    initZone();
  }

  Future<void> _buildHistoryMarkerDisplay() async {
    markers.clear();
    eventMarkers.clear();
    labelMarkers.clear();
    directionMarkers.clear();
    _cancelSubscriptions();

    final AudioMessage currentAudioMessage =
        MessageHistoryController.to.currentTrack!.value;
    if (currentAudioMessage.audioLocations == null ||
        currentAudioMessage.audioLocations!.coordinates.isEmpty) return;
    if (currentAudioMessage.ownerPosition != null) {
      final RxPosition existingPos =
          HomeController.to.activeGroup$.value.members.positions.firstWhere(
              (element) => element.id == currentAudioMessage.ownerPosition!.id,
              orElse: () => null!);
      final RxPosition pos = RxPosition(
          id: currentAudioMessage.ownerPosition!.id,
          title: currentAudioMessage.ownerPosition!.title,
          worker: existingPos.worker,
          workerLocation: existingPos.workerLocation,
          positionType: existingPos.positionType,
          status: currentAudioMessage.ownerPosition!.status.obs,
          shiftDuration: existingPos.shiftDuration,
          shiftStartedAt: existingPos.shiftStartedAt,
          alertCheckState:
              currentAudioMessage.ownerPosition!.alertCheckState.obs,
          statusUpdatedAt: currentAudioMessage.ownerPosition!.statusUpdatedAt,
          alertCheckStateUpdatedAt:
              currentAudioMessage.ownerPosition!.alertCheckStateUpdatedAt,
          coordinates: null as Coordinates,
          customer: null as Rx<RxUser>,
          distance: 0 as int,
          hasTours: null as bool,
          imageSrc: '',
          parentGroup: null as RxGroup,
          parentId: '',
          parentPosition: null as RxPosition,
          perimeter: null as Perimeter,
          qrCode: '');

      if (pos.workerLocation() != null)
        await _drawPositionMarker(pos,
            posId: '${pos.id}_worker_history_player');

      final audioLatLng =
          (currentAudioMessage.audioLocations!.coordinates.isNotEmpty)
              ? currentAudioMessage.audioLocations!.coordinates.first.coordinate
                  .toMapLatLng()
              : null;

      if (audioLatLng != null) _animateToLatLng(audioLatLng);
    } else {
      final RxUser user = currentAudioMessage.owner;
      if (user.location() != null)
        await _drawUserMarker(user, userId: '${user.id}_history_player');
    }
    TelloLogger().i("buildHistoryMarkerDisplay");

    drawMessageHistoryPolyline(
        'audioMessagePolygon', currentAudioMessage.audioLocations!);

    updateMapLayout();
    _audioMessageSubscription =
        MessageHistoryController.to.currentProgress.listen((val) async {
      final AudioMessage currentMessage =
          MessageHistoryController.to.currentTrack!.value;

      if (currentMessage.audioLocations != null) {
        final foundCoordinate = currentMessage.audioLocations!.coordinates
            .lastWhere((element) => element.timeMs < val * 1000,
                orElse: () => null!);
        if (foundCoordinate != null) {
          final AudioMessage currentAudioMessage =
              MessageHistoryController.to.currentTrack!.value;
          if (currentAudioMessage.ownerPosition != null) {
            final pos = HomeController.to.activeGroup.members.positions
                .firstWhere((element) =>
                    element.id == currentAudioMessage.ownerPosition!.id);
            if (pos.workerLocation() != null)
              await _drawPositionMarker(pos,
                  posId: '${pos.id}_worker_history_player');
          } else {
            final user = HomeController.to.activeGroup.members.users.firstWhere(
                (element) => element.id == currentAudioMessage.owner.id);
            if (user.location() != null)
              await _drawUserMarker(user, userId: '${user.id}_history_player');
          }
        }
        updateMapLayout();
      }
    });
  }

  void drawMessageHistoryPolyline(String id, AudioLocations audioLocations) {
    final List<LatLng> polylineCoordinates = [];
    if ((audioLocations.coordinates.length) < 2) return;
    for (final point in audioLocations.coordinates) {
      if (point.coordinate == null) return;
      TelloLogger()
          .i("drawMessageHistoryPolyline ${point.coordinate.longitude}");
      polylineCoordinates
          .add(LatLng(point.coordinate.latitude, point.coordinate.longitude));
    }

    polylines.add(FlutterPolyline(
      id: id,
      color: AppColors.sos,
      points: polylineCoordinates,
      strokeWidth: 5,
    ));
  }

  void removeMessageHistoryPolyline(String id) {
    polylines.removeWhere((p) => p.id == id);
  }

  @override
  Future<void> onReady() async {
    //await initZone();
    super.onReady();
  }

  @override
  void onClose() {
    TelloLogger().i("flutter map Call onClose ");
    _cancelSubscriptions();
    _showToleranceSub.cancel();
    _isOnlineSub.cancel();
    locationUpdateSub.cancel();
    onPlayerReadyHandler = null as VoidCallback;
    onCloseHandler = null as VoidCallback;
    _activeGroupSub.cancel();
    customInfoWindowController.dispose();
    super.dispose();
  }

  void _cancelSubscriptions() {
    for (final sub in subscriptions) {
      sub.cancel();
    }
    subscriptions.clear();
  }

  Future<void> _animateToLatLng(LatLng latLng) async {
    mapController.move(latLng, currentZoom);
  }

  Future<void> animateToLatLngZoom(LatLng latLng,
      {double zoomLevel = 16, bool? keepZoom}) async {
    await mapController.onReady;
    await mapController.state.initCompleter.future;
    mapController.move(latLng, zoomLevel);
  }

  bool _moveToLatLngZoom(LatLng latLng, {double zoomLevel = 16}) {
    return mapController.move(latLng, zoomLevel);
  }

  Future showCurrentLocation({bool fast = false}) async {
    LatLng latLng;
    if (Session.hasShift) {
      final pos = HomeController.to.activeGroup.members.positions.firstWhere(
          (element) => element.id == Session.shift!.currentPosition!.id);
      latLng = pos.workerLocation().toMapLatLng();
    } else {
      final user = HomeController.to.activeGroup.members.users
          .firstWhere((element) => element.id == Session.user!.id);
      latLng = user.location().coordinates!.toMapLatLng();
    }

    if (latLng == null) {
      return Get.showSnackbar(GetBar(
        backgroundColor: AppColors.error,
        message: LocalizationService().of().systemCannotTrackLocation,
        titleText: Text(LocalizationService().of().locationNotAvailTitle,
            style: AppTypography.captionTextStyle),
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppColors.brightIcon),
      ));
    }

    if (fast) {
      _moveToLatLngZoom(latLng, zoomLevel: AppSettings().maxMapZoomLevel - 1);
    } else {
      animateToLatLngZoom(latLng, zoomLevel: AppSettings().maxMapZoomLevel - 1);
    }
  }

  Future setPositionForZoom(RxPosition pos, {bool fast = false}) async {
    if (pos.workerLocation == null) return;

    final latLngCameraZoom =
        LatLng(pos.workerLocation().latitude, pos.workerLocation().longitude);
    await animateToLatLngZoom(latLngCameraZoom);
  }

  bool limitMapBounds() {
    return Session.hasShift;
  }

  void showCurrentZone() {
    setZoneBounds();
    mapController.fitBounds(zoneBounds);
  }

  bool isMarkerClustered(String id) {
    if (mapController.mapState == null ||
        mapController.mapState!.layers == null) {
      TelloLogger().i("isMarkerClustered ===> FALSE");
      return false;
    }
    final layer = mapController.mapState!.layers
            .firstWhere((element) => element is MarkerClusterLayer)
        as MarkerClusterLayer;
    final res = layer.isMarkerClustered(id);
    TelloLogger().i("isMarkerClustered ===> RESULT $res");
    return res;
  }

  void setZoneBounds() {
    zone = HomeController.to.activeGroup.zone!;

    zoneInnerPerimeter = zone.perimeter.polygonPerimeter.perimeter;
    zoneOuterPerimeter = zone.perimeter.polygonPerimeter.perimeterWithTolerance;
    zoneTolerance = zone.perimeter.tolerance;

    if (zoneTolerance > 0 && zoneOuterPerimeter.isNotEmpty) {
      zoneBounds = LatLngBounds.fromPoints(zone
          .perimeter.polygonPerimeter.perimeterWithTolerance
          .map((e) => LatLng(e.latitude, e.longitude))
          .toList());
    } else {
      zoneBounds = LatLngBounds.fromPoints(zone
          .perimeter.polygonPerimeter.perimeter
          .map((e) => LatLng(e.latitude, e.longitude))
          .toList());
    }
    if (limitMapBounds()) {
      final oorCoordinates = HomeController.to.activeGroup.members.outOfRange
          .map((p) => p.workerLocation())
          .where((loc) => loc != null && !loc.isEmpty())
          .toList();
      final activeUsersCoordinates = HomeController
          .to.activeGroup.members.activeUsers
          .map((u) => u.location().coordinates)
          .where((c) => c != null && !c.isEmpty())
          .toList();
      final perimeter = zone.perimeter.polygonPerimeter.perimeterWithTolerance
          .map((e) => map_tools.LatLng(e.latitude, e.longitude));

      final filteredOorCoordinates = oorCoordinates
          .filter((element) =>
              map_tools.PolygonUtil.containsLocation(
                  map_tools.LatLng(element.latitude, element.longitude),
                  perimeter.toList(),
                  false) ==
              false)
          .toList();

      final filteredActiveUsersCoordinates = activeUsersCoordinates.filter(
          (element) =>
              map_tools.PolygonUtil.containsLocation(
                  map_tools.LatLng(element!.latitude, element.longitude),
                  perimeter.toList(),
                  false) ==
              false);

      if (filteredOorCoordinates.isNotEmpty) {
        filteredOorCoordinates.forEach((element) {
          zoneBounds.extend(element.toMapLatLng());
        });
      }

      if (filteredActiveUsersCoordinates.isNotEmpty) {
        filteredActiveUsersCoordinates.forEach((element) {
          zoneBounds.extend(element!.toMapLatLng());
        });
      }
    }
  }

  void clearEventRoutes() {
    for (final routePolyline in _routePolylines) {
      polylines.removeWhere((element) => element.id == routePolyline);
    }

    circles.removeWhere((element) => element.id == 'endNavigationPath');
    circles.removeWhere((element) => element.id == 'startNavigationPath');

    _routePolylines.clear();
  }

  void showEvent(IncomingEvent event) {
    assert(event.hasLocation);

    if (!event.hasLocation) {
      Get.showSnackbarEx(GetBar(
        backgroundColor: Colors.red,
        message: 'The event has no location!',
        duration: const Duration(seconds: 3),
      ));
      return;
    }

    markers.clear();
    eventMarkers.clear();
    labelMarkers.clear();
    directionMarkers.clear();
    _cancelSubscriptions();

    HomeController.to.gotoBottomNavTab(BottomNavTab.map);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _drawEventMarker(event, ignoreShowOnMap: true);
      _showEventInfoWindow(event);

      if (event.config.policy.drawPath) buildRouteToEvent(event);
      animateToLatLngZoom(event.location!.coordinates.toMapLatLng(),
          zoomLevel: 18.0);
    });
  }

  Future<void> buildRouteToEvent(IncomingEvent event) async {
    assert(event.hasLocation);

    if (!event.hasLocation) {
      Get.showSnackbarEx(GetBar(
        backgroundColor: Colors.red,
        message: 'The event has no location!',
        duration: const Duration(seconds: 3),
      ));
    }

    await mapController.onReady;
    clearEventRoutes();

    final Position myPosition = await LocationService().getCurrentPosition();
    late List<List<LatLng>> result;

    try {
      final calculator = ApiOSRM();
      result = myPosition != null
          ? await calculator.getRoute(
              myPosition.longitude,
              myPosition.latitude,
              event.location!.coordinates.longitude,
              event.location!.coordinates.latitude,
            )
          : null!;
    } catch (e, s) {
      TelloLogger().e('getRouteBetweenCoordinates error: $e', stackTrace: s);
    }

    if (result.isEmpty) {
      Get.showSnackbarEx(GetBar(
        backgroundColor: Colors.red,
        message: "Can't build a route to the event",
        duration: const Duration(seconds: 3),
      ));
    } else {
      int index = 0;
      List<LatLng> polylineCoordinates;
      for (final route in result) {
        polylineCoordinates = [];
        for (final point in route) {
          polylineCoordinates.add(point);
        }

        polylineCoordinates.add(event.location!.coordinates.toMapLatLng());
        final String id = '${event.typeId}NavigationPath_${index++}';

        polylines.add(FlutterPolyline(
            isDotted: true,
            id: id,
            color: Colors.blueAccent,
            points: polylineCoordinates,
            strokeWidth: 4));

        _routePolylines.add(id);
      }
    }
    circles.addAll([
      FlutterCircle(
        id: "startNavigationPath",
        point: LatLng(myPosition.latitude, myPosition.longitude),
        radius: 4,
        color: Colors.blueAccent,
        borderColor: Colors.blue,
        borderStrokeWidth: 1,
      ),
      FlutterCircle(
        id: "endNavigationPath",
        point: event.location!.coordinates.toMapLatLng(),
        radius: 4,
        color: Colors.blueAccent,
        borderColor: Colors.blue,
        borderStrokeWidth: 1,
      )
    ]);

    updateMapLayout();

    mapController.fitBounds(GeoUtils.mapBoundsFromCoordinatesList([
      Coordinates(
        latitude: myPosition.latitude,
        longitude: myPosition.longitude,
      ),
      event.location!.coordinates
    ]));
  }

  // Future<void> onFullscreenPressed({bool exit = false}) async {
  //   hideInfoWindow();
  //   if (exit) {
  //     Get.back();
  //   } else {
  //     await Get.toNamed(AppRoutes.mapFullscreen);
  //   }
  //   hideInfoWindowFullScreen();
  //   await initMapController();
  //   await initZone();
  // }

  bool isCurrentPosition(RxPosition pos) {
    return Session.hasShift && Session.shift!.positionId == pos.id;
  }

  bool isCurrentUser(RxUser user) {
    return !Session.hasShift && Session.user!.id == user.id;
  }

  Widget _buildPositionMarkerWidget(RxPosition pos, {String? posId}) {
    final bool isTransmitting = pos.isTransmitting();
    final bool isAlertnessFailed =
        pos.alertCheckState() == AlertCheckState.failed;

    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      _buildWorkerLabelWidget(pos.worker.value.fullName ?? pos.title),
      const SizedBox(
        height: 2,
      ),
      SizedBox(
          width: _markerIconSize, //+ (_markerIconSize * 0.18),
          height: _markerIconSize,
          child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _showInfoWindow(pos: pos, id: posId!, user: null as RxUser);
              },
              child: Stack(children: [
                Positioned(
                    top: 0,
                    left: 0,
                    child: SizedBox(
                        width: _markerIconSize,
                        height: _markerIconSize,
                        child: Image.asset(_markerImageForPosition(pos)))),
                if (needToShowLabel() && pos.worker() != null)
                  Positioned(
                      top: 3,
                      left: _markerIconSize * 0.11,
                      child: ClipOval(
                          child: SizedBox(
                              height: _markerIconSize * 0.77,
                              width: _markerIconSize * 0.77,
                              child: CachedNetworkImage(
                                  imageUrl: pos.worker().avatar))))
                else
                  Container(),
                if (isTransmitting)
                  Positioned(
                      top: 2,
                      left: _markerIconSize * 0.53,
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              Image.asset('assets/images/speaker_green.png')))
                else
                  Container(),
                if (isAlertnessFailed)
                  Positioned(
                      top: _markerIconSize * 0.5,
                      right: _markerIconSize * 0.53,
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child: Image.asset(
                              'assets/images/alertness_failed_icon.png')))
                else
                  Container(),
                if (pos.worker().location().locationDetails != null)
                  drawSpeedWidget(pos.worker().location().locationDetails!)
                /* Positioned(
                      top: 0,
                      left: 11,
                      child: SizedBox(width: 20, height: 20, child: Image.asset('assets/images/marker_empty_blue.png')))*/
                else
                  Container(),
              ])))
    ]);
  }

  Widget _buildUserMarkerWidget(RxUser user, {String? userId}) {
    final bool isTransmitting = user.isTransmitting();
    final bool currentUser = isCurrentUser(user);
    TelloLogger().i("_buildUserMarkerWidget ${user.fullName}");
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      _buildWorkerLabelWidget(user.fullName!),
      const SizedBox(
        height: 2,
      ),
      SizedBox(
          width: _markerIconSize, //+ (_markerIconSize * 0.18),
          height: _markerIconSize,
          child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _showInfoWindow(
                    user: user, id: userId!, pos: null as RxPosition);
              },
              child: Stack(children: [
                Positioned(
                    top: 0,
                    left: 0,
                    child: SizedBox(
                        width: _markerIconSize,
                        height: _markerIconSize,
                        child: Image.asset(_markerImageForUser(user)))),
                if (needToShowLabel())
                  Positioned(
                      top: 2,
                      left: _markerIconSize * 0.11,
                      child: ClipOval(
                          child: SizedBox(
                              height: _markerIconSize * 0.77,
                              width: _markerIconSize * 0.77,
                              child:
                                  CachedNetworkImage(imageUrl: user.avatar))))
                else
                  Container(),
                if (isTransmitting)
                  Positioned(
                      top: 5,
                      left: _markerIconSize * 0.53,
                      child: SizedBox(
                          width: 20,
                          height: 20,
                          child:
                              Image.asset('assets/images/speaker_green.png')))
                else
                  Container(),
                if (user.location().locationDetails != null)
                  drawSpeedWidget(user.location().locationDetails!)
                /*Positioned(
                      top: 0,
                      left: 11,
                      child: SizedBox(width: 20, height: 20, child: Image.asset('assets/images/marker_empty_blue.png')))*/
                else
                  Container(),
              ])))
    ]);
  }

  Widget drawSpeedWidget(LocationDetails locationDetails) {
    return locationDetails.speed > 5.0
        ? Positioned(
            top: 0,
            left: 13,
            child: Stack(children: [
              Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white,
                      border: Border.all(color: Colors.red, width: 2.0))),
              Positioned(
                  left: locationDetails.speed > 99 ? 3 : 5,
                  top: 4,
                  child: Text(
                    locationDetails.speed.toStringAsFixed(0),
                    style: const TextStyle(
                      fontSize: 7.0,
                      color: Colors.black,
                      fontWeight: FontWeight.w600,
                    ),
                  ))
            ]))
        : Container();
  }

  bool needToShowLabel() {
    return currentZoom >= AppSettings().minLabelShowingZoom;
  }

  Widget createLabel(String text) {
    return needToShowLabel()
        ? Container(
            height: 22,
            width: 100,
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
              borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(3),
                  topRight: Radius.circular(3),
                  bottomLeft: Radius.circular(3),
                  bottomRight: Radius.circular(3)),
            ),
            child: Padding(
                padding: const EdgeInsets.all(2),
                child: Text(text,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.markerCaptionTextStyle
                        .copyWith(fontSize: 12))),
          )
        : Container();
  }

  Widget createDistanceLabel(String text) {
    return Container(
      color: AppColors.brightText,
      height: 20,
      width: 120,
      child: Padding(
          padding: const EdgeInsets.all(2),
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTypography.markerCaptionTextStyle
                .copyWith(fontSize: 10, color: AppColors.error),
          )),
    );
  }

  Widget _buildInitialPositionLabelWidget(RxPosition pos) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
      child: createLabel(pos.title),
    );
  }

  Widget _buildWorkerLabelWidget(String fullName) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 0, 0, 0),
      child: createLabel(fullName),
    );
  }

  Widget _buildDistanceLabelWidget(String text) {
    return Stack(children: [
      Positioned(
        top: 0,
        left: 10,
        child: createDistanceLabel(text),
      ),
    ]);
  }

  Widget _buildInitialPositionMarkerWidget(RxPosition pos) {
    return Column(mainAxisAlignment: MainAxisAlignment.end, children: [
      _buildInitialPositionLabelWidget(pos),
      const SizedBox(
        height: 2,
      ),
      SizedBox(
          width: _initialPositionIconSize,
          height: _initialPositionIconSize,
          child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () {
                _showInitialPositionInfoWindow(pos: pos);
              },
              child: Image.asset(
                _initialPositionIconFromStatus(pos),
                width: _initialPositionIconSize,
                height: _initialPositionIconSize,
              ))),
    ]);
  }

  Future<void> _drawInitialPositionMarker(RxPosition pos) async {
    final String id = 'position_location_${pos.id}';
    markers.removeWhere((element) => element.id == id);
    markers.add(FlutterMarker(
        id: id,
        controller: mapController,
        width: _labelWidth,
        height: _initialPositionMarkerHeight,
        point: pos.coordinates.toMapLatLng(),
        builder: (ctx) => _buildInitialPositionMarkerWidget(pos),
        anchorPos: AnchorPos.align(AnchorAlign.top),
        position: pos,
        color: _initialPositionColorFromStatus(pos)));
  }

  Future<void> _removePositionMarker(RxPosition pos,
      {String? posId, String? labId}) async {
    final id = posId ?? '${pos.id}worker';
    final String labelId = labId ?? '${pos.id}_pos_label';
    markers.removeWhere((p) => p.id == id);
    labelMarkers.removeWhere((element) => element.id == labelId);

    removeDirectionAndCircle(pos.id);
  }

  Future<void> _drawPositionMarker(RxPosition pos,
      {String? posId, bool withDirection = false}) async {
    assert(pos.workerLocation() != null);

    final id = posId ?? '${pos.id}worker';

    markers.removeWhere((p) => p.id == id);
    final marker = FlutterMarker(
      id: id,
      controller: mapController,
      width: _labelWidth,
      height: _markerIconHeight,
      point: pos.workerLocation().toMapLatLng(),
      builder: (ctx) => _buildPositionMarkerWidget(pos, posId: posId),
      anchorPos: AnchorPos.align(AnchorAlign.top),
      position: pos,
      color: _positionColorFromStatus(pos),
    );
    markers.add(marker);

    if (withDirection && pos.worker().location().locationDetails != null) {
      drawDirectionAndAccuracy(id, pos.workerLocation().toMapLatLng(),
          pos.worker().location().locationDetails!);
    }
    //await _drawDistanceLine(pos: pos);
  }

  Future<void> _removeUserMarker(RxUser user) async {
    markers.removeWhere((u) => u.id == user.id);
    final String labelId = '${user.id}_user_label';
    labelMarkers.removeWhere((element) => element.id == labelId);

    removeDirectionAndCircle(user.id);
  }

  Future<void> _drawUserMarker(RxUser user,
      {String? userId, bool withDirection = false}) async {
    assert(user.location() != null);

    final String id = userId ?? user.id;
    markers.removeWhere((u) => u.id == id);
    markers.add(FlutterMarker(
        id: id,
        controller: mapController,
        point: user.location().coordinates!.toMapLatLng(),
        width: _labelWidth,
        height: _markerIconHeight,
        builder: (ctx) => _buildUserMarkerWidget(user, userId: id),
        anchorPos: AnchorPos.align(AnchorAlign.top),
        user: user,
        color: _markerColorForUser(user)));

    if (withDirection && user.location().locationDetails != null) {
      TelloLogger()
          .i("drawDirectionAndAccuracy ==> check for ${user.fullName}");
      drawDirectionAndAccuracy(id, user.location().coordinates!.toMapLatLng(),
          user.location().locationDetails!);
    }
  }

  void removeDirectionAndCircle(String id) {
    final accuracyCircleId = "accuracyCircle$id";
    circles.removeWhere((u) => u.id == accuracyCircleId);

    final directionId = "direction$id";
    directionMarkers.removeWhere((u) => u.id == directionId);
  }

  void drawDirectionAndAccuracy(
      String id, LatLng location, LocationDetails locationDetails) {
    final accuracyCircleId = "accuracyCircle$id";
    circles.removeWhere((u) => u.id == accuracyCircleId);

    final directionId = "direction$id";
    directionMarkers.removeWhere((u) => u.id == directionId);

    if (currentZoom < 16 || isMarkerClustered(id)) {
      TelloLogger().i("drawDirectionAndAccuracy ==> 00000");
      return;
    }

    circles.addAll({
      FlutterCircle(
          id: accuracyCircleId,
          point: location,
          radius: locationDetails.accuracy,
          color: Colors.blueAccent.withOpacity(0.4),
          borderColor: Colors.blue,
          borderStrokeWidth: 1),
    });

    directionMarkers.add(FlutterMarker(
      id: directionId,
      controller: mapController,
      point: location,
      width: _labelWidth,
      height: _markerIconHeight,
      builder: (ctx) {
        return Transform.rotate(
            angle: GeoUtils.degreeToRadian(locationDetails.heading),
            child: Image.asset(
              "assets/images/beam_marker.png",
              width: 32,
              height: 32,
            ));
      },
      anchorPos: AnchorPos.align(AnchorAlign.center),
    ));
  }

  Future<void> initZone({bool zoomToZone = true}) async {
    TelloLogger().i("INIT ZONE 1111");
    //TODO: return if the activeGroup is the same
    if (HomeController.to.activeGroup != null) {
      if (showPlayer$) return;

      zoneInit = Completer();
      updateMapLayout();
      _cancelSubscriptions();
      TelloLogger().i("INIT ZONE ${HomeController.to.activeGroup.title}");
      setZoneBounds();

      polygons.clear();
      markers.clear();
      eventMarkers.clear();
      labelMarkers.clear();
      directionMarkers.clear();
      circles.clear();
      polylines.clear();

      if (zoneInnerPerimeter != null && zoneInnerPerimeter.isNotEmpty) {
        if (HomeController.to.activeGroup.id != currentGroup) {
          currentGroup = HomeController.to.activeGroup.id;
          // if (zoomToZone) {
          //   showCurrentZone();
          // }
        }
        _drawZonePerimeter(zone.id, zone.perimeter);
        TelloLogger().i(
            "INIT ZONE number of positions ${HomeController.to.activeGroup.members.positions.length}");

        for (final pos in HomeController.to.activeGroup.members.positions) {
          if (pos.perimeter != null) {
            TelloLogger().i("MapController: position status - ${pos.title}");
            await _drawPositionPerimeter(pos);
          }
          await _drawInitialPositionMarker(pos);
          if (pos.worker() != null &&
              pos.workerLocation() != null &&
              pos.status() != PositionStatus.inactive) {
            TelloLogger().i("Create Marker for position - ${pos.status()}");
            await _drawPositionMarker(pos);
          }
          subscriptions.add(pos.status.listen((status) async {
            if (pos.worker() == null) {
              _removePositionMarker(pos);
            } else {
              if (pos.workerLocation() != null) await _drawPositionMarker(pos);
            }
            updateMapLayout();
          }));

          subscriptions.add(pos.workerLocation.listen((wLoc) async {
            if (wLoc == null) return;

            _drawPositionMarker(pos, withDirection: true);
            if (pos.worker().tracking()) {
              _animateToLatLng(wLoc.toMapLatLng());
            }

            if (pos.worker().drawingPath()) {
              _drawMarkerPath(pos.worker().id, wLoc.toMapLatLng());
            }

            if ((customInfoWindowController.isVisible.call()) &&
                _currentInfoWindowId == pos.id) {
              _showInfoWindow(pos: pos, id: '', user: null as RxUser);
            }

            setZoneBounds();

            updateMapLayout(positions: [pos]);
          }));

          subscriptions.add(pos.isTransmitting.listen((transmitting) async {
            if (pos.workerLocation() != null) await _drawPositionMarker(pos);
            updateMapLayout();
          }));

          subscriptions.add(pos.alertCheckState.listen((state) async {
            if (pos.workerLocation() != null) await _drawPositionMarker(pos);
            updateMapLayout();
          }));
        }

        for (final user in HomeController.to.activeGroup.members.users) {
          if (user.hasActiveSession.value) {
            final onPosition =
                Session.hasShiftStarted! && user.id == Session.user!.id;
            final existsAsPosition = HomeController
                    .to.activeGroup.members.positions
                    .firstWhere((pos) => pos.worker.value.id == user.id,
                        orElse: () => null!) !=
                null;
            if (onPosition && existsAsPosition) {
              continue;
            }
            TelloLogger().i("Show User ${user.fullName} ==> $onPosition");
            if (user.location() != null &&
                !onPosition &&
                user.hasActiveSession()) {
              await _drawUserMarker(user);
            }
          }
          subscriptions.add(user.hasActiveSession.listen((isLoggedIn) async {
            if (isLoggedIn) {
              if (user.location() != null) {
                if (user.location() != null) await _drawUserMarker(user);
                updateMapLayout();
              }
            } else {
              _removeUserMarker(user);
            }

            updateMapLayout();
          }));

          subscriptions.add(user.isOnline.listen((online) async {
            if (user.location() != null) await _drawUserMarker(user);
            updateMapLayout();
          }));

          subscriptions.add(user.location.listen((loc) async {
            if (loc == null) return;

            if (user.id == Session.user!.id && Session.hasShift) {
              return;
            }
            TelloLogger().i(
                "user.location.listen ===> ${user.location().locationDetails?.speed}");
            await _drawUserMarker(user, withDirection: true);

            if (user.tracking()) {
              _animateToLatLng(loc.coordinates!.toMapLatLng());
            }

            if (user.drawingPath()) {
              _drawMarkerPath(user.id, loc.coordinates!.toMapLatLng());
            }

            if ((customInfoWindowController.isVisible.call()) &&
                _currentInfoWindowId == user.id) {
              _showInfoWindow(user: user, id: '', pos: null as RxPosition);
            }

            setZoneBounds();

            updateMapLayout();
          }));

          subscriptions.add(user.isTransmitting.listen((transmitting) async {
            if (user.location() != null) await _drawUserMarker(user);
            updateMapLayout();
          }));
        }

        for (final event in HomeController.to.activeGroup.events$) {
          if (event.hasLocation) {
            _drawEventMarker(event);
          }
        }

        subscriptions
            .add(HomeController.to.activeGroup.events$.listen((events) {
          //eventMarkers.clear();
          markers.removeWhere((element) => element.isEventMarker == true);
          for (final event in events) {
            if (event.hasLocation) {
              _drawEventMarker(event);
            }
          }
          updateMapLayout();
        }));

        if (!zoneInit.isCompleted) zoneInit.complete();
      }
    }
    TelloLogger().i("COMPLETE NIT ZONE 1111");
    updateMapLayout();
    // updateMapLayout(positions: HomeController.to.activeGroup.members.positions);
  }

  void _drawZonePerimeter(String id, Perimeter perimeter) {
    final polygonPerimeter = perimeter.polygonPerimeter;
    final perimeterStyle = perimeter.style;
    final tolerance = perimeter.tolerance;

    polygons.addAll({
      FlutterPolygon(
        id: id,
        points: polygonPerimeter.perimeter.map((x) => x.toMapLatLng()).toList(),
        color: perimeterStyle.fillColor
            .toColor()
            .withOpacity(perimeterStyle.fillColorOpacity),
        borderColor: perimeterStyle.borderColor.toColor(),
        borderStrokeWidth: perimeterStyle.borderThickness.toDouble(),
      ),
    });
    if (tolerance > 0 && showPerimeterTolerance) {
      _drawZoneTolerance(id, perimeter);
    }
  }

  Future<void> _removeOutOfRangeDistanceLine(RxPosition pos) async {
    final String id = '${pos.id}_${pos.worker().id}';
    labelMarkers.removeWhere((m) => m.id == id);
    polylines.removeWhere((p) => p.id == id);
  }

  Future<void> _drawDistanceLine(
      {RxPosition? pos,
      Coordinates? workerLocation,
      Coordinates? positionLocation}) async {
    final Coordinates endPoint = positionLocation ?? pos!.coordinates;
    final Coordinates startPoint = workerLocation ?? pos!.workerLocation();
    if (endPoint == null || startPoint == null) {
      await _removeOutOfRangeDistanceLine(pos!);
      return;
    }
    //perimeter.circlePerimeter?.center ?? getCenterLatLong(perimeter.polygonPerimeter?.perimeter);

    final double distance = Geolocator.distanceBetween(startPoint.latitude,
        startPoint.longitude, endPoint.latitude, endPoint.longitude);
    if (distance < 5 && pos!.status.value != PositionStatus.outOfRange) {
      await _removeOutOfRangeDistanceLine(pos);
      return;
    }
    final String id = '${pos?.id}_${pos!.worker().id}';
    labelMarkers.removeWhere((m) => m.id == id);
    if (pos.status.value == PositionStatus.outOfRange) {
      final LatLng midLabelPoint = midPoint(endPoint.latitude,
          endPoint.longitude, startPoint.latitude, startPoint.longitude);
      final String text = distance > 99
          ? '${(distance / 1000).toStringAsFixed(2)}km'
          : '${distance.floor()}m';

      final double bearing = Geolocator.bearingBetween(
          endPoint.latitude,
          endPoint.longitude,
          pos.workerLocation().latitude,
          pos.workerLocation().longitude);

      labelMarkers.add(FlutterMarker(
        id: id,
        point: midLabelPoint,
        width: 50,
        height: 25,
        builder: (ctx) => _buildDistanceLabelWidget(text),
        anchorPos: AnchorPos.align(AnchorAlign.center),
      ));
    }
    TelloLogger().i(
        "DRAW 444444 LABEL DISTANCE labelMarkers.length == ${labelMarkers.length}");
    final List<LatLng> polyline = [
      LatLng(startPoint.latitude, startPoint.longitude),
      LatLng(endPoint.latitude, endPoint.longitude)
    ];

    polylines.removeWhere((p) => p.id == id);
    polylines.add(FlutterPolyline(
        id: id,
        color: getPositionStatusColor(pos),
        points: polyline,
        strokeWidth: pos.status.value != PositionStatus.outOfRange ? 1 : 3));
  }

  void _drawZoneTolerance(String id, Perimeter perimeter) {
    final polygonPerimeter = perimeter.polygonPerimeter;
    final perimeterStyle = perimeter.style;
    final List<LatLng> points = polygonPerimeter.perimeterWithTolerance
        .map((x) => x.toMapLatLng())
        .toList();
    points.add(points.first);

    polylines.add(FlutterPolyline(
      id: '${id}tolerance',
      color: perimeterStyle.borderColor.toColor(),
      borderColor: perimeterStyle.borderColor.toColor(),
      isDotted: true,
      strokeWidth: perimeterStyle.borderThickness.toDouble(),
      points: points,
    ));
  }

  void _drawPositionTolerance(RxPosition pos) {
    final Perimeter perimeter = pos.perimeter;
    if (perimeter.style.borderThickness == 0.0) return;
    final polygonPerimeter = perimeter.polygonPerimeter;

    final perimeterStyle = perimeter.style;
    final List<LatLng> points = polygonPerimeter.perimeterWithTolerance
        .map((x) => x.toMapLatLng())
        .toList();
    //points.add(points.first);
    TelloLogger().i(
        "########################################### Draw polygonPerimeter count ${points.length} ${perimeterStyle.borderThickness.toDouble()} ${perimeterStyle.borderColor.toColor()} == ${points.first.latitude},${points.first.longitude} ${points.last.latitude},${points.last.longitude}");

    polylines.add(FlutterPolyline(
      id: '${pos.id}tolerance',
      borderColor: perimeterStyle.borderColor.toColor(),
      isDotted: true,
      strokeWidth: perimeterStyle.borderThickness.toDouble(),
      points: points,
    ));
  }

  void _drawPositionCircleTolerance(RxPosition pos) {
    final Perimeter perimeter = pos.perimeter;

    final circlePerimeter = perimeter.circlePerimeter;
    final perimeterStyle = perimeter.style;
    final tolerance = perimeter.tolerance;
    final List<LatLng> points = GeoUtils.createMapCirclePoints(
            circlePerimeter.center.toLatLng(),
            circlePerimeter.radius + tolerance,
            1)
        .cast<LatLng>();
    points.add(points.first);

    polylines.add(FlutterPolyline(
      id: '${pos.id}tolerance',
      borderColor: perimeterStyle.borderColor.toColor(),
      isDotted: true,
      strokeWidth: perimeterStyle.borderThickness.toDouble(),
      points: points,
    ));
  }

  Color getPositionStatusColor(RxPosition pos) {
    Color val = Colors.black;
    switch (pos.status.value) {
      case PositionStatus.inactive:
        val = Colors.black;
        break;
      case PositionStatus.active:
        val = Colors.green;
        break;
      case PositionStatus.outOfRange:
        val = Colors.red;
        break;
    }
    return val;
  }

  Widget _buildEventMarkerWidget(IncomingEvent event) {
    String _eventMarkerImagePath = "";
    _eventMarkerImagePath = 'assets/images/events/${event.mapIconCfg.id}.svg';

    return _eventMarkerImagePath.isNotEmpty
        ? GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              _showEventInfoWindow(event);
            },
            child: SvgPicture.asset(
              _eventMarkerImagePath,
            ),
          )
        : const SizedBox();
  }

  void _drawEventMarker(IncomingEvent event, {bool ignoreShowOnMap = false}) {
    assert(event.hasLocation);

    if (!event.hasLocation) {
      Get.showSnackbarEx(GetBar(
        backgroundColor: Colors.red,
        message: 'The event has no location!',
        duration: const Duration(seconds: 3),
      ));
    }

    if (!ignoreShowOnMap && event.doNotShowOnMap) return;

    TelloLogger().i("_drawEventMarker ==> ${event.title}");
    markers.removeWhere((e) => e.id == event.id);
    markers.add(
      FlutterMarker(
          controller: mapController,
          id: event.id,
          point: event.location!.coordinates.toMapLatLng(),
          width: _eventMarkerIconSize,
          height: _eventMarkerIconSize,
          builder: (ctx) => _buildEventMarkerWidget(event),
          anchorPos: AnchorPos.align(AnchorAlign.top),
          isEventMarker: true,
          color: Colors.red),
    );
  }

  Future<void> _showEventInfoWindow(IncomingEvent event,
      {String? markerId}) async {
    assert(event.hasLocation);

    if (!event.hasLocation) {
      Get.showSnackbarEx(GetBar(
        backgroundColor: Colors.red,
        message: 'The event has no location!',
        duration: const Duration(seconds: 3),
      ));
    }

    final String infoWindowId = markerId ?? event.id!;
    if (HomeController.to.currentBottomNavBarIndex != 1) {
      return hideInfoWindowFullScreen();
    }
    currentLocation = event.location!.coordinates.toMapLatLng();

    if (currentLocation == null) return;

    customInfoWindowController.addInfoWindow(
      EntityDetailsInfo.createEventDetails(event),
      currentLocation as map_tools.LatLng,
      0,
      0,
      markers.firstWhere((element) => element.id == infoWindowId),
    );
    updateMapLayout();
  }

  Future<void> _drawPositionPerimeter(RxPosition pos) async {
    // Either of the two perimeter types shouldn't be null;
    final circlePerimeter = pos.perimeter.circlePerimeter;
    final polygonPerimeter = pos.perimeter.polygonPerimeter;
    final perimeterStyle = pos.perimeter.style;
    final tolerance = pos.perimeter.tolerance;

    if (polygonPerimeter != null) {
      polygons.addAll({
        FlutterPolygon(
            id: pos.id,
            points:
                polygonPerimeter.perimeter.map((x) => x.toMapLatLng()).toList(),
            color: perimeterStyle.fillColor
                .toColor()
                .withOpacity(perimeterStyle.fillColorOpacity),
            borderColor: perimeterStyle.borderColor.toColor(),
            borderStrokeWidth: perimeterStyle.borderThickness.toDouble()),
      });

      if (tolerance > 0 && showPerimeterTolerance) {
        _drawPositionTolerance(pos);
      }
    }

    if (circlePerimeter != null) {
      TelloLogger().i(
          "########################################### Draw Position Circle tolerance == $tolerance");
      circles.addAll({
        FlutterCircle(
            id: pos.id,
            point: circlePerimeter.center.toMapLatLng(),
            radius: circlePerimeter.radius,
            color: perimeterStyle.fillColor
                .toColor()
                .withOpacity(perimeterStyle.fillColorOpacity),
            borderColor: perimeterStyle.borderColor.toColor(),
            borderStrokeWidth: perimeterStyle.borderThickness.toDouble()),
      });

      if (tolerance > 0 && showPerimeterTolerance) {
        _drawPositionCircleTolerance(pos);
      }
    }
  }

  Future<void> onSwitchMapType(String mapTypeToSwitch) async {
    mapType.value = mapTypeToSwitch;
    //TODO: inject the value inside the string
    if (mapType.value == 'm') {
      layer.value = '${AppSettings().externalTileServerUrl}{z}/{x}/{y}.png';
    } else {
      layer.value =
          'https://server.arcgisonline.com/ArcGIS/rest/services/World_Imagery/MapServer/tile/{z}/{y}/{x}';
    }
    await TileStorageCachingManager.cleanCache();
    tileProvider$.value = StorageCachingTileProvider();
    imageCache.clear();
    updateMapLayout();
    TelloLogger().i("onSwitchMapType ${mapType.value}");
  }

  Future<void> hideInfoWindowFullScreen() async {
    customInfoWindowController.hideInfoWindow!();
    TelloLogger().i("hideInfoWindow full");
    _currentInfoWindowId = null;
    topActionButtons$.clear();
    if (_selectedPosition != null) {
      await _removeOutOfRangeDistanceLine(_selectedPosition);
      updateMapLayout();
      _selectedPosition = null!;
    }
  }

  void onTap([LatLng? latlng]) {
    hideInfoWindowFullScreen();
    currentSelectedLocation = latlng!;
    initZone(zoomToZone: false);
    //clearAllClusterStartDisplay();
  }

  Future<void> handleCameraMove(MapPosition position) async {
    currentZoom = position.zoom!;
    customInfoWindowController.onCameraMove!();
    // await initZone();
  }

  ///CAUTION! Either RxPosition or RxUser must be provided!
  Future<void> _showInitialPositionInfoWindow({required RxPosition pos}) async {
    topActionButtons$.clear();

    final String id = 'position_location_${pos.id}';
    TelloLogger().i(
        "_showInitialPositionInfoWindow ${HomeController.to.currentBottomNavBarIndex} ${Get.currentRoute}");
    if (HomeController.to.currentBottomNavBarIndex != 1) {
      return hideInfoWindowFullScreen();
    }

    TelloLogger()
        .i("_showInitialPositionInfoWindow == $customInfoWindowController");
    currentLocation =
        EntityDetailsInfo.getWindowMapLatLng(pos: pos, static: true) as LatLng;

    if (currentLocation == null) return;

    _currentInfoWindowId = 'initial_${pos.id}';
    customInfoWindowController.addInfoWindow(
        EntityDetailsInfo.createInitialPositionDetails(pos: pos, static: true),
        currentLocation as map_tools.LatLng,
        0,
        needToShowLabel() ? -11 : 11,
        markers.firstWhere((element) => element.id == id));

    if (pos != null) {
      _selectedPosition = pos;
      await _drawDistanceLine(pos: pos);
      updateMapLayout();
    }
    //await _animateToLatLng(pos.coordinates.toLatLng());
  }

  ///CAUTION! Either RxPosition or RxUser must be provided!
  Future<void> _showInfoWindow({
    required RxPosition pos,
    required RxUser user,
    bool static = false,
    required String id,
  }) async {
    topActionButtons$.clear();

    final String infoWindowId = id;
    if (HomeController.to.currentBottomNavBarIndex != 1) {
      return hideInfoWindowFullScreen();
    }
    currentLocation = EntityDetailsInfo.getWindowMapLatLng(
        pos: pos, user: user, static: static) as LatLng;

    if (currentLocation == null) return;

    _currentInfoWindowId = pos.id;
    TelloLogger().i(
        "_showInfoWindow $_currentInfoWindowId infoWindowId==  $infoWindowId");
    customInfoWindowController.addInfoWindow(
        EntityDetailsInfo.createDetails(
          pos: pos,
          user: user,
          static: static,
          forMap: true,
        ),
        currentLocation as map_tools.LatLng,
        5,
        needToShowLabel() ? -11 : 11,
        markers.firstWhere((m) => m.id == infoWindowId));
    if (pos != null) {
      _selectedPosition = pos;
      await _drawDistanceLine(pos: pos);
      updateMapLayout();
    }
    //await _animateToLatLng(pos!=null?pos.coordinates.toLatLng():user.location().coordinates.toLatLng());
  }

  String _markerImageForPosition(RxPosition pos) =>
      _positionIconFromStatus(pos);

  String _markerImageForUser(RxUser user) => user.isOnline()
      ? user.isSupervisor!
          ? 'assets/images/marker_sup_green.png'
          : 'assets/images/marker_user_green.png'
      : user.isSupervisor!
          ? 'assets/images/marker_sup_grey.png'
          : 'assets/images/marker_user_grey.png';

  Color _markerColorForUser(RxUser user) =>
      user.isOnline() ? Colors.green : Colors.grey;

  String _positionIconFromStatus(RxPosition pos) {
    final isSup = pos.worker().isSupervisor ?? false;
    final onlineWorker = pos.worker.value.isOnline();
    TelloLogger().i("_positionIconFromStatus ==> $isSup ,,, $onlineWorker");
    if (pos.positionType.mobilityType == MobilityType.Pedestrian) {
      if (pos.status() == PositionStatus.active && onlineWorker) {
        return isSup
            ? 'assets/images/marker_sup_green.png'
            : 'assets/images/marker_guard_green.png';
      } else if (pos.status() == PositionStatus.inactive) {
        return isSup
            ? 'assets/images/marker_sup_black.png'
            : 'assets/images/marker_guard_black.png';
      } else if (pos.status() == PositionStatus.outOfRange) {
        return isSup
            ? 'assets/images/marker_sup_red.png'
            : 'assets/images/marker_guard_red.png';
      } else {
        return isSup
            ? 'assets/images/marker_sup_grey.png'
            : 'assets/images/marker_guard_grey.png';
      }
    } else if (pos.positionType.mobilityType == MobilityType.Motorized) {
      if (pos.status() == PositionStatus.active && onlineWorker) {
        return isSup
            ? 'assets/images/supervisor_patrol_green_round.png'
            : 'assets/images/marker_green_car.png';
      } else if (pos.status() == PositionStatus.inactive) {
        return isSup
            ? 'assets/images/supervisor_patrol_black_round.png'
            : 'assets/images/marker_black_car.png';
      } else if (pos.status() == PositionStatus.outOfRange) {
        return isSup
            ? 'assets/images/supervisor_patrol_red_round.png'
            : 'assets/images/marker_red_car.png';
      } else {
        return isSup
            ? 'assets/images/supervisor_patrol_grey_round.png'
            : 'assets/images/marker_grey_car.png';
      }
    }
    return null!;
  }

  Color _positionColorFromStatus(RxPosition pos) {
    final isSup = pos.worker().isSupervisor ?? false;
    final onlineWorker = pos.worker.value.isOnline();
    TelloLogger().i("_positionIconFromStatus ==> $isSup ,,, $onlineWorker");
    if (pos.positionType.mobilityType == MobilityType.Pedestrian) {
      if (pos.status() == PositionStatus.active && onlineWorker) {
        return Colors.green;
      } else if (pos.status() == PositionStatus.inactive) {
        return Colors.black;
      } else if (pos.status() == PositionStatus.outOfRange) {
        return Colors.red;
      } else {
        return Colors.grey;
      }
    } else if (pos.positionType.mobilityType == MobilityType.Motorized) {
      if (pos.status() == PositionStatus.active && onlineWorker) {
        return Colors.green;
      } else if (pos.status() == PositionStatus.inactive) {
        return Colors.black;
      } else if (pos.status() == PositionStatus.outOfRange) {
        return Colors.red;
      } else {
        return Colors.grey;
      }
    }
    return null!;
  }

  String _initialPositionIconFromStatus(RxPosition pos) {
    final onlineWorker = pos.worker.value.isOnline();
    if (pos.positionType.mobilityType == MobilityType.Pedestrian) {
      if (pos.status() == PositionStatus.active && onlineWorker) {
        return 'assets/images/shield_green_triangle.png';
      } else if (pos.status() == PositionStatus.inactive) {
        return 'assets/images/shield_black_triangle.png';
      } else if (pos.status() == PositionStatus.outOfRange) {
        return 'assets/images/shield_red_triangle.png';
      } else {
        return 'assets/images/shield_grey_triangle.png';
      }
    } else if (pos.positionType.mobilityType == MobilityType.Motorized) {
      if (pos.status() == PositionStatus.active && onlineWorker) {
        return 'assets/images/car_green_triangle.png';
      } else if (pos.status() == PositionStatus.inactive) {
        return 'assets/images/car_black_triangle.png';
      } else if (pos.status() == PositionStatus.outOfRange) {
        return 'assets/images/car_red_triangle.png';
      } else {
        return 'assets/images/car_grey_triangle.png';
      }
    }
    return null!;
  }

  Color _initialPositionColorFromStatus(RxPosition pos) {
    final onlineWorker = pos.worker.value.isOnline();
    if (pos.positionType.mobilityType == MobilityType.Pedestrian) {
      if (pos.status() == PositionStatus.active && onlineWorker) {
        return Colors.green;
      } else if (pos.status() == PositionStatus.inactive) {
        return Colors.black;
      } else if (pos.status() == PositionStatus.outOfRange) {
        return Colors.red;
      } else {
        return Colors.grey;
      }
    } else if (pos.positionType.mobilityType == MobilityType.Motorized) {
      if (pos.status() == PositionStatus.active && onlineWorker) {
        return Colors.green;
      } else if (pos.status() == PositionStatus.inactive) {
        return Colors.black;
      } else if (pos.status() == PositionStatus.outOfRange) {
        return Colors.red;
      } else {
        return Colors.grey;
      }
    }
    return null!;
  }

  Future<void> toggleUserTracking(String userId,
      {bool onPosition = false}) async {
    TelloLogger().i("toggleUserTracking");
    if (userId == null) return;

    TelloLogger().i("toggleUserTracking user id $userId");
    final activeGroup = HomeController.to.activeGroup;
    late bool isTracking;

    if (trackingUserId == null || userId == trackingUserId) {
      if (onPosition) {
        final position = activeGroup.members.positions
            .firstWhere((p) => p.worker().id == userId, orElse: () => null!);
        if (position != null) {
          position.worker().tracking.toggle();
          isTracking = position.worker().tracking();
        }
      } else {
        final user = activeGroup.members.users
            .firstWhere((u) => u.id == userId, orElse: () => null!);
        if (user != null) {
          user.tracking.toggle();
          isTracking = user.tracking();
        }
      }
      if (isTracking) {
        trackingUserId = userId;
      } else {
        trackingUserId = null;
      }

      updateMapLayout();
    }
  }

  void togglePathDrawing(String userId, {bool onPosition = false}) {
    if (userId == null) return;
    final activeGroup = HomeController.to.activeGroup;

    late bool isDrawing;
    if (onPosition) {
      final position = activeGroup.members.positions
          .firstWhere((p) => p.worker().id == userId, orElse: () => null!);
      if (position != null) {
        position.worker().drawingPath.toggle();
        isDrawing = position.worker().drawingPath();
      }
    } else {
      final user = activeGroup.members.users
          .firstWhere((u) => u.id == userId, orElse: () => null!);
      if (user != null) {
        user.drawingPath.toggle();
        isDrawing = user.drawingPath();
      }
    }

    if (!isDrawing) polylines.removeWhere((p) => p.id == userId);

    updateMapLayout();
  }

  void _drawMarkerPath(String userId, LatLng latLng) {
    final oldPolyline =
        polylines.firstWhere((p) => p.id == userId, orElse: () => null!);
    final newPolyline = FlutterPolyline(
      id: userId,
      color: AppColors.mapMarkerPath,
      points: (oldPolyline.points ?? []) + [latLng],
      strokeWidth: 5,
    );
    if (oldPolyline != null) {
      polylines.removeWhere((p) => p.id == userId);
    }
    polylines.add(newPolyline);

    updateMapLayout();
  }

  LatLng midPoint(double lat1, double lon1, double lat2, double lon2) {
    final double dLon = math_vector.radians(lon2 - lon1);
    // ignore: parameter_assignments
    lat1 = math_vector.radians(lat1);
    // ignore: parameter_assignments
    lat2 = math_vector.radians(lat2);
    // ignore: parameter_assignments
    lon1 = math_vector.radians(lon1);

    final double bx = math.cos(lat2) * math.cos(dLon);
    final double by = math.cos(lat2) * math.sin(dLon);
    final double lat3 = math.atan2(math.sin(lat1) + math.sin(lat2),
        math.sqrt((math.cos(lat1) + bx) * (math.cos(lat1) + bx) + by * by));
    final double lon3 = lon1 + math.atan2(by, math.cos(lat1) + bx);

    return LatLng(math_vector.degrees(lat3), math_vector.degrees(lon3));
  }

  Coordinates getCenterLatLong(List<Coordinates> latLongList) {
    if (latLongList == null) return Coordinates(latitude: 0, longitude: 0);
    final double pi = math.pi / 180;
    final double xpi = 180 / math.pi;
    double x = 0, y = 0, z = 0;

    if (latLongList.length == 1) {
      return latLongList[0];
    }
    for (int i = 0; i < latLongList.length; i++) {
      final double latitude = latLongList[i].latitude * pi;
      final double longitude = latLongList[i].longitude * pi;
      final double c1 = math.cos(latitude);
      x = x + c1 * math.cos(longitude);
      y = y + c1 * math.sin(longitude);
      z = z + math.sin(latitude);
    }

    final int total = latLongList.length;
    x = x / total;
    y = y / total;
    z = z / total;

    final double centralLongitude = math.atan2(y, x);
    final double centralSquareRoot = math.sqrt(x * x + y * y);
    final double centralLatitude = math.atan2(z, centralSquareRoot);

    return Coordinates(
        latitude: centralLatitude * xpi, longitude: centralLongitude * xpi);
  }
}
