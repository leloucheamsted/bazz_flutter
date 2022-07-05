import 'dart:async';
import 'dart:io';

import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/coordinates_model.dart';
import 'package:bazz_flutter/models/device_state.dart';
import 'package:bazz_flutter/models/local_audio_message.dart';
import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/user_location_model.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/location_tracking/location_service.dart';
import 'package:bazz_flutter/modules/message_history/message_upload_service.dart';
import 'package:bazz_flutter/modules/settings_module/settings_controller.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/rtc_service.dart';
import 'package:bazz_flutter/services/statistics_service.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:flutter_webrtc/webrtc.dart';
// import 'package:flutter_webrtc/flutter_webrtc.dart';
// import 'package:flutter_webrtc/enums.dart';
// import 'package:flutter_webrtc/media_recorder.dart';
import 'package:geolocator/geolocator.dart';
import 'package:media_info/media_info.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';

/// Used for transmissions recording. The instance of this class is created only once in RTCService.init()
class TransmissionRecording {
  late String? tempDir;
  File? recordingFile;
  MediaRecorder? _mediaRecorder;
  Completer? prevRecordingComplete;
  final record = Record();

  /// Sample rate used for Streams
  TransmissionRecording({this.tempDir});

  /// Make sure you await for stop() before calling start(), since common resources are used for the recording
  Future<void> start(
      {required Stopwatch stopwatch, bool isOffline = false}) async {
    recordingFile = File('$tempDir/rec-${Uuid().v1()}.m4a');
    try {
      TelloLogger().i(
          "Transmission start(): starting recording to file path -> ${recordingFile!.path}");
      if (isOffline) {
        AudioEncoder encoder = AudioEncoder.aacEld;

        if (Platform.isAndroid) {
          if (SettingsController.to!.osSDKInt < 29) {
            encoder = AudioEncoder.aacLc;
          }
        }

        await record.start(
            path: recordingFile!.path, // required
            bitRate: 1024 * 8,
            samplingRate: 8000,
            encoder: encoder);
      } else {
        _mediaRecorder = MediaRecorder();
        await _mediaRecorder!.start(recordingFile!.path,
            audioChannel: RecorderAudioChannel.INPUT);
      }
      RTCService().prevRecordingComplete = Completer();
    } catch (e, s) {
      TelloLogger().e("Transmission start(): FAILED _mediaRecorder Reason $e",
          stackTrace: s);
    }
  }

  /// Make sure you await for stop() before calling start(), since common resources are used for the recording
  Future<void> stop(LocalAudioMessage message, {bool isOffline = false}) async {
    TelloLogger()
        .i("Transmission stop(): stopping recording  ${recordingFile!.path}");
    try {
      if (isOffline) {
        await record.stop();
        //TODO: should work without it, remove if no problems with offline recording found
        // await Record.close();
      } else {
        await _mediaRecorder!.stop();
      }
      TelloLogger().i("Transmission stop(): recording stopped");

      final targetFile = File(recordingFile!.path);
      final targetFileSize = await targetFile.length();

      if (message == null || !targetFile.existsSync() || targetFileSize == 0)
        return;

      final mediaInfo = await MediaInfo().getMediaInfo(recordingFile!.path);
      final duration = mediaInfo['durationMs'] as int;

      TelloLogger().i("Transmission stop(): recording duration: $duration");

      if (duration < AppSettings().audioMessageRetainThresholdMs) {
        return targetFile.deleteSync();
      }

      final Position position = LocationService().lastKnownPosition;
      final updatedDeviceState = await DeviceState.createDeviceState();
      final UserLocation? userLocation = position != null
          ? UserLocation(
              coordinates: Coordinates.fromPosition(position),
              updatedAt: dateTimeToSeconds(message.createdAt),
            )
          : null;
      final owner = Session.user!
        ..location(userLocation)
        ..deviceCard.deviceState(updatedDeviceState)
        ..isOnline(HomeController.to.isOnline);

      PositionInfoCard? ownerPosition;

      if (Session.hasShiftStarted!) {
        for (final group in HomeController.to.groups) {
          final myPosition = group.members.positions.firstWhere(
            (pos) => pos.id == Session.shift!.positionId,
            orElse: () => null as RxPosition,
          );

          if (myPosition != null) {
            ownerPosition = PositionInfoCard.fromPosition(myPosition);
            break;
          }
        }
      }

      StatisticsService().totalPTTRecordingSent += targetFileSize;
      TelloLogger().i("Transmission stop(): fileSize ==> $targetFileSize");
      message
        ..mimeType = mediaInfo['mimeType'] as String
        ..owner = owner
        ..ownerPosition = ownerPosition!
        ..filePath = recordingFile!.path
        ..fileDurationMs = duration
        ..createdAtTimestamp = dateTimeToSeconds(message.createdAt)
        ..groupId = HomeController.to.activeGroup.id!;

      MessageUploadService.to.addAndProcess(message);
    } catch (e, s) {
      TelloLogger().e('Transmission stop(): error while stopping recording: $e',
          stackTrace: s);
    } finally {
      RTCService().prevRecordingComplete.complete();
    }
  }
}
