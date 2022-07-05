import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/services_address.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/services/data_connection_checker.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/media_stream.dart';
import 'package:flutter_webrtc/rtc_data_channel.dart';
import 'package:flutter_webrtc/rtc_ice_candidate.dart';
import 'package:flutter_webrtc/rtc_peerconnection.dart';
import 'package:flutter_webrtc/rtc_session_description.dart';
import 'package:flutter_webrtc/utils.dart';
import 'package:flutter_webrtc/webrtc.dart';
// import 'package:flutter_webrtc/webrtc.dart';
import 'package:logger/logger.dart' as log;

enum VideoSignalingState {
  // ignore: constant_identifier_names
  CallStateOutgoing,
  // ignore: constant_identifier_names
  CallStateIncoming,
  // ignore: constant_identifier_names
  CallStateConnected,
  // ignore: constant_identifier_names
  CallStateIdle,
  // ignore: constant_identifier_names
  CallStateBusy,
  // ignore: constant_identifier_names
  ConnectionOpen,
  // ignore: constant_identifier_names
  ConnectionClosed,
  // ignore: constant_identifier_names
  ConnectionError
}

/*
 * callbacks for Signaling API.
 */
typedef SignalingStateCallback = void Function(
    VideoSignalingState state, String peerId);

typedef StreamStateCallback = void Function(MediaStream stream);

typedef OtherEventCallback = void Function(dynamic event);

typedef OnOfferCallback = void Function(String peerId);

typedef OnLeaveCallback = void Function(String peerId);

typedef OnAnswerCallback = void Function(String peerId);

typedef OnCandidateCallback = void Function(String peerId);

typedef OnByeCallback = void Function(String peerId);

typedef OnBusyCallback = void Function(String peerId);

typedef OnErrorCallback = void Function();

typedef DataChannelMessageCallback = void Function(
    RTCDataChannel dc, RTCDataChannelMessage data);

typedef DataChannelCallback = void Function(RTCDataChannel dc);

class VideoSignaling {
  static final VideoSignaling _singleton = VideoSignaling._();

  factory VideoSignaling() => _singleton;

  VideoSignaling._();

  late WebSocket _socket;

  // ignore: prefer_typing_uninitialized_variables
  late String _sessionId;
  VideoSignalingState? _callState;

  late dynamic _lastOffer;

  late String _selfId;

  String? _contactName;
  late RTCPeerConnection _peerConnection;
  final _remoteCandidates = [];
  late bool _isConnecting;
  bool disposing = false;
  bool isOnline = false;
  late StreamSubscription _socketListener;

  late MediaStream _localStream;
  late MediaStream _remoteStream;
  late SignalingStateCallback onStateChange;
  late StreamStateCallback onLocalStream;
  late StreamStateCallback onAddRemoteStream;
  late StreamStateCallback onRemoveRemoteStream;
  late OtherEventCallback onPeersUpdate;
  late DataChannelMessageCallback onDataChannelMessage;
  late DataChannelCallback onDataChannel;
  late OnOfferCallback onOffer;
  late OnLeaveCallback onLeave;
  late OnAnswerCallback onAnswer;
  late OnByeCallback onBye;
  late OnCandidateCallback onCandidate;
  late OnErrorCallback onError;
  late OnBusyCallback onBusy;

  final Map<String, dynamic> _config = {
    'mandatory': {},
    'optional': [
      {'DtlsSrtpKeyAgreement': true},
    ],
  };

