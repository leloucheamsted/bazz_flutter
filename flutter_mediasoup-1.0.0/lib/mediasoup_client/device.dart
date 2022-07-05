import 'dart:async';
// import '../../../lib/modules/settings_module/media_settings.dart';
import 'package:flutter_mediasoup/mediasoup_client/dtls_parameters.dart';
import 'package:flutter_mediasoup/mediasoup_client/device_details.dart';
import 'package:flutter_mediasoup/mediasoup_client/sdp_utils.dart';
import 'package:flutter_mediasoup/mediasoup_client/transport.dart';
import 'package:logger/logger.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'ortc.dart';
import '../../../lib/modules/settings_module/media_settings.dart';
part 'device.g.dart';

@JsonSerializable(nullable: false)
class Device {
  String? flag;
  String? name;
  String? version;

  Map? _extendedRtpCapabilities;
  Map? _recvRtpCapabilities;
  Map? _sendingRemoteRtpParametersByKind = Map();
// md.  _mediaSettings;
  Map<String, dynamic> config = {
    'iceServers': [
      {"url": "stun:stun.l.google.com:19302"},
    ],
    'iceTransportPolicy': 'all',
    'bundlePolicy': 'max-bundle',
    'rtcpMuxPolicy': 'require',
    // 'sdpSemantics': MediaSettings.isPlanB ? 'plan-b' : 'unified-plan',
    'startAudioSession': false
  };

  final Map<String, dynamic> constraints = {
    'mandatory': {
      'OfferToReceiveAudio': true,
      //'OfferToReceiveVideo': MediaSettings.videoModeEnabled,
    },
    'optional': [
      {'`DtlsSrtpKeyAgreement`': true},
    ],
  };

  toMap() => _$DeviceToJson(this);

  DeviceDetails? _deviceDetails;
  Map? _nativeRtpCapabilities;
  Map get nativeRtpCapabilities => _nativeRtpCapabilities!;
  DeviceDetails get deviceDetails => _deviceDetails!;
  Map get rtpCapabilities => _recvRtpCapabilities!;
  bool? _videoSupport;
  bool get videoSupport => _videoSupport!;
  getNativeRtpCapabilities() async {
    RTCPeerConnection pc = await createPeerConnection(config, constraints);

    RTCSessionDescription offer = await pc.createOffer(constraints);
    await pc.close();
    pc.dispose();

    final Map sdpObject = parse(offer.sdp);
    Logger().log(Level.info,
        "getNativeRtpCapabilities ==:> ${extractRtpCapabilities(sdpObject)}");
    return extractRtpCapabilities(sdpObject);
  }

  Future<void> init() async {
    _nativeRtpCapabilities =
        await getNativeRtpCapabilities() as Map<dynamic, dynamic>;
    final codecs = _nativeRtpCapabilities!["codecs"] as List<dynamic>;
    final result = codecs.firstWhere((element) => element['kind'] == 'video',
        orElse: () => null);
    _videoSupport = result != null;

    Logger().log(Level.info, "device init() $result $_videoSupport");
  }

  load(Map routerRtpCapabilities, {Map? supportedCodecs}) async {
    Map nativeRtpCapabilities =
        await getNativeRtpCapabilities() as Map<dynamic, dynamic>;

    final deviceNativeRtpCapabilities = nativeRtpCapabilities;
    final mediaRouterRtpCapabilities = routerRtpCapabilities;

    Logger()
        .log(Level.info, "nativeRtpCapabilities ==:> ${nativeRtpCapabilities}");
    Logger()
        .log(Level.info, "routerRtpCapabilities ==:> ${routerRtpCapabilities}");
    _extendedRtpCapabilities = getExtendedRtpCapabilities(
        nativeRtpCapabilities, routerRtpCapabilities,
        supportedCodecs: supportedCodecs) as Map<dynamic, dynamic>;
    Logger().log(Level.info,
        "_extendedRtpCapabilities ==:> ${_extendedRtpCapabilities}");
    _sendingRemoteRtpParametersByKind!["video"] =
        getSendingRemoteRtpParameters("video", _extendedRtpCapabilities!);
    _sendingRemoteRtpParametersByKind!["audio"] =
        getSendingRemoteRtpParameters("audio", _extendedRtpCapabilities!);
    Logger().log(Level.info,
        "_extendedRtpCapabilities audio ==:> ${_sendingRemoteRtpParametersByKind!["audio"]}");
    Logger().log(Level.info,
        "_extendedRtpCapabilities video ==:> ${_sendingRemoteRtpParametersByKind!["video"]}");
    _recvRtpCapabilities = getRecvRtpCapabilities(_extendedRtpCapabilities!)
        as Map<dynamic, dynamic>;
    _deviceDetails = DeviceDetails(
        deviceNativeRtpCapabilities: deviceNativeRtpCapabilities,
        mediaRouterRtpCapabilities: mediaRouterRtpCapabilities,
        rtpCapabilities: _recvRtpCapabilities);
  }

  sendingRemoteRtpParameters(String kind) =>
      _sendingRemoteRtpParametersByKind![kind];

  createSendTransport(peerId,
      {id,
      iceParameters,
      iceCandidates,
      dtlsParameters,
      sctpParameters,
      startAudioSession = true}) async {
    return _createTransport("send", peerId,
        id: id,
        iceParameters: iceParameters,
        iceCandidates: iceCandidates,
        dtlsParameters: dtlsParameters,
        sctpParameters: sctpParameters);
  }

  createRecvTransport(
    peerId, {
    id,
    iceParameters,
    iceCandidates,
    dtlsParameters,
    sctpParameters,
  }) async {
    return _createTransport("recv", peerId,
        id: id,
        iceParameters: iceParameters,
        iceCandidates: iceCandidates,
        dtlsParameters: dtlsParameters,
        sctpParameters: sctpParameters);
  }

  _createTransport(direction, peerId,
      {id,
      iceParameters,
      iceCandidates,
      dtlsParameters,
      sctpParameters,
      startAudioSession = false}) {
    return Transport.fromMap({
      "id": id,
      "iceParameters": iceParameters,
      "iceCandidates": iceCandidates,
      "dtlsParameters": dtlsParameters,
      "sctpParameters": sctpParameters,
      "direction": direction,
      "startAudioSession": startAudioSession
    }, this);
  }

  static fromJson(Map json) => _$DeviceFromJson(json as Map<String, dynamic>);
}
