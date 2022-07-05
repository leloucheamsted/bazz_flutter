import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/coordinates_model.dart';
import 'package:bazz_flutter/models/location_details_model.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/user_location_model.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/location_tracking/kalman_filter.dart';
import 'package:bazz_flutter/services/activity_recognition_service.dart';
import 'package:bazz_flutter/services/background_service.dart';
import 'package:bazz_flutter/services/entities_history_tracking.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/shared_widgets/system_dialog.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:eventify/eventify.dart';
import 'package:eventify/eventify.dart' as evf;
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:geolocator/geolocator.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:get_storage/get_storage.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';
// import 'package:sensors/sensors.dart';

const MethodChannel _channelEnableGps = MethodChannel('com.bazzptt/enable_gps');

class LocationService extends EventEmitter {
  static final LocationService _singleton = LocationService._();

  factory LocationService() => _singleton;

  LocationService._();

  late KalmanLatLong _filter;
  late Position _lastKnownPosition;

  Position get lastKnownPosition => _lastKnownPosition;
  Timer locationUpdateTimer = null!;
  late evf.Listener _cancelStillActivityListener;
  late evf.Listener _startStillActivityListener;
  late int _locationUpdatePeriod;
  RxBool gnssEnabled$ = false.obs;

  bool get gnssEnabled => gnssEnabled$.value;

  int get locationUpdatePeriod => _locationUpdatePeriod;
  bool showDeniedMessage = false;
  Future<bool> isLocationServiceEnabled() async {
    final bool res = await Geolocator.isLocationServiceEnabled();
    return res;
  }

  Future<Position> getCurrentPosition(
      {int timeLimit = -1,
      bool ignoreLastKnownPos = true,
      LocationAccuracy desiredAccuracy = LocationAccuracy.best}) async {
    Position? position;
    try {
      int timeLimitDefined;
      if (timeLimit == -1) {
        timeLimitDefined = AppSettings().getCurrentPositionTimeout;
      } else {
        timeLimitDefined = timeLimit;
      }
      position = await Geolocator.getCurrentPosition(
          desiredAccuracy: desiredAccuracy,
          forceAndroidLocationManager:
              AppSettings().forceAndroidLocationManager,
          timeLimit: Duration(seconds: timeLimitDefined));
      TelloLogger().i("getCurrentPosition ====> $position");
      gnssEnabled$.value = true;

      if (position != null && AppSettings().useKalmanFilterForGPS) {
        _filter.process(
            position.latitude,
            position.longitude,
            position.accuracy,
            position.timestamp!.millisecondsSinceEpoch.toDouble());
        position = Position(
            latitude: _filter.latitude!,
            longitude: _filter.longitude!,
            accuracy: position.accuracy,
            altitude: position.altitude,
            heading: position.heading,
            speed: position.speed * 3.6,
            speedAccuracy: position.speedAccuracy,
            timestamp: position.timestamp);
      }
    } catch (e, s) {
      TelloLogger().e("getCurrentPosition error ====> $e", stackTrace: s);
      final isDenied = await Permission.locationAlways.isDenied;
      if (isDenied && !showDeniedMessage) {
        showDeniedMessage = true;
        final String message =
            LocalizationService().of().mobileGPSAccessIsDeniedByUser;
        //User denied permissions to access the device's location
        SystemDialog.showConfirmDialog(
          title: LocalizationService().of().mobileGPSAccessIsDenied,
          message: message,
          confirmButtonText: LocalizationService().of().ok,
          confirmCallback: () async {
            Get.back();
            await Permission.locationAlways.request();
          },
        );

        //TODO
      }
      gnssEnabled$.value = false;
    }
    return position ?? (ignoreLastKnownPos ? null : _lastKnownPosition)!;
  }

  void pause({bool force = false}) {
    try {
      //await _mutex.acquire().timeout(const Duration(seconds: 5));
      _stop();
      /*if (!_isLocked || force) {
        isPaused = true;
      }*/
    } finally {
      //_mutex.release();
    }
  }

  void enableGps() {
    _channelEnableGps.invokeMethod("enable");
  }

  void disableGps() {
    _channelEnableGps.invokeMethod("disable");
  }

