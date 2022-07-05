import 'dart:async';
import 'dart:io';

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/device_model.dart' as device_model;
import 'package:bazz_flutter/models/group_model.dart';
import 'package:bazz_flutter/models/local_audio_message.dart';
import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/recipient_model.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/services/device_outputs_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/signaling.dart';
import 'package:bazz_flutter/services/snack_bar_display.dart';
import 'package:bazz_flutter/services/sound_pool_service.dart';
import 'package:bazz_flutter/services/transmission_recording.dart';
import 'package:bazz_flutter/shared_widgets/system_dialog.dart';
import 'package:eventify/eventify.dart' as evf;
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_audio_manager/flutter_audio_manager.dart';
import 'package:flutter_incall_manager/flutter_incall_manager.dart';
import 'package:flutter_mediasoup/mediasoup_client/media_track_stats.dart';
import 'package:flutter_webrtc/media_stream_track.dart';
import 'package:flutter_webrtc/utils.dart';
import 'package:flutter_webrtc/webrtc.dart';
// import 'package:flutter_webrtc/web/media_stream.dart';
// import 'package:flutter_mediasoup/flutter_mediasoup.dart';
// import 'package:flutter_mediasoup/mediasoup_client/media_track_stats.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:flutter_webrtc/utils.dart';
// import 'package:flutter_webrtc/webrtc.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:get/get_navigation/get_navigation.dart';
// import 'package:get/get_navigation/src/snackbar/snack.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';
import 'package:mutex/mutex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:rxdart/subjects.dart';
import 'package:uuid/uuid.dart';
import 'package:flutter_mediasoup/flutter_mediasoup.dart';

typedef GroupModifiedCallback = Function(
    Map<String, dynamic> groupModifiedEvent);
typedef StreamStateCallback = void Function(MediaStream stream);

class TxState {
  StreamingState state;
  RxUser? user;
  String? groupId;

  TxState({this.state = StreamingState.idle, this.groupId, this.user});

  bool get active => state != StreamingState.idle;
}

class RTCService extends evf.EventEmitter {
  static RTCService _singleton = RTCService._();

  factory RTCService() => _singleton;

  RTCService._();

  // NotificationService _notificationService = NotificationService();
  bool? _isConnected;
  bool? _connecting;
  Completer? _connected;

  late Signaling _signaling;
  late Completer prevRecordingComplete;
  late Completer _sendTransportReady;
  late Completer _producing;
  late Transport _sendTransport;
  late Transport _recvTransport;
  late Device _device;
  late IncallManager _incallManager;
  late String _userId;
  late String _positionId;
  late RxGroup _activeGroup;
  late String _txId;
  late String _offlineTxId;
  late bool _preparing;
  late bool _cleaning;
  late bool _sending;
  late RxUser _receivingFromUser;
  late String _receivingFromGroupId;
  late RxGroup _group;
  late RxUser _privateCallUser;
  late String _privateGroupId;
  late List<Producer> _producers = [];
  late LocalAudioMessage currentMessage;

  GroupModifiedCallback? onGroupModified;
  void Function()? onCancelled;
  void Function(String txId)? onReady;

  late BehaviorSubject<bool> setActiveGroupError$;
  late BehaviorSubject<bool> isOnline$;
  late BehaviorSubject<bool> timeOutConnecting$;
  late BehaviorSubject<TxState> callState$;
  late Map<String, dynamic> metrics;
  late Map routerRtpCapabilities;

  late StreamSubscription _signalingConnectedSub;
  late Timer _createTransportsTimer;
  late Timer _transportStatTimer;
  late TransmissionRecording onlineRecording;
  late TransmissionRecording offlineRecording;
  late final List<evf.Listener> _listeners = [];
  final Mutex _mutex = Mutex();
  late List<evf.Listener> _sendTransportListeners = [];
  late List<evf.Listener> _receiveTransportListeners = [];

  Device get device => _device;

