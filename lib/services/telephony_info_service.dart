import 'dart:async';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:cross_connectivity/cross_connectivity.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:wifi/wifi.dart';

// ignore: avoid_classes_with_only_static_members
class FltTelephonyInfo {
  static const MethodChannel _channel = MethodChannel('com.bazzptt/network');

  static Future<TelephonyInfo> get info async {
    String ssid = await Wifi.ssid;
    int level = await Wifi.level;
    String ip =
        HomeController.to.isRecordingOfflineMessage ? await Wifi.ip : 'null';
    final TelephonyInfo telephonyInfo = TelephonyInfo.fromMap(
        await _channel.invokeMapMethod<String, dynamic>(
            'getTelephonyProperties') as Map<String, dynamic>,
        ssid,
        level,
        ip);

    return telephonyInfo;
  }
}

class CallState {
  /// Device call state: No activity. */
  static const int CALL_STATE_IDLE = 0;

  /// Device call state: Ringing. A new call arrived and is
  ///  ringing or waiting. In the latter case, another call is
  ///  already active. */
  static const int CALL_STATE_RINGING = 1;

  /// Device call state: Off-hook. At least one call exists
  /// that is dialing, active, or on hold, and no calls are ringing
  /// or waiting. */
  static const int CALL_STATE_OFFHOOK = 2;
}

class NetworkType {
  /// Network type is unknown */
  static const int NETWORK_TYPE_UNKNOWN = 0;

  /// Current network is GPRS */
  static const int NETWORK_TYPE_GPRS = 1;

  /// Current network is EDGE */
  static const int NETWORK_TYPE_EDGE = 2;

  /// Current network is UMTS */
  static const int NETWORK_TYPE_UMTS = 3;

  /// Current network is CDMA: Either IS95A or IS95B*/
  static const int NETWORK_TYPE_CDMA = 4;

  /// Current network is EVDO revision 0*/
  static const int NETWORK_TYPE_EVDO_0 = 5;

  /// Current network is EVDO revision A*/
  static const int NETWORK_TYPE_EVDO_A = 6;

  /// Current network is 1xRTT*/
  static const int NETWORK_TYPE_1xRTT = 7;

  /// Current network is HSDPA */
  static const int NETWORK_TYPE_HSDPA = 8;

  /// Current network is HSUPA */
  static const int NETWORK_TYPE_HSUPA = 9;

  /// Current network is HSPA */
  static const int NETWORK_TYPE_HSPA = 10;

  /// Current network is iDen */
  static const int NETWORK_TYPE_IDEN = 11;

  /// Current network is EVDO revision B*/
  static const int NETWORK_TYPE_EVDO_B = 12;

  /// Current network is LTE */
  static const int NETWORK_TYPE_LTE = 13;

  /// Current network is eHRPD */
  static const int NETWORK_TYPE_EHRPD = 14;

  /// Current network is HSPA+ */
  static const int NETWORK_TYPE_HSPAP = 15;

  /// Current network is GSM */
  static const int NETWORK_TYPE_GSM = 16;

  /// Current network is TD_SCDMA */
  static const int NETWORK_TYPE_TD_SCDMA = 17;

  /// Current network is IWLAN */
  static const int NETWORK_TYPE_IWLAN = 18;

  /// Current network is LTE_CA {@hide} */
  static const int NETWORK_TYPE_LTE_CA = 19;

  /// Max network type number. Update as new types are added. Don't add negative types. {@hide} */
  static const int MAX_NETWORK_TYPE = NETWORK_TYPE_LTE_CA;
}

class PhoneType {
  /// No phone radio. */
  static const int PHONE_TYPE_NONE = 0;

  /// Phone radio is GSM. */
  static const int PHONE_TYPE_GSM = 1;

  /// Phone radio is CDMA. */
  static const int PHONE_TYPE_CDMA = 2;

  /// Phone is via SIP. */
  static const int PHONE_TYPE_SIP = 3;
}

class TelephonyInfo {
  TelephonyInfo._({
    this.ssid,
    this.wifiLevel,
    this.wifiIP,
    this.callState,
    this.dataNetworkType,
    this.deviceSoftwareVersion,
    this.imei,
    this.signalStrength,
    this.isDataEnabled,
    this.isNetworkRoaming,
    this.isSmsCapable,
    this.isVoiceCapable,
    this.line1Number,
    this.meid,
    this.nai,
    this.networkCountryIso,
    this.networkOperator,
    this.networkSpecifier,
    this.networkType,
    this.networkOperatorName,
    this.phoneCount,
    this.phoneType,
    this.serviceState,
    this.simCarrierId,
    this.simCarrierIdName,
    this.simCountryIso,
    this.simOperator,
    this.simOperatorName,
    this.simSerialNumber,
  });

