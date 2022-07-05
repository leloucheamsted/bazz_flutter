import 'dart:async';
import 'dart:convert';
import 'package:logger/logger.dart';
import 'package:eventify/eventify.dart';
import 'package:executor/executor.dart';
import 'package:flutter_mediasoup/mediasoup_client/producer.dart';
import 'package:flutter_mediasoup/mediasoup_client/sdp_unified_plan.dart';
import 'package:flutter_mediasoup/mediasoup_client/sdp_utils.dart';
import 'package:flutter_mediasoup/mediasoup_client/remote_sdp.dart';
import 'package:flutter_mediasoup/mediasoup_client/media_track_stats.dart';
import 'package:flutter_mediasoup/mediasoup_client/device.dart';
import 'package:flutter_mediasoup/mediasoup_client/producer_info.dart';
import 'package:flutter_mediasoup/mediasoup_client/consumer_info.dart';
import 'package:flutter_webrtc/rtc_peerconnection.dart';
import 'package:flutter_webrtc/rtc_rtp_receiver.dart';
import 'package:flutter_webrtc/rtc_rtp_sender.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:sdp_transform/sdp_transform.dart';
import 'package:serializable/serializable.dart';
import 'dtls_parameters.dart';
import 'ice_candidate.dart';
import '../../../lib/modules/settings_module/media_settings.dart';

@serializable
class Transport extends EventEmitter {
  String id;
  List<IceCandidate> iceCandidates;
  DtlsParameters dtlsParameters;
  Map iceParameters;
  Map sctpParameters;

  late RTCPeerConnection pc;
  static num nextMidId = 1000;

  late Function onAddRemoteStream;
  late RTCSignalingState state;
  late bool _transportReady;
  String direction;
  bool startAudioSession;
  Completer initCompleter = Completer();
  Device device;
  Executor executor = new Executor(concurrency: 1);
  late RemoteSdp _remoteSdp;

  Transport(
      {required this.device,
      required this.id,
      required this.direction,
      required this.iceParameters,
      required this.iceCandidates,
      required this.dtlsParameters,
      required this.sctpParameters,
      this.startAudioSession = true}) {
    _transportReady = false;
    _init();
  }

  _init() async {
    Logger().log(Level.info, "Init Transport ======>");
    _remoteSdp = RemoteSdp(
        iceParameters: iceParameters,
        iceCandidates: iceCandidates,
        dtlsParameters: dtlsParameters,
        sctpParameters: sctpParameters);

    final Map<String, dynamic> constraints = {
      'mandatory': {
        'OfferToReceiveAudio': true,
        //'OfferToReceiveVideo':
        //  MediaSettings.videoModeEnabled && device.videoSupport,
      },
      'optional': [
        {'DtlsSrtpKeyAgreement': true},
      ],
    };

    Map<String, dynamic> config = {
      'iceServers': [
        {"url": "stun:stun.l.google.com:19302"},
      ],
      'iceTransportPolicy': 'all',
      'bundlePolicy': 'max-bundle',
      // 'sdpSemantics': MediaSettings.isPlanB ? 'plan-b' : 'unified-plan',
      'rtcpMuxPolicy': 'require'
    };

    config['startAudioSession'] = startAudioSession;
    pc = await createPeerConnection(Map<String, dynamic>.from(config),
        Map<String, dynamic>.from(constraints));

    pc.onIceCandidate = (candidate) async {
      Logger().log(Level.info, "Ice candidate: $candidate");
      await pc.addCandidate(candidate);
    };

    pc.onIceConnectionState = (state) {
      Logger().log(Level.info, "Ice state: $state");
    };

    pc.onSignalingState = (_state) {
      Logger().log(Level.info, "State: $_state");
      state = _state;
    };

    pc.onAddStream = (stream) {
      Logger().log(Level.info, "Add stream!");
      if (onAddRemoteStream != null) onAddRemoteStream(stream);
      // //_remoteStreams.add(stream);
      if (stream.getAudioTracks().isNotEmpty) {
        final MediaStreamTrack track = stream.getAudioTracks()[0];
      }
      if (stream.getVideoTracks().isNotEmpty) {
        final MediaStreamTrack track = stream.getVideoTracks()[0];
        Logger().log(Level.info, "Get Video Track ${track.enabled}");
      }
    };

    pc.onAddTrack2 =
        (RTCRtpReceiver receiver, [List<MediaStream>? mediaStreams]) {
      Logger().log(Level.info, "on Add track2");
    };

    pc.onAddTrack = (MediaStream stream, MediaStreamTrack track) {
      Logger().log(Level.info, "on Add track ${track.kind}");
      if (track.kind == 'audio') {
        final MediaStreamTrack track = stream.getAudioTracks()[0];
      }
      if (track.kind == 'video') {
        final MediaStreamTrack track = stream.getVideoTracks()[0];
        Logger().log(Level.info, "Get Video Track ${track.enabled}");
      }
      emit("onAddTrack", null, {"track": track});
    };

    pc.onRemoveStream = (stream) {
      Logger().log(Level.info, "Remove stream!");
    };

    pc.onDataChannel = (channel) {
      // _addDataChannel(id, channel);
    };

    initCompleter.complete();
  }

