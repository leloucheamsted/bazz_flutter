import 'dart:isolate';

import 'package:flutter/cupertino.dart';
import 'background_service.dart';
import 'package:bazz_flutter/services/logger.dart';

void backgroundMain() {
  TelloLogger().i("######################## START backgroundMain");
  WidgetsFlutterBinding.ensureInitialized();
  BackgroundService.instance().startKeepAliveBackgroundService();
  TelloLogger().i("######################## END backgroundMain");
}


void foregroundServiceFunction() {
  TelloLogger().i("######################## START foregroundServiceFunction");
  BackgroundService.instance().startKeepAliveFromForeground();
  TelloLogger().i("######################## END foregroundServiceFunction");
}

Future<void> backgroundServiceHandler() async {
  final DateTime now = DateTime.now();
  final int isolateId = Isolate.current.hashCode;
  TelloLogger().i("[BackgroundService] backgroundServiceHandler isolate=$isolateId");
  TelloLogger().i('################### START Background call PTT Service Init########################');
  BackgroundService.instance().startKeepAliveAlarmService();
  TelloLogger().i('################### END Background call PTT Service Init########################');
}
