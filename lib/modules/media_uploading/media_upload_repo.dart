import 'dart:io';

import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/signed_url_response.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/networking_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';
import 'package:flutter/material.dart';

typedef OnSendProgress = void Function(int count, int total);

class MediaUploadRepository {
  Future<SignedUrlResponse?> getSignedUrl(String fileName,
      {bool withLongLife = false}) async {
    TelloLogger().i('MediaUploadRepo getting signed url...');
    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/Storage/GetSignedUrl',
      data: {
        'fileName': fileName,
        //TODO: set fileType dynamically
        'fileType': 3,
        'withLongLife': withLongLife,
      },
    );
    return resp.data != null ? SignedUrlResponse.fromMap(resp.data!) : null;
  }

  Future<void> uploadFile({
    required String signedUrl,
    required File file,
    required String mimeType,
    required OnSendProgress onSendProgress,
    required CancelToken cancelToken,
  }) async {
    TelloLogger().i('MediaUploadRepo uploading started...');
    final resp = await Dio().put<dynamic>(
      signedUrl,
      cancelToken: cancelToken,
      onSendProgress: onSendProgress,
      data: file.openRead(),
      options: Options(
          sendTimeout: 1000 * AppSettings().sendRestRequestTimeout,
          receiveTimeout: 1000 * AppSettings().sendRestRequestTimeout,
          contentType: mimeType,
          headers: {
            Headers.contentLengthHeader: file.lengthSync(),
          }),
    );
    return;
  }
}
