import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/modules/chat/chat_controller.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/enums.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_container.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_footer.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// A default Widget that can be used to display text
/// This is more an example to give you an idea how to structure your own Widget
class ChatMessageText extends StatelessWidget {
  const ChatMessageText(
      this.index, this.message, this.messagePosition, this.messageFlow,
      {Key? key,
      this.color = AppColors.brightBackground,
      required this.isPending})
      : super(key: key);

  final int index;
  final ChatMessage message;
  final MessagePosition messagePosition;
  final MessageFlow messageFlow;
  final Color color;
  final bool isPending;

  @override
  Widget build(BuildContext context) {
    return MessageContainer(
      padding: EdgeInsets.zero,
      decoration: messageDecoration(
        context,
        messagePosition: messagePosition,
        messageFlow: messageFlow,
        color: isPending
            ? AppTheme().colors.disabledButton.withOpacity(0.4)
            : messageFlow == MessageFlow.outgoing
                ? AppTheme().colors.outgoingChatMsg
                : AppTheme().colors.incomingChatMsg,
      ),
      child: IntrinsicWidth(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (message.quotedMessage != null)
              GestureDetector(
                onTap: () {
                  ChatController.to
                      .goToMessage(messageId: message.quotedMessage.id);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    border: const Border(
                      left:
                          BorderSide(width: 3, color: AppColors.primaryAccent),
                    ),
                    color: messageFlow == MessageFlow.outgoing
                        ? AppTheme().colors.outgoingQuotedMsg
                        : AppTheme().colors.incomingQuotedMsg,
                  ),
                  child: Row(
                    children: [
                      if (message.quotedMessage.attachmentUrl != null)
                        Container(
                          height: 40,
                          padding: const EdgeInsets.only(right: 5),
                          child: CachedNetworkImage(
                              imageUrl: message.quotedMessage.attachmentUrl),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            FitHorizontally(
                              alignment: Alignment.centerLeft,
                              shrinkLimit: .9,
                              child: TextOneLine(
                                message.quotedMessage.author.name,
                                style: AppTheme().typography.chatMsgAuthorStyle,
                              ),
                            ),
                            FitHorizontally(
                              alignment: Alignment.centerLeft,
                              shrinkLimit: .9,
                              child: TextOneLine(
                                message.quotedMessage.text,
                                style: AppTheme().typography.bgText3Style,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 3, 8, 0),
              child:
                  Text(message.text, style: AppTheme().typography.bgText3Style),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Align(
                alignment: Alignment.centerRight,
                child: MessageFooter(message),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
