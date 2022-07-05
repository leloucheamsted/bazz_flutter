import 'package:flutter_webrtc/rtc_rtp_sender.dart';
import 'package:flutter_webrtc/webrtc.dart';

class Producer {
  String? id;
  MediaStreamTrack? track;
  MediaStreamTrack? track2;
  MediaStream? stream;
  RTCRtpSender? sender;
  String? kind;
  String? localId;
  Map? rtpParameters;
  bool? enabled = true;

  Producer(
      {this.id,
      this.track,
      this.track2,
      this.stream,
      this.sender,
      this.kind,
      this.localId,
      this.rtpParameters});

  pause() {
    enabled = false;
    track!.enabled = false;
  }

  resume() {
    enabled = true;
    track!.enabled = true;
  }
}
