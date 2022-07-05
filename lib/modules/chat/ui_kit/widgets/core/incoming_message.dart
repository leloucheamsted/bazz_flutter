import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/styling/message_style.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/enums.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/core/messages_list_tile.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_audio.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_image.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_pdf.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_text.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_video.dart';

import 'package:flutter/material.dart';

/// The default helper widget that represents an incoming [MessageBase]
/// It will build a title by default (author's username) above the user's first message
/// The avatar is built if you supply [IncomingMessageTileBuilders.avatarBuilder]
/// You can position the avatar on the first or last message with [MessageStyle.avatarBehaviour]
/// This widget display simple text by default
class IncomingMessage extends StatelessWidget {
  /// The item containing the tile data
  final ChatMessage item;

  /// The list index of this tile
  final int index;

  /// Custom styling you want to apply
  final MessageStyle style;

  /// The custom component builders
  final IncomingMessageTileBuilders builders;

  /// The message's position relative to other messages
  final MessagePosition messagePosition;

  const IncomingMessage(
      {Key? key,
      required this.item,
      required this.index,
      IncomingMessageTileBuilders? builders,
      this.messagePosition = MessagePosition.isolated,
      this.style = const MessageStyle(selectionColor: Colors.white)})
      : builders = builders ?? const IncomingMessageTileBuilders(),
        super(key: key);

  bool get _shouldBuildAvatar =>
      builders.avatarBuilder != null &&
      (messagePosition == MessagePosition.isolated ||
          (messagePosition == MessagePosition.surroundedBot &&
              style.avatarBehaviour == AvatarBehaviour.alwaysTop) ||
          (messagePosition == MessagePosition.surroundedTop &&
              style.avatarBehaviour == AvatarBehaviour.alwaysBottom));

  bool get _shouldBuildTitle =>
      builders.titleBuilder != null &&
      messagePosition != MessagePosition.surrounded &&
      messagePosition != MessagePosition.surroundedTop;

  @override
  Widget build(BuildContext context) {
    Widget _child;

    if (builders.bodyBuilder != null) {
      _child =
          builders.bodyBuilder!.call(context, index, item, messagePosition);
    } else {
      if (item.messageType == MessageBaseType.text) {
        _child = ChatMessageText(
            index, item, messagePosition, MessageFlow.incoming,
            isPending: item.isPending);
      } else if (item.messageType == MessageBaseType.image) {
        _child = ChatMessageImage(
            index, item, messagePosition, MessageFlow.incoming);
      } else if (item.messageType == MessageBaseType.audio) {
        _child = ChatMessageAudio(
            index, item, messagePosition, MessageFlow.incoming);
      } else if (item.messageType == MessageBaseType.video) {
        _child = ChatMessageVideo(
            index, item, messagePosition, MessageFlow.incoming);
      } else if (item.messageType == MessageBaseType.pdf) {
        _child =
            ChatMessagePdf(index, item, messagePosition, MessageFlow.incoming);
      } else {
        _child = Container();
      }
    }

    final _messageBody = Row(
      crossAxisAlignment: style.avatarBehaviour == AvatarBehaviour.alwaysTop
          ? CrossAxisAlignment.start
          : CrossAxisAlignment.end,
      children: [
        if (_shouldBuildAvatar)
          builders.avatarBuilder!.call(context, index, item, messagePosition),
        if (!_shouldBuildAvatar && builders.avatarBuilder != null)
          Container(width: style.avatarWidth),
        _child
      ],
    );

    if (!_shouldBuildTitle) return _messageBody;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(width: style.avatarWidth),
            builders.titleBuilder(context, index, item, messagePosition)
          ],
        ),
        _messageBody
      ],
    );
  }
}
