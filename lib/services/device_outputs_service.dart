import 'dart:async';
import 'package:eventify/eventify.dart' as evf;
import 'package:flutter_audio_manager/flutter_audio_manager.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:get_storage/get_storage.dart';
import 'package:get/get.dart';

class DeviceOutputs extends evf.EventEmitter {
  static final DeviceOutputs _singleton = DeviceOutputs._();

  factory DeviceOutputs() => _singleton;

  DeviceOutputs._();

  List<AudioInput> _availableInputs = [];
  RxBool hasHeadphone$ = false.obs;
  RxBool hasBluetooth$ = false.obs;

  bool get hasBluetooth => hasBluetooth$.value;

  bool get hasHeadphone => hasHeadphone$.value;

  Rx<AudioPort> selectedDevice$ = AudioPort.speaker.obs;

  AudioPort get selectedDevice => selectedDevice$.value;

  AudioInput _currentInput = const AudioInput("unknow", 0);

  Future<void> init() async {
    await _buildAvailableDeviceInputs();
    _availableInputs = await FlutterAudioManager.getAvailableInputs();

    if (GetStorage().hasData(StorageKeys.deviceOutputId)) {
      final port = GetStorage().read(StorageKeys.deviceOutputId) as int;
      selectedDevice$.value = AudioPort.values[port];
    }

    await _getInput();
    FlutterAudioManager.setListener(() async {
      TelloLogger().i("FlutterAudioManager.setListener change audio input");
      await _getInput();
    });
  }

  Future<void> dispose() async {
    FlutterAudioManager.setListener(null);
  }

  Future<void> _getInput() async {
    _currentInput = await FlutterAudioManager.getCurrentOutput();
    TelloLogger().i("current:$_currentInput");
    _availableInputs = await FlutterAudioManager.getAvailableInputs();
    TelloLogger().i("available $_availableInputs");
    bool res = false;

    switch (selectedDevice$.value) {
      case AudioPort.speaker:
        if (_currentInput.port != AudioPort.speaker) {
          res = await FlutterAudioManager.changeToSpeaker();
          TelloLogger().i("change to speaker:$res");
        }
        break;
      case AudioPort.headphones:
        if (_currentInput.port != AudioPort.headphones) {
          res = await FlutterAudioManager.changeToHeadphones();
          TelloLogger().i("change to speaker:$res");
        }
        break;
      case AudioPort.bluetooth:
        if (_currentInput.port != AudioPort.bluetooth) {
          res = await FlutterAudioManager.changeToBluetooth();
          TelloLogger().i("change to speaker:$res");
        }
        break;
      case AudioPort.unknow:
        // TODO: Handle this case.
        break;
      case AudioPort.receiver:
        // TODO: Handle this case.
        break;
    }
  }

  Future<void> _buildAvailableDeviceInputs() async {
    try {
      _availableInputs = await FlutterAudioManager.getAvailableInputs();
      final headphones = _availableInputs.firstWhere(
          (element) => element.port == AudioPort.headphones,
          orElse: () => null as AudioInput);

      hasHeadphone$.value = headphones != null;

      final bluetooth = _availableInputs.firstWhere(
          (element) => element.port == AudioPort.bluetooth,
          orElse: () => null as AudioInput);

      hasBluetooth$.value = bluetooth != null;
    } catch (e, s) {
      TelloLogger().e("_getInput error ==> $e", stackTrace: s);
    }
  }

  Future<void> changeToHeadphone() async {
    if (hasHeadphone) {
      await FlutterAudioManager.changeToHeadphones();
      selectedDevice$.value = AudioPort.headphones;
      GetStorage().write(StorageKeys.deviceOutputId, selectedDevice$.value);
    }
  }

  Future<void> changeToBluetooth() async {
    if (hasBluetooth) {
      await FlutterAudioManager.changeToBluetooth();
      selectedDevice$.value = AudioPort.bluetooth;
      GetStorage().write(StorageKeys.deviceOutputId, selectedDevice$.value);
    }
  }

  Future<void> changeToSpeaker() async {
    await FlutterAudioManager.changeToSpeaker();
    selectedDevice$.value = AudioPort.speaker;
    GetStorage().write(StorageKeys.deviceOutputId, selectedDevice$.value);
  }
}