  Future<MediaTrackStats> getMediaTrackStat({String kind = "audio"}) async {
    final List<StatsReport> reportList = await pc.getStats();
    /* reportList.forEach((element) {
        Logger().log(Level.info, "report.type === > ${element.type},,,${element.values['bytesSent']}");
      });*/
    final report = reportList.firstWhere((element) => element.type == "ssrc",
        orElse: () => null!);
    if (report != null) {
      //Logger().log(Level.info, "report.type === > ${report.type},,,${report.values['bytesSent']}");
      final stats =
          MediaTrackStats.fromMap(report.values, isVideo: kind == "video");
      return stats;
    }
    return null!;
  }

  _emitPromise(String eventName, dynamic eventData) async {
    Completer eventCompleter = Completer();
    emit(eventName, null, {
      "data": eventData,
      "cb": () {
        eventCompleter.complete();
      }
    });

    return eventCompleter.future;
  }

  _setupTransport(localDtlsRole, localSdpObject, remoteSdp) async {
    Logger().log(Level.info, "_setupTransport ===> $localSdpObject");
    // Get our local DTLS parameters.
    final Map dtlsParameters =
        extractDtlsParameters(localSdpObject) as Map<dynamic, dynamic>;

    // Set our DTLS role.
    dtlsParameters["role"] = localDtlsRole;

    // Update the remote DTLS role in the SDP.
    remoteSdp.updateDtlsRole(localDtlsRole == 'client' ? 'server' : 'client');

    // Need to tell the remote transport about our parameters.
    // await this.safeEmitAsPromise('@connect', { dtlsParameters });

    _transportReady = true;

    await _emitPromise('connect', dtlsParameters);
  }