  void start(
      {bool isLocked = false,
      int locationUpdatePeriod = 0,
      LocationAccuracy desiredAccuracy = LocationAccuracy.best}) {
    _locationUpdatePeriod = locationUpdatePeriod;
    TelloLogger().i(
        'start locationUpdatePeriod ==> $locationUpdatePeriod ,,, $desiredAccuracy');
    _start(
        locationUpdatePeriod: _locationUpdatePeriod,
        desiredAccuracy: desiredAccuracy);
  }

  void init() {
    _locationUpdatePeriod = AppSettings().locationUpdatePeriod;
    _filter = KalmanLatLong(2);
    if (AppSettings().useStillActivitiesForGPS) {
      _cancelStillActivityListener = ActivityRecognitionService()
          .on("cancelStillActivity", this, (ev, context) {
        if (locationUpdateTimer == null) {
          _start(locationUpdatePeriod: _locationUpdatePeriod);
        }
      });

      _startStillActivityListener = ActivityRecognitionService()
          .on("startStillActivity", this, (ev, context) {
        if (locationUpdateTimer != null) {
          _stop();
        }
      });
    }
    _start(locationUpdatePeriod: _locationUpdatePeriod);
  }

  void _start(
      {int? locationUpdatePeriod,
      LocationAccuracy desiredAccuracy = LocationAccuracy.best}) {
    TelloLogger().i('_start ==> $locationUpdatePeriod ,,, $desiredAccuracy');
    locationUpdateTimer.cancel();
    //AccelerometerService().startListenToAccelerometer();
    locationUpdateTimer =
        Timer.periodic(Duration(seconds: locationUpdatePeriod!), (timer) async {
      try {
        /*await _mutex.acquire();
        if (isPaused) return;*/
        final position =
            await getCurrentPosition(desiredAccuracy: desiredAccuracy);
        TelloLogger()
            .i('LocationService(): updated position - ${position.toString()}');
        if (position.toString() != _lastKnownPosition.toString()) {
          TelloLogger().i(
              'UPDATE POSITION details ${position.longitude}, ${position.latitude}, ${position.accuracy},${position.heading}, ${position.speed}, ${position.speedAccuracy}');
          emit('locationUpdate', this, position);
          if (!BackgroundService.instance().isBackground) {
            if (AppSettings().enableHistoryTracking &&
                EntitiesHistoryTracking().isTracking) {
              return;
            }
            if (Session.user != null) {
              final userLocation = position != null
                  ? UserLocation(
                      coordinates: Coordinates.fromPosition(position),
                      updatedAt: dateTimeToSeconds(DateTime.now()),
                      locationDetails: LocationDetails.fromPosition(position),
                    )
                  : null;
              //userLocation.locationDetails.speed = calculateSpeedLimitDiff(userLocation.locationDetails.speed);
              _updateUserLocation(
                  userId: Session.user!.id, location: userLocation!);
              if (Session.shift != null) {
                _updatePositionLocation(
                  positionId: Session.shift!.positionId!,
                  userLocation: userLocation,
                );
              }
            }
          }
          _lastKnownPosition = position;
        }
      } finally {
        //_mutex.release();
      }
    });
  }

  double calculateSpeedLimitDiff(double speed) {
    double diff = 0.0;
    TelloLogger().i(
        "calculateSpeedLimitDiff =====> 000000 $speed ${AccelerometerService().velocity}");
    if (AccelerometerService().velocity == 0) {
      return speed;
    }
    if (AccelerometerService().velocity > speed) {
      diff = (AccelerometerService().velocity / speed) - 1;
    } else {
      diff = 1 - (AccelerometerService().velocity / speed);
    }
    if (diff > 0.1) {
      return AccelerometerService().velocity;
    }
    TelloLogger().i("calculateSpeedLimitDiff =====> $speed");
    return speed;
  }

  void _stop() {
    gnssEnabled$.value = false;
    locationUpdateTimer.cancel();
    //AccelerometerService().stopListenToAccelerometer();
    locationUpdateTimer = null!;
  }

