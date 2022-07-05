import 'package:bazz_flutter/services/networking_client.dart';
import 'package:dio/dio.dart';

class ShiftActivitiesStatsRepository {
  Future<Response<Map<String, dynamic>>> fetchStatsForPosition(String positionId) async {
    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/Shift/GetTourStats',
      data: {
        'positionId': positionId,
      },
    );
    return resp;
  }
}
