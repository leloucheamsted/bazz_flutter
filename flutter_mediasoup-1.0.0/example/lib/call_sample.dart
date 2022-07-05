import 'package:flutter/material.dart';
// import 'package:flutter_mediasoup_example/websocket/signaling.dart';
import 'dart:core';
import 'package:flutter_mediasoup/flutter_mediasoup.dart';
import 'package:flutter_webrtc/webrtc.dart';

import 'websocket/signaling.dart';

class CallSample extends StatefulWidget {
  static String tag = 'call_sample';

  final String ip;

  CallSample({Key? key, required this.ip}) : super(key: key);

  @override
  _CallSampleState createState() => new _CallSampleState(serverIP: ip);
}

class _CallSampleState extends State<CallSample> {
  Signaling? _signaling;
  List<dynamic>? _peers;
  var _selfId;
  RTCVideoRenderer _localRenderer = new RTCVideoRenderer();
  RTCVideoRenderer _remoteRenderer = new RTCVideoRenderer();
  bool _inCalling = false;
  final String serverIP;

  _CallSampleState({Key? key, required this.serverIP});

  @override
  initState() {
    super.initState();
    initRenderers();
    _connect();
  }

  initRenderers() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  @override
  deactivate() {
    super.deactivate();
    if (_signaling != null) _signaling!.close();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
  }

  void _connect() async {
    if (_signaling == null) {
      _signaling = new Signaling(serverIP)..connect();

      _signaling!.onStateChange = (SignalingState state) {
        switch (state) {
          case SignalingState.CallStateNew:
            this.setState(() {
              _inCalling = true;
            });
            break;
          case SignalingState.CallStateBye:
            this.setState(() {
              _localRenderer.srcObject = null as MediaStream;
              _remoteRenderer.srcObject = null as MediaStream;
              _inCalling = false;
            });
            break;
          case SignalingState.CallStateInvite:
          case SignalingState.CallStateConnected:
          case SignalingState.CallStateRinging:
          case SignalingState.ConnectionClosed:
          case SignalingState.ConnectionError:
          case SignalingState.ConnectionOpen:
            break;
        }
      };

      _signaling!.onPeersUpdate = ((event) {
        this.setState(() {
          _selfId = event['self'];
          _peers = event['peers'] as List<dynamic>;
        });
      });

      _signaling!.onLocalStream = ((stream) {
        _localRenderer.srcObject = stream;
      });

      _signaling!.onAddRemoteStream = ((stream) {
        // for (MediaStreamTrack track in stream.getAudioTracks()) {
        //   track.setVolume(3);
        //   track.enableSpeakerphone(true);
        //   track.enabled = true;
        // }
        setState(() {
          // _remoteRenderer.srcObject = stream;
        });
      });

      _signaling!.onRemoveRemoteStream = ((stream) {
        _remoteRenderer.srcObject = null!;
      });
    }
  }

  _invitePeer(context, peerId, use_screen) async {
    if (_signaling != null && peerId != _selfId) {
      _signaling!.invite(peerId as String, 'video', use_screen);
    }
  }

  _hangUp() {
    if (_signaling != null) {
      _signaling!.bye();
    }
  }

  _switchCamera() {
    _signaling!.switchCamera();
  }

  _muteMic() {}

  _buildRow(context, Peer peer) {
    var self = (peer.id == _selfId);
    return ListBody(children: <Widget>[
      ListTile(
        title: Text(self
            ? peer.displayName! + '[Your self]'
            : peer.displayName! + '[' + peer.device!.name! + ']'),
        onTap: null,
        trailing: new SizedBox(
            width: 100.0,
            child: new Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  IconButton(
                    icon: const Icon(Icons.videocam),
                    onPressed: () => _invitePeer(context, peer.id, false),
                    tooltip: 'Video calling',
                  ),
                  IconButton(
                    icon: const Icon(Icons.screen_share),
                    onPressed: () => _invitePeer(context, peer.id, true),
                    tooltip: 'Screen sharing',
                  )
                ])),
        subtitle: Text('id: ' + peer.id!),
      ),
      Divider()
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
        appBar: new AppBar(
          title: new Text('P2P Call Sample'),
          actions: <Widget>[
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: null,
              tooltip: 'setup',
            ),
          ],
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
        floatingActionButton: _inCalling
            ? new SizedBox(
                width: 200.0,
                child: new Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      FloatingActionButton(
                        child: const Icon(Icons.switch_camera),
                        onPressed: _switchCamera,
                      ),
                      FloatingActionButton(
                        onPressed: _hangUp,
                        tooltip: 'Hangup',
                        child: new Icon(Icons.call_end),
                        backgroundColor: Colors.pink,
                      ),
                      FloatingActionButton(
                        child: const Icon(Icons.mic_off),
                        onPressed: _muteMic,
                      )
                    ]))
            : null,
        body: _inCalling
            ? OrientationBuilder(builder: (context, orientation) {
                return new Container(
                  child: new Stack(children: <Widget>[
                    new Positioned(
                        left: 0.0,
                        right: 0.0,
                        top: 0.0,
                        bottom: 0.0,
                        child: new Container(
                          margin: new EdgeInsets.fromLTRB(0.0, 0.0, 0.0, 0.0),
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context).size.height,
                          child: new RTCVideoView(_remoteRenderer),
                          decoration: new BoxDecoration(color: Colors.black54),
                        )),
                    new Positioned(
                      left: 20.0,
                      top: 20.0,
                      child: new Container(
                        width:
                            orientation == Orientation.portrait ? 90.0 : 120.0,
                        height:
                            orientation == Orientation.portrait ? 120.0 : 90.0,
                        child: new RTCVideoView(_localRenderer),
                        decoration: new BoxDecoration(color: Colors.black54),
                      ),
                    ),
                  ]),
                );
              })
            : ElevatedButton(
                child: Text('connect'),
                onPressed: () => _invitePeer(context, '', ''),
              )
        // : new ListView.builder(
        //     shrinkWrap: true,
        //     padding: const EdgeInsets.all(0.0),
        //     itemCount: (_peers != null ? _peers.length : 0),
        //     itemBuilder: (context, i) {
        //       return _buildRow(context, _peers[i]);
        //     }),
        );
  }
}
