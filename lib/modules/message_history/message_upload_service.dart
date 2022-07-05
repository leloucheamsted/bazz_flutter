import 'dart:async';
import 'dart:io';

import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/local_audio_message.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/message_history/audio_messages_repo.dart';
import 'package:bazz_flutter/modules/synchronization/sync_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:mutex/mutex.dart';
import 'package:path/path.dart' as p;

class MessageUploadService extends GetxController {
  static MessageUploadService get to => Get.find();

  final AudioMessagesRepository _repo = AudioMessagesRepository();

  final _mutex = Mutex();

  GetStorage? messagesUploadQueue;
  bool _processingQueue = false;

  Completer syncMessagesCompleted = Completer();

  // ANOTHER WAY OF HANDLING SYNC FUTURES - REMOVE IT LATER, if the current scheme works well.
  // ///We use RxDart here instead of 0.obs, because we plan to add errors to this stream,
  // ///and get: 3.26.0 has a bug on this, which later was fixed.
  // final _messagesLeft$ = BehaviorSubject<int>.seeded(0);
  //
  // int get messagesLeft => _messagesLeft$.stream.value;
  //
  // // ValueStream<int> get messagesLeftStream => _messagesLeft$.stream;
  //
  // set messagesLeft(int val) => _messagesLeft$.add(val);
  //
  // Stream<bool> hasData$;
  //
  // Stream<int> _messagesLeftBroadcast;
  //
  // Future<bool> get syncMessagesCompleted => _messagesLeft$.any((messagesLeft) => messagesLeft == 0);

  final RxInt _messagesLeft$ = 0.obs;

  int get messagesLeft$ => _messagesLeft$();

  set messagesLeft$(int val) => _messagesLeft$(val);

  bool get hasData$ => messagesLeft$ > 0;

  // ANOTHER WAY OF HANDLING SYNC FUTURES - REMOVE IT LATER, if the current scheme works well.
  // Stream<int> _messagesLeftBroadcast;

  // Future<bool> get syncMessagesCompleted => _messagesLeftBroadcast.any((messagesLeft) {
  //   print('_messagesLeftBroadcast messagesLeft: $messagesLeft');
  //   return messagesLeft == 0;
  // });

  bool _closing = false;

  // StreamSubscription _connectivitySub;
  StreamSubscription? _isOnlineSub;

  String? uploadFailedMsgKey;
  int uploadFailedCount = 0;

  @override
  Future<void> onInit() async {
    //TODO: moved it to main.dart, remove if it works well there
    // await GetStorage.init('MessageUploadQueue');
    messagesUploadQueue = GetStorage(StorageKeys.messageUploadQueueBox);
    messagesLeft$ = messagesUploadQueue!.getKeys<Iterable<String>>().length;
    if (messagesLeft$ == 0) syncMessagesCompleted.complete();
    // ANOTHER WAY OF HANDLING SYNC FUTURES - REMOVE IT LATER, if the current scheme works well.
    // _messagesLeftBroadcast = _messagesLeft$.stream.asBroadcastStream();
    _isOnlineSub = HomeController.to.isOnline$.listen((online) {
      if (online) return;

      _mutex.protect(() {
        uploadFailedCount = 0;
        uploadFailedMsgKey = null;
        return null!;
      });
    });
    super.onInit();
  }

  @override
  void onClose() {
    _closing = true;
    _isOnlineSub!.cancel();
    // _connectivitySub?.cancel();
    super.onClose();
  }

  Future<void> addAndProcess(LocalAudioMessage msg) async {
    try {
      await messagesUploadQueue!.write(msg.txId, msg.toMap());
      messagesLeft$++;
      processQueue();
    } catch (e, s) {
      TelloLogger().e('Failed writing audio message: $e', stackTrace: s);
    }
  }

