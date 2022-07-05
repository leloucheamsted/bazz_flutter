import 'package:flutter/services.dart';
import 'package:soundpool/soundpool.dart';

import 'localization_service.dart';
import 'logger.dart';

class SoundPoolService {
  static final SoundPoolService _singleton = SoundPoolService._();

  factory SoundPoolService() => _singleton;
  late int startPlayTime;
  late int playDurationInMilliseconds = 1000;

  SoundPoolService._();

  late int _soundIdStart,
      _soundIdPttStart,
      _soundIdPttEnd,
      _soundIdMessageReceived,
      _soundIdOffline,
      _soundIdOnline;
  late int _startStreamId,
      _startPttStreamId,
      _endPttStreamId,
      _receivedMessageStreamId;
  late String radioChirpFilePath = 'assets/sounds/radio_chirp.wav';
  late String radioChirpEndFilePath = 'assets/sounds/radio_chirp_end.mp3';
  late String messageReceivedFilePath =
      'assets/sounds/message_notification.mp3';
  late String offlineNotificationFilePath =
      'assets/sounds/offline_notification.aac';
  late String onlineNotificationFilePath =
      'assets/sounds/online_notification.aac';
  late Soundpool _outOfRangeSoundPool,
      _startPttSoundPool,
      _endPttSoundPool,
      _messageReceivedSoundPool,
      _onlineOfflineSoundPool;

  Future<void> init() async {
    TelloLogger().i('SoundPoolService init');
    try {
      _outOfRangeSoundPool = Soundpool(streamType: StreamType.ring);
      final String languageCode = LocalizationService().getLanguageCode();
      final String soundOutOfRangeFilePath =
          'assets/sounds/out_of_range_$languageCode.mp3';
      _soundIdStart = await rootBundle
          .load(soundOutOfRangeFilePath)
          .then((ByteData soundData) {
        return _outOfRangeSoundPool.load(soundData);
      });

      _startPttSoundPool = Soundpool(streamType: StreamType.notification);
      _soundIdPttStart =
          await rootBundle.load(radioChirpFilePath).then((ByteData soundData) {
        return _startPttSoundPool.load(soundData);
      });

      _endPttSoundPool = Soundpool(streamType: StreamType.notification);
      _soundIdPttEnd = await rootBundle
          .load(radioChirpEndFilePath)
          .then((ByteData soundData) {
        return _endPttSoundPool.load(soundData);
      });

      _messageReceivedSoundPool =
          Soundpool(streamType: StreamType.notification);
      _soundIdMessageReceived = await rootBundle
          .load(messageReceivedFilePath)
          .then((ByteData soundData) {
        return _messageReceivedSoundPool.load(soundData);
      });

      _onlineOfflineSoundPool = Soundpool(streamType: StreamType.notification);
      _soundIdOffline = await rootBundle
          .load(offlineNotificationFilePath)
          .then((ByteData soundData) {
        return _onlineOfflineSoundPool.load(soundData);
      });
      _soundIdOnline = await rootBundle
          .load(onlineNotificationFilePath)
          .then((ByteData soundData) {
        return _onlineOfflineSoundPool.load(soundData);
      });
    } catch (e, s) {
      TelloLogger().e("sound pool errors $e", stackTrace: s);
    }
  }

  Future<void> playOfflineSound() async {
    await _onlineOfflineSoundPool.play(_soundIdOffline);
  }

  Future<void> playOnlineSound() async {
    await _onlineOfflineSoundPool.play(_soundIdOnline);
  }

  Future<void> playMessageReceivedSound() async {
    await stopMessageReceivedSound();
    _receivedMessageStreamId = await _messageReceivedSoundPool
        .play(_soundIdMessageReceived, repeat: 5);
  }

  Future<void> stopMessageReceivedSound() async {
    if (_receivedMessageStreamId != null) {
      await _messageReceivedSoundPool.stop(_receivedMessageStreamId);
    }
  }

  Future<void> playOutOfRangeSound() async {
    await stopOutOfRangeSound();
    TelloLogger().i(
        "LocalizationService().getLanguageCode() == ${LocalizationService().getLanguageCode()}");
    _startStreamId = await _outOfRangeSoundPool.play(_soundIdStart, repeat: 5);
  }

  Future<void> stopOutOfRangeSound() async {
    if (_startStreamId != null) {
      await _outOfRangeSoundPool.stop(_startStreamId);
    }
  }

  late int _startPlayTime;

  Future<void> playRadioChirpSound() async {
    TelloLogger().i('playing start chirp');
    await stopRadioChirpSound();
    _startPttStreamId = await _startPttSoundPool.play(_soundIdPttStart);
    _startPlayTime = DateTime.now().millisecondsSinceEpoch;
  }

  Future<void> stopRadioChirpSound() async {
    if (_startPttStreamId != null) {
      /*final int durationSincePlaying =
          DateTime.now().millisecondsSinceEpoch - _startPlayTime;
      if (durationSincePlaying < playDurationInMilliseconds) {
        await Future.delayed(Duration(milliseconds: playDurationInMilliseconds - durationSincePlaying));
      }*/
      await _startPttSoundPool.stop(_startPttStreamId);
    }
  }

  Future<void> playRadioChirpEndSound() async {
    TelloLogger().i('playing end chirp');
    await stopRadioChirpSound();
    _endPttStreamId = await _endPttSoundPool.play(_soundIdPttEnd);
  }

  Future<void> stopRadioChirpEndSound() async {
    TelloLogger().i('stop playing end chirp');
    if (_endPttStreamId != null) {
      await _endPttSoundPool.stop(_endPttStreamId);
    }
  }

  Future<void> close() async {
    _endPttSoundPool.release();
    _startPttSoundPool.release();
    _outOfRangeSoundPool.release();
    _messageReceivedSoundPool.release();
    _onlineOfflineSoundPool.release();
  }

  Future<void> dispose() async {
    _endPttSoundPool.dispose();
    _startPttSoundPool.dispose();
    _outOfRangeSoundPool.dispose();
    _messageReceivedSoundPool.dispose();
    _onlineOfflineSoundPool.dispose();

    _endPttSoundPool = null as Soundpool;
    _startPttSoundPool = null as Soundpool;
    _outOfRangeSoundPool = null as Soundpool;
    _messageReceivedSoundPool = null as Soundpool;
    _onlineOfflineSoundPool = null as Soundpool;
  }
}
