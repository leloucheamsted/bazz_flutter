import 'package:flutter/cupertino.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';

class Media {
  final String id = Uuid().v4();
  final String path, thumbPath;

  bool get isVideo => path.isVideoFileName;

  bool get isImage => path.isImageFileName;

  Media({required this.path, required this.thumbPath});

  Media copyWith({
    String? path,
    String? thumbPath,
  }) {
    return Media(
      path: path ?? this.path,
      thumbPath: thumbPath ?? this.thumbPath,
    );
  }
}
