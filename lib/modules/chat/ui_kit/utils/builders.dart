import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/models/chat_base.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/enums.dart';
import 'package:flutter/material.dart';

/// Builder called to construct parts of the [ChatsListTile] widget.
/// [index] is the item's position in the list
typedef ChatsWidgetBuilder<T extends ChatBase> = Widget Function(
    BuildContext context, int index, ChatBase item);

typedef DateBuilder = Widget Function(BuildContext context, DateTime date);

/// Builder called to construct parts of the [MessagesListTile] widget.
/// [index] is the item's position in the list
typedef MessageWidgetBuilder = Widget Function(
    BuildContext context, int index, ChatMessage item, MessagePosition messagePosition);
