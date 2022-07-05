import 'dart:convert';

GnssStatusModel gnssStatusModelFromJson(String str) =>
    GnssStatusModel.fromJson(json.decode(str) as Map<String, dynamic>);

String gnssStatusModelToJson(GnssStatusModel data) =>
    json.encode(data.toJson());

/// Model for the GnssStatus class in Android
class GnssStatusModel {
  GnssStatusModel({
    this.satelliteCount,
    this.hashCodec,
    this.status,
  });

  int satelliteCount;
  int hashCodec;
  List<Status> status;

  factory GnssStatusModel.fromJson(Map<String, dynamic> json) =>
      GnssStatusModel(
        satelliteCount: json["satelliteCount"] as int == null
            ? null
            : json["satelliteCount"] as int,
        hashCodec:
            json["hashCode"] as int == null ? null : json["hashCode"] as int,
        status: json["status"] == null
            ? null
            : List<Status>.from(json["status"].map((x) => Status.fromJson(
                    Map<String, dynamic>.from(x as Map<dynamic, dynamic>)))
                as Iterable<dynamic>),
      );

  Map<String, dynamic> toJson() => {
        "satelliteCount": satelliteCount == null ? null : satelliteCount,
        "hashCode": hashCodec == null ? null : hashCodec,
        "status": status == null
            ? null
            : List<dynamic>.from(status.map((x) => x.toJson())),
      };
}

class Status {
  Status({
    this.azimuthDegrees,
    this.carrierFrequencyHz,
    this.cn0DbHz,
    this.constellationType,
    this.elevationDegrees,
    this.svid,
    this.hasAlmanacData,
    this.hasCarrierFrequencyHz,
    this.hasEphemerisData,
    this.usedInFix,
  });

  double azimuthDegrees;
  double carrierFrequencyHz;
  double cn0DbHz;
  int constellationType;
  double elevationDegrees;
  int svid;
  bool hasAlmanacData;
  bool hasCarrierFrequencyHz;
  bool hasEphemerisData;
  bool usedInFix;

  factory Status.fromJson(Map<String, dynamic> json) => Status(
        azimuthDegrees: json["azimuthDegrees"] as double == null
            ? null
            : json["azimuthDegrees"].toDouble() as double,
        carrierFrequencyHz: json["carrierFrequencyHz"] as double == null
            ? null
            : json["carrierFrequencyHz"].toDouble() as double,
        cn0DbHz: json["cn0DbHz"] as double == null
            ? null
            : json["cn0DbHz"].toDouble() as double,
        constellationType: json["constellationType"] as int == null
            ? null
            : json["constellationType"] as int,
        elevationDegrees: json["elevationDegrees"] as double == null
            ? null
            : json["elevationDegrees"].toDouble() as double,
        svid: json["svid"] as int == null ? null : json["svid"] as int,
        hasAlmanacData: json["hasAlmanacData"] as bool == null
            ? null
            : json["hasAlmanacData"] as bool,
        hasCarrierFrequencyHz: json["hasCarrierFrequencyHz"] as bool == null
            ? null
            : json["hasCarrierFrequencyHz"] as bool,
        hasEphemerisData: json["hasEphemerisData"] as bool == null
            ? null
            : json["hasEphemerisData"] as bool,
        usedInFix: json["usedInFix"] as bool == null
            ? null
            : json["usedInFix"] as bool,
      );

  Map<String, dynamic> toJson() => {
        "azimuthDegrees": azimuthDegrees == null ? null : azimuthDegrees,
        "carrierFrequencyHz":
            carrierFrequencyHz == null ? null : carrierFrequencyHz,
        "cn0DbHz": cn0DbHz == null ? null : cn0DbHz,
        "constellationType":
            constellationType == null ? null : constellationType,
        "elevationDegrees": elevationDegrees == null ? null : elevationDegrees,
        "svid": svid == null ? null : svid,
        "hasAlmanacData": hasAlmanacData == null ? null : hasAlmanacData,
        "hasCarrierFrequencyHz":
            hasCarrierFrequencyHz == null ? null : hasCarrierFrequencyHz,
        "hasEphemerisData": hasEphemerisData == null ? null : hasEphemerisData,
        "usedInFix": usedInFix == null ? null : usedInFix,
      };
}
