import 'dart:async';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/services/rtc_service.dart';
import 'package:eventify/eventify.dart' as evf;
import 'package:bazz_flutter/constants.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

class StatisticsService extends evf.EventEmitter {
  static final StatisticsService _singleton = StatisticsService._();

  factory StatisticsService() => _singleton;

  StatisticsService._();

  late RxInt totalIncomingPTTStreamInSeconds$ = 0.obs;
  late RxInt totalOutgoingPTTStreamInSeconds$ = 0.obs;

  int get totalIncomingPTTStreamInSeconds =>
      totalIncomingPTTStreamInSeconds$.value;

  int get totalOutgoingPTTStreamInSeconds =>
      totalOutgoingPTTStreamInSeconds$.value;

  late RxInt incomingPTTStreamInSeconds$ = 0.obs;
  late RxInt outgoingPTTStreamInSeconds$ = 0.obs;

  int get incomingPTTStreamInSeconds => incomingPTTStreamInSeconds$.value;

  int get outgoingPTTStreamInSeconds => outgoingPTTStreamInSeconds$.value;
/*
  set totalOutgoingPTTStreamInSeconds(double value) {
    totalOutgoingPTTStreamInSeconds$(value);
  }

  set totalIncomingPTTStreamInSeconds(double value) {
    totalIncomingPTTStreamInSeconds$(value);
  }
*/

  late StreamSubscription<TxState> _subscrtiption;

  Future<void> init() async {
    if (GetStorage().hasData(StorageKeys.totalPTTStreamOutgoingId)) {
      totalOutgoingPTTStreamInSeconds$.value =
          GetStorage().read(StorageKeys.totalPTTStreamOutgoingId);
    }

    if (GetStorage().hasData(StorageKeys.totalPTTStreamIncomingId)) {
      totalIncomingPTTStreamInSeconds$.value =
          GetStorage().read(StorageKeys.totalPTTStreamIncomingId);
    }

    _subscrtiption = HomeController.to.txState$.listen((state) {
      if (StreamingState.idle == state.state) {
        totalPTTBytesReceived += avgPttBytesReceived;
        totalPTTBytesSent += avgPttBytesSent;
      }
    });
  }

  Future<void> dispose() async {
    GetStorage().write(StorageKeys.totalPTTStreamOutgoingId,
        totalOutgoingPTTStreamInSeconds$.value);
    GetStorage().write(StorageKeys.totalPTTStreamIncomingId,
        totalIncomingPTTStreamInSeconds$.value);
    _subscrtiption.cancel();
  }

  void updatePTTStreamTime(int value, StreamingState state) {
    if (state == StreamingState.sending) {
      outgoingPTTStreamInSeconds$.value += value;
      emit("outgoingStatistics", this, outgoingPTTStreamInSeconds$.value);
      totalOutgoingPTTStreamInSeconds$.value += value;
      emit("totalOutgoingStatistics", this,
          totalOutgoingPTTStreamInSeconds$.value);
    } else if (state == StreamingState.receiving) {
      incomingPTTStreamInSeconds$.value += value;
      emit("incomingStatistics", this, incomingPTTStreamInSeconds$.value);
      totalIncomingPTTStreamInSeconds$.value += value;
      emit("totalIncomingStatistics", this,
          totalIncomingPTTStreamInSeconds$.value);
    }
  }

  RxDouble totalOtherBytesSent$ = 0.0.obs;
  RxDouble totalOtherBytesReceived$ = 0.0.obs;
  RxDouble avgPttBytesReceived$ = 0.0.obs;
  RxDouble avgPttBytesSent$ = 0.0.obs;

  double get avgPttBytesReceived => avgPttBytesReceived$.value;

  double get avgPttBytesSent => avgPttBytesSent$.value;

  double get totalOtherBytesSent => totalOtherBytesSent$.value;

  double get totalOtherBytesReceived => totalOtherBytesReceived$.value;

  set totalOtherBytesReceived(double val) =>
      totalOtherBytesReceived$.value = val;
  set totalOtherBytesSent(double val) => totalOtherBytesSent$.value = val;
  set avgPttBytesReceived(double val) => avgPttBytesReceived$.value = val;
  set avgPttBytesSent(double val) => avgPttBytesSent$.value = val;

  RxDouble totalPTTRecordingSent$ = 0.0.obs;
  RxDouble totalPTTRecordingReceived$ = 0.0.obs;

  double get totalPTTRecordingSent => totalPTTRecordingSent$.value;

  double get totalPTTRecordingReceived => totalPTTRecordingReceived$.value;

  set totalPTTRecordingSent(double val) => totalPTTRecordingSent$.value = val;
  set totalPTTRecordingReceived(double val) =>
      totalPTTRecordingReceived$.value = val;

  RxDouble totalPTTBytesSent$ = 0.0.obs;
  RxDouble totalPTTBytesReceived$ = 0.0.obs;

  double get totalPTTBytesSent => totalPTTBytesSent$.value;

  double get totalPTTBytesReceived => totalPTTBytesReceived$.value;

  set totalPTTBytesSent(double val) => totalPTTBytesSent$.value = val;
  set totalPTTBytesReceived(double val) =>
      totalPTTRecordingReceived$.value = val;
}
