class ProducerInfo {
  Map<dynamic, dynamic>? offerMediaObject;
  Map<dynamic, dynamic>? rtpParameters;
  Map<dynamic, dynamic>? sdpSendingRtpParameters;
  Map<dynamic, dynamic>? sdpSendingRemoteRtpParameters;
  Map<dynamic, dynamic>? sdpCodecOptions;
  dynamic? reuseMid;
  String? sdpAnswer;
  String? sdpOffer;
  dynamic? encodings;
  Map? localSdpObject;
  String? mid;
  String? kind;
  String? localId;
  String? streamId;
  Map<String, dynamic>? constraints;
  dynamic? cname;
  String? trackId;
  dynamic? mediaSectionId;

  ProducerInfo(
      {this.offerMediaObject,
      this.streamId,
      this.constraints,
      this.rtpParameters,
      this.sdpSendingRtpParameters,
      this.sdpSendingRemoteRtpParameters,
      this.sdpCodecOptions,
      this.reuseMid,
      this.sdpAnswer,
      this.sdpOffer,
      this.encodings,
      this.localSdpObject,
      this.mid,
      this.kind,
      this.localId,
      this.cname,
      this.trackId,
      this.mediaSectionId});
}
