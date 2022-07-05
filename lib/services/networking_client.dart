import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/auth_module/auth_service.dart';
import 'package:bazz_flutter/routes/app_pages.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/shared_widgets/loader.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/route_manager.dart';

import 'data_connection_checker.dart';

class NetworkingClient {
  static NetworkingClient? _instance;
  static bool skipErrorDisplay = true;
  Dio? _dio;
  final String? _apiUrl;

  factory NetworkingClient() => _instance!;

  NetworkingClient.init(this._apiUrl) {
    _dio = Dio(BaseOptions(
      baseUrl: _apiUrl!,
      connectTimeout: 1000 * AppSettings().sendRestRequestTimeout,
      receiveTimeout: 1000 * AppSettings().sendRestRequestTimeout,
      headers: {
        'Accept': 'application/json',
      },
    ));

    if (Session.authToken != null) setBearerToken(Session.authToken!);

    if (!kReleaseMode) {
      _dio!.interceptors
          .add(LogInterceptor(responseBody: true, requestBody: true));
    }
    _dio!.interceptors.add(InterceptorsWrapper(
      onRequest: (RequestOptions options) async {
        final contentLength = options.headers['Content-Length'];
        TelloLogger().i("Request Content Length ==> $contentLength");
      } as Function(RequestOptions, RequestInterceptorHandler),
      onResponse: (Response resp) async {
        if (resp.data == null) throw 'Response is null!';

        final contentLength = resp.headers['Content-Length'];
        final serverTimestamp = resp.data['serverTimestamp'] as int;
        final dateDiff =
            (serverTimestamp - DateTime.now().millisecondsSinceEpoch / 1000)
                .abs();
        final isTimeWrong = dateDiff > AppSettings().sendRestRequestTimeout;
        TelloError? serverError;

        TelloLogger().i("Response Content Length ==> $contentLength");

        if (resp.data is Map && resp.data['status']['code'] as int > 0) {
          serverError = TelloError.fromMap(resp.data as Map<String, dynamic>);
        }

        TelloLogger().w(
            "InterceptorsWrapper: ERROR CODE: ${serverError!.code} MESSAGE: ${serverError.message}");
        //in case of the auth problems:
        if (serverError.code == 3 || serverError.code == 4) {
          try {
            await AuthService.to.logOut(locally: true);
          } catch (e, s) {
            TelloLogger().e('Error while fetching settings on logout: $e',
                stackTrace: s);
          }
        }
        throw serverError;

        if (isTimeWrong && Get.currentRoute.isNotEmpty) {
          TelloLogger().i("Wrong time error!");
          final wrongTimeError = WrongTimeError();
          if (Loader.isVisible) Loader.hide();
          if (Get.currentRoute == AppRoutes.home) {
            TelloLogger().i("Logging out because of wrong time error");
            await AuthService.throwToLogin(wrongTimeError.message);
          }
          throw wrongTimeError;
        }

        // return resp.data;
      } as Function(Response, ResponseInterceptorHandler),
    ));

    _instance = this;
  }

  void setBearerVersion() {
    // _dio.options.headers['X-Client-Version'] = '1.1.2-66'; // For testing purposes
    _dio!.options.headers['X-Client-Version'] = AppSettings().appVersion;
  }

  void setBearerToken(String token) {
    _dio!.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, Object>? queryParameters,
  }) async {
    final isConnected = await checkConnectivity();
    if (!isConnected) throw checkConnectivity().toString();
    return _dio!.get(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(
    String path, {
    Map<String, Object>? data,
    Map<String, Object>? queryParameters,
    RequestOptions? options,
  }) async {
    final isConnected = await checkConnectivity();
    if (!isConnected) throw checkConnectivity().toString();
    return _dio!.post<T>(path, data: data ?? {}, options: options as Options);
  }

  Future<bool> checkConnectivity() async {
    final bool isConnected =
        await DataConnectionChecker().isConnectedToInternet;
    if (!isConnected) {
      /*if (Get.isSnackbarOpen) {
        Get.back();
      }
      Get.showSnackbarEx(GetBar(
        backgroundColor: AppColors.error,
        message: DataConnectionChecker().toString(),
        titleText: Text(LocalizationService().localizationContext().systemInfo, style: AppTypography.captionTextStyle),
        icon: const Icon(
          Icons.warning_amber_rounded,
          color: AppColors.brightIcon,
        ),
      ));*/
      return false;
    } else {
      return true;
    }
  }
}

class NetworkingClient2 {
  static NetworkingClient2? _instance;

  Dio? _dio;
  final String _apiUrl;

  factory NetworkingClient2() => _instance!;

  NetworkingClient2.init(this._apiUrl) {
    _dio = Dio(BaseOptions(
      baseUrl: _apiUrl,
      connectTimeout: 1000 * AppSettings().sendRestRequestTimeout,
      receiveTimeout: 1000 * AppSettings().sendRestRequestTimeout,
      headers: {
        'Accept': 'application/json',
      },
    ));

    if (Session.authToken != null) setBearerToken(Session.authToken!);

    _dio!.interceptors.add(InterceptorsWrapper(
      onResponse: (Response resp) async {
        if (resp.data == null) throw 'Response is null!';

        final serverTimestamp = resp.data['serverTimestamp'];
        final dateDiff =
            (serverTimestamp - DateTime.now().millisecondsSinceEpoch / 1000)
                .abs();
        final isTimeWrong = dateDiff > AppSettings().sendRestRequestTimeout;

        if (isTimeWrong && Get.currentRoute == AppRoutes.domain) {
          TelloLogger().e("Wrong time error!");
          throw WrongTimeError();
        }

        return resp.data;
      } as Function(Response, ResponseInterceptorHandler),
    ));

    _instance = this;
  }

  void setBearerToken(String token) {
    _dio!.options.headers['Authorization'] = 'Bearer $token';
  }

  void setBearerVersion() {
    _dio!.options.headers['X-Client-Version'] = AppSettings().appVersion;
  }

  Future<Response<T>> get<T>(
    String path, {
    Map<String, Object>? queryParameters,
  }) {
    return _dio!.get(path, queryParameters: queryParameters);
  }

  Future<Response<T>> post<T>(
    String path, {
    Map<String, Object>? data,
    Map<String, Object>? queryParameters,
  }) {
    return _dio!.post<T>(path, data: data ?? {});
  }
}

class TelloError implements Exception {
  final int code;
  final String message;
  final List<String>? supportedVersions;
  final int serverTimeStamp;
  final String clientVersion;
  bool skipErrorDisplay = false;

  TelloError.fromMap(Map<String, dynamic> map)
      : code = map['status']['code'] as int,
        message = map['status']['message'] as String,
        serverTimeStamp = map['serverTimestamp'] as int,
        supportedVersions = map["supportedVersions"] != null
            ? (map["supportedVersions"] as List<dynamic>)
                .map((x) => x as String)
                .toList()
            : null,
        clientVersion =
            map["clientVersion"] != null ? map['clientVersion'] : null;

  @override
  String toString() {
    return message;
  }
}

class WrongTimeError {
  final message = " AppLocalizations.of(Get.context).incorrectSystemTime";
}
