import 'dart:async';

import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/coordinates_model.dart';
import 'package:bazz_flutter/models/device_state.dart';
import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/user_location_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';

class PositionSnapshot {
  PositionSnapshot({
    this.timeStamp,
    this.id,
    this.position,
  });

  final String ? id;
  int? timeStamp;
  RxPosition? position;
}

class UserSnapshot {
  UserSnapshot({
    this.timeStamp,
    this.id,
    this.user,
  });

  int ?timeStamp;
  String ?id;
  RxUser ?user;
}

class EntitiesHistoryTracking {
  static final EntitiesHistoryTracking _singleton = EntitiesHistoryTracking._();

 late factory EntitiesHistoryTracking() => _singleton;

  EntitiesHistoryTracking._();

  final List<StreamSubscription> _subscriptions = [];
  StreamSubscription ? _activeGroupSub;
  StreamSubscription? _trackingSub;
  final List<UserSnapshot> usersSnapshotList = [];
  final List<PositionSnapshot> positionsSnapshotList = [];
  int? _currentPositionsTrackingDateTimeInSeconds;
  int ?_currentUsersTrackingDateTimeInSeconds;
  bool? _isTracking = false;

  RxDouble sliderValue$ = 0.0.obs;
  RxDouble sliderMinValue$ = 0.0.obs;
  RxDouble sliderMaxValue$ = 0.0.obs;
  RxInt sliderDivisionsValue$ = 0.obs;
  RxString displayedSliderValue$ = "".obs;

  bool get isTracking => _isTracking!;
  Timer ? _discardItemsTimer;
  bool _initialized = false;
  RxBool trackingIsOpened$ = false.obs;

  double get sliderValue => sliderValue$.value;

  double get sliderMinValue => sliderMinValue$.value;

  double get sliderMaxValue => sliderMaxValue$.value;

  String get displayedSliderValue => displayedSliderValue$.value;

  int get sliderDivisionsValue => sliderDivisionsValue$.value;

  bool get trackingIsOpened => trackingIsOpened$.value;

  final double _trackingTimeUnitInSeconds = 5.0;

  Timer ?_playbackTimer;

  int ?_totalCountTimer;

  final int _maxTrackingPeriodInSeconds = 60 * 60;

