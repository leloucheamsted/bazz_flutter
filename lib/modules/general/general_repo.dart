import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/networking_client.dart';

class GeneralRepository {
  Future<Map<String, dynamic>> fetchSettings(String simSerial) async {
    // Logger().log('GeneralRepository fetchSettings() started...');
    final resp = await NetworkingClient2().post<Map<String, dynamic>>(
      '/General/Setting',
      data: {
        'simSerialNumber': simSerial,
      },
    );
    // Logger().log('GeneralRepository fetchSettings() completed');
    return resp.data!;
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    final resp = await NetworkingClient2()
        .post<Map<String, dynamic>>('/User/GetUserInfo');
    return resp.data!;
  }
}
