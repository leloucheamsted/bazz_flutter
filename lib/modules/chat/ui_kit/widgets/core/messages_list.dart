import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/modules/chat/chat_controller.dart';
import 'package:bazz_flutter/modules/chat/models/chat.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/styling/message_style.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/enums.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/extensions.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/core/messages_list_tile.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/build_date.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/loading_messages_label.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_multi_formatter/utils/unfocuser.dart';
import 'package:get/get.dart';
// import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:scrollable_positioned_list/scrollable_positioned_list.dart';
import 'package:visibility_detector/visibility_detector.dart';

class MessagesList extends StatelessWidget {
  MessagesList(
      {Key? key,
      required this.chat,
      required this.appUserId,
      this.areItemsTheSame,
      this.scrollHandler,
      this.style,
      this.useCustomTile,
      this.messagePosition,
      this.shouldBuildDate,
      this.builders = const MessageTileBuilders()})
      :
        // assert(useCustomTile != null && builders.customTileBuilder != null,
        //       "You have to provide a customTileBuilder if you set useCustomTile"),
        super(key: key);

  /// The controller that manages items and actions
  final Chat chat;

  /// The id of the app's current user.
  /// Required to determine whether a message is owned.
  final String appUserId;

  /// Called by the DiffUtil to decide whether two object represent the same Item.
  /// By default, this will check whether oldItem.id == newItem.id;
  final bool Function(ChatMessage oldItem, ChatMessage newItem)?
      areItemsTheSame;

  /// Scrolling will trigger [NotificationListener], which will call this handler.
  /// Typically looks like this:
  /// void _handleScrollEvent(ScrollNotification scroll) {
  ///   if (scroll.metrics.pixels == scroll.metrics.maxScrollExtent)
  ///     _getMoreChats();
  /// }
  final Function(ScrollNotification scroll)? scrollHandler;

  /// Provide your custom builders to override the default behaviour
  late MessageTileBuilders? builders;

  /// Custom styling you want to apply to the messages
  final MessageStyle? style;

  /// Pass a function to test whether [builders.customTileBuilder] should be called.
  /// The typical use case is to call the custom builder when you have
  /// event types messages (user joined chat, renaming chat etc.).
  late bool Function(
          int index, ChatMessage item, MessagePosition messagePosition)?
      useCustomTile;

  /// Pass a function to override the default [_messagePosition]
  final MessagePosition Function(
      ChatMessage previousItem,
      ChatMessage currentItem,
      ChatMessage nextItem,
      bool Function(ChatMessage currentItem) shouldBuildDate)? messagePosition;

  /// Pass a function to override the default [_shouldBuildDate]
  final bool Function(ChatMessage currentItem)? shouldBuildDate;

  List<ChatMessage> get _items => chat.items;

  /// Helper method to determine whether a date label should be shown.
  /// If true, [_buildDate] will be called
  bool _shouldBuildDate(ChatMessage currentItem) {
    if (shouldBuildDate != null) return shouldBuildDate!.call(currentItem);

    final int index = _items.indexOf(currentItem);
    final DateTime currentItemDate = currentItem.createdAt;

    final ChatMessage previousItem =
        index + 1 < _items.length ? _items[index + 1] : null!;
    final DateTime prevItemDate = previousItem.createdAt;

    //build date if the previous item is older than the current item (and not same day)
    //or if no previous item exists and the current item is older than today
    return prevItemDate == null && currentItemDate.isYesterdayOrOlder ||
        prevItemDate != null &&
            prevItemDate.isBeforeAndDifferentDay(currentItemDate);
  }

  /// Default method to determine the padding above the tile
  /// It will vary depending on the [MessagePosition]
  double _topItemPadding(int index, MessagePosition messagePosition) {
    const padding = 8.0;
    if (index == _items.length) return 0;
    if (messagePosition == MessagePosition.surrounded ||
        messagePosition == MessagePosition.surroundedTop) return 1.0;
    return padding;
  }

