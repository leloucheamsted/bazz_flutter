import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/shift_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/services/session_service.dart';

import 'device_model.dart';

//TODO: refactor to Prefs, and manipulate local storage directly, with separate keys
class Session {
  static Session _instance = Session._internal();
  static String? authToken;
  static RxUser? user;
  static Shift? shift;
  static Device? device;
  static int? groupCount;
  static AuthenticationType? authenticationMethod;
  factory Session() => _instance;

  Session._internal() {
    _instance = this;
  }

  factory Session.create(String token, RxUser usr, Shift shf, Device de,
      int grCount, AuthenticationType method) {
    authToken = token; // ignore: prefer_initializing_formals
    user = usr; // ignore: prefer_initializing_formals
    shift = shf; // ignore: prefer_initializing_formals
    device = de; // ignore: prefer_initializing_formals
    groupCount = grCount;
    authenticationMethod = method; // ignore: prefer_initializing_formals
    return _instance;
  }

  factory Session.fromMap(Map<String, dynamic> m) {
    authToken = m['authToken'] as String;
    user = m['user'] != null
        ? RxUser.fromMap(m['user'] as Map<String, dynamic>)
        : null;
    shift = m['shift'] != null
        ? Shift.fromMap(m['shift'] as Map<String, dynamic>)
        : null;
    device = m['device'] != null
        ? Device.fromMap(m['device'] as Map<String, dynamic>)
        : null;
    groupCount = m['groupCount'] != null ? m['groupCount'] as int : 0;
    authenticationMethod = m['authenticationMethod'] != null
        ? AuthenticationType.values[m['authenticationMethod'] as int]
        : AuthenticationType.Password;
    return _instance;
  }

  static bool get hasAuthToken => authToken != null;

  static bool get hasNoToken => authToken == null;

  static bool get hasShift => shift != null;

  static bool? get hasShiftStarted => hasShift && shift!.hasStarted;

  static bool get isSupervisor => user?.role.id == 'Supervisor';

  static bool get isNotSupervisor => !isSupervisor;

  static bool get isManager => user?.role.id == 'Manager';

  static bool get isNotManager => !isManager;

  static bool get isGuard => user?.role.id == 'Guard';

  static bool get isNotGuard => !isGuard;

  static bool get isCustomer => user?.role.id == 'Customer';

  static bool get isNotCustomer => !isCustomer;

  static Future<void> updateAndStoreSession(
      {required String authToken,
      required RxUser user,
      required Shift shift,
      required Device device,
      bool storeSession = false,
      required int groupCount,
      AuthenticationType authenticationMethod =
          AuthenticationType.Password}) async {
    Session.create(
        authToken, user, shift, device, groupCount, authenticationMethod);
    if (storeSession) {
      return SessionService.storeSession();
    }
    return;
  }

  static Future<void> storeCurrentSession() {
    return SessionService.storeSession();
  }

  static Map<String, Object> toMap() {
    return {
      'authToken': authToken!,
      'user': user!.toMap(),
      'shift': shift!.toMap(),
      'device': device!.toMap(),
    };
  }

  static Future<void> wipeSession() {
    authToken = null;
    user = null;
    shift = null;
    device = null;
    return SessionService.deleteSession();
  }
}
