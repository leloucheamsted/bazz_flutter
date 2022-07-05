class Device {
  String? id;
  String? pttKeyDownName;
  String? pttKeyUpName;
  String? sosKeyDownName;
  String? sosKeyUpName;
  String? pttChannelKeyDownName;
  String? pttChannelKeyUpName;
  int? hardwareKeyType;
  int? sosKeyCode;
  int? pttKeyCode;
  int? switchUpKeyCode;
  int? switchDownKeyCode;
  static bool? isPrivate;

  Device.fromObsoleteResponse(Map<String, dynamic> map)
      : id = map['deviceId'] != null ? map['deviceId'] as String : "",
        pttKeyCode = map['keysConfig']['ptt'] as int,
        sosKeyCode = map['keysConfig']['sos'] as int,
        switchUpKeyCode = map['keysConfig']['pttChannelUp'] as int,
        switchDownKeyCode = map['keysConfig']['pttChannelDown'] as int;

  Device.fromResponse(Map<String, dynamic> map)
      : id = map['deviceId'] != null ? map['deviceId'] as String : "",
        pttKeyCode = map['keyConfig'] != null &&
                map['keyConfig']['keyCodeConfig'] != null
            ? map['keyConfig']['keyCodeConfig']['ptt'] as int
            : 266,
        sosKeyCode = map['keyConfig'] != null &&
                map['keyConfig']['keyCodeConfig'] != null
            ? map['keyConfig']['keyCodeConfig']['sos'] as int
            : 269,
        switchUpKeyCode = map['keyConfig'] != null &&
                map['keyConfig']['keyCodeConfig'] != null
            ? map['keyConfig']['keyCodeConfig']['pttChannelUp'] as int
            : 270,
        switchDownKeyCode = map['keyConfig'] != null &&
                map['keyConfig']['keyCodeConfig'] != null
            ? map['keyConfig']['keyCodeConfig']['pttChannelDown'] as int
            : 271,
        hardwareKeyType =
            map['keyConfig'] != null ? map['keyConfig']['useType'] as int : 0,
        pttKeyDownName = map['keyConfig'] != null &&
                map['keyConfig']['keyNameConfig'] != null
            ? map['keyConfig']['keyNameConfig']['pttDown'] as String
            : "android.intent.action.PTT.down",
        pttKeyUpName = map['keyConfig'] != null &&
                map['keyConfig']['keyNameConfig'] != null
            ? map['keyConfig']['keyNameConfig']['pttUp'] as String
            : "android.intent.action.PTT.up",
        sosKeyDownName = map['keyConfig'] != null &&
                map['keyConfig']['keyNameConfig'] != null
            ? map['keyConfig']['keyNameConfig']['sosUp'] as String
            : "android.intent.action.SOS.up",
        sosKeyUpName = map['keyConfig'] != null &&
                map['keyConfig']['keyNameConfig'] != null
            ? map['keyConfig']['keyNameConfig']['sosDown'] as String
            : "android.intent.action.SOS.down",
        pttChannelKeyDownName = map['keyConfig'] != null &&
                map['keyConfig']['keyNameConfig'] != null
            ? map['keyConfig']['keyNameConfig']['pttChannelDown'] as String
            : "android.intent.action.CHANNELDOWN",
        pttChannelKeyUpName = map['keyConfig'] != null &&
                map['keyConfig']['keyNameConfig'] != null
            ? map['keyConfig']['keyNameConfig']['pttChannelUp'] as String
            : "android.intent.action.CHANNELUP";

  Device.fromMap(Map<String, dynamic> map)
      : id = map['deviceId'] != null ? map['deviceId'] as String : "",
        pttKeyCode = map['pttKeyCode'] as int,
        sosKeyCode = map['sosKeyCode'] as int,
        switchUpKeyCode = map['pttChannelUpKeyCode'] as int,
        switchDownKeyCode = map['pttChannelDownKeyCode'] as int,
        hardwareKeyType = map['hardwareKetType'] as int,
        pttKeyDownName = map['pttKeyDownName'] as String,
        pttKeyUpName = map['pttKeyUpName'] as String,
        sosKeyDownName = map['sosKeyDownName'] as String,
        sosKeyUpName = map['sosKeyUpName'] as String,
        pttChannelKeyDownName = map['pttChannelKeyUpName'] as String,
        pttChannelKeyUpName = map['pttChannelKeyUpName'] as String;

  Map<String, dynamic> toMap() {
    return {
      'deviceId': id,
      'sosKeyCode': sosKeyCode,
      'pttKeyCode': pttKeyCode,
      "pttChannelUpKeyCode": switchUpKeyCode,
      "pttChannelDownKeyCode": switchDownKeyCode,
      'hardwareKetType': hardwareKeyType,
      'pttKeyDownName': pttKeyDownName,
      'pttKeyUpName': pttKeyUpName,
      "sosKeyDownName": sosKeyDownName,
      "sosKeyUpName": sosKeyUpName,
      "pttChannelKeyDownName": pttChannelKeyDownName,
      "pttChannelKeyUpName": pttChannelKeyUpName
    };
  }
}
