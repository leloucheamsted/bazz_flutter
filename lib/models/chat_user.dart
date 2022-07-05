import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/models/user_base.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:flutter/cupertino.dart';

class ChatUser extends UserBase {
  @override
  String id, name, avatar;
  @override
  late String positionId, positionTitle;

  ChatUser(
      {required this.id,
      required this.name,
      required this.avatar,
      required this.positionId,
      required this.positionTitle});

  ChatUser.fromMap(Map<String, dynamic> map)
      : id = map['id'] as String,
        name = map['name'] as String,
        avatar = map['avatar'] as String,
        positionId = map['positionId'] as String,
        positionTitle = map['positionTitle'] != null
            ? Uri.decodeQueryComponent(map['positionTitle'])
            : null!;

  Map<String, dynamic> toMap() => {
        "id": id,
        "name": name,
        "avatar": avatar,
        "positionId": positionId,
        "positionTitle": positionTitle,
      };

  factory ChatUser.fromUser(RxUser user, [RxPosition? position]) {
    TelloLogger().i("CHAT USER POSITION ${position?.title}");
    return ChatUser(
        id: user.id,
        name: user.fullName!,
        avatar: user.avatar,
        positionId: position!.id,
        positionTitle: position.title);
  }

  factory ChatUser.fromUnknownUser(String id) {
    return ChatUser(
        id: id,
        name: "Unknown User",
        avatar: "",
        positionId: "",
        positionTitle: "");
  }
}
