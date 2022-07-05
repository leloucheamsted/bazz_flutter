import 'dart:convert';

import 'package:bazz_flutter/modules/media_uploading/media_upload_service.dart';
import 'package:flutter/cupertino.dart';

class ShiftActivityResult {
  final String taskId;
  String? comment;
  bool? isOk;
  List<String>? imageUrls, videoUrls;
  List<UploadableMedia>? deferredUploadMedia;

  bool get hasDeferredUploadMedia => deferredUploadMedia!.isNotEmpty;

  ShiftActivityResult({
    required this.taskId,
    this.comment,
    this.isOk,
    this.imageUrls,
    this.videoUrls,
    this.deferredUploadMedia,
  });

  factory ShiftActivityResult.fromMap(Map<String, dynamic> map,
      {bool listFromJson = false}) {
    return ShiftActivityResult(
      taskId: map['activityId'] as String,
      comment: map['comment'] as String,
      isOk: map['isOk'] as bool,
      imageUrls: map['imageUrls'] != null
          ? List<String>.from(listFromJson
              ? json.decode(map['imageUrls'] as String) as List<dynamic>
              : map['imageUrls'] as List<dynamic>)
          : null,
      videoUrls: map['videoUrls'] != null
          ? List<String>.from(listFromJson
              ? json.decode(map['videoUrls'] as String) as List<dynamic>
              : map['videoUrls'] as List<dynamic>)
          : null,
      deferredUploadMedia: map['deferredUploadMedia'] != null
          ? (json.decode(map['deferredUploadMedia'] as String) as List<dynamic>)
              .map((m) => UploadableMedia.fromMap(m as Map<String, dynamic>))
              .toList()
          : null,
    );
  }

  void clearDeferredUploadMedia() {
    deferredUploadMedia?.clear();
  }

  void addMediaUrl(UploadableMedia m) {
    if (m.isImage) {
      final listOfUrls = imageUrls ?? [];
      listOfUrls.add(m.publicUrl);
      imageUrls = listOfUrls;
    } else {
      final listOfUrls = videoUrls ?? [];
      listOfUrls.add(m.publicUrl);
      videoUrls = listOfUrls;
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'activityId': taskId,
      'comment': comment,
      'isOk': isOk,
      'imageUrls': imageUrls != null ? json.encode(imageUrls) : null,
      'videoUrls': videoUrls != null ? json.encode(videoUrls) : null,
      'deferredUploadMedia': deferredUploadMedia != null
          ? json.encode(deferredUploadMedia!.map((m) => m.toMap()).toList())
          : null,
    };
  }

  Map<String, dynamic> toMapForServer() {
    return {
      'activityId': taskId,
      'comment': comment,
      'imageUrls': imageUrls,
      'videoUrls': videoUrls,
      'isOk': isOk,
    };
  }

  ShiftActivityResult copyWith({
    String? taskId,
    String? comment,
    bool? isOk,
    List<String>? imageUrls,
    List<String>? videoUrls,
    List<UploadableMedia>? deferredUploadMedia,
  }) {
    return ShiftActivityResult(
      taskId: taskId ?? this.taskId,
      comment: comment ?? this.comment,
      isOk: isOk ?? this.isOk,
      imageUrls:
          imageUrls ?? (this.imageUrls != null ? [...?this.imageUrls] : null),
      videoUrls:
          videoUrls ?? (this.videoUrls != null ? [...?this.videoUrls] : null),
      deferredUploadMedia: deferredUploadMedia ??
          this.deferredUploadMedia?.map((e) => e.copy()).toList(),
    );
  }
}
