import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/modules/chat/chat_controller.dart';
import 'package:bazz_flutter/modules/chat/models/chat.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/styling/message_style.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/builders.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/enums.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/core/incoming_message.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/core/outgoing_message.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:swipe_to/swipe_to.dart';

class MessageTileBuilders {
  /// Called if [MessagesList.useCustomTile] is not null.
  /// The typical use case is to call the custom builder when you have
  /// event types messages (user joined chat, renaming chat etc.).
  /// This builder will be called instead of [MessagesList._buildItem].
  final Widget Function(BuildContext context, int index, ChatMessage item,
      MessagePosition messagePosition)? customTileBuilder;

  /// Call this builder to override the default [DateLabel] widget to build the date labels
  final DateBuilder? customDateBuilder;

  /// Wraps the default [MessagesListTile] and overrides the default [InkWell]
  /// If you use this, you have to implement your own selection Widget
  final Widget Function(BuildContext context, int index, ChatMessage item,
      MessagePosition messagePosition, Widget child)? wrapperBuilder;

  final IncomingMessageTileBuilders? incomingMessageBuilders;

  final OutgoingMessageTileBuilders? outgoingMessageBuilders;

  const MessageTileBuilders(
      {this.customTileBuilder,
      this.customDateBuilder,
      this.wrapperBuilder,
      this.incomingMessageBuilders = const IncomingMessageTileBuilders(),
      this.outgoingMessageBuilders = const OutgoingMessageTileBuilders()});
}

class IncomingMessageTileBuilders<T> {
  /// Builder to display a widget in front of the body;
  /// Typically build the user's avatar here
  final MessageWidgetBuilder? avatarBuilder;

  /// Builder to display a widget on top of the first message from the same user.
  /// Typically build the user's username here.
  /// Pass null to disable the default builder [_defaultIncomingMessageTileTitleBuilder].
  final MessageWidgetBuilder titleBuilder;

  /// Override the default text widget and supply a complete widget (including container) using your own logic
  final MessageWidgetBuilder? bodyBuilder;

  const IncomingMessageTileBuilders(
      {this.avatarBuilder,
      this.bodyBuilder,
      this.titleBuilder = _defaultIncomingMessageTileTitleBuilder});
}

class OutgoingMessageTileBuilders {
  /// Override the default text widget and supply a complete widget (including container) using your own logic
  final MessageWidgetBuilder? bodyBuilder;

  const OutgoingMessageTileBuilders({this.bodyBuilder});
}

Widget _defaultIncomingMessageTileTitleBuilder(BuildContext context, int index,
    ChatMessage item, MessagePosition messagePosition) {
  return Padding(
      padding: const EdgeInsets.only(bottom: 5.0),
      child: Text(
          "${item.author.positionTitle}${item.author.positionTitle != "" ? "-" : ""}${item.author.name}",
          style: AppTheme().typography.chatMsgAuthorStyle));
}

class MessagesListTile<T> extends StatelessWidget {
  MessagesListTile(
      {Key? key,
      required this.item,
      required this.index,
      required this.chat,
      required this.appUserId,
      this.style,
      this.builders,
      this.messagePosition})
      : super(key: key);

  /// The item containing the tile data
  final ChatMessage item;

  /// The list index of this tile
  final int index;

  /// The controller that manages items and actions
  final Chat chat;

  /// The id of the app's current user.
  /// Required to determine whether a message is owned
  final String appUserId;

  late MessageStyle? style;

  final MessageTileBuilders? builders;

  final MessagePosition? messagePosition;

  @override
  Widget build(BuildContext context) {
    final Widget child = Padding(
        padding: style!.padding,
        child: item.isOutgoing
            ? OutgoingMessage(
                item: item,
                index: index,
                messagePosition: messagePosition!,
                builders: builders!.outgoingMessageBuilders)
            : IncomingMessage(
                item: item,
                index: index,
                style: style!,
                messagePosition: messagePosition!,
                builders: builders!.incomingMessageBuilders));
    if (builders!.wrapperBuilder != null) {
      return builders!.wrapperBuilder!
          .call(context, index, item, messagePosition!, child);
    }
    return Container(
      foregroundDecoration: BoxDecoration(
          color: chat.isItemSelected(item)
              ? style!.selectionColor
              : Colors.transparent),
      child: Material(
        clipBehavior: Clip.antiAlias,
        type: MaterialType.transparency,
        child: SwipeTo(
          iconOnRightSwipe: Icons.arrow_left,
          iconColor: AppTheme().colors.icon,
          onLeftSwipe: () {
            ChatController.to.onSwipeItem(context, index, item);
          },
          child: InkWell(
            splashColor: Colors.blue,
            //TODO: currently we don't need these, candidates for removal
            // onTap: () => controller.onItemTap(context, index, item),
            //onLongPress: () => chat.onItemLongPress(context, index, item),
            child: AbsorbPointer(
                absorbing: chat.isSelectionModeActive, child: child),
          ),
        ),
      ),
    );
  }
}
