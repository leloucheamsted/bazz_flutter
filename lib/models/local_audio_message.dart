import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/user_model.dart';

class LocalAudioMessage {
  late String long;
  late String lat;
  late String filePath;
  late String fileUrl;
  late int fileDurationMs;
  late String mimeType;
  late String groupId;
  late DateTime createdAt;
  late int createdAtTimestamp;
  late String txId;
  late RxUser owner;
  late PositionInfoCard ownerPosition;
  late List<String> recipients;

  LocalAudioMessage({
    required this.createdAt,
    required this.txId,
    required this.long,
    required this.lat,
    required this.filePath,
    required this.mimeType,
    required this.createdAtTimestamp,
    required this.groupId,
    required this.owner,
    required this.ownerPosition,
    required this.recipients,
  });

  LocalAudioMessage.fromMap(Map<String, dynamic> map)
      : createdAt =
            map['createdAt'] == null ? null! : DateTime.parse(map['createdAt']),
        createdAtTimestamp = map['createdAtTimestamp'] as int,
        filePath = map['recordingUrl'] as String,
        fileUrl = map['fileUrl'] as String,
        fileDurationMs = map['fileDurationMs'] as int,
        txId = map['txId'] as String,
        mimeType = map['mimeType'] as String,
        groupId = map['groupId'] as String,
        owner = map['owner'] != null
            ? RxUser.fromMap(map['owner'] as Map<String, dynamic>)
            : null!,
        recipients = map['recipients'] != null
            ? List<String>.from(map['recipients'] as List<dynamic>)
            : null!,
        ownerPosition = map['ownerPosition'] != null
            ? PositionInfoCard.fromMap(
                map['ownerPosition'] as Map<String, dynamic>)
            : null!;

  Map<String, dynamic> toMap() => {
        'txId': txId,
        'recordingUrl': filePath,
        'fileUrl': fileUrl,
        'fileDurationMs': fileDurationMs,
        'createdAt': createdAt.toIso8601String(),
        'createdAtTimestamp': createdAtTimestamp,
        'mimeType': mimeType,
        'groupId': groupId,
        'owner': owner.toMap(),
        'ownerPosition': ownerPosition.toMap(),
        'recipients': recipients,
      };

  Map<String, dynamic> toMapForServer() => {
        'groupId': groupId,
        'owner': owner.toMapForServer(),
        'ownerPosition': ownerPosition.toMap(),
        'audioFile': {
          'durationMs': fileDurationMs,
          'url': fileUrl,
        },
        'createdAt': createdAtTimestamp,
        'recipientUserIds': recipients,
      };
}
