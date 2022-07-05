import 'dart:async';
import 'dart:convert';

import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/alert_check_result.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/outgoing_event.dart';
import 'package:bazz_flutter/modules/home_module/events_repo.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/sos_repo.dart';
import 'package:bazz_flutter/modules/home_module/sos_service.dart';
import 'package:bazz_flutter/modules/media_uploading/media_upload_service.dart';
import 'package:bazz_flutter/modules/message_history/message_upload_service.dart';
import 'package:bazz_flutter/modules/shift_activities/models/reporting_point_visit.dart';
import 'package:bazz_flutter/modules/shift_module/shift_repo.dart';
import 'package:bazz_flutter/modules/synchronization/sync_repo.dart';
import 'package:bazz_flutter/services/event_handling_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/networking_client.dart';
import 'package:get/get.dart';
import 'package:get/get_state_manager/src/simple/list_notifier.dart';
import 'package:get_storage/get_storage.dart';
import 'package:uuid/uuid.dart';

/// This class manages sync for OfflineLocations, OfflineDeviceStates, OfflineAlertCheckResults
/// and offline reporting points. The latter is being managed separately from others.
class SyncService extends GetxController {
  static SyncService get to => Get.find();

  final SyncRepo _repo = SyncRepo();

  late GetStorage rPointVisitsUploadQueue;

  late GetStorage offlineEventsBox;

  Completer otherDataSyncCompleted = Completer();

  Completer rPointsSyncCompleted = Completer();

  Completer offlineEventsSyncCompleted = Completer();

  StreamSubscription? _isOnlineSub;

  late Timer _syncTimer;

  final RxBool _syncingRPointVisits$ = false.obs;

  bool get syncingRPointVisits$ => _syncingRPointVisits$();

  set syncingRPointVisits$(bool val) => _syncingRPointVisits$(val);

  final RxBool _syncingOtherData$ = false.obs;

  bool get syncingOtherData$ => _syncingOtherData$();

  set syncingOtherData$(bool val) => _syncingOtherData$(val);

  final RxBool _syncingOfflineEvents$ = false.obs;

  bool get syncingOfflineEvents$ => _syncingOfflineEvents$();

  set syncingOfflineEvents$(bool val) => _syncingOfflineEvents$(val);

  RxInt offlineLocationsLeft$ = 0.obs;
  RxInt offlineDeviceStatesLeft$ = 0.obs;
  RxInt offlineAlertCheckResultsLeft$ = 0.obs;
  RxInt offlineEventsLeft$ = 0.obs;
  RxInt rPointVisitsLeft$ = 0.obs;

  // ANOTHER WAY OF HANDLING SYNC FUTURES - REMOVE IT LATER, if the current scheme works well.

  // Stream<bool> _hasRPointsUploadQueueBroadcast;
  // rx.ValueConnectableStream<bool> _hasOtherDataBroadcast;

  // Future<bool> get rPointsSyncCompleted => _hasRPointsUploadQueueBroadcast.any((hasData) => !hasData);
  //
  // Future<bool> get otherDataSyncCompleted => _hasOtherDataBroadcast.any((hasData) {
  //   print('hasOtherData: $hasData');
  //   return !hasData;
  // });

  bool get hasData$ =>
      offlineLocationsLeft$() > 0 ||
      offlineDeviceStatesLeft$() > 0 ||
      offlineAlertCheckResultsLeft$() > 0 ||
      offlineEventsLeft$() > 0 ||
      rPointVisitsLeft$() > 0;

  bool get hasRPointVisits$ => rPointVisitsLeft$() > 0;

  bool get hasOfflineEvents$ => offlineEventsLeft$() > 0;

  bool get hasOtherData$ =>
      offlineLocationsLeft$() > 0 ||
      offlineDeviceStatesLeft$() > 0 ||
      offlineAlertCheckResultsLeft$() > 0;

  int get otherDataLength$ =>
      offlineLocationsLeft$() +
      offlineDeviceStatesLeft$() +
      offlineAlertCheckResultsLeft$();

