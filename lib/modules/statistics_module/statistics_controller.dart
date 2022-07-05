import 'package:bazz_flutter/services/statistics_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:get/get.dart';
import 'package:eventify/eventify.dart' as evf;

class StatisticsController extends GetxController {
  static StatisticsController get to => Get.find();

  RxString incomingDurationDisplay$ = "".obs;
  RxString outgoingDurationDisplay$ = "".obs;

  String get incomingDurationDisplay => incomingDurationDisplay$.value;

  String get outgoingDurationDisplay => outgoingDurationDisplay$.value;

  RxString totalIncomingDurationDisplay$ = "".obs;
  RxString totalOutgoingDurationDisplay$ = "".obs;

  String get totalIncomingDurationDisplay =>
      totalIncomingDurationDisplay$.value;

  String get totalOutgoingDurationDisplay =>
      totalOutgoingDurationDisplay$.value;

  evf.Listener? _incomingSub;
  evf.Listener? _outgoingSub;
  evf.Listener? _incomingTotalSub;
  evf.Listener? _outgoingTotalSub;
  @override
  Future<void> onInit() async {
    TelloLogger().i("onInit() ===> StatisticsController");
    final incoming =
        Duration(seconds: StatisticsService().incomingPTTStreamInSeconds);
    incomingDurationDisplay$.value = incoming.toString();

    final outgoing =
        Duration(seconds: StatisticsService().outgoingPTTStreamInSeconds);
    outgoingDurationDisplay$.value = outgoing.toString();

    final totalIncoming =
        Duration(seconds: StatisticsService().totalIncomingPTTStreamInSeconds);
    totalIncomingDurationDisplay$.value = totalIncoming.toString();

    final totalOutgoing =
        Duration(seconds: StatisticsService().totalOutgoingPTTStreamInSeconds);
    totalOutgoingDurationDisplay$.value = totalOutgoing.toString();

    _incomingSub =
        StatisticsService().on("incomingStatistics", this, (ev, context) {
      TelloLogger().i("incomingStatistics ==> ${ev.eventData}");
      if (ev.eventData != null) {
        final incoming = Duration(seconds: ev.eventData as int);
        incomingDurationDisplay$.value = incoming.toString();
      }
    });

    _outgoingSub =
        StatisticsService().on("outgoingStatistics", this, (ev, context) {
      TelloLogger().i("outgoingStatistics ==> ${ev.eventData}");
      if (ev.eventData != null) {
        final outgoing = Duration(seconds: ev.eventData as int);
        outgoingDurationDisplay$.value = outgoing.toString();
      }
    });

    _incomingTotalSub =
        StatisticsService().on("totalIncomingStatistics", this, (ev, context) {
      TelloLogger().i("totalIncomingStatistics ==> ${ev.eventData}");
      if (ev.eventData != null) {
        final incoming = Duration(seconds: ev.eventData as int);
        totalIncomingDurationDisplay$.value = incoming.toString();
      }
    });

    _outgoingTotalSub =
        StatisticsService().on("totalOutgoingStatistics", this, (ev, context) {
      TelloLogger().i("totalOutgoingStatistics ==> ${ev.eventData}");
      if (ev.eventData != null) {
        final outgoing = Duration(seconds: ev.eventData as int);
        totalOutgoingDurationDisplay$.value = outgoing.toString();
      }
    });
    super.onInit();
  }

  @override
  Future<void> onClose() async {
    _incomingSub?.cancel();
    _outgoingSub?.cancel();
    _incomingTotalSub?.cancel();
    _outgoingTotalSub?.cancel();
  }
}
