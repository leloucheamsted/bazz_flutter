import 'package:bazz_flutter/models/device_details.dart';
import 'package:bazz_flutter/models/device_state.dart';
import 'package:get/get.dart';

class DeviceCard {
  final String id;
  final Rx<DeviceState> deviceState;
  final DeviceDetails deviceDetails;

  DeviceCard.fromMap(Map<String, dynamic> m)
      : id = m['id'] as String,
        deviceState = m['state'] != null
            ? DeviceState.fromMap(m['state'] as Map<String, dynamic>).obs
            : DeviceState.createEmpty().obs,
        deviceDetails =
            DeviceDetails.fromMap(m['details'] as Map<String, dynamic>);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'state': deviceState().toMap(),
      'details': deviceDetails.toMap(),
    };
  }
}