  // ANOTHER WAY OF HANDLING SYNC FUTURES - REMOVE IT LATER, if the current scheme works well.
  // StreamSubscription _hasOtherDataBroadcastSub;

  late Disposer _offlineLocationsDisposer;
  late Disposer _offlineDeviceStatesDisposer;
  late Disposer _offlineAlertCheckResultsDisposer;
  late Disposer _rPointVisitsUploadQueueDisposer;
  late Disposer _offlineEventsBoxDisposer;

  final rpVisitsUploadFailures = <String, int>{};

  @override
  Future<void> onInit() async {
    TelloLogger().i('SyncServices onInit()');
    rPointVisitsUploadQueue =
        GetStorage(StorageKeys.rPointVisitsUploadQueueBox);
    offlineEventsBox = GetStorage(StorageKeys.offlineEventsBox);
    // We must init keys before listening them
    GetStorage()
      ..writeIfNull(StorageKeys.offlineAlertCheckResults, null)
      ..writeIfNull(StorageKeys.offlineLocations, null)
      ..writeIfNull(StorageKeys.offlineDeviceStates, null);

    final locationsString = GetStorage().read(StorageKeys.offlineLocations);
    final existingStatesString =
        GetStorage().read(StorageKeys.offlineDeviceStates);
    final alertCheckResultsString =
        GetStorage().read(StorageKeys.offlineAlertCheckResults);

    offlineLocationsLeft$(locationsString != null
        ? (json.decode(locationsString as String) as List<dynamic>).length
        : 0);
    offlineDeviceStatesLeft$(existingStatesString != null
        ? (json.decode(existingStatesString as String) as List<dynamic>).length
        : 0);
    offlineAlertCheckResultsLeft$(alertCheckResultsString != null
        ? (json.decode(alertCheckResultsString as String) as List<dynamic>)
            .length
        : 0);

    rPointVisitsLeft$(
        rPointVisitsUploadQueue.getKeys<Iterable<String>>().length);
    offlineEventsLeft$(offlineEventsBox.getKeys<Iterable<String>>().length);

    _offlineLocationsDisposer =
        GetStorage().listenKey(StorageKeys.offlineLocations, (data) {
      final dataLength = data != null
          ? (json.decode(data as String) as List<dynamic>).length
          : 0;
      offlineLocationsLeft$(dataLength);
      if (data != null && otherDataSyncCompleted.isCompleted)
        otherDataSyncCompleted = Completer<bool>();
      TelloLogger().i('offlineLocations listener data length: $dataLength');
    });

    _offlineDeviceStatesDisposer =
        GetStorage().listenKey(StorageKeys.offlineDeviceStates, (data) {
      final dataLength = data != null
          ? (json.decode(data as String) as List<dynamic>).length
          : 0;
      offlineDeviceStatesLeft$(dataLength);
      if (data != null && otherDataSyncCompleted.isCompleted)
        otherDataSyncCompleted = Completer<bool>();
      TelloLogger().i('offlineDeviceStates listener data length: $dataLength');
    });

    _offlineAlertCheckResultsDisposer =
        GetStorage().listenKey(StorageKeys.offlineAlertCheckResults, (data) {
      final dataLength = data != null
          ? (json.decode(data as String) as List<dynamic>).length
          : 0;
      offlineAlertCheckResultsLeft$(dataLength);
      if (data != null && otherDataSyncCompleted.isCompleted)
        otherDataSyncCompleted = Completer<bool>();
      TelloLogger()
          .i('offlineAlertCheckResults listener data length: $dataLength');
    });

    _rPointVisitsUploadQueueDisposer = rPointVisitsUploadQueue.listen(() {
      final keys = rPointVisitsUploadQueue.getKeys<Iterable<String>>();
      rPointVisitsLeft$(keys.length);
      if (keys.isNotEmpty && rPointsSyncCompleted.isCompleted)
        rPointsSyncCompleted = Completer<bool>();
      TelloLogger().i('rPointsUploadQueue length: ${keys.length}');
    });

    _offlineEventsBoxDisposer = offlineEventsBox.listen(() {
      final keys = offlineEventsBox.getKeys<Iterable<String>>();
      offlineEventsLeft$(keys.length);
      if (keys.isNotEmpty && offlineEventsSyncCompleted.isCompleted)
        offlineEventsSyncCompleted = Completer<bool>();
      TelloLogger().i('offlineEventsBox length: ${keys.length}');
    });

    // ANOTHER WAY OF HANDLING SYNC FUTURES - REMOVE IT LATER, if the current scheme works well.
    // The idea is to form a broadcast stream and then use getter with .any((hasData) => !hasData)
    // on it to get a future, which resolves when there is no data. An error should be added to the original stream.

    // _hasRPointsUploadQueueBroadcast = hasRPointsUploadQueue$.stream.asBroadcastStream();
    // _hasOtherDataBroadcast = rx.Rx.combineLatest3<bool, bool, bool, bool>(
    //   hasOfflineLocations$.stream,
    //   hasOfflineDeviceStates$.stream,
    //   hasOfflineAlertCheckResults$.stream,
    //   (a, b, c) {
    //     print('has locations: $a');
    //     print('has dStates: $b');
    //     print('has aChecks: $c');
    //     return a || b || c;
    //   },
    // ).publishValue();
    //
    // _hasOtherDataBroadcastSub = _hasOtherDataBroadcast.connect();
    //
    // hasOfflineLocations$.refresh();
    // hasOfflineDeviceStates$.refresh();
    // hasOfflineAlertCheckResults$.refresh();

    if (!hasOtherData$) otherDataSyncCompleted.complete();
    if (!hasRPointVisits$) rPointsSyncCompleted.complete();
    if (!hasOfflineEvents$) offlineEventsSyncCompleted.complete();

    _syncTimer = Timer.periodic(5.seconds, (_) {
      TelloLogger().i('Periodic sync timer triggered');
      syncRPointVisits();
      syncOtherData();
      syncOfflineEvents();
    });

    _isOnlineSub = HomeController.to.isOnline$.listen((online) {
      if (online) return;

      rPointsSyncCompleted.future.whenComplete(() {
        TelloLogger().i(
            'SyncService: the system is offline, clearing rpVisitsUploadFailures...');
        rpVisitsUploadFailures.clear();
      });
    });

    super.onInit();
  }

