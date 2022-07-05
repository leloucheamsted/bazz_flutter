import 'package:bazz_flutter/services/networking_client.dart';
import 'package:dio/dio.dart';

class ChangePasswordRepository {
  Future<Response<Map<String, dynamic>>> updatePassword(String newPassword) async {
    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/User/Update',
      data: {
        'password': newPassword,
      },
    );
    return resp;
  }
}