  Future<RTCService> init() async {
    try {
      TelloLogger().i("init() RTCService");
      _userId = Session.user!.id;
      _positionId = Session.shift!.positionId!;
      offlineRecording = TransmissionRecording(
          tempDir: (await getExternalStorageDirectory())!.path);
      final tempDir = await getExternalStorageDirectory();
      onlineRecording = TransmissionRecording(tempDir: tempDir!.path);
      _isConnected = false;
      _connected = Completer();
      _sendTransportReady = Completer();
      _producing = Completer();
      _device = Device as Device;
      await _device.init();
      setActiveGroupError$ = BehaviorSubject<bool>.seeded(false);
      isOnline$ = BehaviorSubject<bool>.seeded(false);
      callState$ = BehaviorSubject();
      metrics = {};
      TelloLogger().i("init() RTCService00000000000000");

      _signaling = Signaling()..init();
      _connecting = true;

      TelloLogger().i(
          "Future<RTCService> init() async routerRtpCapabilities === $routerRtpCapabilities");
      if (Platform.isIOS) {
        _incallManager = IncallManager();
      }

      //the underline layer is clearing the transport channel so the timer recreate the transport when transport is disposed
      _createTransportsTimer = Timer.periodic(
          Duration(seconds: AppSettings().createTransportsPeriod),
          (timer) async {
        if (_isConnected == true) {
          try {
            await _mutex.acquire();
            await createSendTransport();
            await createReceiveTransport();
          } catch (e, s) {
            TelloLogger().e("Error while creating send receive transport $e ",
                stackTrace: s);
          } finally {
            _mutex.release();
          }
        }
      });

      _signalingConnectedSub =
          _signaling.connected.listen((bool isConnected) async {
        _isConnected = isConnected;
        if (_isDisposing) return;
        if (isConnected) {
          if (!_connected!.isCompleted) {
            TelloLogger().i("[RTC Service] signaling connected");

            // Cleanup state
            _connecting = false;
            _preparing = false;
            if (_offlineTxId == null) _sending = false;
            _receivingFromUser = null as RxUser;
            _receivingFromGroupId = null as String;
            _cleaning = false;

            _connected!.complete();

            await createReceiveTransport();
            await createSendTransport();
            _pushState();
          }

          _updateActiveGroup();
          _updateMetrics();
        } else {
          _connecting = true;
          _pushState();

          if (onCancelled != null) {
            onCancelled!();
          }
          _connected = Completer();
          _producers = [];
          await closeSendTransport(isOnline: false);
          await closeReceiveTransport(isOnline: false);
          TelloLogger().e("[RTC Service] signaling disconnected!!");
        }
      });
      TelloLogger().i('RTC SERVICE INIT DONE 00000 ');
      _listeners.add(_signaling.on('newConsumer', this, (event, context) async {
        try {
          TelloLogger().i("[RTC Service] Receiving transmission!");
          if (onCancelled != null) {
            onCancelled!();
          }
          if (_activeGroup == null) return;
          final message = event.eventData as Map<String, dynamic>;
          _handleNewConsumer(message);
        } catch (e, s) {
          TelloLogger()
              .e("Consumer failure cant get receiving user $e", stackTrace: s);
          Get.showSnackbarEx(GetBar(
            backgroundColor: AppColors.error,
            message: 'Consumer failure cant get receiving user $e',
            titleText: const Text("Error Consumer event",
                style: AppTypography.captionTextStyle),
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.brightIcon,
            ),
          ));
        }
      }));

      _listeners.add(
          _signaling.on('newPrivateConsumer', this, (event, context) async {
        try {
          TelloLogger().i("[RTC Service] Receiving Private transmission!");
          if (onCancelled != null) {
            onCancelled!();
          }
          if (_activeGroup == null) return;
          final message = event.eventData as Map<String, dynamic>;
          _handleNewConsumer(message, privateCall: true);
        } catch (e, s) {
          TelloLogger().e("Private Consumer failure cant get receiving user $e",
              stackTrace: s);
          Get.showSnackbarEx(GetBar(
            backgroundColor: AppColors.error,
            message: 'Private Consumer failure cant get receiving user $e',
            titleText: const Text("Error Consumer event",
                style: AppTypography.captionTextStyle),
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.brightIcon,
            ),
          ));
        }
      }));

      _listeners.add(_signaling.on('consumerClosed', this, (event, context) {
        closeCurrentConsumer();
      }));

      _listeners.add(
          _signaling.on('newReceiveTransport', this, (event, context) async {
        try {
          TelloLogger().i("[RTC Service] newReceiveTransport");
          final message = event.eventData as Map<String, dynamic>;

          await createReceiveTransport();

          _signaling.acceptWithTimeout(message);
        } catch (e, s) {
          TelloLogger().e(
              "new Receive Transport failure cant get receiving user $e",
              stackTrace: s);
          Get.showSnackbarEx(GetBar(
            backgroundColor: AppColors.error,
            message: 'new Receive Transport failure cant get receiving user $e',
            titleText: const Text("new Receive Transport event",
                style: AppTypography.captionTextStyle),
            icon: const Icon(
              Icons.warning_amber_rounded,
              color: AppColors.brightIcon,
            ),
          ));
        }
      }));

      _listeners.add(
          _signaling.on('signalingHeartbeatResponse', this, (event, context) {
        TelloLogger().i('signalingHeartbeatResponse: ${event.eventData}');
      }));

      _listeners.add(_signaling
          .on('systemEventsSignalingHeartbeatResponse', this, (event, context) {
        TelloLogger()
            .i('systemEventsSignalingHeartbeatResponse: ${event.eventData}');
      }));

      _listeners.add(
          _signaling.on('failedCreatingConsumer', this, (event, context) async {
        final data = event.eventData as Map<String, dynamic>;
        TelloLogger().i('failedCreatingConsumer ===> ${data['reason']}');
        await _refreshReceiveTransport();
      }));

      _listeners.add(_signaling.on('enableLogging', this, (event, context) {
        emit('enableLogging', this);
      }));

