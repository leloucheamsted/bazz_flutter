import 'package:bazz_flutter/services/logger.dart';
import 'package:flutter/services.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';

class KeyEvent {
  final int deviceId, source, metaState, action, keyCode, scanCode, repeatCount, flags, downTime, eventTime;
  final String characters;

  KeyEvent.fromMsg(List msg)
      : deviceId = msg[0] as int,
        source = msg[1] as int,
        metaState = msg[2] as int,
        action = msg[3] as int,
        keyCode = msg[4] as int,
        scanCode = msg[5] as int,
        repeatCount = msg[6] as int,
        flags = msg[7] as int,
        downTime = msg[8] as int,
        eventTime = msg[9] as int,
        characters = msg[10] as String;

  @override
  String toString() {
    return "KeyEvent { action=$action, "
        "keycode=$keyCode, "
        "scanCode=$scanCode, "
        "metaState=$metaState, "
        "flags=$flags, "
        "repeatCount=$repeatCount, "
        "eventTime=$eventTime, "
        "downTime=$downTime, "
        "deviceId=$deviceId, "
        "source=$source  }";
  }
}

typedef OnKey = void Function(int keyCode, KeyEvent event);

const MethodChannel _channel = MethodChannel('com.bazzptt/keyboard');

mixin Keyboard {
  static final List<OnKey> onKeyDown = [];
  static final List<OnKey> onKeyUp = [];
  static final List<OnKey> onPttButtonDown = [];
  static final List<OnKey> onPttButtonUp = [];
  static final List<OnKey> onSOSButtonDown = [];
  static final List<OnKey> onSOSButtonUp = [];
  static final List<OnKey> onSwitchButtonDown = [];
  static final List<OnKey> onSwitchButtonUp = [];

  static int pttKeyCode = -1;
  static int sosKeyCode = -1;
  static int switchUpKeyCode = -1;
  static int switchDownKeyCode = -1;
  static RxInt keyboardDownKey$ = 0.obs;
  static RxInt keyboardUpKey$ = 0.obs;

  static Future<void> setPttButtonCode(int code) async => pttKeyCode = code;

  static Future<void> setSOSButtonCode(int code) async => sosKeyCode = code;

  static Future<void> setSwitchUpButtonCode(int code) async => switchUpKeyCode = code;

  static Future<void> setSwitchDownButtonCode(int code) async => switchDownKeyCode = code;

  static void init() {
    _channel.setMethodCallHandler((call) async {
      final args = call.arguments;
      switch (call.method) {
        case "onKeyDown":
          try {
            final evt = KeyEvent.fromMsg(args[1] as List);
            final int argValue = args[0] as int;
            keyboardDownKey$.value = evt.keyCode;
            TelloLogger().i("KeyEvent.fromMsg ==> ${evt.keyCode}");
            if (evt.keyCode == pttKeyCode && evt.repeatCount == 0) {
              for (final value in onPttButtonDown) {
                value(argValue, evt);
              }
              break;
            } else if (evt.keyCode == sosKeyCode && evt.repeatCount == 0) {
              for (final value in onSOSButtonDown) {
                value(argValue, evt);
              }
              break;
            } else if (evt.keyCode == switchUpKeyCode && evt.repeatCount == 0) {
              for (final value in onSwitchButtonUp) {
                value(argValue, evt);
              }
              break;
            } else if (evt.keyCode == switchDownKeyCode && evt.repeatCount == 0) {
              for (final value in onSwitchButtonDown) {
                value(argValue, evt);
              }
              break;
            }
            for (final value in onKeyDown) {
              value(argValue, evt);
            }
          } catch (e, s) {
            TelloLogger().e(e, stackTrace: s);
          }
          break;
        case "onKeyUp":
          try {
            final evt = KeyEvent.fromMsg(args[1] as List);
            final argValue = args[0] as int;
            keyboardUpKey$.value = evt.keyCode;
            // Logger().log("evt.scanCode key up ${evt.scanCode}");
            if (evt.keyCode == pttKeyCode && evt.repeatCount == 0) {
              for (final value in onPttButtonUp) {
                value(argValue, evt);
              }
              break;
            } else if (evt.keyCode == sosKeyCode && evt.repeatCount == 0) {
              for (final value in onSOSButtonUp) {
                value(argValue, evt);
              }
              break;
            }

            for (final value in onKeyUp) {
              value(argValue, evt);
            }
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
