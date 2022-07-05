class ConsumerInfo {
  Map<dynamic, dynamic>? answerMediaObject;
  Map<dynamic, dynamic>? rtpParameters;
  Map<dynamic, dynamic>? offerRtpParameters;
  dynamic? reuseMid;
  String? sdpAnswer;
  String? remoteSdp;
  Map? encodings;
  String? localSdpObject;
  String? mid;
  String? kind;
  String? localId;
  dynamic? cname;
  String? trackId;

  ConsumerInfo(
      {this.answerMediaObject,
      this.rtpParameters,
      this.offerRtpParameters,
      this.reuseMid,
      this.sdpAnswer,
      this.remoteSdp,
      this.encodings,
      this.localSdpObject,
      this.mid,
      this.kind,
      this.localId,
      this.cname,
      this.trackId});
}
