import 'media_section.dart';

class OfferMediaSection extends MediaSection {
  OfferMediaSection(data) : super(data as Map<dynamic, dynamic>) {
    Map sctpParameters = data["sctpParameters"] as Map<dynamic, dynamic>;
    Map plainRtpParameters =
        data["plainRtpParameters"] as Map<dynamic, dynamic>;
    String mid = data["mid"] as String;
    String kind = data["kind"] as String;
    Map offerRtpParameters =
        data["offerRtpParameters"] as Map<dynamic, dynamic>;
    String streamId = data["streamId"] as String;
    String trackId = data["trackId"] as String;
    bool oldDataChannelSpec = data["oldDataChannelSpec"] as bool;

    mediaObject["mid"] = mid.toString();
    mediaObject["type"] = kind;

    if (plainRtpParameters == null) {
      mediaObject["connection"] = {"ip": '127.0.0.1', "version": 4};

      if (sctpParameters == null) {
        mediaObject["protocol"] = 'UDP/TLS/RTP/SAVPF';
      } else {
        mediaObject["protocol"] = 'UDP/DTLS/SCTP';
      }

      mediaObject["port"] = 7;
    } else {
      mediaObject["connection"] = {
        "ip": plainRtpParameters["ip"],
        "version": plainRtpParameters["ipVersion"]
      };
      mediaObject["protocol"] = 'RTP/AVP';
      mediaObject["port"] = plainRtpParameters["port"];
    }

    switch (kind) {
      case 'audio':
      case 'video':
        {
          mediaObject["direction"] = 'sendonly';
          mediaObject["rtp"] = [];
          mediaObject["rtcpFb"] = [];
          mediaObject["fmtp"] = [];

          if (!planB) {
            mediaObject["msid"] = "${streamId} $trackId";
          }

          for (Map codec
              in offerRtpParameters["codecs"] as List<Map<dynamic, dynamic>>) {
            Map rtp = {
              "payload": codec["payloadType"],
              "codec": getCodecName(codec),
              "rate": codec["clockRate"]
            };

            if (codec["channels"] != null && codec["channels"] as int > 1) {
              rtp["encoding"] = codec["channels"];
            }

            mediaObject["rtp"].add(rtp);

            Map fmtp = {"payload": codec["payloadType"], "config": ''};

            for (String key in codec["parameters"].keys as List<String>) {
              if (fmtp["config"].length > 0 != null) {
                fmtp["config"] += ';';
              }

              fmtp["config"] += "$key=${codec["parameters"][key]}";
            }

            if (fmtp["config"] != null) {
              mediaObject["fmtp"].add(fmtp);
            }

            for (Map fb
                in codec["rtcpFeedback"] as List<Map<dynamic, dynamic>>) {
              mediaObject["rtcpFb"].add({
                "payload": codec["payloadType"],
                "type": fb["type"],
                "subtype": fb["parameter"]
              });
            }
          }

          mediaObject["payloads"] = offerRtpParameters["codecs"]
              .map((codec) => codec["payloadType"])
              .join(' ');

          mediaObject["ext"] = [];

          for (Map ext in offerRtpParameters["headerExtensions"]
              as List<Map<dynamic, dynamic>>) {
            mediaObject["ext"].add({"uri": ext["uri"], "value": ext["id"]});
          }

          mediaObject["rtcpMux"] = 'rtcp-mux';
          mediaObject["rtcpRsize"] = 'rtcp-rsize';

          Map encoding =
              offerRtpParameters["encodings"][0] as Map<dynamic, dynamic>;
          int ssrc = encoding["ssrc"] as int;
          int? rtxSsrc =
              (encoding["rtx"] != null && encoding["rtx"]["ssrc"] != null)
                  ? encoding["rtx"]["ssrc"] as int
                  : null;

          mediaObject["ssrcs"] = [];
          mediaObject["ssrcGroups"] = [];

          if (offerRtpParameters["rtcp"]["cname"] != null) {
            mediaObject["ssrcs"].add({
              "id": ssrc,
              "attribute": 'cname',
              "value": offerRtpParameters["rtcp"]["cname"]
            });
          }

          if (planB) {
            mediaObject["ssrcs"].add({
              "id": ssrc,
              "attribute": 'msid',
              "value": "${streamId} $trackId"
            });
          }

          if (rtxSsrc != null) {
            if (offerRtpParameters["rtcp"]["cname"] != null) {
              mediaObject["ssrcs"].add({
                "id": rtxSsrc,
                "attribute": 'cname',
                "value": offerRtpParameters["rtcp"]["cname"]
              });
            }

            if (planB) {
              mediaObject["ssrcs"].add({
                "id": rtxSsrc,
                "attribute": 'msid',
                "value": "${streamId} $trackId"
              });
            }

            // Associate original and retransmission SSRCs.
            mediaObject["ssrcGroups"]
                .add({"semantics": 'FID', "ssrcs": "$ssrc $rtxSsrc"});
          }

          break;
        }

      case 'application':
        {
          // New spec.
          if (!oldDataChannelSpec != null) {
            mediaObject["payloads"] = 'webrtc-datachannel';
            mediaObject["sctpPort"] = sctpParameters["port"];
            mediaObject["maxMessageSize"] = sctpParameters["maxMessageSize"];
          }
          // Old spec.
          else {
            mediaObject["payloads"] = sctpParameters["port"];
            mediaObject["sctpmap"] = {
              "app": 'webrtc-datachannel',
              "sctpmapNumber": sctpParameters["port"],
              "maxMessageSize": sctpParameters["maxMessageSize"]
            };
          }

          break;
        }
    }
  }

