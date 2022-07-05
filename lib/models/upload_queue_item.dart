import 'local_audio_message.dart';

class UploadQueueItem {
  String? localFilePath;
  LocalAudioMessage? message;

  UploadQueueItem({this.localFilePath, this.message});
}
