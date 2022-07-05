import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/modules/chat/chat_controller.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/enums.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_container.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_footer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:path/path.dart';

/// A default Widget that can be used to load an image
/// This is more an example to give you an idea how to structure your own Widget,
/// since too many aspects would require to be customized, for instance
/// implementing your own image loader, padding, constraints, footer etc.
class ChatMessagePdf extends StatelessWidget {
  const ChatMessagePdf(
      this.index, this.message, this.messagePosition, this.messageFlow,
      {Key? key, this.callback})
      : super(key: key);

  final int index;

  final ChatMessage message;

  final MessagePosition messagePosition;

  final MessageFlow messageFlow;

  final void Function()? callback;

  Widget createPdfHeader(String fileName) {
    return Container(
        padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 6),
        decoration: BoxDecoration(
          color: Colors.black38,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          TextOneLine(
            fileName,
            style: const TextStyle(color: Colors.white, fontSize: 8),
          )
        ]));
  }

  @override
  Widget build(BuildContext context) {
    const double maxSizeWidth = 150;
    return MessageContainer(
        padding: EdgeInsets.zero,
        decoration: messageDecoration(context,
            messagePosition: messagePosition,
            messageFlow: messageFlow,
            color: Colors.transparent),
        child: GestureDetector(
          onTap: () {
            if (message.isDownloading()) return;
            ChatController.to.openPdf(message);
          },
          child: Container(
            width: maxSizeWidth,
            height: maxSizeWidth + (message.text.isNotEmpty ? 31 : 0),
            decoration: BoxDecoration(
              boxShadow: const [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 2,
                )
              ],
              borderRadius: const BorderRadius.all(Radius.circular(2)),
              color: messageFlow == MessageFlow.outgoing
                  ? AppTheme().colors.outgoingChatMsg
                  : AppTheme().colors.incomingChatMsg,
            ),
            child: Column(
              children: [
                if (message.text.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.fromLTRB(8, 5, 8, 5),
                    color: messageFlow == MessageFlow.outgoing
                        ? AppTheme().colors.outgoingChatMsg
                        : AppTheme().colors.incomingChatMsg,
                    child: Text(message.text,
                        style: AppTheme().typography.bgText3Style),
                  ),
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Image(
                        image: AssetImage(
                            'assets/images/pdf-image-placeholder.png')),
                    Positioned(
                        top: 0,
                        child: Padding(
                            padding: const EdgeInsets.fromLTRB(0, 3, 0, 0),
                            child: createPdfHeader(
                                basename(message.attachmentUrl)))),
                    Positioned(
                      right: 5,
                      bottom: 5,
                      child: MessageFooter(message),
                    ),
                    Obx(() {
                      if (!message.isDownloading()) return const SizedBox();
                      return ClipOval(
                        child: Container(
                          height: 50,
                          width: 50,
                          color: Colors.black38,
                          child: Center(
                            child: SpinKitFadingCircle(
                              color: AppColors.loadingIndicator,
                              size: 35,
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ],
            ),
          ),
        ));
  }
}
