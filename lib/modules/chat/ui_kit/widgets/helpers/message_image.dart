import 'dart:io';

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/modules/chat/chat_controller.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/styling/message_style.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/enums.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_container.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_footer.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/path_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

/// A default Widget that can be used to load an image
/// This is more an example to give you an idea how to structure your own Widget,
/// since too many aspects would require to be customized, for instance
/// implementing your own image loader, padding, constraints, footer etc.
class ChatMessageImage extends StatelessWidget {
  const ChatMessageImage(
      this.index, this.message, this.messagePosition, this.messageFlow,
      {Key? key, this.callback})
      : super(key: key);

  final int index;

  final ChatMessage message;

  final MessagePosition messagePosition;

  final MessageFlow messageFlow;

  final void Function()? callback;

  @override
  Widget build(BuildContext context) {
    final directory =
        StoragePaths().getDirectoryByMessageType(message.messageType);
    final File filePath = File('$directory/${message.fileName}');
    TelloLogger().i("Loading Image  ${filePath.path}");
    const double height = 200;
    final Widget _image = filePath.existsSync()
        ? Image.file(
            filePath,
            errorBuilder: (_, e, s) => const Icon(Icons.broken_image),
          )
        : CachedNetworkImage(
            imageUrl: message.attachmentUrl,
            fit: BoxFit.contain,
            placeholder: (_, __) {
              return Container(
                height: height,
                color: Colors.black26,
                child: Center(
                  child: SpinKitFadingCircle(
                    color: AppColors.loadingIndicator,
                    size: 35,
                  ),
                ),
              );
            },
            errorWidget: (_, __, ___) => const Icon(Icons.broken_image),
          );

    return MessageContainer(
        padding: EdgeInsets.zero,
        decoration: messageDecoration(context,
            messagePosition: messagePosition,
            messageFlow: messageFlow,
            color: Colors.transparent),
        child: Container(
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
            child: GestureDetector(
              onTap: () {
                ChatController.to.showImage(_image);
                if (message.isNotDownloaded)
                  ChatController.to.downloadFile(message);
              },
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
                    children: [
                      _image,
                      Positioned(
                        right: 5,
                        bottom: 5,
                        child: MessageFooter(message),
                      ),
                    ],
                  ),
                ],
              ),
            )));
  }
}