  /// Default method to determine the padding below the tile.
  /// It will vary depending on the [MessagePosition]
  double _bottomItemPadding(int index, MessagePosition messagePosition) {
    const padding = 8.0;
    if (messagePosition == MessagePosition.surrounded ||
        messagePosition == MessagePosition.surroundedBot) return 5.0;
    return padding;
  }

  /// Helper method to determine the [MessagePosition]
  MessagePosition _messagePosition(ChatMessage item) {
    final currentItem = item;
    //this will return the index in the new item list
    final int index = _items.indexOf(currentItem);

    final ChatMessage nextItem =
        (index > 0 && _items.length >= index) ? _items[index - 1] : null!;

    ChatMessage previousItem =
        index + 1 < _items.length ? _items[index + 1] : null!;

    if (messagePosition != null) {
      return messagePosition!
          .call(previousItem, currentItem, nextItem, _shouldBuildDate);
    }

    if (_shouldBuildDate(currentItem)) {
      previousItem = null!;
    } else {
      previousItem = index + 1 < _items.length ? _items[index + 1] : null!;
    }

    if (previousItem.author.id == currentItem.author.id &&
        nextItem.author.id == currentItem.author.id) {
      return MessagePosition.surrounded;
    } else if (previousItem.author.id == currentItem.author.id &&
        nextItem.author.id != currentItem.author.id) {
      return MessagePosition.surroundedTop;
    } else if (previousItem.author.id != currentItem.author.id &&
        nextItem.author.id == currentItem.author.id) {
      return MessagePosition.surroundedBot;
    } else {
      return MessagePosition.isolated;
    }
  }

  /// The item builder.
  /// Be aware that [ImplicitlyAnimatedList] will call this builder to build new items as well
  /// as update items. Therefore, the index passed can be the index in the old items list as
  /// well as the index in the new items list.
  Widget _buildItem(BuildContext context, int i) {
    final item = _items[i];
    final MessagePosition _position = _messagePosition(item);

    if (useCustomTile != null && useCustomTile!.call(i, item, _position)) {
      return builders!.customTileBuilder!.call(context, i, item, _position);
    }

    final Widget child = Unfocuser(
      child: VisibilityDetector(
        key: UniqueKey(),
        onVisibilityChanged: (VisibilityInfo info) {
          ChatController.to.onMsgVisibilityChanged(item, info.visibleFraction);
        },
        child: MessagesListTile(
            item: item,
            index: i,
            chat: chat,
            appUserId: appUserId,
            builders: builders!,
            style: style ??
                MessageStyle(
                    padding: EdgeInsets.only(
                        left: 10,
                        right: 10,
                        top: _topItemPadding(i, _position),
                        bottom: _bottomItemPadding(i, _position)),
                    selectionColor: null!),
            messagePosition: _position),
      ),
    );

    if (i == -1 || !_shouldBuildDate(item)) {
      return Column(
        children: [
          Obx(() {
            if (ChatController.to.messageHistoryLoading$.isFalse ||
                i != _items.length - 1) return const SizedBox();
            return LoadingMessagesLabel();
          }),
          child,
        ],
      );
    }
    item.dateIsVisible = true;
    return Column(
      children: [
        Obx(() {
          if (ChatController.to.messageHistoryLoading$.isFalse ||
              i != _items.length - 1) return const SizedBox();
          return LoadingMessagesLabel();
        }),
        BuildDate(item, builders!),
        child,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    // Specify the generic type of the data in the list.
    return GetBuilder<ChatController>(
        id: 'messagesList${chat.id}',
        builder: (controller) {
          return NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification scroll) {
              if (scrollHandler != null) scrollHandler!.call(scroll);
              return null!;
            },
            child: ScrollablePositionedList.builder(
              itemScrollController: controller.itemScrollCtrl,
              itemPositionsListener: controller.itemPositionsListener,
              padding: const EdgeInsets.only(top: 10),
              reverse: true,
              itemBuilder: _buildItem,
              itemCount: _items.length,
            ),
          );
        });
  }
}
