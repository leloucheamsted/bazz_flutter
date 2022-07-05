import 'package:bazz_flutter/services/networking_client.dart';
import 'package:bazz_flutter/services/system_events_signaling.dart';

class AuthRepository {
  static final AuthRepository _singleton = AuthRepository._();

  factory AuthRepository() => _singleton;

  AuthRepository._();

  Future<Map<String, dynamic>> logIn(
      String login, String pwd, String simSerialNumber,
      {bool ignoreActiveSession = true, bool skipErrorDisplay = false}) async {
    NetworkingClient.skipErrorDisplay = skipErrorDisplay;

    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/Auth/Login',
      data: {
        'login': login,
        'password': pwd,
        'simSerialNumber': simSerialNumber,
        'ignoreActiveSession': ignoreActiveSession,
      },
    );
    NetworkingClient.skipErrorDisplay = false;
    return resp.data!;
  }

  Future<Map<String, dynamic>> logInNfc(String nfcToken, String simSerialNumber,
      {bool ignoreActiveSession = true, bool skipErrorDisplay = false}) async {
    NetworkingClient.skipErrorDisplay = skipErrorDisplay;

    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/Auth/NfcLogin',
      data: {
        'nfcAuthToken': nfcToken,
        'simSerialNumber': simSerialNumber,
        'ignoreActiveSession': ignoreActiveSession,
      },
    );
    NetworkingClient.skipErrorDisplay = false;
    return resp.data!;
  }

  Future<Map<String, dynamic>> faceLogin(
      String login, String simSerialNumber, String img64,
      {bool ignoreActiveSession = true, bool skipErrorDisplay = false}) async {
    NetworkingClient.skipErrorDisplay = skipErrorDisplay;
    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/Auth/FaceLogin',
      data: {
        'login': login,
        'simSerialNumber': simSerialNumber,
        'faceImageBase64': img64,
        'ignoreActiveSession': ignoreActiveSession,
      },
    );
    NetworkingClient.skipErrorDisplay = false;
    return resp.data!;
  }

  Future<void> logOut() async {
    SystemEventsSignaling().skipConnectionRecovery = true;
    try {
      await NetworkingClient().post<Map<String, dynamic>>('/Auth/Logout');
    } catch (err) {
      rethrow;
    } finally {
      SystemEventsSignaling().skipConnectionRecovery = false;
    }
  }
}
