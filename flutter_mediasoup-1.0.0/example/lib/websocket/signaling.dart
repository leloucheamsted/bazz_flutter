import 'dart:convert';
import 'dart:async';
import 'dart:math';
// import 'package:flutter_mediasoup_example/websocket/websocket.dart';
// import 'package:bazz_flutter/services/websocket.dart';
import 'package:flutter_mediasoup_example/websocket/websocket.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'random_string.dart';
import 'package:flutter_mediasoup/flutter_mediasoup.dart';
import 'package:eventify/eventify.dart';

enum SignalingState {
  CallStateNew,
  CallStateRinging,
  CallStateInvite,
  CallStateConnected,
  CallStateBye,
  ConnectionOpen,
  ConnectionClosed,
  ConnectionError,
}

/*
 * callbacks for Signaling API.
 */
typedef void SignalingStateCallback(SignalingState state);
typedef void StreamStateCallback(MediaStream stream);
typedef void OtherEventCallback(dynamic event);
typedef void DataChannelMessageCallback(
    RTCDataChannel dc, RTCDataChannelMessage data);
typedef void DataChannelCallback(RTCDataChannel dc);

class Signaling {
  String _selfId = randomNumeric(6);
  late SimpleWebSocket _socket;
  var _sessionId;
  var _host;
  var _port = 4443;
  late RTCPeerConnection? _peerConnection;
  var _dataChannels = new Map<String, RTCDataChannel>();
  var _remoteCandidates = [];
  Map<String, RTCPeerConnection> _peerConnections = {};
  Random randomGen = Random();

  MediaStream? _localStream;
  List<MediaStream>? _remoteStreams;
  SignalingStateCallback? onStateChange;
  StreamStateCallback? onLocalStream;
  StreamStateCallback? onAddRemoteStream;
  StreamStateCallback? onRemoveRemoteStream;
  OtherEventCallback? onPeersUpdate;
  DataChannelMessageCallback? onDataChannelMessage;
  DataChannelCallback? onDataChannel;

  Map<int, Request> requestQueue = {};
  List<Transport> transportList = [];
  List<Peer> _peers = [];

  late Transport _sendTransport;
  late Transport _recvTransport;

  Device device = Device();

  Completer connected = Completer();

  Signaling(this._host);

  close() {
    if (_localStream != null) {
      _localStream!.dispose();
      _localStream = null;
    }

    // _peerConnections.forEach((key, pc) {
    //   pc.close();
    // });
    if (_socket != null) _socket.close();
  }

  void switchCamera() {
    if (_localStream != null) {
      _localStream!.getVideoTracks()[0].switchCamera();
    }
  }

  void invite(String peerId, String media, useScreen) async {
    this._sessionId = this._selfId + '-' + peerId;

    if (this.onStateChange != null) {
      this.onStateChange!(SignalingState.CallStateNew);
    }

    // Wait for the socket connection
    await connected.future;

    // Map rtpCapabilities = await getNativeRtpCapabilities();
    Map routerRtpCapabilities =
        await _send('getRouterRtpCapabilities', null) as Map<dynamic, dynamic>;

    await device.load(routerRtpCapabilities);

    // Create producer
    print("Creating send transport");
    Map sendTransportResponse = await _send('createWebRtcTransport', {
      "producing": true,
      "consuming": false,
      "forceTcp": false,
      "sctpCapabilities": {
        "numStreams": {"OS": 1024, "MIS": 1024}
      }
    }) as Map<dynamic, dynamic>;
    _sendTransport = await device.createSendTransport(
      peerId,
      id: sendTransportResponse["id"],
      iceParameters: sendTransportResponse["iceParameters"],
      iceCandidates: sendTransportResponse["iceCandidates"],
      dtlsParameters: sendTransportResponse["dtlsParameters"],
      sctpParameters: sendTransportResponse["sctpParameters"],
    ) as Transport;
    _sendTransport.on('connect', this, (Event ev, Object? context) async {
      Map eventData = ev.eventData as Map<dynamic, dynamic>;
      DtlsParameters dtlsParameters = eventData["data"] as DtlsParameters;
      print("Connecting send transport");
      await _connectTransport(_sendTransport, dtlsParameters);
      print("Send transport connceted");
      eventData["cb"]();
    });

    _sendTransport.on('produce', this, (Event ev, Object? context) async {
      Producer producer = ev.eventData as Producer;
      dynamic res = await _send('produce', {
        'transportId': _sendTransport.id,
        'kind': producer.kind,
        'rtpParameters': producer.rtpParameters
      });
      print(res);
    });

    Map recvTransportResponse = await _send('createWebRtcTransport', {
      "producing": false,
      "consuming": true,
      "forceTcp": false,
      "sctpCapabilities": {
        "numStreams": {"OS": 1024, "MIS": 1024}
      }
    }) as Map<dynamic, dynamic>;
    print("Creating receive transport");
    _recvTransport = await device.createRecvTransport(
      peerId,
      id: recvTransportResponse["id"],
      iceParameters: recvTransportResponse["iceParameters"],
      iceCandidates: recvTransportResponse["iceCandidates"],
      dtlsParameters: recvTransportResponse["dtlsParameters"],
      sctpParameters: recvTransportResponse["sctpParameters"],
    ) as Transport;

    _recvTransport.on('connect', this, (Event ev, Object? context) async {
      Map eventData = ev.eventData as Map<dynamic, dynamic>;
      DtlsParameters dtlsParameters = eventData["data"] as DtlsParameters;
      print("Connecting receive transport");
      await _connectTransport(_recvTransport, dtlsParameters);
      print("receive transport connceted");
      eventData["cb"]();
    });

    _recvTransport.onAddRemoteStream = onAddRemoteStream!;

    dynamic res = await _send('join', {
      "displayName": "Sigilyph",
      "device": {"flag": "mobile", "name": "mobile", "version": "1.0"},
      "rtpCapabilities": device.rtpCapabilities
    });

    if (res != null) {
      _peers = List<Peer>.from(res['peers']
              .map((peer) => Peer.fromJson(peer as Map<dynamic, dynamic>))
          as Iterable<dynamic>);
      _updatePeers();

      _localStream = await createStream();
      onLocalStream!(_localStream!);
      sendLocalStream(_localStream!, "audio");
      // sendLocalStream(_localStream, "video");
    }
  }

