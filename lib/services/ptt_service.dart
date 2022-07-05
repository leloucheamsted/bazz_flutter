import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/group_model.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/modules/settings_module/media_settings.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/rtc_service.dart';
import 'package:bazz_flutter/services/snack_bar_display.dart';
import 'package:bazz_flutter/services/sound_pool_service.dart';
import 'package:bazz_flutter/services/transmission_recording.dart';
import 'package:bazz_flutter/services/vibrator.dart';
import 'package:eventify/eventify.dart' as evf;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/media_stream.dart';
import 'package:flutter_webrtc/utils.dart';
// import 'package:flutter_webrtc/web/media_stream.dart';
import 'package:flutter_webrtc/get_user_media.dart' as nav;
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:flutter_webrtc/media_stream.dart';
// import 'package:flutter_webrtc/webrtc.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
// import 'package:get/get_navigation/src/snackbar/snack.dart';
import 'package:get_storage/get_storage.dart';
import 'package:rxdart/rxdart.dart';
// ignore: import_of_legacy_library_into_null_safe
import 'package:flutter_webrtc/get_user_media.dart' as md;
import '../app_theme.dart';

class PTTService extends evf.EventEmitter {
  static final PTTService _singleton = PTTService._();

 late factory PTTService() => _singleton;

  PTTService._();

 late  MediaStream _localStream;
 late  Map<String, Object> _mediaConstraints;
 late  RTCService rtcService;
 late  Directory tempDir;
 late  Map<String, TransmissionRecording> transmissionMap = {};

  late BehaviorSubject<RxGroup> activeGroup$;
  late PublishSubject<RxGroup> requestTx$;
  late PublishSubject<String> txStarted$;
 late  PublishSubject<int> stopTx$;
 late  PublishSubject<String> txStopped$;
 
 late  int stop = 0;
  late bool _serviceInitialized = false;
 late  Uint8List chirpSoundBuffer;
  late Uint8List chirpEndSoundBuffer;
  late RxGroup _activeGroup;
 late  DateTime activeGroupStartTime;
 late  List<StreamSubscription> _subscriptions = [];
late   List<evf.Listener> _listeners = [];
 late  RxUser _privateCallUser;
late   String _privateGroupId;
 late  bool isVideoMode = true;

  Future<void> init({bool isOnline = false}) async {
    try {
      TelloLogger().i(
          '################################### STARTING Services initialized: $_serviceInitialized &&  ${Session.user}###################################');
      if (_serviceInitialized) return;
      activeGroup$ = BehaviorSubject();
      requestTx$ = PublishSubject();
      txStarted$ = PublishSubject();
      stopTx$ = PublishSubject();
      txStopped$ = PublishSubject();
      TelloLogger().i("init() PTT Service");
      rtcService = await RTCService().init();
      if (AppSettings().videoModeEnabled) {
        RTCService().onAddRemoteStream = (stream) {
          TelloLogger().i("CALL _signaling.onAddRemoteStream");
          if (stream.getVideoTracks().isNotEmpty) {
            emit('videoRemoteStreamAdded', this, stream);
          }
        };

        RTCService().onRemoveRemoteStream = (stream) {
          TelloLogger().i("CALL _signaling.onRemoveRemoteStream");
          emit('videoRemoteStreamRemoved', this, stream);
        };
      }

      if (isOnline) {
        await rtcService.connect();
      }

      rtcService.setMetric('sessionId', TelloLogger.sessionId);

      _listeners.add(rtcService.on('trackStats', this, (event, context) {
        emit('trackStats', this, event.eventData);
      }));

      _listeners.add(rtcService.on('producerOffer', this, (event, context) {
        emit('producerOffer', this, event.eventData);
      }));

      _listeners.add(rtcService.on('producerInfo', this, (event, context) {
        emit('producerInfo', this, event.eventData);
      }));

      _listeners.add(rtcService.on('consumerOffer', this, (event, context) {
        emit('consumerOffer', this, event.eventData);
      }));

      _listeners.add(rtcService.on('consumerInfo', this, (event, context) {
        emit('consumerInfo', this, event.eventData);
      }));

      rtcService.onCancelled = () {
        stopSending();
      };
      TelloLogger().i("init() PTT Service 44444");
      _initButtonStreamControls();

      _subscriptions.add(rtcService.callState$
          .where((TxState txState) {
            final majorState = [StreamingState.receiving, StreamingState.sending].contains(txState.state);
            TelloLogger().i("00000txState: [${txState.state}] $majorState");
            return majorState;
          })
          .map((txState) {
            TelloLogger().i("11111txState: [${txState.state}] Major state transition");
            return txState;
          })
          .debounceTime(const Duration(seconds: 30))
          .switchMap((TxState txState) =>
              rtcService.callState$.where((TxState txState) => txState.state == StreamingState.idle).take(1))
          .listen((TxState txState) async {
            TelloLogger().i("2222txState: [${txState.state}] Idle after Major state transition");
            if (rtcService.callState$.value != null && rtcService.callState$.value.state == StreamingState.idle) {
              TelloLogger().i("333333txState: [${txState.state}] Closing transports...");
              await rtcService.closeReceiveTransport();
              await rtcService.closeSendTransport();
            }
          }));

      rtcService.onReady = (txId) async {
        try {
          await SoundPoolService().stopRadioChirpSound();
          await Vibrator.stopNotificationVibration();
          //await transmission?.start();
        } catch (e, s) {
          TelloLogger().e("error while rtc service is ready $e", stackTrace: s);
        }
      };

      TelloLogger().i(
          '################################### FINISH  Services initialized: $_serviceInitialized &&  ${Session.user}###################################');
      _serviceInitialized = true;
    } catch (e, s) {
      TelloLogger().e("PTT SERVICE INIT Error $e", stackTrace: s);
      rethrow;
    }
  }