  /**
	 * @param {String} role
	 */
  setDtlsRole(String role) {
    // Always 'actpass'.
    mediaObject["setup"] = 'actpass';
  }

  planBReceive(data) {
    Map offerRtpParameters =
        data["offerRtpParameters"] as Map<dynamic, dynamic>;
    String streamId = data["streamId"] as String;
    String trackId = data["trackId"] as String;
    Map encoding = offerRtpParameters["encodings"][0] as Map<dynamic, dynamic>;
    String ssrc = encoding["ssrc"] as String;
    String? rtxSsrc =
        (encoding["rtx"] != null && encoding["rtx"]["ssrc"] != null)
            ? encoding["rtx"]["ssrc"] as String
            : null;

    if (offerRtpParameters["rtcp"]["cname"] as bool) {
      mediaObject["ssrcs"].add({
        "id": ssrc,
        "attribute": 'cname',
        "value": offerRtpParameters["rtcp"]["cname"]
      });
    }

    mediaObject["ssrcs"].add(
        {"id": ssrc, "attribute": 'msid', "value": "${streamId} $trackId"});

    if (rtxSsrc != null) {
      if (offerRtpParameters["rtcp"]["cname"] as bool) {
        mediaObject["ssrcs"].add({
          "id": rtxSsrc,
          "attribute": 'cname',
          "value": offerRtpParameters["rtcp"]["cname"]
        });
      }

      mediaObject["ssrcs"].add({
        "id": rtxSsrc,
        "attribute": 'msid',
        "value": "${streamId} $trackId"
      });

      // Associate original and retransmission SSRCs.
      mediaObject["ssrcGroups"]
          .add({"semantics": 'FID', "ssrcs": "$ssrc $rtxSsrc"});
    }
  }

  planBStopReceiving(offerRtpParameters) {
    Map encoding = offerRtpParameters["encodings"][0] as Map<dynamic, dynamic>;
    String ssrc = encoding["ssrc"] as String;
    String? rtxSsrc =
        (encoding["rtx"] != null && encoding["rtx"]["ssrc"] != null)
            ? encoding["rtx"]["ssrc"] as String
            : null;

    mediaObject["ssrcs"] = mediaObject["ssrcs"]
        .filter((s) => s["id"] != ["ssrc"] && s["id"] != ["rtxSsrc"]);

    if (rtxSsrc != null) {
      mediaObject["ssrcGroups"] = mediaObject["ssrcGroups"]
          .filter((group) => group["ssrcs"] != "$ssrc $rtxSsrc");
    }
  }
}