  sendLocalStream(MediaStream stream, String kind) async {
    Producer producer = await _sendTransport.produce(
        kind: kind,
        stream: stream,
        sendingRemoteRtpParameters: device.sendingRemoteRtpParameters('audio')
            as Map<dynamic, dynamic>) as Producer;
  }

  Future<MediaStream> createStream() async {
    Map<String, dynamic> mediaConstraints = {
      'audio': true,
      'video': {
        'mandatory': {
          'minWidth':
              '640', // Provide your own width, height and frame rate here
          'minHeight': '480',
          'minFrameRate': '30',
        },
        'facingMode': 'environment',
        'optional': [],
      }
    };

    MediaStream stream = await navigator.getUserMedia(mediaConstraints);
    return stream;
  }

  void bye() {
    _send('bye', {
      'session_id': this._sessionId,
      'from': this._selfId,
    });
  }

  void onMessage(message) async {
    Map<String, dynamic> mapData = message as Map<String, dynamic>;
    var data = mapData['data'];
    int requestId = mapData['id'] as int;
    String method = mapData['method'] as String;

    if (requestQueue.containsKey(requestId)) {
      requestQueue[requestId]!.completer.complete(data);
    }

    if (mapData['notification'] == true) {
      print("Notification: $method");
      switch (method) {
        case 'peerClosed':
          print('peerClosed');
          _peers.removeWhere((peer) => peer.id == data['peerId']);
          _updatePeers();
          break;
        case 'newPeer':
          _peers.add(Peer.fromJson(data as Map<dynamic, dynamic>));
          _updatePeers();
          break;
      }
    }

    if (mapData['request'] == true) {
      print("Request: $method");
      switch (method) {
        case 'newConsumer':
          _recvTransport.consume(
              id: message["data"]["id"] as String,
              kind: message["data"]["kind"] as String,
              rtpParameters:
                  message["data"]["rtpParameters"] as Map<dynamic, dynamic>);

          _accept(message);
          break;
      }
    }

    requestQueue.remove(requestId);
  }

  void connect() async {
    var url = 'wss://$_host:$_port';
    // _socket = SimpleWebSocket(_host as String, _port as int,
    //     roomId: 'bazz' as String, peerId: _selfId as String);

    print('connect to $url');

    _socket.onOpen = () async {
      print('onOpen');
      this.onStateChange!(SignalingState.ConnectionOpen);

      connected.complete();
    };

    _socket.onMessage = (message) {
      print('Recivied data: ' + message);
      JsonDecoder decoder = new JsonDecoder();
      this.onMessage(decoder.convert(message));
    };

    _socket.onClose = (int code, String reason) {
      print('Closed by server [$code => $reason]!');
      if (this.onStateChange != null) {
        this.onStateChange!(SignalingState.ConnectionClosed);
      }
    };

    await _socket.connect();
  }

  _updatePeers() {
    if (this.onPeersUpdate != null) {
      Map<String, dynamic> event = new Map<String, dynamic>();
      event['self'] = _selfId;
      event['peers'] = _peers;
      this.onPeersUpdate!(event);
    }
  }

  _connectTransport(Transport transport, DtlsParameters dtlsParameters) async {
    await _send('connectWebRtcTransport', {
      'transportId': transport.id,
      'dtlsParameters': dtlsParameters.toMap()
    });
  }

  _addDataChannel(id, RTCDataChannel channel) {
    channel.onDataChannelState = (e) {};
    channel.onMessage = (RTCDataChannelMessage data) {
      if (this.onDataChannelMessage != null)
        this.onDataChannelMessage!(channel, data);
    };
    _dataChannels[id as String] = channel;

    if (this.onDataChannel != null) this.onDataChannel!(channel);
  }

  _createDataChannel(id, RTCPeerConnection pc, {label: 'fileTransfer'}) async {
    RTCDataChannelInit dataChannelDict = new RTCDataChannelInit();
    RTCDataChannel channel =
        await pc.createDataChannel(label as String, dataChannelDict);
    _addDataChannel(id, channel);
  }

  _accept(message, {data}) {
    JsonEncoder encoder = new JsonEncoder();
    _socket.send(encoder.convert({
      "response": true,
      "id": message["id"],
      "ok": true,
      "data": data ?? {}
    }));
  }

  _send(method, data) {
    Map message = Map();
    int requestId = randomGen.nextInt(100000000);
    message['method'] = method;
    message['request'] = true;
    message['id'] = requestId;
    message['data'] = data;
    print("Sending request $method id: $requestId");
    requestQueue[requestId] = Request(message);
    JsonEncoder encoder = new JsonEncoder();
    _socket.send(encoder.convert(message));

    return requestQueue[requestId]!.completer.future;
  }
}
