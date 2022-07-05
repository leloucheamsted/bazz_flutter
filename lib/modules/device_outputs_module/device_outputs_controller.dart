import 'package:bazz_flutter/services/device_outputs_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:flutter_audio_manager/flutter_audio_manager.dart';
import 'package:get/get.dart';

class DeviceOutputsController extends GetxController {
  static DeviceOutputsController get to => Get.find();

  RxBool hasHeadphone$ = false.obs;
  RxBool hasBluetooth$ = false.obs;

  bool get hasBluetooth => hasBluetooth$.value;
  bool get hasHeadphone => hasHeadphone$.value;

  Rx<AudioPort> selectedDevice$ = AudioPort.speaker.obs;
  AudioPort get selectedDevice => selectedDevice$.value;

  @override
  Future<void> onInit() async {
    TelloLogger().i("0000 selected device ==> ${DeviceOutputs().selectedDevice}");
    selectedDevice$.value = DeviceOutputs().selectedDevice;
    hasHeadphone$.value =  DeviceOutputs().hasHeadphone;
    hasBluetooth$.value =  DeviceOutputs().hasBluetooth;
    super.onInit();
  }


  Future<void> changeToHeadphone() async{
    DeviceOutputs().changeToHeadphone();
    selectedDevice$.value = DeviceOutputs().selectedDevice;
  }

  Future<void> changeToBluetooth() async{
    DeviceOutputs().changeToBluetooth();
    selectedDevice$.value = DeviceOutputs().selectedDevice;
  }

  Future<void> changeToSpeaker() async{
    DeviceOutputs().changeToSpeaker();
    selectedDevice$.value = DeviceOutputs().selectedDevice;
  }
}
