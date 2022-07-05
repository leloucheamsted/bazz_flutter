import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/modules/chat/chat_controller.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/enums.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/core/messages_list_tile.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_audio.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_container.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_image.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_pdf.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_text.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_video.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class OutgoingMessage extends StatelessWidget {
  /// The item containing the tile data
  final ChatMessage item;

  /// The list index of this tile
  final int index;

  /// The custom component builders
  final OutgoingMessageTileBuilders builders;

  /// The message's position relative to other messages
  final MessagePosition messagePosition;

  const OutgoingMessage(
      {Key? key,
      required this.item,
      required this.index,
      OutgoingMessageTileBuilders? builders,
      this.messagePosition = MessagePosition.isolated})
      : builders = builders ?? const OutgoingMessageTileBuilders(),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    if (builders.bodyBuilder != null) {
      return builders.bodyBuilder!.call(context, index, item, messagePosition);
    }

    final Widget uploadingPlaceholder = GestureDetector(
      onTap: () => ChatController.to.cancelUploading(item),
      child: MessageContainer(
        constraints: BoxConstraints(
          minHeight: 150,
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        color: Colors.black38,
        child: Center(
          child: Obx(() {
            return ClipOval(
              child: Container(
                height: 50,
                width: 50,
                color: Colors.black38,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      height: 50,
                      width: 50,
                      child: CircularProgressIndicator(
                        valueColor: const AlwaysStoppedAnimation<Color>(
                            AppColors.brightText),
                        value: item.uploadProgress() / 100,
                      ),
                    ),
                    if (item.isUploading())
                      const Icon(
                        Icons.close_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );

    Widget _child;

    if (item.isUploading()) {
      _child = uploadingPlaceholder;
    } else if (item.messageType == MessageBaseType.text) {
      _child = ChatMessageText(
        index,
        item,
        messagePosition,
        MessageFlow.outgoing,
        isPending: item.isPending,
      );
    } else if (item.messageType == MessageBaseType.image) {
      _child =
          ChatMessageImage(index, item, messagePosition, MessageFlow.outgoing);
    } else if (item.messageType == MessageBaseType.audio) {
      _child =
          ChatMessageAudio(index, item, messagePosition, MessageFlow.outgoing);
    } else if (item.messageType == MessageBaseType.video) {
      _child =
          ChatMessageVideo(index, item, messagePosition, MessageFlow.outgoing);
    } else if (item.messageType == MessageBaseType.pdf) {
      _child =
          ChatMessagePdf(index, item, messagePosition, MessageFlow.outgoing);
    } else {
      _child = Container();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        if (item.isPending && ChatController.to.isConnecting$.isFalse)
          IconButton(
            visualDensity: VisualDensity.compact,
            highlightColor: Colors.transparent,
            splashRadius: 20,
            icon: Icon(Icons.refresh_rounded, color: AppTheme().colors.icon),
            onPressed: () {
              ChatController.to.resendMessage(item);
            },
          ),
        if (item.isPending)
          IconButton(
            visualDensity: VisualDensity.compact,
            highlightColor: Colors.transparent,
            splashRadius: 20,
            icon: Icon(Icons.delete_outline_rounded,
                color: AppColors.danger.withOpacity(0.8)),
            onPressed: () {
              ChatController.to.deletePending(item.id);
            },
          ),
        _child,
      ],
    );
  }
}
