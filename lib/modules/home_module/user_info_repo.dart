import 'package:bazz_flutter/services/networking_client.dart';

class UserInfoRepository {
  Future<Map<String, dynamic>> getAdminList() async {
    final resp = await NetworkingClient()
        .post<Map<String, dynamic>>('/User/GetAdminList');
    return resp.data!;
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    final resp = await NetworkingClient()
        .post<Map<String, dynamic>>('/User/GetUserInfo');
    return resp.data!;
  }
}
