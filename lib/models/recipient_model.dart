import 'package:bazz_flutter/models/user_model.dart';

class Recipient {
  String recipientType;
  String recipientId;
  // For groups we need to specify the current list of users so people
  // will not recieve messages from before they joined the group
  List<RxUser> userList;

  Recipient(
      {required this.recipientType,
      required this.recipientId,
      required this.userList});

  Recipient.fromJson(Map<String, dynamic> json)
      : recipientType = json['recipientType'] as String,
        recipientId = json['recipientId'] as String,
        userList = (json['userList'])
            ?.map((e) =>
                e == null ? null : RxUser.fromMap(e as Map<String, dynamic>))
            ?.toList();

  Map<String, dynamic> toJson() => {
        'recipientType': recipientType,
        'recipientId': recipientId,
        'userList': userList,
      };
}
