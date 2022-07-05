import 'package:bazz_flutter/services/logger.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('com.bazzptt/applyhardwarekeys');
const MethodChannel _directChannel = MethodChannel('com.bazzptt/directchannel');
typedef OnHardwareKey = void Function(String key);

mixin HardwareKey {
  static OnHardwareKey? onHardwareKey;

  static void init() {
    _directChannel.setMethodCallHandler((call) async {
      if (onHardwareKey != null) {
        onHardwareKey!(call.arguments);
      }
    });
  }

  static void addPttDownHardwareKey(String hardwareKey) {
    _channel.invokeMethod("pttDown", hardwareKey);
  }

  static void addPttUpHardwareKey(String hardwareKey) {
    _channel.invokeMethod("pttUp", hardwareKey);
  }

  static void addSosUpHardwareKey(String hardwareKey) {
    _channel.invokeMethod("sosUp", hardwareKey);
  }

  static void addSosDownHardwareKey(String hardwareKey) {
    _channel.invokeMethod("sosDown", hardwareKey);
  }

  static void addChannelDownHardwareKey(String hardwareKey) {
    _channel.invokeMethod("pttChannelDown", hardwareKey);
  }

  static void addChannelUpHardwareKey(String hardwareKey) {
    _channel.invokeMethod("pttChannelUp", hardwareKey);
  }

  static void startReceiver() {
    _channel.invokeMethod("startReceiver", null);
  }
}