  dynamic ssid;
  dynamic wifiLevel;
  dynamic wifiIP;
  dynamic callState;
  dynamic dataNetworkType;
  dynamic deviceSoftwareVersion;
  dynamic imei;
  dynamic signalStrength;
  dynamic isDataEnabled;
  dynamic isNetworkRoaming;
  dynamic isSmsCapable;
  dynamic isVoiceCapable;
  dynamic line1Number;
  dynamic meid;
  dynamic nai;
  dynamic networkCountryIso;
  dynamic networkOperator;
  dynamic networkSpecifier;
  dynamic networkType;
  dynamic networkOperatorName;
  dynamic phoneCount;
  dynamic phoneType;
  dynamic serviceState;
  dynamic simCarrierId;
  dynamic simCarrierIdName;
  dynamic simCountryIso;
  dynamic simOperator;
  dynamic simOperatorName;
  dynamic simSerialNumber;

  static Map<String, dynamic>? _map;
  late StreamSubscription? _connectivitySub;
  late Rx<MobileNetworkType> mobileNetworkType$;
  late Rx<int> mobileNetworkStrength$;

  MobileNetworkType get mobileNetworkType => mobileNetworkType$.value;

  int get mobileNetworkStrength => mobileNetworkStrength$.value;

  //FIXME: create dedicated class and return it instead of Map<String, dynamic>
  Future<Map<String, dynamic>?> getConnectivityStatus() async {
    final ConnectivityStatus connectivityStatus =
        await Connectivity().checkConnectivity();

    if (connectivityStatus == ConnectivityStatus.mobile) {
      return {
        "networkType": MobileNetworkType.GSM,
        "networkStrength": signalStrength
      };
    } else if (connectivityStatus == ConnectivityStatus.wifi) {
      return {
        "networkType": MobileNetworkType.WiFi,
        "networkStrength": wifiLevel
      };
    } else if (connectivityStatus == ConnectivityStatus.none) {
      return {"networkType": MobileNetworkType.none, "networkStrength": 0};
    }
    return null;
  }

  static TelephonyInfo fromMap(
      Map<String, dynamic> map, String ssid, int wifiLevel, String wifiIP) {
    _map = map;
    return TelephonyInfo._(
      ssid: ssid,
      wifiLevel: wifiLevel,
      wifiIP: wifiIP,
      callState: map["callState"],
      signalStrength: map["signalStrength"],
      simCountryIso: map["simCountryIso"],
      simOperator: map["simOperator"],
      simOperatorName: map["simOperatorName"],
      phoneType: map["phoneType"],
      networkType: map["networkType"],
      networkOperatorName: map["networkOperatorName"],
      simSerialNumber: map["simSerialNumber"] ?? "",
      dataNetworkType: map["dataNetworkType"] ?? "",
      deviceSoftwareVersion: map["deviceSoftwareVersion"] ?? "",
      imei: map["imei"] ?? "",
      isDataEnabled: map["isDataEnabled"] ?? "",
      isSmsCapable: map["isSmsCapable"] ?? "",
      isVoiceCapable: map["isVoiceCapable"] ?? "",
      line1Number: map["line1Number"] ?? "",
      meid: map["meid"] ?? "",
      nai: map["nai"] ?? "",
      networkCountryIso: map["networkCountryIso"] ?? "",
      networkOperator: map["networkOperator"] ?? "",
      networkSpecifier: map["networkSpecifier"] ?? "",
      phoneCount: map["phoneCount"] ?? "",
      serviceState: map["serviceState"] ?? "",
      simCarrierId: map["simCarrierId"] ?? "",
      simCarrierIdName: map["simCarrierIdName"] ?? "",
    );
  }

  String rawString() {
    return _map.toString();
  }

  @override
  String toString() {
    super.toString();
    return "{"
        "\ncallState:$callState,"
        "\nsignalStrength:$signalStrength,"
        "\ndataNetworkType:$dataNetworkType,"
        "\ndeviceSoftwareVersion:$deviceSoftwareVersion,"
        "\nimei:$imei,"
        "\nisDataEnabled:$isDataEnabled,"
        "\nisSmsCapable:$isSmsCapable,"
        "\nisVoiceCapable:$isVoiceCapable,"
        "\nline1Number:$line1Number,"
        "\nmeid:$meid,"
        "\nnai:$nai,"
        "\nnetworkCountryIso:$networkCountryIso,"
        "\nnetworkOperator:$networkOperator,"
        "\nnetworkSpecifier:$networkSpecifier,"
        "\nnetworkType:$networkType,"
        "\nnetworkOperatorName:$networkOperatorName,"
        "\nphoneCount:$phoneCount,"
        "\nphoneType:$phoneType,"
        "\nserviceState:$serviceState,"
        "\nsimCarrierId:$simCarrierId,"
        "\nsimCarrierIdName:$simCarrierIdName,"
        "\nsimCountryIso:$simCountryIso,"
        "\nsimOperator:$simOperator,"
        "\nsimOperatorName:$simOperatorName,"
        "\nsimSerialNumber:$simSerialNumber"
        "\n}";
  }
}
