import 'dart:io';

import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/signed_url_response.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/networking_client.dart';
import 'package:dio/dio.dart';

class ChatRepository {
  Future<SignedUrlResponse> getSignedUrl(String fileName) async {
    TelloLogger().i('ChatRepository getSignedUrl...');
    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/Storage/GetSignedUrl',
      data: {
        'fileName': fileName,
        'fileType': 2,
      },
    );
    return resp.data != null ? SignedUrlResponse.fromMap(resp.data!) : null!;
  }

  Future<void> uploadFile(
    String signedUrl,
    String mimeType,
    File file,
    Function(int, int) progressCallback,
    CancelToken cancelToken,
  ) async {
    TelloLogger().i('ChatRepository uploadAudioFile...');

    final resp = await Dio().put<dynamic>(
      signedUrl,
      data: file.openRead(),
      options: Options(
          sendTimeout: 1000 * AppSettings().sendRestRequestTimeout,
          receiveTimeout: 1000 * AppSettings().sendRestRequestTimeout,
          contentType: mimeType,
          headers: {
            Headers.contentLengthHeader: file.lengthSync(),
          }),
      onSendProgress: progressCallback,
      cancelToken: cancelToken,
    );
    return;
  }
}