  @override
  void onClose() {
    TelloLogger().i('SyncServices onClose()');
    _syncTimer.cancel();
    _isOnlineSub?.cancel();
    // ANOTHER WAY OF HANDLING SYNC FUTURES - REMOVE IT LATER, if the current scheme works well.
    // _hasOtherDataBroadcastSub.cancel();
    _offlineLocationsDisposer.call();
    _offlineDeviceStatesDisposer.call();
    _offlineAlertCheckResultsDisposer.call();
    _rPointVisitsUploadQueueDisposer.call();
    _offlineEventsBoxDisposer.call();
    super.onClose();
  }

  ///CAUTION: currently we don't await for all async calls inside this method!
  Future<void> syncRPointVisits() async {
    final rPointVisitKeys = rPointVisitsUploadQueue.getKeys<Iterable<String>>();
    final noVisits = rPointVisitKeys.isEmpty;

    if (!Get.isRegistered<SyncService>() ||
        !HomeController.to.isOnline ||
        syncingRPointVisits$ ||
        noVisits) return;

    syncingRPointVisits$ = true;
    if (rPointsSyncCompleted.isCompleted)
      rPointsSyncCompleted = Completer<bool>();

    int passedCounter = 0;
    int failedCounter = 0;

    void checkIn(String rPointVisitKey, {bool error = false}) {
      if (error) {
        failedCounter++;
        final prevRPVisitErrorCounter =
            rpVisitsUploadFailures[rPointVisitKey] ?? 0;
        rpVisitsUploadFailures[rPointVisitKey] = prevRPVisitErrorCounter + 1;
        final currRPVisitErrorCounter = rpVisitsUploadFailures[rPointVisitKey];

        if (currRPVisitErrorCounter! >= 3) {
          TelloLogger().i(
              'SyncService, syncRPoints(): Reached error threshold for $rPointVisitKey, removing it...');
          rpVisitsUploadFailures.remove(rPointVisitKey);
          rPointVisitsUploadQueue.remove(rPointVisitKey);
        }
      } else {
        passedCounter++;
        rpVisitsUploadFailures.remove(rPointVisitKey);
      }
      if (passedCounter + failedCounter == rPointVisitKeys.length) {
        if (!rPointsSyncCompleted.isCompleted) {
          if (passedCounter == rPointVisitKeys.length) {
            rPointsSyncCompleted.complete();
          } else {
            rPointsSyncCompleted.completeError(
                'SyncService, syncRPoints() finished: $failedCounter errors!');
            // ANOTHER WAY OF HANDLING SYNC FUTURES - REMOVE IT LATER, if the current scheme works well.
            // hasRPointsUploadQueue$.addError('SyncService, syncRPoints() finished: $failedCounter errors!');
          }
        }
        syncingRPointVisits$ = false;
      }
      TelloLogger().i('rPoints processed: ${passedCounter + failedCounter}');
    }

    TelloLogger().i('rPointKeys length: ${rPointVisitKeys.length}');
    for (final rPointVisitKey in rPointVisitKeys) {
      final rPointVisitData =
          rPointVisitsUploadQueue.read<Map<String, dynamic>>(rPointVisitKey);
      final rPointVisit =
          ReportingPointVisit.fromMap(rPointVisitData!, listFromJson: true);
      final _repo = ShiftRepository();

      if (rPointVisit.hasDeferredUploadMedia) {
        final mediaUploadService = MediaUploadService.to;
        rPointVisit.getLinksForDeferredMedia(mediaUploadService).then((_) {
          // We don't await here because we want to upload all rPoints without waiting for their media to be uploaded
          // final sendRPoint = _repo.sendReportingPoint(rPointVisit);
          _repo.sendRPointVisit(rPointVisit).then((_) {
            rPointVisit.uploadAllDeferredMedia(mediaUploadService).then((_) {
              TelloLogger().i('Removing $rPointVisitKey');
              rPointVisitsUploadQueue.remove(rPointVisitKey);
              checkIn(rPointVisitKey);
            }).catchError((_) {
              checkIn(rPointVisitKey, error: true);
            });
          }).catchError((e, s) {
            TelloLogger().e('sendRPointVisit error: $e',
                stackTrace: s is StackTrace ? s : null);
            //TODO: remove if it works without it - don't see any point to write it here - we didn't delete it yet
            // rPointVisitsUploadQueue.write(rPointVisitKey, rPointVisit.toMap(listToJson: true));
            checkIn(rPointVisitKey, error: true);
          });
        }).catchError((e, s) {
          checkIn(rPointVisitKey, error: true);
        });
      } else {
        TelloLogger().i(
            'No media in rPointVisit ${rPointVisit.id}, sending and removing $rPointVisitKey');
        _repo.sendRPointVisit(rPointVisit).then((_) {
          rPointVisitsUploadQueue.remove(rPointVisitKey);
          checkIn(rPointVisitKey);
        }).catchError((e, s) {
          TelloLogger().e('sendReportingPoint error: $e',
              stackTrace: s is StackTrace ? s : null);
          checkIn(rPointVisitKey, error: true);
        });
      }
    }
  }

