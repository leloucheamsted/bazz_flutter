import 'package:vibration/vibration.dart';

class Vibrator {
  static Future<void> startShortVibration() async {
    if (!await Vibration.hasVibrator()) {
      return;
    }
    if (await Vibration.hasCustomVibrationsSupport()) {
      Vibration.vibrate(duration: 200);
    } else {
      Vibration.vibrate();
      await Future.delayed(const Duration(milliseconds: 500));
      Vibration.vibrate();
    }
  }

  static Future<void> startShortNotificationVibration() async {
    if (!await Vibration.hasVibrator()) return;

    stopNotificationVibration();

    final List<int> pattern = [
      500,
      1000,
    ];
    final List<int> intensities = [128, 255];

    if (await Vibration.hasAmplitudeControl()) {
      return Vibration.vibrate(amplitude: 128, pattern: pattern, intensities: intensities);
    } else if (await Vibration.hasCustomVibrationsSupport()) {
      return Vibration.vibrate(pattern: pattern, intensities: intensities);
    }

    return Vibration.vibrate();
  }

  static Future<void> startNotificationVibration() async {
    if (!await Vibration.hasVibrator()) return;

    stopNotificationVibration();

    final List<int> pattern = [
      500,
      3000,
      500,
      3000,
      500,
      3000,
      500,
      3000,
      500,
      3000,
      500,
      3000,
      500,
      3000,
      500,
      3000,
      500,
      3000,
      500,
      3000
    ];
    final List<int> intensities = [128, 255];

    if (await Vibration.hasAmplitudeControl()) {
      return Vibration.vibrate(amplitude: 128, pattern: pattern, intensities: intensities);
    } else if (await Vibration.hasCustomVibrationsSupport()) {
      return Vibration.vibrate(pattern: pattern, intensities: intensities);
    }

    return Vibration.vibrate();
  }

  static Future<void> stopNotificationVibration() async {
    return Vibration.cancel();
  }
}
