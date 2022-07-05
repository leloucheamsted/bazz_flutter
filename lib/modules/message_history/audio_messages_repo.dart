import 'dart:io';

import 'package:bazz_flutter/models/audio_locations_model.dart';
import 'package:bazz_flutter/models/audio_message.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/local_audio_message.dart';
import 'package:bazz_flutter/models/signed_url_response.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/networking_client.dart';
import 'package:dio/dio.dart';

class AudioMessagesRepository {
  Future<List<AudioMessage>> fetchAudioMessages(String groupId) async {
    TelloLogger().i('AudioMessagesRepository fetchAudioMessages...');
    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/AudioMessage/GetAudioMessages',
      data: {
        'groupId': groupId,
        'timeRangeInSeconds': AppSettings().audioMessageLifePeriodSec
      },
    );
    final audioMessages = resp.data!['messages'] != null
        ? List<AudioMessage>.from((resp.data!['messages'] as List<dynamic>)
            .map((x) => AudioMessage.fromNestedMap(x as Map<String, dynamic>)))
        : null;
    return audioMessages!;
  }

  Future<AudioLocations?> getAudioLocations(String messageId) async {
    TelloLogger().i('AudioMessagesRepository getAudioLocations... $messageId');
    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/AudioMessage/GetAudioLocations',
      data: {
        'messageId': messageId,
      },
    );
    //FIXME: map['audioLocations'] can't be null
    return resp.data != null ? AudioLocations.fromMap(resp.data!) : null;
  }

  Future<SignedUrlResponse?> getSignedUrl(String fileName) async {
    TelloLogger().i('AudioMessagesRepository getSignedUrl...');
    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/Storage/GetSignedUrl',
      data: {
        'fileName': fileName,
        'fileType': 1,
      },
    );
    return resp.data != null ? SignedUrlResponse.fromMap(resp.data!) : null;
  }

  Future<void> uploadAudioFile(String signedUrl, File audioFile) async {
    TelloLogger().i('AudioMessagesRepository uploadAudioFile...');
    final resp = await Dio().put<dynamic>(
      signedUrl,
      data: audioFile.openRead(),
      options: Options(
          sendTimeout: 1000 * AppSettings().sendRestRequestTimeout,
          receiveTimeout: 1000 * AppSettings().sendRestRequestTimeout,
          contentType: 'audio/mp4',
          headers: {
            Headers.contentLengthHeader: audioFile.lengthSync(),
          }),
    );
    return;
  }

  Future<void> uploadMetadata(LocalAudioMessage audioMessage) async {
    final data = audioMessage.toMapForServer();
    TelloLogger().i('AudioMessagesRepository uploadMetadata... $data');
    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/AudioMessage/CreateByUrl',
      data: data as Map<String, Object>,
    );
    return;
  }

  Future<bool> markListened(String messageId) async {
    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/AudioMessage/SetListened',
      data: {
        "messageId": messageId,
      },
    );
    // ignore: avoid_bool_literals_in_conditional_expressions
    return resp.data != null ? resp.data!['isListened'] as bool : false;
  }
}
