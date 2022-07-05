import 'package:bazz_flutter/services/networking_client.dart';

class SosRepository {
  Future<void> createSos(Map<String, dynamic>? data) async {
    await NetworkingClient().post<Map<String, dynamic>>(
      '/Event/CreateSos',
      data: data as Map<String, Object>,
    );
  }
}
