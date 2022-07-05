import 'dart:convert';

import 'package:bazz_flutter/models/alert_check_result.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/services/networking_client.dart';
import 'package:dio/dio.dart';

class AlertCheckRepository {
  Future<Response<Map<String, dynamic>>> sendResult(
      AlertCheckResult result) async {
    final preparedData = result.toMapForServer();
    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/Shift/Quiz',
      data: {
        'shiftId': Session.shift!.id!,
        'state': preparedData,
        'faceRecImage64': result.faceRecImage64
      },
    );
    return resp;
  }
}