  Future<void> processQueue({bool anyway = false}) async {
    if (_closing ||
        !HomeController.to.isOnline ||
        (!anyway && _processingQueue)) return;
    _processingQueue = true;

    final keys = messagesUploadQueue!.getKeys<Iterable<String>>();

    TelloLogger().i(
        'MessageUploadService: messagesLeft => ${messagesLeft$}, keys.length => ${keys.length}');
    messagesLeft$ = keys.length;

    if (keys.isEmpty) {
      TelloLogger().i('MessageUploadService: no tracks to load!');
      if (!syncMessagesCompleted.isCompleted) syncMessagesCompleted.complete();
      _processingQueue = false;
      return;
    }

    TelloLogger().i(
        'MessageUploadService: processing queue... ${messagesLeft$} tracks pending');
    if (syncMessagesCompleted.isCompleted)
      syncMessagesCompleted = Completer<bool>();
    final msgKey = keys.first;
    final messageMap = messagesUploadQueue!.read<Map<String, dynamic>>(msgKey);
    final message =
        messageMap != null ? LocalAudioMessage.fromMap(messageMap) : null;
    final localFile = message != null ? File(message.filePath) : null;

    if (localFile?.existsSync() != true) {
      TelloLogger().i(
          'MessageUploadService: cannot form LocalAudioMessage from the $msgKey, deleting it...');
      messagesUploadQueue!.remove(msgKey);
      messagesLeft$--;
      if (messagesLeft$ == 0) {
        syncMessagesCompleted.complete();
        _processingQueue = false;
        return;
      }
      processQueue(anyway: true);
    }

    try {
      if (SyncService.to.hasOtherData$) throw WaitOtherDataSyncCompleted();

      final signedUrlResponse =
          await _repo.getSignedUrl(p.basename(message!.filePath));
      TelloLogger().i(
          "MessageUploadService -> Get SignedUrl## ${signedUrlResponse!.signedUrl}");
      if (signedUrlResponse == null) throw 'signedUrlResponse is null!';

      await _repo.uploadAudioFile(signedUrlResponse.signedUrl, localFile!);

      TelloLogger().i(
          "uploadAudioFile -> Get signedUrlResponse.publicUrl## ${signedUrlResponse.publicUrl} localFile = $localFile");
      TelloLogger().i("_processQueue");
      TelloLogger().i("${message.toMap()}", isWrapped: true);

      await _repo
          .uploadMetadata(message..fileUrl = signedUrlResponse.publicUrl);

      messagesUploadQueue!.remove(msgKey);
      await localFile.delete();
      uploadFailedCount = 0;
      uploadFailedMsgKey = null;
      messagesLeft$--;

      TelloLogger().i(
          'MessageUploadService: ${message.txId} audio message uploaded and deleted! Messages left: ${messagesLeft$}');

      if (messagesLeft$ == 0) {
        syncMessagesCompleted.complete();
      } else {
        processQueue(anyway: true);
      }
    } catch (e, s) {
      if (e is WaitOtherDataSyncCompleted) {
        TelloLogger().i(e);
      } else {
        TelloLogger().i(
          'MessageUploadService: error while uploading audio message: $e',
          stackTrace: s,
        );

        _mutex.protect(() async {
          uploadFailedMsgKey ??= msgKey;
          if (msgKey == uploadFailedMsgKey) {
            uploadFailedCount++;
          }
          if (uploadFailedCount >= 3) {
            TelloLogger().i(
                'MessageUploadService: reached error threshold for uploadFailedMsgKey: $e');
            messagesUploadQueue!.remove(msgKey);
            messagesLeft$--;
            await localFile!.delete();
            uploadFailedCount = 0;
            uploadFailedMsgKey = null;
          }
        });

        if (!syncMessagesCompleted.isCompleted) {
          syncMessagesCompleted.completeError(
              'MessageUploadService: error while uploading audio message: $e');
          // ANOTHER WAY OF HANDLING SYNC FUTURES - REMOVE IT LATER, if the current scheme works well.
          // _messagesLeft$.addError('error while uploading audio message: $e');
        }
      }
    } finally {
      _processingQueue = false;
    }
  }
}

class WaitOtherDataSyncCompleted {
  String message = 'Other data is not synchronized yet!';
}
