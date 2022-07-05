import 'dart:async';

import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:data_usage/data_usage.dart';
import 'package:eventify/eventify.dart' as evf;
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class DataUsageService extends evf.EventEmitter {
  static final DataUsageService _singleton = DataUsageService._();

  factory DataUsageService() => _singleton;

  DataUsageService._();

  bool _initialized = false;
  Timer? _dataUsageTimer;

  int _firstDataUsage = 0;
  int _firstDataUsageAll = 0;

  final RxInt _totalDataUsage$ = 0.obs;
  final RxInt _totalDataUsageAll$ = 0.obs;

  int get totalDataUsageAll => _totalDataUsageAll$.value;

  int get totalDataUsage => _totalDataUsage$.value;

  final RxInt totalStorageDataUsage$ = 0.obs;
  final RxInt totalStorageDataUsageAll$ = 0.obs;

  int get totalStorageDataUsageAll => totalStorageDataUsageAll$.value;

  int get totalStorageDataUsage => totalStorageDataUsage$.value;

  Future<void> init() async {
    await DataUsage.init();
    _initialized = true;
  }

  int _toMegaBytes(int bytes) {
    if (bytes == 0) return 0;
    return (bytes / 1024 / 1024).ceil();
  }

  Future<void> stop() async {
    if (!_initialized) return;
    _dataUsageTimer?.cancel();
    _dataUsageTimer = null;
  }

  Future<void> start() async {
    try {
      if (!_initialized) return;
      if (GetPlatform.isAndroid) {
        const dataUsage = DataUsageType.wifi;

        final appName = "Tello Mobile";
        final firstDataUsages =
            await DataUsage.dataUsageAndroid(dataUsageType: dataUsage);
        final DataUsageModel firstUsage =
            firstDataUsages.firstWhere((element) => element.appName == appName);
        _firstDataUsage =
            _toMegaBytes(firstUsage.received! + (firstUsage.sent as int));

        firstDataUsages.forEach((element) {
          // Logger().log("element.packageName ==> ${element.received + element.sent} ,, ${element.appName}");
          if (element.appName != appName) {
            _firstDataUsageAll +=
                _toMegaBytes(element.received! + (element.sent as int));
          }
        });

        TelloLogger()
            .i("first _firstDataUsage ==> $_firstDataUsage ,, $dataUsage");
        _dataUsageTimer =
            Timer.periodic(const Duration(seconds: 60), (timer) async {
          final dataUsages =
              await DataUsage.dataUsageAndroid(dataUsageType: dataUsage);
          final DataUsageModel usage =
              dataUsages.firstWhere((element) => element.appName == appName);
          _totalDataUsage$.value =
              _toMegaBytes(usage.received! + (usage.sent as int)) -
                  _firstDataUsage;
          TelloLogger().i(
              "_totalDataUsage ==>  ${_totalDataUsage$.value} = ${_toMegaBytes(usage.received! + (usage.sent as int))} - $_firstDataUsage");
          int allDataUsage = 0;
          dataUsages.forEach((element) {
            if (element.appName != appName) {
              allDataUsage +=
                  _toMegaBytes(element.received! + (element.sent as int));
            }
          });
          _totalDataUsageAll$.value -= allDataUsage - _firstDataUsageAll;
          updateDataStorage();

          TelloLogger()
              .i("_totalDataUsageAll ==> ${_totalDataUsageAll$.value}");
        });
      }
    } catch (e, s) {
      TelloLogger().e("initatDataUsage ==> $e", stackTrace: s);
    }
  }

  void updateDataStorage() {
    if (GetStorage().hasData(StorageKeys.totalDataUsageId)) {
      final value = GetStorage().read(StorageKeys.totalDataUsageId) as int;
      totalStorageDataUsage$.value = value + _totalDataUsageAll$.value;
      GetStorage()
          .write(StorageKeys.totalDataUsageId, totalStorageDataUsage$.value);
    }

    if (GetStorage().hasData(StorageKeys.dataUsageId)) {
      final value = GetStorage().read(StorageKeys.dataUsageId) as int;
      totalStorageDataUsageAll$.value = value + _totalDataUsage$.value;
      GetStorage()
          .write(StorageKeys.dataUsageId, value + _totalDataUsage$.value);
    }
  }
}
