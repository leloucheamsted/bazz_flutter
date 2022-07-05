import 'dart:convert';

import 'package:bazz_flutter/models/base_event.dart';
import 'package:bazz_flutter/models/location.dart';
import 'package:bazz_flutter/modules/media_uploading/media_upload_service.dart';

class OutgoingEvent extends BaseEvent {
  List<String> imageUrls = [];
  List<String> videoUrls = [];
  List<UploadableMedia> deferredUploadMedia = [];

  bool get hasDeferredUploadMedia => deferredUploadMedia.isNotEmpty;

  bool get hasNoDeferredUploadMedia => !hasDeferredUploadMedia;

  OutgoingEvent(String typeId) : super(typeId: typeId);

  OutgoingEvent.fromMap(Map<String, dynamic> map)
      : imageUrls = List<String>.from(json.decode(map['imageUrls'] as String) as List<dynamic>),
        videoUrls = List<String>.from(json.decode(map['videoUrls'] as String) as List<dynamic>),
        deferredUploadMedia = (json.decode(map['deferredUploadMedia'] as String) as List<dynamic>)
            .map((m) => UploadableMedia.fromMap(m as Map<String, dynamic>))
            .toList(),
        super(
          id: map['id'] as String,
          groupId: map['groupId'] as String,
          comment: map['description'] as String,
          createdAt: map['createdAt'] as int,
          ownerPositionId: map['positionId'] as String,
          location: map['location'] != null ? Location.fromMap(map['location'] as Map<String, dynamic>) : null,
          typeId: map['typeId'] as String,
        );

  Map<String, dynamic> toMap({bool forServer = false}) {
    final map = {
      "id": id,
      "typeId": typeId,
      "groupId": groupId,
      "description": comment,
      "createdAt": createdAt,
      "positionId": ownerPositionId,
      "location": location?.toMap(),
      "imageUrls": forServer ? imageUrls : json.encode(imageUrls),
      "videoUrls": forServer ? videoUrls : json.encode(videoUrls),
      'deferredUploadMedia': json.encode(deferredUploadMedia.map((m) => m.toMap()).toList()),
    };
    if (forServer) {
      map..remove('id')..remove('deferredUploadMedia');
    }
    return map;
  }

  void addMediaUrl(UploadableMedia m) {
    if (m.isImage) {
      imageUrls.add(m.publicUrl);
    } else {
      videoUrls.add(m.publicUrl);
    }
  }

  void clearDeferredUploadMedia() => deferredUploadMedia.clear();

  void addDeferredUploadMedia(UploadableMedia m) => deferredUploadMedia.add(m);
}