  Future<void> syncOtherData() async {
    if (!Get.isRegistered<SyncService>() ||
        !HomeController.to.isOnline ||
        syncingOtherData$) return;

    if (!hasOtherData$) {
      if (MessageUploadService.to.hasData$)
        MessageUploadService.to.processQueue();
      TelloLogger()
          .i('SyncService syncOtherData(): no other data, returning...');
      return;
    }

    syncingOtherData$ = true;
    if (otherDataSyncCompleted.isCompleted)
      otherDataSyncCompleted = Completer<bool>();

    final prevBrokenPackageId =
        GetStorage().read(StorageKeys.prevBrokenPackageId) as String;
    final syncPackageId = Uuid().v1();
    TelloLogger().i('SyncService syncOtherData(): data sync started');

    final locationsString = GetStorage().read(StorageKeys.offlineLocations);
    final existingStatesString =
        GetStorage().read(StorageKeys.offlineDeviceStates);
    final alertCheckResultsString =
        GetStorage().read(StorageKeys.offlineAlertCheckResults);
    late List<Map<String, dynamic>> alertCheckResults;
    late List<Map<String, dynamic>> locations;
    late List<Map<String, dynamic>> deviceStates;

    if (alertCheckResultsString != null) {
      alertCheckResults =
          (json.decode(alertCheckResultsString as String) as List<dynamic>)
              .map((el) {
        return AlertCheckResult.fromMap(el as Map<String, dynamic>)
            .toMapForServer();
      }).toList();
    }

    if (locationsString != null) {
      locations = List<Map<String, dynamic>>.from(
          json.decode(locationsString as String) as List<dynamic>);
    }

    if (existingStatesString != null) {
      TelloLogger().i(
          'SyncService syncOtherData() existingStatesString: $existingStatesString ');
      deviceStates = List<Map<String, dynamic>>.from(
          json.decode(existingStatesString as String) as List<dynamic>);
    }

    try {
      TelloLogger().i('SyncService syncOtherData() syncing...');
      TelloLogger().i(
          'SyncService syncOtherData() alertCheckResults: ${alertCheckResults.length}, $alertCheckResults');
      TelloLogger().i(
          'SyncService syncOtherData() locations: ${locations.length}, $locations');
      TelloLogger().i(
          'SyncService syncOtherData() deviceStates: ${deviceStates.length}, $deviceStates');
      await _repo.openSync(
        syncPackageId: syncPackageId,
        prevBrokenPackageId: prevBrokenPackageId,
        locations: locations,
        deviceStates: deviceStates,
        alertCheckResults: alertCheckResults,
      );
      await _repo.closeSync(syncPackageId);
      await _cleanOtherDataStorage();
      TelloLogger().i('SyncService syncOtherData(): sync is completed.');
      if (!otherDataSyncCompleted.isCompleted)
        otherDataSyncCompleted.complete();
      if (MessageUploadService.to.hasData$)
        MessageUploadService.to.processQueue();
    } catch (e, s) {
      // ANOTHER WAY OF HANDLING SYNC FUTURES - REMOVE IT LATER, if the current scheme works well.
      // hasOfflineLocations$.addError('SyncService: otherData sync error: $e');
      // hasOfflineDeviceStates$.addError('SyncService: otherData sync error: $e');
      // hasOfflineAlertCheckResults$.addError('SyncService: otherData sync error: $e');
      GetStorage().write(StorageKeys.prevBrokenPackageId, syncPackageId);
      if (!otherDataSyncCompleted.isCompleted) {
        otherDataSyncCompleted.completeError(
            'SyncService syncOtherData(): otherData sync error: $e');
      }
      TelloLogger().e('SyncService syncOtherData(): otherData sync error: $e',
          stackTrace: s);
    } finally {
      syncingOtherData$ = false;
    }
  }

