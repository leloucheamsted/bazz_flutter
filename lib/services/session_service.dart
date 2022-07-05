import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:get_storage/get_storage.dart';

class SessionService {
  static Future<void> storeSession() {
    return GetStorage().write(StorageKeys.currentSession, Session.toMap());
  }

  static Session? restoreSession() {
    final data =
        GetStorage().read<Map<String, dynamic>>(StorageKeys.currentSession);
    return data != null ? Session.fromMap(data) : null;
  }

  static Future<void> deleteSession() {
    final generalBox = GetStorage();
    //TODO: don't .erase() them here, we should clean the queue in the MessageUploadService and SyncService,
    // and if we didn't manage to upload data because the shift has ended, the next user should complete the sync
    GetStorage(StorageKeys.messageUploadQueueBox).erase();
    GetStorage(StorageKeys.rPointVisitsUploadQueueBox).erase();
    GetStorage(StorageKeys.offlineEventsBox).erase();
    GetStorage(StorageKeys.readOfflineChatMessagesBox).erase();

    generalBox
      ..remove(StorageKeys.periodicShiftTimestamp)
      ..remove(StorageKeys.notifications)
      ..remove(StorageKeys.groups)
      ..remove(StorageKeys.activeGroup)
      ..remove(StorageKeys.adminUsers);
    return generalBox.remove(StorageKeys.currentSession);
  }
}