  produce(
      {String? kind,
      MediaStream? stream,
      MediaStreamTrack? track,
      Map? encodings,
      Map? codecOptions,
      Map? sendingRemoteRtpParameters}) async {
    await initCompleter.future;
    final Map<String, dynamic> constraints = {
      'mandatory': {
        'OfferToReceiveAudio': kind == 'audio',
        'OfferToReceiveVideo': kind == 'video',
      },
      'optional': [],
    };
    executor.scheduleTask(() async {
      Logger().log(Level.info, "Start produce  ===> : $kind");
      Map mediaSectionIdx =
          _remoteSdp.getNextMediaSectionIdx(kind!) as Map<dynamic, dynamic>;
      RTCRtpMediaType mediaType;
      if (kind == "video") {
        mediaType = RTCRtpMediaType.RTCRtpMediaTypeVideo;
      }
      if (kind == "audio") {
        mediaType = RTCRtpMediaType.RTCRtpMediaTypeAudio;
      }

      final RTCRtpSender sender = await pc.addTrack(track!, [stream!.id]);

      final RTCSessionDescription offer = await pc.createOffer(constraints);
      Map localSdpObject = parse(offer.sdp);
      if (!_transportReady) {
        await _setupTransport('server', localSdpObject, _remoteSdp);
      }

      await pc.setLocalDescription(offer);

      final Map sendingRtpParameters = Map.from(sendingRemoteRtpParameters!);

      final String offerSdp = (await pc.getLocalDescription()).sdp;

      localSdpObject = parse(offerSdp);
      emit("producerOffer", this, offerSdp);
      Map offerMediaObject = localSdpObject["media"][mediaSectionIdx["idx"]]
          as Map<dynamic, dynamic>;

      // if (MediaSettings().videoModeEnabled) {
      //   for (Map media
      //       in localSdpObject["media"] as List<Map<String, dynamic>>) {
      //     if (media["type"] == kind) {
      //       offerMediaObject = media;
      //     }
      //     Logger().log(Level.info, "The media ===> ${media["type"]}");
      //   }
      // }

      Logger().log(Level.info,
          "The offerMediaObject $kind ,, $mediaSectionIdx ,, ${mediaSectionIdx["idx"]} ,,,, ${localSdpObject["media"].length} ===> $offerMediaObject");
      // Set MID
      final String localId = (nextMidId++).toString();
      sendingRtpParameters["mid"] = localId;

      // Set RTCP CNAME
      sendingRtpParameters["rtcp"]["cname"] = getCname(offerMediaObject);
      Logger().log(Level.info,
          "The rtcp name $kind ===> ${sendingRtpParameters["rtcp"]["cname"]}");
      if (encodings == null) {
        // if (MediaSettings.isPlanB) {
        //   sendingRtpParameters["encodings"] =
        //       getRtpEncodingsPlanB(offerMediaObject, track);
        // } else {
        //   sendingRtpParameters["encodings"] = getRtpEncodings(offerMediaObject);
        // }
      } // TODO: handle else
      //sendingRtpParameters["encodings"] = null;
      Logger().log(Level.info,
          "sendingRtpParameters encoding==> ${sendingRtpParameters["encodings"]} ");
      Logger()
          .log(Level.info, "sendingRtpParameters ==> $sendingRtpParameters ");
      Logger().log(Level.info,
          "sendingRemoteRtpParameters ==> $sendingRemoteRtpParameters");

      _remoteSdp.send(offerMediaObject, mediaSectionIdx["reuseMid"],
          sendingRtpParameters, sendingRemoteRtpParameters, codecOptions, true);

      final RTCSessionDescription answer =
          RTCSessionDescription(_remoteSdp.getSdp(), 'answer');
      Logger().log(Level.info,
          "RTCSessionDescription answer ==> ${answer.type} ${answer.sdp}");
      pc.setRemoteDescription(answer);
      final producerInfo = ProducerInfo(
          constraints: constraints,
          streamId: stream.id,
          offerMediaObject: offerMediaObject,
          rtpParameters: sendingRtpParameters,
          cname: sendingRtpParameters["rtcp"]["cname"],
          encodings: sendingRtpParameters["encodings"],
          kind: kind,
          localId: localId,
          localSdpObject: localSdpObject,
          mid: localId,
          reuseMid: mediaSectionIdx["reuseMid"],
          sdpAnswer: answer.sdp,
          sdpOffer: offerSdp,
          sdpCodecOptions: codecOptions,
          sdpSendingRemoteRtpParameters: sendingRemoteRtpParameters,
          sdpSendingRtpParameters: sendingRtpParameters,
          trackId: track.id,
          mediaSectionId: mediaSectionIdx["reuseMid"]);
      emit("producerInfo", this, producerInfo);
      emit(
          'produce',
          null,
          Producer(
              track: track,
              sender: sender,
              kind: kind,
              localId: localId,
              rtpParameters: sendingRtpParameters));
    });
  }

