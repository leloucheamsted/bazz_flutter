import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/networking_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';

class SyncRepo {
  Future<Response<Map<String, dynamic>>> openSync({
    required String syncPackageId,
    List<Map<String, dynamic>>? locations,
    List<Map<String, dynamic>>? deviceStates,
    List<Map<String, dynamic>>? alertCheckResults,
    List<Map<String, dynamic>>? reportingPoints,
    String? prevBrokenPackageId,
  }) async {
    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/Repository/SyncOpen',
      data: {
        'syncPackageId': syncPackageId,
        'prevBrokenPackageId': prevBrokenPackageId!,
        'ownerId': null as Object,
        'coordinateSnapshots': locations!,
        'quizPackage': alertCheckResults != null
            ? {
                // ignore: todo
                //TODO: handle the offline shift change case, in this case we can't send current Session.shift.id
                'shiftId': Session.shift!.id,
                'states': alertCheckResults,
              }
            : null!,
        'reportingPointPackage': reportingPoints!.isNotEmpty
            ? {
                //TODO: handle the offline shift change case, in this case we can't send current Session.shift.id
                'shiftId': Session.shift!.id,
                'reportingPointStates': reportingPoints,
              }
            : null!,
        'deviceInfos': deviceStates as Object,
      },
    );
    return resp;
  }

  Future<Response<Map<String, dynamic>>> closeSync(String syncPackageId) async {
    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/Repository/SyncClose',
      data: {
        'syncPackageId': syncPackageId,
      },
    );
    return resp;
  }

  Future<Response<Map<String, dynamic>>> dumpLogs(
    String url,
    String appName,
    String appVersion,
    List<RemoteLog> logs, {
    String? userId,
    String? shiftId,
    String? positionId,
    String? deviceId,
    String? systemShiftId,
  }) async {
    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      url,
      data: {
        'app': {
          'name': appName,
          'version': appVersion,
        },
        'details': {
          'userId': userId,
          'shiftId': shiftId,
          'positionId': positionId,
          'deviceId': deviceId,
          'systemShiftId': systemShiftId,
        },
        'messages': logs.map((l) => l.toMap()).toList(),
      },
    );
    return resp;
  }
}
