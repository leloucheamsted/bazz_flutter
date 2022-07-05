import 'package:flutter_webrtc/webrtc.dart';

getRtpEncodings(offerMediaObject) {
  Set? ssrcs;

  for (Map line in offerMediaObject["ssrcs"] ?? []) {
    late int? ssrc;
    ssrc = line["id"] as int;
    ssrcs!.add(ssrc);
  }

  if (ssrcs!.length == 0) throw ('no a=ssrc lines found');

  Map ssrcToRtxSsrc = Map();

  // First assume RTX is used.
  for (Map line in offerMediaObject["ssrcGroups"] ?? []) {
    if (line["semantics"] != 'FID') continue;

    List<String> tokens = (line["ssrcs"] as String).split(" ");
    int? ssrc, rtxSsrc;
    if (tokens.length > 0) {
      ssrc = int.parse(tokens[0]);
    }
    if (tokens.length > 1) {
      rtxSsrc = int.parse(tokens[1]);
    }

    if (ssrcs.contains(ssrc)) {
      // Remove both the SSRC and RTX SSRC from the set so later we know that they
      // are already handled.
      ssrcs.remove(ssrc);
      ssrcs.remove(rtxSsrc);

      // Add to the map.
      ssrcToRtxSsrc[ssrc] = rtxSsrc!;
    }
  }

  // If the set of SSRCs is not empty it means that RTX is not being used, so take
  // media SSRCs from there.
  for (int ssrc in ssrcs as List<int>) {
    // Add to the map.
    ssrcToRtxSsrc[ssrc] = null;
  }

  List encodings = [];

  for (int ssrc in ssrcToRtxSsrc.keys as List<int>) {
    int rtxSsrc = ssrcToRtxSsrc[ssrc] as int;
    Map encoding = {"ssrc": ssrc};

    if (rtxSsrc != null) encoding["rtx"] = {"ssrc": rtxSsrc};

    encodings.add(encoding);
  }

  return encodings;
}

getRtpEncodingsPlanB(offerMediaObject, MediaStreamTrack track) {
  Set ssrcs = Set();
  int? firstSsrc;
  for (Map line in offerMediaObject["ssrcs"] ?? []) {
    if (line["attribute"] != 'msid') {
      continue;
    }

    //ssrcs.add(ssrc);
    String trackId = line['value'].toString().split(' ')[1];

    if (trackId == track.id) {
      int ssrc = line["id"] as int;

      ssrcs.add(ssrc);

      if (firstSsrc == null) {
        firstSsrc = ssrc;
      }
    }
  }

  if (ssrcs.length == 0) throw ('no a=ssrc lines found');

  Map ssrcToRtxSsrc = Map();

  // First assume RTX is used.
  for (Map line in offerMediaObject["ssrcGroups"] ?? []) {
    if (line["semantics"] != 'FID') continue;

    List<String> tokens = (line["ssrcs"] as String).split(" ");
    int? ssrc, rtxSsrc;
    if (tokens.length > 0) {
      ssrc = int.parse(tokens[0]);
    }
    if (tokens.length > 1) {
      rtxSsrc = int.parse(tokens[1]);
    }

    if (ssrcs.contains(ssrc)) {
      // Remove both the SSRC and RTX SSRC from the set so later we know that they
      // are already handled.
      ssrcs.remove(ssrc);
      ssrcs.remove(rtxSsrc);

      // Add to the map.
      ssrcToRtxSsrc[ssrc] = rtxSsrc;
    }
  }

  // If the set of SSRCs is not empty it means that RTX is not being used, so take
  // media SSRCs from there.
  for (int ssrc in ssrcs as List<int>) {
    // Add to the map.
    ssrcToRtxSsrc[ssrc] = null;
  }

  List encodings = [];

  for (int ssrc in ssrcToRtxSsrc.keys as List<int>) {
    int rtxSsrc = ssrcToRtxSsrc[ssrc] as int;
    Map encoding = {"ssrc": ssrc};

    if (rtxSsrc != null) encoding["rtx"] = {"ssrc": rtxSsrc};

    encodings.add(encoding);
  }

  return encodings;
}