  final Map<String, dynamic> _constraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [],
  };

  Map<String, dynamic> config = {
    'iceServers': [
      {"url": "stun:stun.l.google.com:19302"},
    ],
    'iceTransportPolicy': 'all',
    'bundlePolicy': 'max-bundle',
    'rtcpMuxPolicy': 'require',
    'sdpSemantics': 'plan-b',
    'startAudioSession': true
  };

  final Map<String, dynamic> constraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      'OfferToReceiveVideo': true,
    },
    'optional': [
      {'`DtlsSrtpKeyAgreement`': true},
    ],
  };

  late StreamSubscription _isOnlineListener;

  //ConnectivityStatus _prevConnectivityStatus;
  late bool startRecoverySupport;

  //Timer _recoveryTimer;

  Future<void> startConnectionRecovery() async {
    if (startRecoverySupport) {
      TelloLogger().i("WAIT FOR VIDEO CONNECTION RECOVERY");
      await Future.delayed(
          Duration(seconds: AppSettings().videoSocketRecoveryPeriod));
      if (startRecoverySupport) connect();
    }
  }

  Future<void> init(String selfId, String contactName) async {
    _isConnecting = false;
    startRecoverySupport = true;
    _selfId = selfId;
    _contactName = contactName;
    _isOnlineListener = DataConnectionChecker().onStatusChange.listen((status) {
      switch (status) {
        case DataConnectionStatus.connected:
          isOnline = true;
          TelloLogger().i('[Video Service]Data connection is available.');
          connect();
          break;
        case DataConnectionStatus.disconnected:
          isOnline = false;
          TelloLogger()
              .i('[Video Service]You are disconnected from the internet.');
          if (!_isConnecting) disconnect();
          break;
      }
    });
  }

  Future<void> dispose() async {
    disposing = true;
    if (_localStream != null) {
      _localStream.dispose();
      _localStream = null as MediaStream;
      WebRTC.stopAudioSession();
    }
    await disconnect();
    _remoteStream.dispose();
    _isOnlineListener.cancel();
    _remoteStream = null as MediaStream;

    _peerConnection.close();

    if (_socket != null) await _socket.close();

    onStateChange = "" as SignalingStateCallback;
    onPeersUpdate = null as Function(dynamic);
    _isConnecting = false;
    startRecoverySupport = false;
    disposing = false;
  }

  Future<void> connect() async {
    final schema = ServiceAddress().webSocketVideoSchema;
    final host = ServiceAddress().webSocketVideoAddress;
    final port = ServiceAddress().wwsVideoPort;

    try {
      TelloLogger().i(
          "################################connect() BEFORE $_isConnecting ,,, $host ,,, $port");
      if (_isConnecting) return;
      _isConnecting = true;
      await disconnect();
      _socket = await _connectForSelfSignedCert(schema, host, port);
      raiseStateChange(VideoSignalingState.ConnectionOpen);

      _socketListener = _socket.listen((data) {
        TelloLogger().i("VIDEO Received data: $data");
        const JsonDecoder decoder = JsonDecoder();
        onMessage(decoder.convert(data as String));
      }, onDone: () async {
        TelloLogger().i('VIDEO Closed by server!');
        if (isOnline && !disposing) await AppSettings().tryUpdate();
        _isConnecting = false;
        startConnectionRecovery();
        raiseStateChange(VideoSignalingState.ConnectionClosed);
      }, onError: (error) async {
        TelloLogger().i('VIDEO Connection error!');
        if (isOnline && !disposing) await AppSettings().tryUpdate();
        _isConnecting = false;
        startConnectionRecovery();
        raiseStateChange(VideoSignalingState.ConnectionClosed);
        raiseStateChange(VideoSignalingState.ConnectionError);
      });

      await _sendWithTimeout('new', {
        'name': _contactName,
        'id': _selfId,
        'user_agent':
            'flutter-webrtc/' + Platform.operatingSystem + '-plugin 0.1.7'
      });

      raiseStateChange(VideoSignalingState.CallStateIdle);
    } catch (e, s) {
      TelloLogger().e("@@@@@@@@@@@@@@@@@@@@@@@@@@@@ VIDEO Connection error $e",
          stackTrace: s);
      if (isOnline && !disposing) await AppSettings().tryUpdate();
      _isConnecting = false;
      startConnectionRecovery();
      raiseStateChange(VideoSignalingState.ConnectionError);
    }
  }

  Future<void> disconnect() async {
    if (_socket != null) {
      await _socket.close().timeout(const Duration(seconds: 5));
      _socket = null as WebSocket;
    }
    _socketListener.cancel();
  }

  // ignore: type_annotate_public_apis
  Future<void> onMessage(message) async {
    final Map<String, dynamic> mapData = message as Map<String, dynamic>;
    if (mapData['type'] == null) {
      TelloLogger()
          .i("############################onMessage VIDEO TYPE IS NULL");
      return;
    }
    final data = mapData['data'];
    final type = mapData['type'];
    TelloLogger().i(
        "############################onMessage VIDEO $type data == ${data.toString()}");
    switch (mapData['type'] as String) {
      case 'peers':
        {
          List<dynamic> peers = data as List<dynamic>;
          if (onPeersUpdate != null) {
            Map<String, dynamic> event = new Map<String, dynamic>();
            event['self'] = _selfId;
            event['peers'] = peers;
            peers.removeWhere((i) => i['id'] == _selfId);
            if (onPeersUpdate != null) {
              onPeersUpdate(event);
            }
          }
        }
        break;
      //Incoming call
      case 'offer':
        {
          if (_peerConnection == null) {
            final media = data['media'];
            if (media == 'video') {
              _lastOffer = data;
              final fromId = data['from'] as String;
              final description = data['description'];
              final sessionId = data['session_id'];
              _sessionId = sessionId as String;
              raiseStateChange(VideoSignalingState.CallStateIncoming, fromId);
              final pc = await _createPeerConnection(fromId);
              _peerConnection = pc;
              await pc.setRemoteDescription(RTCSessionDescription(
                  description['sdp'] as String, description['type'] as String));
              if (_remoteCandidates.isNotEmpty) {
                // ignore: avoid_function_literals_in_foreach_calls
                _remoteCandidates.forEach((candidate) async {
                  await pc.addCandidate(candidate as RTCIceCandidate);
                });
                _remoteCandidates.clear();
              }
              if (onOffer != null) {
                onOffer(fromId);
                TelloLogger().i(
                    "STAGE 5555 GETTING AN  OFFER RAISE EVENT from id = $fromId self id $_selfId data.toString() = ${data.toString()}");
              }
            }
          } else {
            final fromId = data['from'] as String;
            sendBusy(fromId);
          }
        }
        break;
      case 'answer':
        {
          final fromId = data['from'];
          final description = data['description'];
          TelloLogger().i(
              "STAGE 77777 GETTING AN  ANSWER from id = $fromId self id $_selfId data.toString() = ${data.toString()}");
          final pc = _peerConnection;
          if (pc != null) {
            await pc.setRemoteDescription(RTCSessionDescription(
                description['sdp'] as String, description['type'] as String));
            TelloLogger().i(
                "STAGE 8888 GETTING AN  ANSWER PC REMOTE DESCRIPTION from id = $fromId self id $_selfId data.toString() = ${data.toString()}");
            raiseStateChange(VideoSignalingState.CallStateConnected);
          }
          if (onAnswer != null) {
            onAnswer(fromId as String);
            TelloLogger().i(
                "STAGE 9999999 GETTING AN  ANSWER onAnswer EVENT from id = $fromId self id $_selfId data.toString() = ${data.toString()}");
          }
        }
        break;
      case 'candidate':
        {
          final fromId = data['from'] as String;
          final candidateMap = data['candidate'];
          final pc = _peerConnection;
          TelloLogger().i(
              "44444444444444444 candidate $_selfId  ${candidateMap['candidate']} $fromId");
          final RTCIceCandidate candidate = RTCIceCandidate(
              candidateMap['candidate'] as String,
              candidateMap['sdpMid'] as String,
              candidateMap['sdpMLineIndex'] as int);
          if (pc != null) {
            await pc.addCandidate(candidate);
          } else {
            _remoteCandidates.add(candidate);
          }
          if (onCandidate != null) {
            onCandidate(fromId);
          }
        }
        break;
      case 'leave':
        {
          final fromId = data as String;
          TelloLogger()
              .i("STAGE ###11111  LEAVE from id = $fromId self id = $_selfId");
          if (isCurrentSession(fromId)) {
            clearSession();

            raiseStateChange(VideoSignalingState.CallStateIdle);
            if (onLeave != null) {
              onLeave(fromId);
            }
          }
        }
        break;
      case 'bye':
        {
          final toId = data['to'] as String;
          TelloLogger().i(
              "STAGE ###222222  BYE from id = $toId self id = $_selfId   $data");
          if (isCurrentSession(toId)) {
            clearSession();
            raiseStateChange(VideoSignalingState.CallStateIdle);

            if (onBye != null) {
              onBye(toId);
            }
          }
        }
        break;
      case 'keepalive':
        {
          TelloLogger().i('keepalive response!');
        }
        break;
      case 'error':
        {
          TelloLogger().i('RECEIVED ERROR MESSAGE DETAILS $data');
          clearSession();

          raiseStateChange(VideoSignalingState.CallStateIdle);

          if (onError != null) {
            onError();
          }
        }
        break;
      case 'busy':
        {
          TelloLogger().i('RECEIVED BUSY MESSAGE DETAILS $data');
          final fromId = data['from'] as String;

          raiseStateChange(VideoSignalingState.CallStateBusy);

          if (onBusy != null) {
            onBusy(fromId);
          }
        }
        break;
      default:
        break;
    }
  }

  void switchCamera() {
    if (_localStream != null) {
      //Helper.switchCamera( _localStream.getVideoTracks()[0]);
      _localStream.getVideoTracks()[0].switchCamera();
    }
  }

  void raiseStateChange(VideoSignalingState signalingState, [String? peerId]) {
    _callState = signalingState;
    if (onStateChange != null) {
      onStateChange(signalingState, peerId!);
    }
  }

  Future<void> invite(String toId) async {
    // ignore: prefer_interpolation_to_compose_strings
    _sessionId = "$_selfId#$toId";
    TelloLogger().i("invite _sessionId $_sessionId");
    raiseStateChange(VideoSignalingState.CallStateOutgoing);
    await _createPeerConnection(toId).then((pc) {
      _peerConnection = pc;
      _createOffer(toId);
    });
  }

  Future<void> bye(String toId) async {
    if (_sessionId != null) {
      TelloLogger().i("BYE ===> $_sessionId");
      await _sendWithTimeout(
          'bye', {'session_id': _sessionId, 'from': _selfId});
      clearSession();
    }
  }

  void clearSession() {
    if (_peerConnection != null) {
      if (_remoteStream != null) {
        _peerConnection.removeStream(_remoteStream);
      }
      _peerConnection.close();
      _peerConnection = null as RTCPeerConnection;
    }
    _sessionId = null as String;
  }

  bool isCurrentSession(String sender) {
    if (_sessionId != null) {
      return _sessionId.contains(sender, 0);
    }
    return false;
  }

  Future<WebSocket> _connectForSelfSignedCert(
      String schema, String host, int port) async {
    try {
      Random r = Random();
      final String key =
          base64.encode(List<int>.generate(8, (_) => r.nextInt(255)));
      final SecurityContext securityContext = SecurityContext();
      final HttpClient client = HttpClient(context: securityContext);
      client.badCertificateCallback =
          (X509Certificate cert, String host, int port) {
        TelloLogger().i('Allow self-signed certificate => $host:$port. ');
        return true;
      };
      TelloLogger().i(" $schema://$host:$port/ws");
      String urlSchema = schema;
      if (schema == "ws") {
        urlSchema = "http";
      } else if (schema == "wss") {
        urlSchema = "https";
      }
      final HttpClientRequest request = await client.getUrl(Uri.parse(
          '$urlSchema://$host:$port/ws')); // form the correct url here
      request.headers.add('Connection', 'Upgrade');
      request.headers.add('Upgrade', 'websocket');
      request.headers.add(
          'Sec-WebSocket-Version', '13'); // insert the correct version here
      request.headers.add('Sec-WebSocket-Key', key.toLowerCase());

      final HttpClientResponse response = await request.close();
      final Socket socket = await response.detachSocket();
      final webSocket = WebSocket.fromUpgradedSocket(
        socket,
        protocol: 'signaling',
        serverSide: false,
      );
      return webSocket;
    } catch (e, s) {
      TelloLogger().e("_connectForSelfSignedCert ERROR $e", stackTrace: s);
      rethrow;
    }
  }

  // ignore: type_annotate_public_apis
  Future<MediaStream> createStream() async {
    TelloLogger().i("Video Chat createStream");
    final Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth': '320',
          'minHeight': '180',
          'minFrameRate': '30',
        },
        //'deviceId': '0',
        'facingMode': 'user',
        'optional': [],
      }
    };

    final MediaStream stream = await navigator.getUserMedia(mediaConstraints);
    //await stream.getMediaTracks();
    if (onLocalStream != null) {
      onLocalStream(stream);
    }
    return stream;
  }

  // ignore: type_annotate_public_apis
  Future<void> createLocalStream() async {
    _localStream = await createStream();
  }

  Future<void> closeLocalStream() async {
    if (_localStream != null) {
      await _localStream.dispose();
    }
  }

  Future<RTCPeerConnection> _createPeerConnection(id) async {
    TelloLogger()
        .i("STAGE  _createPeerConnection Create 0000 Local Stream id = $id");
    _localStream = await createStream();

    TelloLogger()
        .i("STAGE  _createPeerConnection Create 1111 Local Stream id = $id");
    final RTCPeerConnection pc = await createPeerConnection(
        config /*..addAll({'sdpSemantics': "unified-plan"})*/, constraints);
    pc.addStream(_localStream);
    pc.onIceCandidate = (candidate) async {
      TelloLogger().i(
          "onIceCandidate ${candidate.sdpMlineIndex}  ${candidate.sdpMid}  ${candidate.candidate}");
      await _sendWithTimeout('candidate', {
        'to': id,
        'from': _selfId,
        'candidate': {
          'sdpMLineIndex': candidate.sdpMlineIndex,
          'sdpMid': candidate.sdpMid,
          'candidate': candidate.candidate,
        },
        'session_id': _sessionId,
      });
    };

    pc.onIceConnectionState = (state) {
      TelloLogger().i("STAGE PC EVENT onIceConnectionState $state");
    };

    pc.onAddStream = (stream) {
      TelloLogger().i("STAGE PC EVENT pc.onAddStream");
      if (onAddRemoteStream != null) {
        onAddRemoteStream(stream);
      }
      _remoteStream = stream;
      WebRTC.startAudioSession();
    };

    pc.onRemoveStream = (stream) {
      TelloLogger().i("STAGE PC EVENT pc.onRemoveStream");
      if (onRemoveRemoteStream != null) {
        onRemoveRemoteStream(stream);
      }
      stream.dispose();
      _remoteStream = null as MediaStream;
      WebRTC.stopAudioSession();
    };

    return pc;
  }

  Future<void> _createOffer(String toId) async {
    TelloLogger().i(" STAGE 2222 CREATING AN OFFER TO = $toId");
    try {
      final RTCSessionDescription sessionDescription =
          await _peerConnection.createOffer(_constraints);

      _peerConnection.setLocalDescription(sessionDescription);
      await _sendWithTimeout('offer', {
        'to': toId,
        'from': _selfId,
        'description': {
          'sdp': sessionDescription.sdp,
          'type': sessionDescription.type
        },
        'session_id': _sessionId,
        'media': "video",
      });
    } catch (e, s) {
      TelloLogger().e("ERROR ON _createOffer $e", stackTrace: s);
    }
  }

  void answer() {
    final id = _lastOffer['from'] as String;
    _createAnswer(id);
  }

  Future<void> _createAnswer(String id) async {
    try {
      final RTCSessionDescription answer =
          await _peerConnection.createAnswer(_constraints);

      _peerConnection.setLocalDescription(answer);
      await _sendWithTimeout('answer', {
        'to': id,
        'from': _selfId,
        'description': {'sdp': answer.sdp, 'type': answer.type},
        'session_id': _sessionId,
      });
    } catch (e, s) {
      TelloLogger().e("_createAnswer error $e", stackTrace: s);
    }
  }

  Future<void> sendBusy(String id) async {
    TelloLogger().i("STAGE USER id = $_selfId BUSY ");
    await _sendWithTimeout('busy', {
      'to': id,
      'from': _selfId,
      'session_id': _sessionId,
    });
  }

  Future<void> _sendWithTimeout(event, data) async {
    await _send(event, data)
        .timeout(Duration(seconds: AppSettings().socketTimeout), onTimeout: () {
      TelloLogger().i('[send timeout!');
    });
  }

  Future<void> _send(event, data) async {
    final sendData = {
      'data': data,
      'type': event,
      'user-token': Session.authToken,
      'api-address': ServiceAddress().baseUrl
    };
    const JsonEncoder encoder = JsonEncoder();
    String endodedData = encoder.convert(sendData);
    if (_socket != null) _socket.add(endodedData);
    TelloLogger().i('############# SEND : $endodedData');
  }
}
