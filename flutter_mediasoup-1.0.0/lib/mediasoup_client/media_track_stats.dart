class MediaTrackStats {
  MediaTrackStats(
      {this.requestsSent,
      this.localCandidateId,
      this.googRemoteAddress,
      this.googRemoteCandidateType,
      this.googRtt,
      this.bytesSent,
      this.googTransportType,
      this.googWritable,
      this.googActiveConnection,
      this.requestsReceived,
      this.remoteCandidateId,
      this.bytesReceived,
      this.responsesSent,
      this.googLocalAddress,
      this.googChannelId,
      this.packetsDiscardedOnSend,
      this.packetsSent,
      this.packetsReceived,
      this.framesDecoded,
      this.googDecodeMs,
      this.responsesReceived,
      this.googLocalCandidateType,
      this.googReadable,
      this.consentRequestsSent,
      this.isProducer,
      this.isVideo});

  final double? requestsSent;
  final String? localCandidateId;
  final String? googRemoteAddress;
  final String? googRemoteCandidateType;
  final String? googRtt;
  final double? bytesSent;
  final String? googTransportType;
  final String? googWritable;
  final String? googActiveConnection;
  final double? requestsReceived;
  final String? remoteCandidateId;
  final double? bytesReceived;
  final double? responsesSent;
  final String? googLocalAddress;
  final String? googChannelId;
  final double? packetsDiscardedOnSend;
  final double? packetsSent;
  final double? packetsReceived;
  final double? framesDecoded;
  final double? googDecodeMs;
  final double? responsesReceived;
  final String? googLocalCandidateType;
  final String? googReadable;
  final double? consentRequestsSent;
  final bool? isProducer;
  final bool? isVideo;
  factory MediaTrackStats.fromMap(Map<dynamic, dynamic> map, {bool? isVideo}) =>
      MediaTrackStats(
          requestsSent: map["requestsSent"] != null
              ? double.parse(map["requestsSent"] as String)
              : 0.0,
          localCandidateId: map["localCandidateId"] as String,
          googRemoteAddress: map["googRemoteAddress"] as String,
          googRemoteCandidateType: map["googRemoteCandidateType"] as String,
          googRtt: map["googRtt"] as String,
          bytesSent: map["bytesSent"] != null
              ? double.parse(map["bytesSent"] as String)
              : 0.0,
          googTransportType: map["googTransportType"] as String,
          googWritable: map["googWritable"] as String,
          googActiveConnection: map["googActiveConnection"] as String,
          requestsReceived: map["requestsReceived"] != null
              ? double.parse(map["requestsReceived"] as String)
              : 0.0,
          remoteCandidateId: map["remoteCandidateId"] as String,
          bytesReceived: map["bytesReceived"] != null
              ? double.parse(map["bytesReceived"] as String)
              : 0.0,
          responsesSent: map["responsesSent"] != null
              ? double.parse(map["responsesSent"] as String)
              : 0.0,
          googLocalAddress: map["googLocalAddress"] as String,
          googChannelId: map["googChannelId"] as String,
          packetsDiscardedOnSend: map["packetsDiscardedOnSend"] != null
              ? double.parse(map["packetsDiscardedOnSend"] as String)
              : 0.0,
          packetsSent: map["packetsSent"] != null
              ? double.parse(map["packetsSent"] as String)
              : 0.0,
          framesDecoded: map["framesDecoded"] != null
              ? double.parse(map["framesDecoded"] as String)
              : 0.0,
          googDecodeMs: map["googDecodeMs"] != null
              ? double.parse(map["googDecodeMs"] as String)
              : 0.0,
          responsesReceived: map["responsesReceived"] != null
              ? double.parse(map["responsesReceived"] as String)
              : 0.0,
          googLocalCandidateType: map["googLocalCandidateType"] as String,
          googReadable: map["googReadable"] as String,
          consentRequestsSent: map["consentRequestsSent"] != null
              ? double.parse(map["consentRequestsSent"] as String)
              : 0.0,
          isProducer: true,
          isVideo: isVideo);

  factory MediaTrackStats.fromMapConsumer(Map<dynamic, dynamic> map,
          {bool? isVideo}) =>
      MediaTrackStats(
          requestsSent: 0.0,
          localCandidateId: "",
          googRemoteAddress: "",
          googRemoteCandidateType: "",
          googRtt: map["googRtt"] as String,
          bytesSent: 0.0,
          googTransportType: "",
          googWritable: "",
          googActiveConnection: "",
          requestsReceived: 0.0,
          remoteCandidateId: "",
          bytesReceived: map["bytesReceived"] != null
              ? double.parse(map["bytesReceived"] as String)
              : 0.0,
          responsesSent: 0.0,
          googLocalAddress: "",
          googChannelId: "",
          packetsDiscardedOnSend: 0.0,
          packetsSent: 0.0,
          packetsReceived: map["packetsReceived"] != null
              ? double.parse(map["packetsReceived"] as String)
              : 0.0,
          responsesReceived: 0.0,
          googLocalCandidateType: "",
          googReadable: "",
          consentRequestsSent: 0.0,
          isProducer: false,
          isVideo: isVideo);
}

//{codecs: [{mimeType: audio/PCMU, kind: audio, preferredPayloadType: 0, clockRate: 8000, channels: 1, parameters: {}, rtcpFeedback: []}], headerExtensions: [{kind: audio, uri: urn:ietf:params:rtp-hdrext:ssrc-audio-level, preferredId: 10, preferredEncrypt: null, direction: sendrecv}]}
