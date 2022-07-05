import 'package:bazz_flutter/services/networking_client.dart';
import 'package:dio/dio.dart';

class LocationRepository {
  Future<Response<Map<String, dynamic>>> sendLocations(List<Map<String, dynamic>> locations) async {
    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/User/UpdateCoordinates',
      data: {
        'coordinateSnapshots': locations,
      },
    );
    return resp;
  }
}
