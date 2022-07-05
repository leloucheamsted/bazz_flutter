import 'dart:async';

import 'package:flutter/services.dart';
import 'utils.dart';

class MediaStreamTrack {
  /// private:
  MethodChannel _channel = WebRTC.methodChannel();
  String _trackId;
  String _label;
  String _kind;
  bool _enabled;

  /// public:
  factory MediaStreamTrack.fromMap(Map<dynamic, dynamic> map) {
    return new MediaStreamTrack(
        map['id'], map['label'], map['kind'], map['enabled']);
  }

  MediaStreamTrack(this._trackId, this._label, this._kind, this._enabled);

  /// Mute/unmute the track.
  set enabled(bool enabled) {
    _channel.invokeMethod('mediaStreamTrackSetEnable',
        <String, dynamic>{'trackId': _trackId, 'enabled': enabled});
    _enabled = enabled;
  }

  bool get enabled => _enabled;

  String get label => _label;

  String get kind => _kind;

  String get id => _trackId;

  Future hasTorch() => _channel.invokeMethod(
        'mediaStreamTrackHasTorch',
        <String, dynamic>{'trackId': _trackId},
      );

  Future<void> setTorch(bool torch) => _channel.invokeMethod(
        'mediaStreamTrackSetTorch',
        <String, dynamic>{'trackId': _trackId, 'torch': torch},
      );

  ///Future contains isFrontCamera
  ///Throws error if switching camera failed
  Future switchCamera() => _channel.invokeMethod(
        'mediaStreamTrackSwitchCamera',
        <String, dynamic>{'trackId': _trackId},
      );

  Future<void> setVolume(double volume) async {
    await _channel.invokeMethod(
      'setVolume',
      <String, dynamic>{'trackId': _trackId, 'volume': volume},
    );
  }

  /// TODO: Split the following method into a RTCAudioTrack and RTCVideoTrack.
  ///
  /// AudioTrack methods.
  /// Mute/unmute the microphone.
  Future<void> setMicrophoneMute(bool mute) async {
    await _channel.invokeMethod(
      'setMicrophoneMute',
      <String, dynamic>{'trackId': _trackId, 'mute': mute},
    );
  }

  Future<void> enableSpeakerphone(bool enable) async {
    await _channel.invokeMethod(
      'enableSpeakerphone',
      <String, dynamic>{'trackId': _trackId, 'enable': enable},
    );
  }

  /// On Flutter Web returns Future<dynamic> which contains data url on success
  captureFrame([String? filePath]) => _channel.invokeMethod(
        'captureFrame',
        <String, dynamic>{'trackId': _trackId, 'path': filePath},
      );

  Future<void> dispose() async {
    await _channel.invokeMethod(
      'trackDispose',
      <String, dynamic>{'trackId': _trackId},
    );
  }
}
