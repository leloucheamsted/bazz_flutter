import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/services/data_connection_checker.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:get/get.dart';

class NetworkJitterController extends GetxController {
  static NetworkJitterController? get to =>
      _instance != null ? Get.find() : null;
  static NetworkJitterController? _instance;

  final RxBool isOnline$;

  NetworkJitterController(this.isOnline$);

  static const _sampleSize = 24;

  // static const _sampleSize = 5; //for testing purposes

  final latencies = <int>[];
  final jitterLog$ = <int>[].obs;
  int maxStatPeriodSec = 3600;
  int currStatPeriodSec = 3600;
  int highestValue = 50;

  int get latenciesMaxLength =>
      maxStatPeriodSec ~/ AppSettings().pingIntervalSec;

  int? get jitter$ => jitterLog$.isNotEmpty ? jitterLog$.last : null;

  int? get latency => latencies.isNotEmpty ? latencies.last : null;

  @override
  void onInit() {
    _instance = this;
    DataConnectionChecker().processLatency = processLatency;
    super.onInit();
  }

  @override
  void onClose() {
    // TODO: implement onClose
    super.onClose();
  }

  void processLatency(int lat) {
    TelloLogger().i('NetworkJitterController new latency: $lat');
    if (lat > highestValue) highestValue = lat;
    latencies.add(lat);
    if (latencies.length > latenciesMaxLength) latencies.removeAt(0);
    final jitter = calculateJitter(latencies, _sampleSize);
    final newJitterLog = [...jitterLog$];
    newJitterLog.add(jitter);
    if (newJitterLog.length > latenciesMaxLength) newJitterLog.removeAt(0);
    jitterLog$.assignAll(newJitterLog);
  }

  int calculateJitter(List<int> latencies, int sampleSize) {
    if (latencies.length < sampleSize) return null!;

    final diffs = <int>[];
    int prevVal = 0;
    for (final val in latencies.reversed.take(sampleSize)) {
      final diff = (prevVal - val).abs();
      if (diff > 0) diffs.add(diff);
      prevVal = val;
    }
    final avg = (diffs.reduce((val, el) => val + el) / diffs.length).round();
    return avg;
  }
}