  consume({
    String? id,
    String? kind,
    Map? rtpParameters,
  }) async {
    await initCompleter.future;
    executor.scheduleTask(() async {
      String localId = (nextMidId++).toString();
      _remoteSdp.receive(
          mid: localId,
          kind: kind,
          offerRtpParameters: rtpParameters,
          streamId: rtpParameters!["rtcp"]["cname"],
          trackId: id);
      RTCSessionDescription offer =
          RTCSessionDescription(_remoteSdp.getSdp(), 'offer');

      await pc.setRemoteDescription(offer);
      RTCSessionDescription answer = await pc.createAnswer({});

      Map localSdpObject = parse(answer.sdp);

      Map answerMediaObject = localSdpObject["media"].firstWhere(
          (m) => m["mid"].toString() == localId,
          orElse: () => null) as Map<String, dynamic>;

      Logger().log(Level.info, "consumerOffer ==> ${answer.sdp}");
      Logger().log(Level.info, "answerMediaObject ==> ${answerMediaObject}");
      emit("consumerOffer", this, answer.sdp);
      applyCodecParameters(
          offerRtpParameters: rtpParameters,
          answerMediaObject: answerMediaObject);

      answer.sdp = write(localSdpObject as Map<String, dynamic>, null);

      if (!_transportReady) {
        await _setupTransport('client', localSdpObject, _remoteSdp);
      }

      Logger().log(Level.info, " Consumer State: $state");
      final consumerInfo = ConsumerInfo(
          cname: rtpParameters["rtcp"]["cname"],
          answerMediaObject: answerMediaObject,
          offerRtpParameters: rtpParameters,
          localSdpObject: answer.sdp,
          rtpParameters: rtpParameters,
          kind: kind,
          localId: localId,
          mid: localId,
          reuseMid: null,
          sdpAnswer: answer.sdp,
          remoteSdp: _remoteSdp.getSdp(),
          trackId: id);
      emit("consumerInfo", this, consumerInfo);
      await pc.setLocalDescription(answer);
    });
  }

/*  stopSending(Producer producer) async {
    // transceiver.sender.replaceTrack(null);
    // pc.removeTrack(producer.sender);
    _remoteSdp.closeMediaSection();
    final RTCSessionDescription offer = await pc.createOffer(MediaSettings().constraints);
    await pc.setLocalDescription(offer);
    final RTCSessionDescription answer = RTCSessionDescription(_remoteSdp.getSdp(), 'answer');
    await pc.setRemoteDescription(answer);
  }*/

  closeProducer(Producer? producer) {
    pc.closeSender(producer!.sender!);
  }

  close() async {
    if (pc != null) {
      pc.close();
      pc.dispose();
    }
  }

  factory Transport.fromMap(Map map, Device device) {
    List<IceCandidate> iceCandidates = List<IceCandidate>.from(
        (map["iceCandidates"] as List)
            .map((candidate) => IceCandidate.fromJson(candidate)));
    Map iceParameters = map["iceParameters"] as Map<dynamic, dynamic>;
    DtlsParameters dtlsParameters =
        DtlsParameters.fromJson(map["dtlsParameters"]);
    Map sctpParameters = map["sctpParameters"] as Map<String, dynamic>;
    String direction = map["direction"] as String;
    String id = map["id"] as String;
    bool startAudioSession = map["startAudioSession"] as bool;

    final Transport transport = Transport(
        device: device,
        id: id,
        direction: direction,
        iceCandidates: iceCandidates,
        iceParameters: iceParameters,
        dtlsParameters: dtlsParameters,
        sctpParameters: sctpParameters,
        startAudioSession: startAudioSession);

    return transport;
  }
}