  // ignore: use_setters_to_change_properties
  void init() {
    if (_initialized) return;
    sliderMinValue$.value = 0.0;
    sliderMaxValue$.value = 0.0;
    sliderDivisionsValue$.value = 0;
    _discardItemsTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
      _discardItems();
    });
    _initialized = true;
    _trackingSub = trackingIsOpened$.listen((val) {
      if (!val) {
        gotoLastTimeStamp();
        _isTracking = false;
        sliderValue$.value = 0;
      } else {
        _isTracking = true;
      }
    });
    startTrackingOnActiveGroup();
  }

  int ? _currentSeekDateTimeInSeconds;

  void trackItemOnChangeTimeStamp(double val) {
    TelloLogger().i("trackItemOnSelectedTimeStamp $val");
    sliderValue$.value = val;
    final int dateTimeInSeconds = dateTimeToSeconds(DateTime.now());
    _currentSeekDateTimeInSeconds = dateTimeInSeconds - (val * _trackingTimeUnitInSeconds * currentPage$.value).toInt();
    displayedSliderValue$.value =
        DateFormat(AppSettings().fullTimeFormat).format(dateTimeFromSeconds(_currentSeekDateTimeInSeconds!) as DateTime);
  }

  void trackItemOnChangeEndTimeStamp(double val) {
    TelloLogger().i("trackItemOnChangeEndTimeStamp $_currentSeekDateTimeInSeconds");
    gotoTrackingTimeStamp(_currentSeekDateTimeInSeconds!);
  }

  UserSnapshot _createUserSnapshot(RxUser user) {
    _currentUsersTrackingDateTimeInSeconds = dateTimeToSeconds(DateTime.now());
    final UserSnapshot userSnapshot =
        UserSnapshot(timeStamp: _currentUsersTrackingDateTimeInSeconds, id: user.id, user: user.clone());
    return userSnapshot;
  }

  PositionSnapshot _createPositionSnapshot(RxPosition pos) {
    final int dateTimeInSeconds = dateTimeToSeconds(DateTime.now());
    _currentPositionsTrackingDateTimeInSeconds = dateTimeInSeconds;
    return PositionSnapshot(timeStamp: dateTimeInSeconds, id: pos.id, position: pos.clone());
  }

  bool trackPositionData(RxPosition position,
      { Coordinates ? workerLocation,
      PositionStatus? status,
      AlertCheckState ?alertCheckState,
      RxUser? worker,
      int? statusUpdatedAt,
      int? alertCheckStateUpdatedAt,
      DeviceState? deviceState}) {
    if (position == null) return false;
    final PositionSnapshot positionSnapshot = _createPositionSnapshot(position);
    positionSnapshot.position!.workerLocation.value = workerLocation!;
    positionSnapshot.position!.status.value = status!;
    positionSnapshot.position!.statusUpdatedAt = statusUpdatedAt!;
    positionSnapshot.position!.alertCheckState.value = alertCheckState!;
    positionSnapshot.position!.alertCheckStateUpdatedAt = alertCheckStateUpdatedAt!;
    if (worker != null) {
      positionSnapshot.position?.worker(worker);
      if (deviceState != null) {
        positionSnapshot.position?.worker().deviceCard.deviceState(deviceState.clone());
      }
    }
    return true;
  }

  bool trackUserData(RxUser user,
      {required UserLocation location,
      required bool isOnline,
      required AlertCheckState alertCheckState,
      required int onlineUpdatedAt,
      required DeviceState deviceState,
      required int rating}) {
    if (user == null) return false;
    final UserSnapshot userSnapshot = _createUserSnapshot(user);
    userSnapshot.user!.location.value = location.clone();
    userSnapshot.user!.isOnline.value = isOnline;
    userSnapshot.user!.onlineUpdatedAt = onlineUpdatedAt;
    userSnapshot.user!.rating = rating;
    userSnapshot.user!.deviceCard.deviceState(deviceState.clone());
    return true;
  }

  void _discardItems() {
    int dateTimeInSeconds = dateTimeToSeconds(DateTime.now());
    dateTimeInSeconds -= 60 * 60;
    positionsSnapshotList.removeWhere((element) => element.timeStamp! < dateTimeInSeconds);
    usersSnapshotList.removeWhere((element) => element.timeStamp! < dateTimeInSeconds);
  }

  RxInt pagesNumber$ = 1.obs;
  RxInt currentPage$ = 1.obs;
  RxBool canMoveNext$ = false.obs;
  RxBool canMoveBack$ = false.obs;

  void moveBack() {
    currentPage$.value--;
    sliderMinValue$.value = 0;
    sliderMaxValue$.value = _maxTrackingPeriodInSeconds / _trackingTimeUnitInSeconds;
    sliderDivisionsValue$.value = _maxTrackingPeriodInSeconds ~/ _trackingTimeUnitInSeconds;
    _refreshNavigationButtons();
  }

  void moveNext() {
    currentPage$.value++;
    if (currentPage$.value < pagesNumber$.value) {
      sliderMinValue$.value = 0;
      sliderMaxValue$.value = _maxTrackingPeriodInSeconds / _trackingTimeUnitInSeconds;
      sliderDivisionsValue$.value = _maxTrackingPeriodInSeconds ~/ _trackingTimeUnitInSeconds;
    } else {
      sliderMinValue$.value = 0;
      sliderMaxValue$.value = _totalCountTimer! / _trackingTimeUnitInSeconds;
      sliderDivisionsValue$.value = _totalCountTimer! ~/ _trackingTimeUnitInSeconds;
    }
    _refreshNavigationButtons();
  }

  void _refreshNavigationButtons() {
    canMoveBack$.value = pagesNumber$.value > 1 && currentPage$.value > 1;
    canMoveNext$.value = pagesNumber$.value > 1 && currentPage$.value < pagesNumber$.value;
    sliderValue$.value = 0;
  }

  void startTrackingOnActiveGroup() {
    _activeGroupSub = HomeController.to.activeGroup$.listen((aGroup) async {
      _closeAllSubscriptions();
      _playbackTimer?.cancel();
      _totalCountTimer = 0;

      _playbackTimer = Timer.periodic(_trackingTimeUnitInSeconds.seconds, (timer) {
        if (_isTracking!) {
          if (_maxTrackingPeriodInSeconds > _totalCountTimer! / currentPage$.value) {
            _totalCountTimer = _totalCountTimer! + _trackingTimeUnitInSeconds.toInt();
            sliderMaxValue$.value = _totalCountTimer! / _trackingTimeUnitInSeconds;
            sliderDivisionsValue$.value = _totalCountTimer! ~/ _trackingTimeUnitInSeconds;
          } else {
            pagesNumber$.value++;
            /*final int dateTimeInSeconds = dateTimeToSeconds(DateTime.now());
            positionsSnapshotList.removeWhere((element) => element.timeStamp < dateTimeInSeconds);
            usersSnapshotList.removeWhere((element) => element.timeStamp < dateTimeInSeconds);*/
          }
          _refreshNavigationButtons();
        }
      });

      if (aGroup == null) return;
      for (final pos in aGroup.members.positions) {
        _subscriptions.add(pos.worker.listen((val) {
          positionsSnapshotList.add(_createPositionSnapshot(pos));
        }));

        _subscriptions.add(pos.workerLocation.listen((val) {
          positionsSnapshotList.add(_createPositionSnapshot(pos));
        }));

        _subscriptions.add(pos.alertCheckState.listen((val) {
          positionsSnapshotList.add(_createPositionSnapshot(pos));
        }));

        _subscriptions.add(pos.status.listen((val) {
          positionsSnapshotList.add(_createPositionSnapshot(pos));
        }));

        if (pos.worker() != null && pos.worker().deviceCard != null) {
          _subscriptions.add(pos.worker().deviceCard.deviceState.listen((val) {
            positionsSnapshotList.add(_createPositionSnapshot(pos));
          }));
        }
      }

      for (final user in aGroup.members.users) {
        _subscriptions.add(user.location.listen((val) {
          usersSnapshotList.add(_createUserSnapshot(user));
        }));

        _subscriptions.add(user.isOnline.listen((val) {
          usersSnapshotList.add(_createUserSnapshot(user));
        }));

        _subscriptions.add(user.hasActiveSession.listen((val) {
          usersSnapshotList.add(_createUserSnapshot(user));
        }));

        if (user.deviceCard != null) {
          _subscriptions.add(user.deviceCard.deviceState.listen((val) {
            usersSnapshotList.add(_createUserSnapshot(user));
          }));
        }
      }
    });
  }

  void stopTrackingOnActiveGroup() {
    _activeGroupSub?.cancel();
    _closeAllSubscriptions();
  }

  void gotoLastTimeStamp() {
    _gotoPositionsTimeStamp(_currentPositionsTrackingDateTimeInSeconds!);
    _gotoUsersTimeStamp(_currentUsersTrackingDateTimeInSeconds!);
  }

  void gotoTrackingTimeStamp(int dateTimeInSeconds) {
    _gotoPositionsTimeStamp(dateTimeInSeconds);
    _gotoUsersTimeStamp(dateTimeInSeconds);
  }

  void _gotoPositionsTimeStamp(int dateTimeInSeconds) {
    TelloLogger().i("_gotoPositionsTimeStamp 000000");
    for (final pos in HomeController.to.activeGroup$.value.members.positions) {
      TelloLogger().i("_gotoPositionsTimeStamp 111111111 ${positionsSnapshotList.length}");
      final item = positionsSnapshotList.reversed
          .firstWhere((element) => element.id == pos.id && element.timeStamp! <= dateTimeInSeconds, orElse: () => null as PositionSnapshot);
      TelloLogger().i("_gotoPositionsTimeStamp $item");
      if (item != null) {
        TelloLogger().i("_gotoPositionsTimeStamp 22222222222");
        _applyPositionSnapShot(item, pos);
      }
    }
  }

  void _gotoUsersTimeStamp(int dateTimeInSeconds) {
    for (final user in HomeController.to.activeGroup$.value.members.users) {
      final item = usersSnapshotList.reversed
          .firstWhere((element) => element.id == user.id && element.timeStamp! <= dateTimeInSeconds, orElse: () => null as UserSnapshot);
      if (item != null) {
        _applyUserSnapShot(item.user!, user);
      }
    }
  }

  void _applyPositionSnapShot(PositionSnapshot snapshot, RxPosition pos) {
    TelloLogger().i("_gotoPositionsTimeStamp 44444");
    HomeController.to.updatePosition(
        positionId: snapshot.id!,
        worker: snapshot.position!.worker.value,
        workerLocation: snapshot.position!.workerLocation.value,
        alertCheckStateUpdatedAt: snapshot.position!.alertCheckStateUpdatedAt,
        statusUpdatedAt: snapshot.position!.statusUpdatedAt,
        alertCheckState: snapshot.position!.alertCheckState.value,
        status: snapshot.position!.status.value);
    if (snapshot.position!.worker.value != null) {
      TelloLogger().i("_gotoPositionsTimeStamp 555555");
      if (pos.worker.value != null) {
        TelloLogger().i("_gotoPositionsTimeStamp 7777777");
        _applyUserSnapShot(snapshot.position!.worker.value, pos.worker.value);
      } else {
        pos.worker.value = snapshot.position!.worker.value;
      }
    }
    pos.worker().deviceCard.deviceState(snapshot.position!.worker().deviceCard.deviceState());
  }

  void _applyUserSnapShot(RxUser snapshot, RxUser user) {
    user.onlineUpdatedAt = snapshot.onlineUpdatedAt;
    user.rating = snapshot.rating;
    user.location.value = snapshot.location.value;
    user.deviceCard.deviceState(snapshot.deviceCard.deviceState());
  }

  void gotoRealTimeTracking(DateTime dateTime) {}

  void _closeAllSubscriptions() {
    positionsSnapshotList.clear();
    usersSnapshotList.clear();
    for (final sub in _subscriptions) {
      sub.cancel();
    }
  }

  void close() {
    stopTrackingOnActiveGroup();
    _closeAllSubscriptions();
    _playbackTimer?.cancel();
    _playbackTimer?.cancel();
    _totalCountTimer = 0;
    _discardItemsTimer?.cancel();
    _trackingSub?.cancel();
    _discardItemsTimer = null;
    _initialized = false;
  }
}