      _listeners.add(_signaling.on('disableLogging', this, (event, context) {
        emit('disableLogging', this);
      }));
      TelloLogger().i('RTC SERVICE INIT DONE');
    } catch (e, s) {
      TelloLogger().e("RTC SERVICE INIT Error $e", stackTrace: s);
      rethrow;
    }
    return _singleton = this;
  }

  Future<void> dispose({bool isOnline = true}) async {
    TelloLogger().i("START  RTC SERVICE dispose()() ");
    _isDisposing = true;
    _listeners.clear();
    _createTransportsTimer.cancel();
    _transportStatTimer.cancel();

    await closeSendTransport(isOnline: isOnline);
    await closeReceiveTransport(isOnline: isOnline);
    await Signaling().dispose();
    _clearSendTransportListeners();
    _clearReceiveTransportListeners();

    callState$.close();
    isOnline$.close();
    setActiveGroupError$.close();
    metrics = {};
    for (final listener in _listeners) {
      listener.cancel();
    }
    _signalingConnectedSub.cancel();
    _isConnected = null;
    _connecting = null;
    _connected = null;
    _signaling = null as Signaling;
    _sendTransportReady = null as Completer<dynamic>;
    _producing = null as Completer<dynamic>;
    _sendTransport = null as Transport;
    _recvTransport = null as Transport;
    _device = null as Device;
    _incallManager = null as IncallManager;
    _userId = null as String;
    _positionId = null as String;
    _activeGroup = null as RxGroup;
    _txId = null as String;
    _preparing = null as bool;
    _cleaning = null as bool;
    _sending = null as bool;
    _receivingFromUser = null as RxUser;
    _receivingFromGroupId = null as String;
    _group = null as RxGroup;
    _privateCallUser = null as RxUser;
    _privateGroupId = null as String;
    _producers = [];
    currentMessage = null as LocalAudioMessage;
    onGroupModified = null;
    onCancelled = null;
    onReady = null;
    isOnline$ = null as BehaviorSubject<bool>;
    callState$ = null as BehaviorSubject<TxState>;
    metrics = null as Map<String, dynamic>;
    routerRtpCapabilities = null as Map<String, dynamic>;
    _signalingConnectedSub = null as StreamSubscription<dynamic>;
    _createTransportsTimer = null as Timer;
    offlineRecording = null as TransmissionRecording;

    _isDisposing = false;
    TelloLogger().i(
        'FINISH RTC DISPOSING routerRtpCapabilities ==  $routerRtpCapabilities');
    super.clear();
  }

  void closeCurrentConsumer() {
    try {
      TelloLogger().i(
          "[RTC Service] consumer closed! send transport == $_sendTransport");
      _receivingFromUser = null as RxUser;
      _receivingFromGroupId = null as String;
      _stopAudioSession();
      _stopTransportStat();
      _pushState();
    } catch (e, s) {
      TelloLogger().e("consumer Closed failure cant get receiving user $e",
          stackTrace: s);
      Get.showSnackbarEx(GetBar(
        backgroundColor: AppColors.error,
        message: 'consumer Closed failure cant get receiving user $e',
        titleText: const Text("Error Consumer event",
            style: AppTypography.captionTextStyle),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.brightIcon,
        ),
      ));
    }
  }

  Future<void> _handleNewConsumer(Map<String, dynamic> message,
      {bool privateCall = false}) async {
    final data = message["data"] as Map;
    final groupId = data['groupId'] as String;
    if (!privateCall &&
        groupId != 'all' &&
        HomeController.to.groups.firstWhere((element) => element.id == groupId,
                orElse: () => null as RxGroup) ==
            null) {
      return;
    }
    RxGroup currentGroup = _activeGroup;
    if (privateCall) {
      if (groupId != null) {
        currentGroup = HomeController.to.groups.firstWhere(
            (element) => element.id == groupId,
            orElse: () => null as RxGroup);
      }
    }
    TelloLogger().i(
        "[RTC Service] Transmission from ${data['userId']} in group ${data['groupId']} ${_activeGroup.members.users.length}");
    final peerId = message["peerId"] as String;
    final kind = message["kind"] as String;

    //TODO: create a RTCUser model and use it instead of RxUser, because data['user'] contains only id, profile and role
    final RxPosition pos = currentGroup.members.positions.firstWhere(
        (element) => element.worker.value.id == data['userId'].toString(),
        orElse: () => null as RxPosition);
    _receivingFromUser = pos.worker.value;
    _receivingFromUser;
    _receivingFromUser = HomeController.to.adminUsers.firstWhere(
        (element) => element.id == data['userId'].toString(),
        orElse: () => null!);

    _receivingFromUser = RxUser.unknownUser(data['userId'].toString());
    _receivingFromUser.isOnline.value = true;

    if (_receivingFromUser == null) {
      Get.showSnackbarEx(GetBar(
        backgroundColor: AppColors.error,
        message:
            'Consumer failure cant get receiving user ${data['userId']} active group ${_activeGroup.title}',
        titleText: const Text("Error Consumer event",
            style: AppTypography.captionTextStyle),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.brightIcon,
        ),
      ));
      //setActiveGroup(activeGroup);
    }
    TelloLogger().i(
        "AFTER [RTC Service] Receiving transmission! ${_receivingFromUser.fullName}  ${_receivingFromUser.id}");
    _receivingFromGroupId = data["groupId"] as String;
    _pushState(groupId: data["groupId"] as String);

    if (kind == 'audio') {
      _startAudioSession();
    }
    if (_recvTransport == null) {
      await createReceiveTransport();
    }
    if (_recvTransport != null) {
      TelloLogger().i(
          "11 START CONSUME ====> ${data["id"]} ${data["kind"]} ${data["rtpParameters"]}");
      _recvTransport.consume(
        id: data["id"] as String,
        kind: data["kind"] as String,
        rtpParameters: data["rtpParameters"] as Map<dynamic, dynamic>,
      );
      _signaling.acceptWithTimeout(message);
      _startTransportStat(false, kind: kind);
    }
  }

  void _startTransportStat(bool producer, {String kind = "audio"}) {
    _transportStatTimer.cancel();
    _transportStatTimer =
        Timer.periodic(const Duration(seconds: 1), (timer) async {
      MediaTrackStats stat;
      if (producer) {
        stat = await _sendTransport.getMediaTrackStat(kind: kind);
      } else {
        stat = await _recvTransport.getMediaTrackStat(kind: kind);
      }

      emit('trackStats', this, stat);
    });
  }

  void _stopTransportStat() {
    _transportStatTimer.cancel();
  }

  void _clearSendTransportListeners() {
    for (final listener in _sendTransportListeners) {
      listener.cancel();
    }
    _sendTransportListeners = [];
  }

  void _clearReceiveTransportListeners() {
    for (final listener in _receiveTransportListeners) {
      listener.cancel();
    }
    _receiveTransportListeners = [];
  }

  bool _isDisposing = false;

  Future<void> _startAudioSession() async {
    WebRTC.startAudioSession();

    TelloLogger().i(
        "####################################### SPEAKER PHONE #######################################");
    final value = DeviceOutputs().selectedDevice;
    switch (value) {
      case AudioPort.speaker:
        if (_incallManager != null) {
          TelloLogger().i('Forcing audio output to speaker');
          _incallManager.setSpeakerphoneOn(true);
        }
        WebRTC.enableSpeakerphone(true);
        break;
      case AudioPort.headphones:
        FlutterAudioManager.changeToHeadphones();
        break;
      case AudioPort.bluetooth:
        FlutterAudioManager.changeToBluetooth();
        break;
      case AudioPort.unknow:
        // TODO: Handle this case.
        break;
      case AudioPort.receiver:
        // TODO: Handle this case.
        break;
    }
  }

  Future<void> _stopAudioSession() async {
    if (AppSettings().videoModeEnabled) {
      if (onRemoveRemoteStream != null) {
        onRemoveRemoteStream!(_remoteStream!);
      }
      _remoteStream = null;
    }
    WebRTC.stopAudioSession();
  }

  void setPreparing() {
    _preparing = true;
    _pushState();
  }

  void unsetPreparing() {
    _preparing = false;
    _pushState();
  }

  //TODO: make a single variable for the StreamingState
  void _pushState({String? groupId, RxUser? user}) {
    StreamingState state = StreamingState.idle;
    TelloLogger().i("## connecting $_connecting sendtransport $_sendTransport");
    if (_connecting == true || _sendTransport == null) {
      state = StreamingState.connecting;
    }
    if (_sending == true) {
      state = StreamingState.sending;
    }
    if (_preparing == true) {
      state = StreamingState.preparing;
    }
    if (_cleaning == true) {
      state = StreamingState.cleaning;
    }
    if (_receivingFromUser != null) {
      state = StreamingState.receiving;
    }
    TelloLogger().i(
        " Call state $state ${groupId ?? _activeGroup.id} ${_receivingFromUser.id} ");
    isOnline$.add(!(state == StreamingState.connecting));
    if (callState$.value.state != state) {
      callState$.add(TxState(
          state: state,
          groupId: _receivingFromGroupId,
          user: _receivingFromUser));
    }
  }

  void setMetric(String key, dynamic value) {
    metrics[key] = value;
    _updateMetrics();
  }

  Future<void> connect() async {
    if (_userId == null)
      return TelloLogger().i('RtcService: _userId is null, returning...');

    await _signaling.connect();
    if (_signaling.connected.value == true) {
      if (_sendTransport == null) {
        await createSendTransport();
      }
      if (_recvTransport == null) {
        await createReceiveTransport();
      }
    }
  }

  MediaStream? _remoteStream;
  StreamStateCallback? onAddRemoteStream;
  StreamStateCallback? onRemoveRemoteStream;

  Future<void> createReceiveTransport() async {
    if (_recvTransport != null) {
      TelloLogger().i(
          '[$_txId] Receive transport has already been set up _sendTransport == $_sendTransport');
      return;
    }
    TelloLogger().i("[$_txId ] Creating receive transport");
    final recvTransportResponse =
        await _signaling.sendWithTimeout('createWebRtcTransport', {
      "producing": false,
      "consuming": true,
      "forceTcp": false,
      "sctpCapabilities": {
        "numStreams": {"OS": 1024, "MIS": 1024}
      }
    });

    if (recvTransportResponse != null &&
        recvTransportResponse is Map<String, dynamic>) {
      TelloLogger().i(
          "recvTransportResponse[sctpParameters] === > ${recvTransportResponse["sctpParameters"]} ,,,${recvTransportResponse["iceParameters"]},,,${recvTransportResponse["iceCandidates"]},,,${recvTransportResponse["sctpParameters"]}");
      _recvTransport = await _device.createRecvTransport(
        _signaling.peerId,
        id: recvTransportResponse["id"],
        iceParameters: recvTransportResponse["iceParameters"],
        iceCandidates: recvTransportResponse["iceCandidates"],
        dtlsParameters: recvTransportResponse["dtlsParameters"],
        sctpParameters: recvTransportResponse["sctpParameters"],
      );

      _clearReceiveTransportListeners();

      _receiveTransportListeners.add(_recvTransport.on('consumerOffer', this,
          (event, Object? context) async {
        emit('consumerOffer', this, event.eventData);
      }));

      _receiveTransportListeners.add(_recvTransport.on('consumerInfo', this,
          (evf.Event event, Object? context) async {
        emit('consumerInfo', this, event.eventData);
      }));

      _receiveTransportListeners.add(_recvTransport.on('connect', this,
          (evf.Event event, Object? context) async {
        final eventData = event.eventData is Map<String, dynamic>
            ? event.eventData as Map<String, dynamic>
            : null;

        if (eventData != null && eventData["data"] != null) {
          final dtlsParameters = eventData["data"];

          TelloLogger().i(
              "[$_txId] Connecting receive transport _sendTransport == $_sendTransport");
          await _connectTransport(_recvTransport, dtlsParameters);

          TelloLogger().i(
              "[$_txId] receive transport connected _sendTransport == $_sendTransport");
          eventData["cb"]();
        } else {
          throw Exception("Can't read connect event.eventData");
        }
      }));

      if (AppSettings().videoModeEnabled) {
        _receiveTransportListeners.add(_recvTransport.on('onAddTrack', this,
            (evf.Event event, Object? context) async {
          if (onAddRemoteStream != null) {
            onAddRemoteStream!(
                _recvTransport.pc.remoteStreams[0] as MediaStream);
          }
        }));
        _recvTransport.onAddRemoteStream = (stream) {
          if (onAddRemoteStream != null) {
            onAddRemoteStream!(stream as MediaStream);
          }
          _remoteStream = stream as MediaStream;
        };
        _recvTransport.pc.onRemoveStream = (stream) {
          TelloLogger().i("STAGE PC EVENT pc.onRemoveStream");
          if (onRemoveRemoteStream != null) {
            onRemoveRemoteStream!(stream as MediaStream);
          }
        };
      }

      TelloLogger()
          .i("[$_txId] CALLING JOIN _sendTransport == $_sendTransport");
      await join();
    }
  }

  Future<void> createSendTransport({Stopwatch? stopwatch}) async {
    _pushState();
    _sendTransportReady = Completer();

    if (_sendTransport == null) {
      await _connected?.future;
      TelloLogger().i("[$_txId] createSendTransport");
      TelloLogger().i("[$_txId] Creating send transport");

      final sendTransportResponse =
          await _signaling.sendWithTimeout('createWebRtcTransport', {
        "producing": true,
        "consuming": false,
        "forceTcp": false,
        "sctpCapabilities": {
          "numStreams": {"OS": 1024, "MIS": 1024}
        }
      });
      if (sendTransportResponse != null && sendTransportResponse is Map) {
        TelloLogger().i(
            "sendTransportResponse[sctpParameters] === > ${sendTransportResponse["sctpParameters"]} ,,,${sendTransportResponse["iceParameters"]},,,${sendTransportResponse["iceCandidates"]},,,${sendTransportResponse["sctpParameters"]}");
        _sendTransport = await _device.createSendTransport(
          _signaling.peerId,
          id: sendTransportResponse["id"],
          iceParameters: sendTransportResponse["iceParameters"],
          iceCandidates: sendTransportResponse["iceCandidates"],
          dtlsParameters: sendTransportResponse["dtlsParameters"],
          sctpParameters: sendTransportResponse["sctpParameters"],
        );
        _clearSendTransportListeners();
        _sendTransportListeners.add(_sendTransport.on('connect', this,
            (evf.Event event, Object? context) async {
          final eventData = event.eventData is Map<String, dynamic>
              ? event.eventData as Map<String, dynamic>
              : null;

          if (eventData != null && eventData["data"] != null) {
            final dtlsParameters = eventData["data"];

            TelloLogger().i("[$_txId] Connecting send transport");
            await _connectTransport(_sendTransport, dtlsParameters);

            TelloLogger().i("[$_txId] Send transport connected");
            eventData["cb"]();
          }
        }));

        _sendTransportListeners.add(_sendTransport.on('produce', this,
            (evf.Event event, Object? context) async {
          TelloLogger().i(
              ">>>>> [$_txId] [${DateFormat('HH:MM:ss.SSS').format(DateTime.now().toUtc())}] on('produce') ");
          _producers.add(event.eventData as Producer);
          final stopwatch = Stopwatch()..start();
          _initProduce(event.eventData as Producer, stopwatch: stopwatch);
        }));

        _sendTransportListeners.add(_sendTransport.on('producerOffer', this,
            (evf.Event event, Object? context) async {
          TelloLogger().i(">>>>> Producer Offer ===> ${event.eventData}");
          emit('producerOffer', this, event.eventData);
        }));

        _sendTransportListeners.add(_sendTransport.on('producerInfo', this,
            (evf.Event event, Object? context) async {
          TelloLogger().i(">>>>> Producer Info ===> ${event.eventData}");
          emit('producerInfo', this, event.eventData);
        }));

        await join();
      }
    }

    if (_sendTransportReady.isCompleted == false) {
      _sendTransportReady.complete();
    }

    _pushState();
  }

  Future<void> _initProduce(Producer producer, {Stopwatch? stopwatch}) async {
    _pushState();
    TelloLogger().i(
        ">>>>> [$_txId] [Sending produce group id == ${_group.id} kind == ${producer.kind} rtp ==> ${producer.rtpParameters}");
    dynamic res;
    TelloLogger()
        .i("_sendRTCMessage step 4.3 time = ${stopwatch?.elapsedMilliseconds}");
    if (_group != null) {
      await onlineRecording.start(stopwatch: stopwatch!);
      TelloLogger().i(
          "_sendRTCMessage step 4.4 time = ${stopwatch.elapsedMilliseconds}");
      WebRTC.startAudioSession();
      if (_privateCallUser == null) {
        final users = _group.members.users
            .where((u) => u.id != _userId)
            .map((u) => Recipient(
                recipientType: 'user',
                recipientId: u.id,
                userList: []).toJson())
            .toList();
        TelloLogger().i(
            "_sendRTCMessage step 4.5 time = ${stopwatch.elapsedMilliseconds}");
        res = await _signaling.sendWithTimeout('produce', {
          'transportId': _sendTransport.id,
          'kind': producer.kind,
          'rtpParameters': producer.rtpParameters,
          'receipientList': users,
          'groupId': _group.id
        });
        TelloLogger().i(
            "_sendRTCMessage step 4.6 time = ${stopwatch.elapsedMilliseconds}");
      } else {
        TelloLogger()
            .i("_initProduce private user ${_privateCallUser.fullName}");
        res = await _signaling.sendWithTimeout('privateProducer', {
          'transportId': _sendTransport.id,
          'kind': producer.kind,
          'rtpParameters': producer.rtpParameters,
          'recipient': Recipient(
              recipientType: 'user',
              recipientId: _privateCallUser.id,
              userList: []).toJson(),
          'groupId': _privateGroupId
        });
      }
      final result = res != null ? res['id'] as String : "";
      if (result == "busy") {
        emit('privateCallBusy', this, _privateCallUser);
        _producing.complete();
        return;
      } else if (result == "recipientPeerNotFound") {
        emit('recipientPeerNotFound', this, _privateCallUser);
        _producing.complete();
        return;
      }
      TelloLogger().i(
          "_sendRTCMessage step 4.7 time = ${stopwatch.elapsedMilliseconds}");
    }
    TelloLogger()
        .i("_sendRTCMessage step 4.8 time = ${stopwatch?.elapsedMilliseconds}");
    TelloLogger().i(">>>>> [$_txId]  produce response received");
    if (res != null && producer != null && res['produceFailed'] == null) {
      _sending = true;
      _pushState();
      producer.id = res['id'] as String;
      producer.resume();
      if (producer.kind == 'audio') {
        currentMessage = LocalAudioMessage(
          createdAt: DateTime.now().toUtc(),
          recipients: _privateCallUser != null
              ? [Session.user!.id, _privateCallUser.id]
              : null!,
          createdAtTimestamp: null as int,
          filePath: '',
          groupId: '',
          lat: '',
          long: '',
          mimeType: '',
          owner: null as RxUser,
          ownerPosition: null as PositionInfoCard,
          txId: '',
        )..txId = _txId;
      }
      TelloLogger().i(
          "_sendRTCMessage step 4.9 time = ${stopwatch?.elapsedMilliseconds}");
      TelloLogger()
          .i("[$_txId] [RTC Service] new producer with id: ${producer.id}");
    } else {
      _txId = null as String;
      _pushState();
      TelloLogger().e("[$_txId] Bad response for produce - no producer ID!");
    }

    _producing.complete();
    TelloLogger().i(
        "_sendRTCMessage step 4.9.1 time = ${stopwatch?.elapsedMilliseconds}");
  }

  Future<void> closeSendTransport({bool isOnline = true}) async {
    TelloLogger().i("[$_txId] closeSendTransport");
    // _incallManager.stop();
    if (_sendTransport != null) {
      TelloLogger()
          .i("[$_txId] closeSendTransport - transport is not null - closing");
      final transportId = _sendTransport.id;
      await _sendTransport.close();
      _sendTransport = null!;
      _producers = [];
      if (isOnline)
        await _signaling
            .sendWithTimeout('closeTransport', {"transportId": transportId});
    }
  }

  Future<void> closeReceiveTransport({bool isOnline = true}) async {
    TelloLogger().i("[$_txId] closeReceiveTransport");
    if (_recvTransport != null) {
      TelloLogger().i(
          "[$_txId] closeReceiveTransport - transport is not null - closing");
      final transportId = _recvTransport.id;
      await _recvTransport.close();
      _recvTransport = null!;
      if (isOnline)
        await _signaling
            .sendWithTimeout('closeTransport', {"transportId": transportId});
    }
  }

  // TODO: currently this is used only to send the rtp capabilities,
  // this should be moved to both create send transport and create receive transport
  Future<void> join() async {
    TelloLogger()
        .i("[$_txId] START join() async  _sendTransport == $_sendTransport");
    if (routerRtpCapabilities == null) {
      TelloLogger().i("Device is LOADING  _sendTransport == $_sendTransport");
      routerRtpCapabilities = await _signaling.sendWithTimeout(
          'getRouterRtpCapabilities', null as Map<String, dynamic>);
      TelloLogger().i(
          "Getting routerRtpCapabilities from router == $routerRtpCapabilities");
      await _device.load(
          routerRtpCapabilities /*, supportedCodecs: MediaSettings().getSupportedCodecs()*/);
      TelloLogger().i(
          "Device loaded  routerRtpCapabilities == ${_device.rtpCapabilities}");
    }
    await _signaling.sendWithTimeout('join', {
      "displayName": "",
      "device": {"flag": "mobile", "name": "mobile", "version": "1.0"},
      "rtpCapabilities": _device.rtpCapabilities
    });
    TelloLogger().i(
        "[$_txId] FINISH join() async  _sendTransport == ${_device.rtpCapabilities}");
  }

  Future<void> closePrivateCall(RxUser user) async {
    await _signaling.sendWithTimeout('closePrivateCall', {
      "recipient":
          Recipient(recipientType: 'user', recipientId: user.id, userList: [])
              .toJson(),
      "groupId": HomeController.to.activeGroup.id
    });
    TelloLogger().i("closePrivateCall ==> ${user.id}");
  }

  Future<void> _refreshSendTransport() async {
    //await _device.load(routerRtpCapabilities);
    await closeSendTransport();
    await createSendTransport();
  }

  Future<void> _refreshReceiveTransport() async {
    //await _device.load(routerRtpCapabilities);
    await closeReceiveTransport();
    await createReceiveTransport();
  }

  Future<String> sendStream(MediaStream stream, RxGroup group,
      {RxUser? privateCallUser,
      String? privateGroupId,
      Stopwatch? stopwatch}) async {
    await _mutex.acquire();
    try {
      TelloLogger().i("[$_txId] sendStream");
      _preparing = true;
      _pushState(groupId: group.id);

      _txId = Uuid().v1();
      _group = group;
      _privateCallUser = privateCallUser!;
      _privateGroupId = privateGroupId!;
      TelloLogger().i(
          "_sendRTCMessage step 3.1 time = ${stopwatch?.elapsedMilliseconds}");
      await createSendTransport(stopwatch: stopwatch);
      TelloLogger().i(
          "_sendRTCMessage step 3.2 time = ${stopwatch?.elapsedMilliseconds}");
      await _sendTransportReady.future;
      TelloLogger().i("[$_txId] sendStream - transport ready");
      TelloLogger().i(
          "_sendRTCMessage step 3.3 time = ${stopwatch?.elapsedMilliseconds}");
      _producing = Completer();

      if (_producers.isEmpty) {
        try {
          if (stream.getAudioTracks().isNotEmpty) {
            TelloLogger().i("Producing Audio ====>");
            const String kind = 'audio';
            await _sendTransport
                .produce(
                    kind: kind,
                    //stream: stream as MediaStream,
                    track: stream.getAudioTracks().first as MediaStreamTrack,
                    sendingRemoteRtpParameters:
                        _device.sendingRemoteRtpParameters(kind))
                .catchError((e, s) {
              TelloLogger().e(
                "[$_txId] Error, unable to produce audio, txId: $_txId, _device.sendingRemoteRtpParameters are NULL ${_device.sendingRemoteRtpParameters(kind) as Map}, unable to produce!!! Error: $e",
                stackTrace: s is StackTrace ? s : null,
              );
              _txId = null as String;
            }).timeout(Duration(
                    milliseconds:
                        AppSettings().sendTransportTimeoutInMilliseconds));
          }
          if (stream.getVideoTracks().isNotEmpty) {
            TelloLogger().i("Producing video ====>");
            const String kind = 'video';
            await _sendTransport
                .produce(
                    kind: kind,
                    // stream: stream as MediaStream!,
                    track: stream.getVideoTracks().first as MediaStreamTrack,
                    sendingRemoteRtpParameters:
                        _device.sendingRemoteRtpParameters(kind) as Map)
                .catchError((e, s) {
              TelloLogger().e(
                "[$_txId] Error, unable to produce video, _txId: $_txId, _device.sendingRemoteRtpParameters are NULL ${_device.sendingRemoteRtpParameters(kind) as Map}, unable to produce!!! Error: $e",
                stackTrace: s is StackTrace ? s : null,
              );
              _txId = null as String;
            }).timeout(Duration(
                    milliseconds:
                        AppSettings().sendTransportTimeoutInMilliseconds));
          }
          TelloLogger().i(
              "_sendRTCMessage step 3.4 time = ${stopwatch?.elapsedMilliseconds}");
        } catch (e, s) {
          TelloLogger()
              .e("[$_txId] Error, unable to produce!!!: $e", stackTrace: s);
          SystemDialog.showConfirmDialog(
            message: 'Unable to create Producer',
          );
          _txId = null as String;
          _producing.complete();
        }
      } else {
        for (final producer in _producers) {
          _initProduce(producer, stopwatch: stopwatch);
        }
      }
      await _producing.future;
      TelloLogger().i("[$_txId] producer ready");

      if (_txId == null) {
        _preparing = false;
        _refreshSendTransport();
      }
      if (onReady != null) {
        // _startAudioSession();
        onReady!(_txId);
      }

      _preparing = false;
      _pushState();
      _startTransportStat(true,
          kind: stream.getVideoTracks().isNotEmpty ? "video" : "audio");
      TelloLogger().i("[$_txId] sendStream complete");
      //HapticFeedback.vibrate();
    } catch (e, s) {
      TelloLogger().e("sendStream Failed reason => $e", stackTrace: s);
      rethrow;
    } finally {
      _mutex.release();
    }
    return _txId;
  }

  Future<LocalAudioMessage> stopSending() async {
    TelloLogger().i("[$_txId] stopSending");
    _stopAudioSession();
    final isPrivateProducer = _privateCallUser != null;
    final groupId = _group.id;
    _group = null as RxGroup;
    _sending = false;
    _preparing = false;
    _cleaning = true;
    _pushState();
    _stopTransportStat();
    HapticFeedback.vibrate();

    if (_producers.isNotEmpty) {
      for (final producer in _producers) {
        final String producerId = producer.id!;
        TelloLogger().i("[$_txId] pausing producer [${producer.id}]");
        producer.pause();
        if (!isPrivateProducer) {
          await _signaling
              .sendWithTimeout('closeProducer', {'producerId': producerId});
          TelloLogger().i("[$_txId] producer closed [$producerId]");
        } else {
          await _signaling.sendWithTimeout('closePrivateProducer', {
            'producerId': producerId,
            "recipient": Recipient(
                recipientType: 'user',
                recipientId: _privateCallUser.id,
                userList: []).toJson(),
            "groupId": groupId
          });
          _privateCallUser = null as RxUser;
          _privateGroupId = null as String;
          TelloLogger().i("[$_txId] private producer closed [$producerId]");
        }
      }
    }

    onlineRecording.stop(currentMessage);
    _cleaning = false;
    _pushState();

    TelloLogger().i("[$_txId] stopSending complete");

    return currentMessage;
  }

  Future<void> _connectTransport(
      Transport transport, DtlsParameters dtlsParameters) async {
    await _signaling.sendWithTimeout('connectWebRtcTransport', {
      'transportId': transport.id,
      'dtlsParameters': dtlsParameters.toMap()
    });
  }

  Future<void> setActiveGroup(RxGroup activeGroup) async {
    if (_receivingFromGroupId != null && activeGroup.id != "all") {
      closeCurrentConsumer();
    }
    _activeGroup = activeGroup;
    if (_isConnected!) {
      await _connected!.future;
      await _updateActiveGroup();
    }
  }

  //TODO: remove later
  // void inviteContact(GroupContact contact) {
  //   Contact _contact = contact.user.contact;
  //   _signaling.send(
  //       'inviteUser', {'mobile': _contact.phones.length > 0 ? _contact.phones.first.value : ''});
  // }

  Future<void> _updateActiveGroup() async {
    TelloLogger()
        .i("[$_txId] _updateActiveGroup [${_activeGroup.title ?? ''}]");
    try {
      await _signaling
          .sendWithTimeout('activeGroup', {"groupId": _activeGroup.id});
      // await Future.delayed(const Duration(seconds: 1), () => throw 'artificial throw'); //for testing purposes
      setActiveGroupError$.add(false);
    } catch (e, s) {
      setActiveGroupError$.add(true);
      SystemDialog.showConfirmDialog(
        message:
            'Failed to set ${_activeGroup.title} as active group, you are in a recorder mode!',
      );
      TelloLogger().e('Failed to update active group: $e', stackTrace: s);
    }
  }

  void _updateMetrics() {
    if (_signaling.connected.value == true) {
      _signaling.sendWithTimeout('metrics', metrics);
    }
  }

  Future<void> recordOfflineMessage({RxUser? privateCallUser}) async {
    try {
      await offlineRecording.start(
          isOffline: true, stopwatch: null as Stopwatch);
      //If a PTT button was released right after being pressed
      if (!HomeController.to.isRecordingOfflineMessage) return;
      _offlineTxId = Uuid().v1();
      currentMessage = LocalAudioMessage(
        createdAt: DateTime.now().toUtc(),
        recipients: _privateCallUser != null
            ? [Session.user!.id, _privateCallUser.id]
            : null!,
        createdAtTimestamp: null as int,
        filePath: '',
        groupId: '',
        lat: '',
        long: '',
        mimeType: '',
        owner: null as RxUser,
        ownerPosition: null as PositionInfoCard,
        txId: '',
      )..txId = _offlineTxId;
      _privateCallUser = privateCallUser!;
      _sending = true;
      _pushState();
      SoundPoolService().playRadioChirpSound();
      HapticFeedback.vibrate();
      TelloLogger().i('Offline message recording started');
    } catch (e, s) {
      TelloLogger().e("recordOfflineMessage failure: $e", stackTrace: s);
      rethrow;
    }
  }

  Future<void> stopOfflineRecording() async {
    try {
      if (_offlineTxId != null) {
        _sending = false;
        _cleaning = true;
        _pushState();
        offlineRecording.stop(currentMessage, isOffline: true);
      }

      _offlineTxId = null as String;
      _privateCallUser = null as RxUser;

      TelloLogger().i('Offline message recording stopped');
      _cleaning = false;
      _pushState();
      SoundPoolService().playRadioChirpEndSound();
      HapticFeedback.vibrate();
    } catch (e, s) {
      TelloLogger().e("stopOfflineRecording failure: $e", stackTrace: s);
      _sending = false;
      _cleaning = false;
      _pushState();
      rethrow;
    }
  }
}
