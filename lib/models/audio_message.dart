import 'package:bazz_flutter/models/audio_locations_model.dart';
import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

class AudioMessage {
  final RxUser owner;
  final PositionInfoCard? ownerPosition;
  final String id, groupId, fileUrl;
  final int fileDuration, createdAt;
  final RxBool isListened, isPlaying;
  AudioLocations? audioLocations;
  List<String> recipients;

  bool get isNotPlaying => isPlaying.isFalse;

  bool get isNotListened => isListened.isFalse;

  bool get isPrivate => recipients.isNotEmpty;

  bool get isForGroup => !isPrivate;

  AudioMessage({
    required this.id,
    required this.owner,
    required this.groupId,
    required this.fileUrl,
    required this.fileDuration,
    required this.createdAt,
    required this.isListened,
    required this.isPlaying,
    required this.recipients,
    this.ownerPosition,
  });

  @override
  String toString() {
    return 'AudioMessage{id: $id, user: $owner, position: $ownerPosition, groupId: $groupId, fileUrl: $fileUrl, '
        'fileDuration: $fileDuration, createdAt: $createdAt, isListened: ${isListened()}, isPlaying: ${isPlaying()}, '
        'recipients: $recipients}';
  }

  //TODO: Deep compare recipients
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AudioMessage &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          owner == other.owner &&
          ownerPosition == other.ownerPosition &&
          groupId == other.groupId &&
          fileUrl == other.fileUrl &&
          fileDuration == other.fileDuration &&
          createdAt == other.createdAt &&
          isListened() == other.isListened() &&
          isPlaying() == other.isPlaying() &&
          recipients.length == other.recipients.length);

  @override
  int get hashCode =>
      id.hashCode ^
      owner.hashCode ^
      ownerPosition.hashCode ^
      groupId.hashCode ^
      fileUrl.hashCode ^
      fileDuration.hashCode ^
      createdAt.hashCode ^
      isListened().hashCode ^
      isPlaying().hashCode ^
      recipients.hashCode;

  /// Decodes a map from HTTP
  factory AudioMessage.fromNestedMap(Map<String, dynamic> map) {
    return AudioMessage(
      id: map['message']['id'] as String,
      groupId: map['message']['groupId'] as String,
      owner: RxUser.fromMap(map['message']['owner'] as Map<String, dynamic>),
      ownerPosition: map['message']['ownerPosition'] != null
          ? PositionInfoCard.fromMap(
              map['message']['ownerPosition'] as Map<String, dynamic>)
          : null!,
      fileUrl: map['message']['audioFile']['url'] as String,
      fileDuration: millisecondsToSeconds(
          map['message']['audioFile']['durationMs'] as int),
      createdAt: map['message']['createdAt'] as int,
      recipients: map['message']['recipientUserIds'] != null
          ? List<String>.from(
              map['message']['recipientUserIds'] as List<dynamic>)
          : null!,
      isListened: (map['isListened'] as bool).obs,
      isPlaying: false.obs,
    );
  }

  /// Decodes a map from the NewAudioMessageEvent event
  factory AudioMessage.fromMap(Map<String, dynamic> map) {
    return AudioMessage(
      id: map['id'] as String,
      groupId: map['groupId'] as String,
      owner: RxUser.fromMap(map['owner'] as Map<String, dynamic>),
      ownerPosition: map['ownerPosition'] != null
          ? PositionInfoCard.fromMap(
              map['ownerPosition'] as Map<String, dynamic>)
          : null,
      fileUrl: map['audioFile']['url'] as String,
      fileDuration:
          millisecondsToSeconds(map['audioFile']['durationMs'] as int),
      createdAt: map['createdAt'] as int,
      recipients: map['recipientUserIds'] != null
          ? List<String>.from(map['recipientUserIds'] as List<dynamic>)
          : null!,
      isListened: false.obs,
      isPlaying: false.obs,
    );
  }

// Map<String, dynamic> toMap() {
//   return {
//     'user': user,
//     'position': position,
//     'groupId': groupId,
//     'groupTitle': groupTitle,
//     'fileUrl': fileUrl,
//     'fileDuration': fileDuration,
//     'createdAt': createdAt,
//     'isListened': isListened(),
//   };
// }
}
