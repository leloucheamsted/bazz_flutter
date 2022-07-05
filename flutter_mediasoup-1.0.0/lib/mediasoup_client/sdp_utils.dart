import 'package:flutter_mediasoup/mediasoup_client/dtls_parameters.dart';
import 'package:sdp_transform/sdp_transform.dart';

extractDtlsParameters(dynamic sdp) {
  Map mediaObject = (sdp["media"].toList() ?? []).firstWhere(
      (media) => media['iceUfrag'] != null && media['port'] != 0,
      orElse: () => null) as Map<dynamic, dynamic>;

  if (mediaObject == null) {
    throw ("Error no actvie media object!");
  }

  Map fingerprint =
      mediaObject["fingerprint"] ?? sdp["fingerprint"] as Map<dynamic, dynamic>;
  String? role;

  switch (mediaObject["setup"] as String) {
    case 'active':
      role = 'client';
      break;
    case 'passive':
      role = 'server';
      break;
    case 'actpass':
      role = 'auto';
      break;
  }

  DtlsParameters dtlsParameters = DtlsParameters.fromJson({
    "role": role,
    "fingerprints": [
      {"algorithm": fingerprint["type"], "value": fingerprint["hash"]}
    ]
  });

  return dtlsParameters;
}

extractRtpCapabilities(Map sdpObject) {
  // Map of RtpCodecParameters indexed by payload type.
  Map codecsMap = Map();
  // Array of RtpHeaderExtensions.
  List headerExtensions = [];
  // Whether a m=audio/video section has been already found.
  bool gotAudio = false;
  bool gotVideo = false;

  for (final Map m in (sdpObject["media"] as List<Map<String, dynamic>>)) {
    String kind = m["type"] as String;

    switch (kind) {
      case 'audio':
        {
          if (gotAudio) continue;

          gotAudio = true;

          break;
        }
      case 'video':
        {
          if (gotVideo) continue;

          gotVideo = true;

          break;
        }
      default:
        {
          continue;
        }
    }

    // Get codecs.
    for (final Map rtp in m["rtp"] as List<Map<String, dynamic>>) {
      Map codec = {
        "kind": kind,
        "mimeType": "$kind/${rtp["codec"]}",
        "preferredPayloadType": rtp["payload"],
        "clockRate": rtp["rate"],
        "channels": rtp["encoding"],
        "parameters": {},
        "rtcpFeedback": []
      };

      codecsMap[codec["preferredPayloadType"]] = codec;
    }

    // Get codec parameters.
    for (Map fmtp in (m["fmtp"] ?? [])) {
      Map _parameters = parse(fmtp["config"] as String);
      Map codec = codecsMap[fmtp["payload"]] as Map<String, dynamic>;

      if (codec == null) continue;

      Map parameters = Map();
      for (final String key in _parameters.keys as List<String>) {
        if (_parameters[key].length > 0 != null) {
          parameters[key] = _parameters[key][0]["value"];
        }
      }

      // Specials case to convert parameter value to string.
      if (parameters != null && parameters['profile-level-id'] != null)
        parameters['profile-level-id'] = parameters['profile-level-id'];

      // codec["parameters"] = parameters;
    }

    // Get RTCP feedback for each codec.
    for (final Map fb in (m["rtcpFb"] ?? [])) {
      final Map codec = codecsMap[fb["payload"]] as Map<String, dynamic>;

      if (codec == null) continue;

      Map feedback = {"type": fb["type"], "parameter": fb["subtype"]};

      if (feedback["parameter"] == null) feedback.remove("parameter");

      codec["rtcpFeedback"].add(feedback);
    }

    // Get RTP header extensions.
    for (final Map ext in (m["ext"] ?? [])) {
      Map headerExtension = {
        "kind": kind,
        "uri": ext["uri"],
        "preferredId": ext["value"]
      };

      headerExtensions.add(headerExtension);
    }
  }

  Map rtpCapabilities = {
    "codecs": codecsMap.keys.map((key) => codecsMap[key]).toList(),
    "headerExtensions": headerExtensions
  };

  return rtpCapabilities;
}

getCname(Map offerMediaObject) {
  Map ssrcCnameLine = (offerMediaObject["ssrcs"] ?? []).firstWhere(
      (line) => line["attribute"] == 'cname',
      orElse: () => null) as Map<String, dynamic>;

  if (ssrcCnameLine == null) return '';

  return ssrcCnameLine["value"];
}

applyCodecParameters({Map? offerRtpParameters, Map? answerMediaObject}) {
  for (final Map codec
      in offerRtpParameters!["codecs"] as List<Map<String, dynamic>>) {
    String mimeType = codec["mimeType"].toLowerCase() as String;

    // Avoid parsing codec parameters for unhandled codecs.
    if (mimeType != 'audio/opus') continue;

    Map rtp = (answerMediaObject!["rtp"] ?? []).firstWhere(
        (r) => r["payload"] == codec["payloadType"],
        orElse: () => null) as Map<String, dynamic>;

    if (rtp == null) continue;

    // Just in case.
    answerMediaObject["fmtp"] = answerMediaObject["fmtp"] ?? [];

    Map fmtp = answerMediaObject["fmtp"].firstWhere(
        (f) => f["payload"] == codec["payloadType"],
        orElse: () => null) as Map<String, dynamic>;

    if (fmtp == null) {
      fmtp = {"payload": codec["payloadType"], "config": ''};
      answerMediaObject["fmtp"].push(fmtp);
    }

    Map parameters = parseParams(fmtp["config"] as String);

    switch (mimeType) {
      case 'audio/opus':
        {
          int spropStereo = codec["parameters"]['sprop-stereo'] as int;

          if (spropStereo != null)
            parameters["stereo"] = spropStereo > 0 ? 1 : 0;

          break;
        }
    }

    // Write the codec fmtp.config back.
    fmtp["config"] = '';

    for (final String key in parameters.keys as List<String>) {
      if (fmtp["config"].length > 0 != null) fmtp["config"] += ';';

      fmtp["config"] += "$key=${parameters[key]}";
    }
  }
}
