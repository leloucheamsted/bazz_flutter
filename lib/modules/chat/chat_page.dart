import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/chat/chat_controller.dart';
import 'package:bazz_flutter/modules/chat/models/chat.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/core/message_input.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/core/messages_list.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/core/messages_list_tile.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/date_label.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/shared_widgets/badge_counter.dart';
import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:bazz_flutter/shared_widgets/tello_divider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:flutter_multi_formatter/flutter_multi_formatter.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:simple_animations/simple_animations.dart';

class ChatView extends GetView<ChatController> {
  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (controller.currentChatGroupContainer$ == null)
        return const SizedBox();

      final hasNoPrivateChats =
          controller.currentChatGroupContainer$.hasNoPrivateChats$;
      if (hasNoPrivateChats || controller.showCurrentChat) {
        Future.delayed(const Duration(), controller.goToCurrentChat);
      }
      return PageView(
        controller: controller.pageController,
        physics: hasNoPrivateChats
            ? const NeverScrollableScrollPhysics()
            : const AlwaysScrollableScrollPhysics(),
        children: [
          _buildChatsList(controller.currentChatGroupContainer$.chats),
          _buildChat(),
        ],
      );
    });
  }

  Widget _buildChatsList(List<Chat> chatList) {
    return ListView.separated(
      itemBuilder: (context, i) {
        final chat = chatList[i];
        return GestureDetector(
          onTap: () => controller.onChatTap(chat),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 5, horizontal: 10),
            color: AppTheme().colors.listItemBackground,
            child: Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: AppTheme().colors.mainBackground,
                        shape: BoxShape.circle,
                      ),
                      height: 40,
                      child: chat.imageUrl.isNotEmpty
                          ? AspectRatio(
                              aspectRatio: 1,
                              child: ClipOval(
                                  child: CachedNetworkImage(
                                      imageUrl: chat.imageUrl)),
                            )
                          : const FittedBox(
                              child: Icon(
                                Icons.group,
                                color: AppColors.primaryAccent,
                              ),
                            ),
                    ),
                    Obx(() {
                      return Positioned(
                        top: 0,
                        right: 0,
                        child: BadgeCounter(chat.unseenCounter$.toString()),
                      );
                    }),
                  ],
                ),
                const SizedBox(width: 5),
                Text(chat.title,
                    style: AppTheme().typography.reportEntryNameStyle),
              ],
            ),
          ),
        );
      },
      separatorBuilder: (_, __) => const TelloDivider(),
      itemCount: chatList.length,
    );
  }

  Widget _buildChat() {
    return Obx(() {
      final currentChat = controller.currentChatGroupContainer$.currentChat$;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final firstUnreadIndex = currentChat.firstUnreadIndex;
        if (firstUnreadIndex > -1) {
          controller.goToMessage(index: firstUnreadIndex, jump: true);
        } else {
          controller.canTrackUnread = true;
        }
      });
      return KeyboardVisibilityProvider(
        child: GestureDetector(
          onTap: () => FocusManager.instance.primaryFocus
              ?.unfocus(disposition: UnfocusDisposition.previouslyFocusedChild),
          child: Stack(
            alignment: Alignment.bottomCenter,
            children: [
              Column(
                children: [
                  Expanded(
                    child: currentChat != null
                        ? MessagesList(
                            chat: currentChat,
                            appUserId: Session.user!.id,
                            builders: MessageTileBuilders(
                              incomingMessageBuilders:
                                  IncomingMessageTileBuilders(
                                avatarBuilder: _avatarBuilder,
                              ),
                            ),
                            scrollHandler: (scroll) {
                              controller.onScroll(scroll);
                              if (scroll is ScrollStartNotification) {
                                controller.showDateTimeLabel();
                              } else if (scroll is ScrollEndNotification) {
                                controller.hideDateTimeLabel();
                              }
                            },
                          )
                        : const SizedBox(),
                  ),
                  _buildUserTypingMessage(),
                  Obx(() {
                    return SizedBox(
                        height: controller.quotedMessage != null ? 113 : 60);
                  }),
                ],
              ),
              _buildFloatingDateLabel(),
              _buildConnectingLabel(),
              _buildGoToBottomButton(),
              _buildBackToChatsButton(),
              Stack(
                children: [
                  ChatMessageInput(
                    height: 60,
                    textController: controller.inputController,
                    sendCallback: controller.sendMessage,
                    typingCallback: controller.typingCallback,
                  ),
                  if (controller.isConnecting$() &&
                      controller.isCurrentChatEmpty)
                    Positioned.fill(
                      child: Container(
                        color: AppColors.overlayBarrier,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBackToChatsButton() {
    return Obx(() {
      final hasNoPrivateChats =
          controller.currentChatGroupContainer$.hasNoPrivateChats$;
      if (hasNoPrivateChats) return const SizedBox();

      return Positioned(
        top: 5,
        left: 5,
        child: Unfocuser(
          child: CircularIconButton(
            color: Colors.black45,
            buttonSize: 35,
            onTap: controller.goToChats,
            child: const Icon(
              Icons.keyboard_arrow_left_rounded,
              color: AppColors.brightText,
              size: 25,
            ),
          ),
        ),
      );
    });
  }

  Obx _buildUserTypingMessage() {
    return Obx(() {
      String? usersTypingText;

      if (controller.usersTyping$.length == 1) {
        usersTypingText = '${controller.usersTyping$.first} is typing';
      } else if (controller.usersTyping$.length == 2) {
        usersTypingText = '${controller.usersTyping$.join(' and ')} are typing';
      } else if (controller.usersTyping$.length > 2) {
        final othersCount = controller.usersTyping$.length - 2;
        usersTypingText = '${controller.usersTyping$.take(2).join(' and ')}'
            ' + $othersCount other${othersCount > 1 ? 's' : ''} are typing';
      }
      return AnimatedContainer(
        height: usersTypingText != null ? 25 : 0,
        width: double.infinity,
        color: AppTheme().colors.mainBackground,
        duration: const Duration(milliseconds: 200),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              usersTypingText ?? '',
              style: AppTheme().typography.userIsTypingTextStyle,
            ),
            const SizedBox(width: 3),
            if (usersTypingText != null) ...[
              _buildJumpingDot(const Duration(milliseconds: 200)),
              _buildJumpingDot(const Duration(milliseconds: 400)),
              _buildJumpingDot(const Duration(milliseconds: 600)),
            ],
          ],
        ),
      );
    });
  }

  Widget _buildJumpingDot(Duration delay) {
    return CustomAnimation<double>(
      control: CustomAnimationControl.mirror,
      tween: Tween(begin: 4, end: 8),
      duration: const Duration(milliseconds: 500),
      delay: delay,
      curve: Curves.easeInCubic,
      builder: (context, child, value) {
        return Padding(
          padding: EdgeInsets.fromLTRB(2, 0, 2, value),
          child: child,
        );
      },
      child: Container(
        width: 4,
        height: 4,
        color: AppColors.lightText,
      ),
    );
  }

  Widget _buildFloatingDateLabel() {
    return Obx(() {
      return Positioned(
        top: 10,
        child: AnimatedOpacity(
          // opacity: 1,
          opacity: controller.isDateLabelVisible$() &&
                  controller.floatingDateTime$!() != null
              ? 1
              : 0,
          duration: const Duration(milliseconds: 200),
          // child: DateLabel(date: DateTime.now()),
          child: controller.floatingDateTime$!() == null
              ? const SizedBox()
              : DateLabel(date: controller.floatingDateTime$!()),
        ),
      );
    });
  }

  Obx _buildGoToBottomButton() {
    return Obx(() {
      return AnimatedPositioned(
        bottom: controller.isGoToBottomVisible$
            ? controller.quotedMessage != null
                ? 123
                : 70
            : 0,
        right: 10,
        duration: const Duration(milliseconds: 100),
        child: Stack(
          children: [
            CircularIconButton(
              color: Colors.black45,
              buttonSize: 40,
              onTap: controller.goToBottom,
              child: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.brightText,
                size: 30,
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: BadgeCounter(controller
                  .currentChatGroupContainer$.currentChat$.unseenCounter$
                  .toString()),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildConnectingLabel() {
    return Obx(() {
      if (controller.isConnecting$.isFalse) return const SizedBox();

      return Positioned(
        top: 10,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.black26,
            borderRadius: BorderRadius.circular(10.0),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Connecting',
                style: AppTheme().typography.bgText4Style,
              ),
              const SizedBox(width: 10),
              SpinKitCircle(
                color: AppColors.brightText,
                size: 20,
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _avatarBuilder(context, index, item, messagePosition) {
    TelloLogger().i("_avatarBuilder index == $index");
    final _chatMessage = item as ChatMessage;
    return Padding(
      padding: const EdgeInsets.only(right: 10),
      child: ClipOval(
        child: SizedBox(
          width: 40,
          height: 40,
          child: _chatMessage.author.avatar != ""
              ? CachedNetworkImage(imageUrl: _chatMessage.author.avatar)
              : const FittedBox(
                  child: Icon(
                  Icons.account_circle,
                  color: AppColors.primaryAccent,
                )),
        ),
        // child: Image.asset(_chatMessage.author.avatar, width: 32, height: 32, fit: BoxFit.cover),
      ),
    );
  }
}
