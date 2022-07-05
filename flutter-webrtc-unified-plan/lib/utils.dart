import 'dart:io';
import 'package:flutter/services.dart';

class WebRTC {
  static const MethodChannel _channel =
      const MethodChannel('FlutterWebRTC.Method');
  static MethodChannel methodChannel() => _channel;

  static bool get platformIsDesktop =>
      Platform.isWindows || Platform.isLinux || Platform.isMacOS;

  static bool get platformIsMobile => Platform.isIOS || Platform.isAndroid;

  static bool get platformIsWeb => false;

  static startAudioSession() {
    _channel.invokeMethod('startAudioSession');
  }

  static stopAudioSession() {
    _channel.invokeMethod('stopAudioSession');
  }

  static enableSpeakerphone(bool enable) async {
    await _channel.invokeMethod(
      'enableSpeakerphone',
      <String, dynamic>{'enable': enable},
    );
  }
}

Map<String, dynamic> defaultConstraints = {
  "mandatory": {},
  "optional": [
    {"DtlsSrtpKeyAgreement": true},
  ],
};

final Map<String, dynamic> defaultSdpConstraints = {
  "mandatory": {
    "OfferToReceiveAudio": true,
    "OfferToReceiveVideo": true,
  },
  "optional": [],
};