  Future<void> dispose({bool isOnline = true}) async {
    if (!_serviceInitialized) return;
    TelloLogger().i("START  PTT SERVICE dispose()");
    //SystemChannels.lifecycle.setMessageHandler(null);
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    for (final listener in _listeners) {
      listener.cancel();
    }
    _subscriptions = [];
    _listeners = [];
    await rtcService.dispose(isOnline: isOnline);
    _localStream.dispose();
    WebRTC.stopAudioSession();
    activeGroup$.close();
    requestTx$.close();
    txStarted$.close();
    stopTx$.close();
    txStopped$.close();
    _localStream = null as MediaStream;
    _mediaConstraints = null as Map<String,Object>;
    rtcService = null as RTCService;

    activeGroup$ = null as BehaviorSubject<RxGroup>;
    requestTx$ = null  as PublishSubject<RxGroup>;
    txStarted$ = null as PublishSubject<String>;
    stopTx$ = null as PublishSubject<int>;
    txStopped$ = null as PublishSubject<String>;
    stop = 0;
    _activeGroup = null as RxGroup;
    activeGroupStartTime = null as DateTime;
    _serviceInitialized = false;
    TelloLogger().i("FINISH  PTT SERVICE dispose()() ");
  }

  Future<void> reset() async {
    await dispose();
    await init();
  }

  void _initButtonStreamControls() {
    final Stream<int> stopAfterStart$ = requestTx$.switchMap((RxGroup group) {
      TelloLogger().i("000000000000000000stopAfterStart ${group.id}");
      return stopTx$;
    }).asBroadcastStream();

    final Stream<String> startedAfterStart$ = requestTx$.switchMap((RxGroup group) {
      TelloLogger().i("1111111111111111111111 startedAfterStart ${group.id}");
      return txStarted$;
    }).asBroadcastStream();

    _subscriptions.add(stopAfterStart$.listen((int stopId) => TelloLogger().i("stopAfterStart $stopId")));
    _subscriptions.add(startedAfterStart$.listen((String txId) => TelloLogger().i("startedAfterStart $txId")));
    _subscriptions.add(txStopped$.startWith(null as String).switchMap((String txId) {
      TelloLogger().i("[request] Switch map");
      return requestTx$.take(1);
    }).listen((RxGroup group) {
      TelloLogger().i("(request, stop) ${group.id}");
      _sendRTCMessage(group);
    }));

    _subscriptions.add(requestTx$.switchMap((RxGroup group) {
      TelloLogger().i("[stop] Switchmap");
      return Rx.combineLatest2(stopAfterStart$.take(1), startedAfterStart$.take(1), (int stopId, String txId) {
        TelloLogger().i("Combine $stopId,$txId");
        return txId;
      });
    }).listen((String txId) {
      TelloLogger().i("(started, stop) $txId");
      _stopSending(txId);
    }));
  }

