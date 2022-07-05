import 'dart:io';

import 'package:bazz_flutter/modules/chat/ui_kit/utils/enums.dart';
// import 'package:ext_storage/ext_storage.dart';
import 'package:external_path/external_path.dart';
class StoragePaths {
 late String pictures, movies, music, documents, downloads, dcim;

  static final StoragePaths _singleton = StoragePaths._();

  late factory StoragePaths() => _singleton;

  StoragePaths._();

  Future<void> init() async {
    final List<String> paths = await Future.wait<String>([
      ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_PICTURES),
      ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_MOVIES),
      ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_MUSIC),
      ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOCUMENTS),
      ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DOWNLOADS),
      ExternalPath.getExternalStoragePublicDirectory(ExternalPath.DIRECTORY_DCIM),
    ]);
    pictures = paths[0];
    movies = paths[1];
    music = paths[2];
    documents = paths[3];
    downloads = paths[4];
    dcim = paths[5];
  }

  String getDirectoryByMessageType(MessageBaseType messageType) {
   late String directory;

    switch (messageType) {
      case MessageBaseType.text:
        break;
      case MessageBaseType.image:
        directory = pictures;
        break;
      case MessageBaseType.audio:
        directory = music;
        break;
      case MessageBaseType.video:
        directory = movies;
        break;
      case MessageBaseType.pdf:
        directory = documents;
        break;
      case MessageBaseType.other:
        directory = documents;
        break;
    }

    return directory;
  }
}