  void _updateUserLocation(
      {required String? userId, required UserLocation? location}) {
    try {
      if (!Get.isRegistered<HomeController>()) return;
      for (final group in HomeController.to.groups) {
        final user = group.members.users
            .firstWhere((u) => u.id == userId, orElse: () => null!);
        user.location(location);
      }
    } catch (e, s) {
      TelloLogger().e("_updateUserLocation() error: $e", stackTrace: s);
    }
  }

  void _updatePositionLocation({
    required String positionId,
    UserLocation? userLocation,
  }) {
    try {
      TelloLogger().i("_updatePositionLocation 00000000");
      if (HomeController.to == null) return;
      final position = HomeController.to.groups
          .firstWhere(
            (gr) => gr.members.positions.any((p) => p.id == positionId),
            orElse: () => null!,
          )
          .members
          .positions
          .firstWhere((p) => p.id == positionId, orElse: () => null!);
      TelloLogger().i("_updatePositionLocation 1111111");
      position.workerLocation(userLocation?.coordinates);
      position.worker().location(userLocation);
    } catch (e, s) {
      TelloLogger().e("UPDATE POSITION ERROR $e", stackTrace: s);
    }
  }

  void saveLocation(Position pos) {
    final combinedLocations = [
      LocationSnapshot(
        latitude: pos.latitude,
        longitude: pos.longitude,
        createdAtMs: DateTime.now().millisecondsSinceEpoch,
      ),
    ];

    final existingLocationsStr =
        GetStorage().read(StorageKeys.offlineLocations);

    TelloLogger()
        .i('saveLocation(): existingLocationsStr: $existingLocationsStr');

    if (existingLocationsStr != null) {
      final decodedData = json.decode(existingLocationsStr as String);
      combinedLocations.addAll(
        (decodedData as List<dynamic>).map(
            (loc) => LocationSnapshot.fromMap(loc as Map<String, dynamic>)),
      );
    }

    final combinedLocationsStr =
        json.encode(combinedLocations.map((el) => el.toMap()).toList());

    TelloLogger().i(
        'saveLocation(): length: ${combinedLocations.length}, combinedLocationsStr: $combinedLocationsStr');

    GetStorage().write(StorageKeys.offlineLocations, combinedLocationsStr);
  }

  void dispose() {
    _cancelStillActivityListener.cancel();
    _startStillActivityListener.cancel();
    AccelerometerService().startListenToAccelerometer();
    locationUpdateTimer.cancel();
    _lastKnownPosition = null as Position;
    locationUpdateTimer = null as Timer;
    super.clear();
  }

  double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    return Geolocator.distanceBetween(
        startLatitude, startLongitude, endLatitude, endLongitude);
  }
}

class AccelerometerService {
  StreamSubscription? _accelerometerSub;
  double _velocity = 0.0;
  double get velocity => _velocity;

  void _onAccelerate(AccelerometerEvent event) {
    if (event == null) return;
    final double newVelocity =
        sqrt(event.x * event.x + event.y * event.y + event.z * event.z);
    // Logger().log("_onAccelerate =====> 0000000 $newVelocity"  );
    if ((newVelocity - _velocity) < 1) {
      _velocity = 0.0;
      return;
    }
    // Logger().log("_onAccelerate =====> $newVelocity"  );
    _velocity = newVelocity;
  }

  void startListenToAccelerometer() {
    _accelerometerSub ??=
        accelerometerEvents.listen((AccelerometerEvent event) {
      _onAccelerate(event);
    });
  }

  void stopListenToAccelerometer() {
    _accelerometerSub?.cancel();
  }
}

class LocationSnapshot {
  LocationSnapshot({
    this.latitude,
    this.longitude,
    this.createdAtMs,
  });

  final double? latitude;
  final double? longitude;
  final int? createdAtMs;

  factory LocationSnapshot.fromMap(Map<String, dynamic> json) =>
      LocationSnapshot(
        latitude: json["latitude"] as double,
        longitude: json["longitude"] as double,
        createdAtMs: json["createdAtMs"] as int,
      );

  Map<String, dynamic> toMap() => {
        "latitude": latitude,
        "longitude": longitude,
        "createdAtMs": createdAtMs,
      };
}