  void sendRTCMessage({RxUser ?privateCallUser, String? privateGroupId, bool isPtt = true}) {
    TelloLogger().i("sendRTCMessage ==> \$ ${_activeGroup.id} $isPtt");
    isVideoMode = !isPtt;
    _privateCallUser = privateCallUser as RxUser;
    _privateGroupId = privateGroupId as String;
    requestTx$.add(_activeGroup);
  }

  void stopSending() {
    if (stopTx$ == null) return;
    TelloLogger().i("stopTx ====>\$");
    _privateCallUser = null as RxUser;
    stopTx$.add(stop++);
  }

  void keepAlive() {
    TelloLogger().i("Keep Alive");
  }

  Future<void> _sendRTCMessage(RxGroup group) async {
    try {
      await Vibrator.startShortVibration();
      SoundPoolService().playRadioChirpSound();
      final Stopwatch stopwatch = Stopwatch()..start();
      TelloLogger().i('[Config Bloc] Sending RTC message to ${group.members.users.length} recipients');
      await createStream();
      emit('localStreamAdded', this, _localStream);

      final txId = await rtcService.sendStream(_localStream, group,
          stopwatch: stopwatch, privateCallUser: _privateCallUser, privateGroupId: _privateGroupId);
      if (txId != null) {
        TelloLogger().i('Txid: $txId');
      } else {
        TelloLogger().i("no transmission created!");
      }
      if (txId == null) {
        TelloLogger().i("stopTx\$ - cancelled");
        stopTx$.add(null as int);
      }
      TelloLogger().i("txStarted\$");
      txStarted$.add(txId);
    } catch (e, s) {
      TelloLogger().e("Failed Sending RTC Message $e", stackTrace: s);
      Get.showSnackbarEx(GetBar(
        backgroundColor: AppColors.error,
        message: 'send RTC Message failure cant get receiving user $e',
        titleText: const Text("send RTC Message", style: AppTypography.captionTextStyle),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.brightIcon,
        ),
      ));
    }
  }

  Future<void> _stopSending(String txId) async {
    try {
      TelloLogger().i("Stop transmission - $txId");
      if (txId != null) {
        TelloLogger().i("Transmission $txId stopped, finalizing recording");
        transmissionMap.remove(txId);
      } else {
        TelloLogger().i("No message created for transmission!");
      }
      TelloLogger().i("[$txId] Recording stopped and queued for upload");
      txStopped$.add(txId);
      await rtcService.stopSending();
      await SoundPoolService().playRadioChirpEndSound();
      emit('localStreamRemoved', this, _localStream);
    } catch (e, s) {
      TelloLogger().i("recordOfflineMessage failure cant get receiving user $e", stackTrace: s);
      Get.showSnackbarEx(GetBar(
        backgroundColor: AppColors.error,
        message: 'record Offline Message failure cant get receiving user $e',
        titleText: const Text("record Offline Message", style: AppTypography.captionTextStyle),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.brightIcon,
        ),
      ));
    }
  }

  Future<void> setActiveGroup(RxGroup group) async {
    if (group != null && group.id == null || _activeGroup == null && group == null) {
      return;
    }
    if (_activeGroup == null || (group != null && _activeGroup != null && group.id != _activeGroup.id)) {
      activeGroupStartTime = DateTime.now().toUtc();
    }

    _activeGroup = group;

    if (_activeGroup.id != "all") {
      activeGroup$.add(_activeGroup);
    }

    await rtcService.setActiveGroup(_activeGroup);
  }

  Future<void> createStream() async {
    final mediaConstraints =
        !isVideoMode ? MediaSettings().mediaConstraintsAudio : MediaSettings().mediaConstraintsVideo;
    if (mediaConstraints != _mediaConstraints) {
      _localStream = null as MediaStream;
      _mediaConstraints = mediaConstraints;
    }
    if (_localStream != null) return;
    final stream = await nav.navigator.getUserMedia(_mediaConstraints) ;
    _localStream = stream as MediaStream;
  }

  void switchCamera() {
    if (_localStream != null && _localStream.getVideoTracks().isNotEmpty) {
      _localStream.getVideoTracks()[0].switchCamera().catchError((e, s) {
        TelloLogger().e("err  switchCamera => $e", stackTrace: s is StackTrace ? s : null);
      });
    }
  }
}