  Future<void> syncOfflineEvents() async {
    final hasNoEvents = !hasOfflineEvents$;
    if (!Get.isRegistered<SyncService>() ||
        !HomeController.to.isOnline ||
        syncingOfflineEvents$ ||
        hasNoEvents) return;

    TelloLogger().i('SyncService syncOfflineEvents(): sync started...');
    syncingOfflineEvents$ = true;
    if (offlineEventsSyncCompleted.isCompleted)
      offlineEventsSyncCompleted = Completer<bool>();

    await HomeController.to.groupsFetched.future;

    final eventFutures = <Future<void>>[];
    final offlineEventsBox = GetStorage(StorageKeys.offlineEventsBox);
    final events = offlineEventsBox
        .getValues<Iterable<dynamic>>()
        .map((e) => e as Map<String, dynamic>)
        .toList();
    final sosEventData =
        offlineEventsBox.read<Map<String, dynamic>>(StorageKeys.sosEvent);

    // TODO: send SOS with other events
    // Here we are separating rest of the events from the sos
    if (sosEventData != null) {
      events.removeWhere((e) {
        final isSos = e['typeId'] as String ==
            AppSettings().eventSettings.sosTypeConfigId;
        return isSos;
      });

      TelloLogger().i('SyncService syncOfflineEvents(): sending sosEvent...');

      final createSosFuture = SosRepository().createSos(sosEventData)
        ..then((_) {
          SosService.to.clearSos();
          TelloLogger()
              .i('SyncService syncOfflineEvents(): sosEvent sent and cleared.');
        })
        ..catchError((e, s) {
          TelloLogger().e(
            'SyncService syncOfflineEvents(): sosEvent sending error: $e',
            stackTrace: s is StackTrace ? s : null,
          );
          if (e?.error is TelloError) {
            final errorCode = (e.error as TelloError).code;
            if (errorCode == 701) SosService.to.clearSos();
          }
        });
      eventFutures.add(createSosFuture);
    }

    // For testing purposes - in case we need to clean events
    // offlineEventsBox.erase();
    // return syncingOfflineEvents$ = false;

    for (final eventData in events) {
      final event = OutgoingEvent.fromMap(eventData);
      TelloLogger().i(
          'SyncService syncOfflineEvents(): sending event: ${event.id}, ${event.title}.');

      if (event.hasDeferredUploadMedia) {
        TelloLogger().i('SyncService syncOfflineEvents(): '
            'event ${event.id} has ${event.deferredUploadMedia.length} deferred media, processing...');
        final mediaUploadService = MediaUploadService.to;
        final eventMedia = mediaUploadService.allMediaByEventId[event.id!] = [
          ...event.deferredUploadMedia
        ];
        mediaUploadService.uploadAllMediaForId(event.id!, showError: false);

        await Future.wait(eventMedia.map((m) => m.uploadComplete.future));
        event.clearDeferredUploadMedia();

        for (final m in eventMedia) {
          if (m.isUploadDeferred()) {
            event.addDeferredUploadMedia(m);
          } else if (m.publicUrl != null) {
            event.addMediaUrl(m);
          }
        }
        MediaUploadService.to.deleteAllById(event.id!);

        if (event.hasDeferredUploadMedia) {
          GetStorage(StorageKeys.offlineEventsBox)
              .write(event.id!, event.toMap());
          TelloLogger().i('SyncService syncOfflineEvents(): '
              'event ${event.id} still has ${event.deferredUploadMedia.length} deferred media, returning...');
          continue;
        }
        TelloLogger().i(
            'SyncService syncOfflineEvents(): deferred media have been uploaded, sending event...');
      }

      final createEventFuture =
          EventsRepository().createEvent(event.toMap(forServer: true))
            ..then((_) {
              EventHandlingService.to?.removeEvent(event.id!);
              TelloLogger().i(
                  'SyncService syncOfflineEvents(): event ${event.id} sent and cleared.');
            })
            ..catchError((e, s) {
              TelloLogger().e(
                'SyncService syncOfflineEvents(): event ${event.id} sending error: $e',
                stackTrace: s is StackTrace ? s : null,
              );
            });
      eventFutures.add(createEventFuture);
    }
    // It'll also work if eventFutures.isEmpty
    Future.wait(eventFutures)
        .then((_) => offlineEventsSyncCompleted.complete())
        .catchError((e) => offlineEventsSyncCompleted.completeError(e))
        .whenComplete(() => syncingOfflineEvents$ = false);
  }

  Future<void> _cleanOtherDataStorage() async {
    TelloLogger().i('SyncService: cleaning otherData storage...');
    // We must await here, otherwise our listeners won't be notified
    await GetStorage().remove(StorageKeys.prevBrokenPackageId);
    await GetStorage().write(StorageKeys.offlineAlertCheckResults, null);
    await GetStorage().write(StorageKeys.offlineLocations, null);
    await GetStorage().write(StorageKeys.offlineDeviceStates, null);
  }
}
