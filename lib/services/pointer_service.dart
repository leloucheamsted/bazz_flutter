import 'package:bazz_flutter/services/logger.dart';
import 'package:flutter/services.dart';

const MethodChannel _channel = MethodChannel('com.bazzptt/pointer');
typedef OnPointerDown = void Function();
typedef OnPointerUp = void Function();

mixin Pointer {
  static OnPointerDown? pointerDown;
  static OnPointerUp? pointerUp;

  static void init() {
    _channel.setMethodCallHandler((call) async {
      switch (call.method) {
        case "onPointerDown":
          try {
            pointerDown?.call();
          } catch (e, s) {
            TelloLogger().e(e, stackTrace: s);
          }
          break;
        case "onPointerUp":
          try {
            pointerUp?.call();
          } catch (e, s) {
            TelloLogger().e(e, stackTrace: s);
          }
          break;
        default:
          throw MissingPluginException();
      }
    });
  }
}
