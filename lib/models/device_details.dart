



class DeviceDetails {
  final String itemNumber, name, simSerialNumber, imei;

  DeviceDetails.fromMap(Map<String, dynamic> m)
      : itemNumber = m['itemNo'] as String,
        name = m['name'] as String,
        simSerialNumber = m['simSerialNumber'] as String,
        imei = m['imei'] as String;

  Map<String, dynamic> toMap() {
    return {
      'itemNo': itemNumber,
      'name': name,
      'simSerialNumber': simSerialNumber,
      'imei': imei,
    };
  }
}
