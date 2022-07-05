import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/modules/settings_module/settings_controller.dart';

class MediaSettings {
  static final MediaSettings _instance = MediaSettings._();

  factory MediaSettings() => _instance;

  MediaSettings._();

  final bool isPlanB = false;

  Map<String, dynamic> config = {
    'iceServers': [
      {"url": "stun:stun.l.google.com:19302"},
    ],
    'iceTransportPolicy': 'all',
    'bundlePolicy': 'max-bundle',
    'rtcpMuxPolicy': 'require',
    'sdpSemantics': 'unified-plan',
    'startAudioSession': false
  };

  final Map<String, dynamic> constraints = {
    'mandatory': {
      'OfferToReceiveAudio': false,
      'OfferToReceiveVideo': false,
    },
    'optional': [
      {'`DtlsSrtpKeyAgreement`': true},
    ],
  };

  final Map<String, dynamic> constraintsOffer = {
    'mandatory': [],
    'optional': [],
  };

  final mediaConstraintsVideo = {
    'audio': {'sampleSize': 16, 'channelCount': 1},
    'video': {
      'mandatory': {
        'minWidth': '320',
        // Provide your own width, height and frame rate here
        'minHeight': '180',
        'minFrameRate': '30',
      },
      //'deviceId': '0',
      'facingMode': 'user',
      'optional': [],
    }
  };

  final mediaConstraintsAudio = {
    'audio': {'sampleSize': 16, 'channelCount': 1},
    'video': false
  };

  final mediaConstraintsAudio2 = {'audio': true, 'video': false};

  Map getSupportedCodecs() {
    if (SettingsController.to!.osSDKInt < 29) {
      return {
        "codecs": [
          {"kind": "audio", "mimeType": "audio/PCMU"},
          {"kind": "audio", "mimeType": "audio/opus"},
          {"kind": "video", "mimeType": "video/VP9"}
        ]
      };
    } else {
      return {
        "codecs": [
          {"kind": "audio", "mimeType": "audio/opus"},
          {"kind": "video", "mimeType": "video/VP9"}
        ]
      };
    }
  }

  bool get videoModeEnabled => AppSettings().videoModeEnabled;

  void init() {
    config['sdpSemantics'] = isPlanB ? 'plan-b' : 'unified-plan';

    constraints['OfferToReceiveAudio'] = !AppSettings().videoModeEnabled;
    constraints['OfferToReceiveVideo'] = AppSettings().videoModeEnabled;
  }
}
