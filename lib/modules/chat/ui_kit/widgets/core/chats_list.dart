import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/models/chat_base.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/controllers.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/core/chats_list_tile.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/group_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:implicitly_animated_reorderable_list/implicitly_animated_reorderable_list.dart';
import 'package:implicitly_animated_reorderable_list/transitions.dart';

class ChatsList<T extends ChatBase> extends StatefulWidget {
  ChatsList(
      {Key? key,
      required this.controller,
      required this.appUserId,
      this.areItemsTheSame,
      //this.chatsListStyle = const ChatsListStyle(),
      this.groupAvatarStyle,
      this.unreadBubbleEnabled = true,
      required this.builders,
      this.scrollHandler})
      : super(key: key);

  /// The controller that manages items and actions
  final ChatsListController controller;

  /// The id of the app's current user
  /// required to determine whether a message is owned
  final String appUserId;

  /// Called by the DiffUtil to decide whether two object represent the same Item.
  /// By default, this will check whether oldItem.getId() == newItem.getId();
  final bool Function(T oldItem, T newItem)? areItemsTheSame;

  /// Example styling configuration for the widget
  //final ChatsListStyle chatsListStyle;

  /// Styling configuration for the default [GroupAvatar] used in [_buildLeading]
  final GroupAvatarStyle? groupAvatarStyle;

  /// Set to true if you want to display a bubble above the group avatar
  /// which shows the number of unread messages
  final bool unreadBubbleEnabled;

  /// Replace any component you are unsatisfied with with a custom Widget, build using
  /// these builders
  final ChatsListTileBuilders builders;

  /// Scrolling will trigger [NotificationListener], which will call this handler;
  /// Typically looks like this:
  /// void _handleScrollEvent(ScrollNotification scroll) {
  ///   if (scroll.metrics.pixels == scroll.metrics.maxScrollExtent)
  ///     _getMoreChats();
  /// }
  final Function(ScrollNotification scroll)? scrollHandler;

  @override
  _ChatsListState createState() => _ChatsListState();
}

class _ChatsListState<T extends ChatBase> extends State<ChatsList> {
  @override
  void initState() {
    widget.controller.addListener(_controllerListener);
    super.initState();
  }

  void _controllerListener() {
    setState(() {});
  }

  Widget _buildItem(BuildContext context, Animation<double> animation,
      ChatBase item, int index) {
    // Specify a transition to be used by the ImplicitlyAnimatedList.
    // See the Transitions section on how to import this transition.
    return SizeFadeTransition(
      sizeFraction: 0.7,
      curve: Curves.easeInOut,
      animation: animation,
      child: ChatsListTile(
          item: item,
          index: index,
          appUserId: widget.appUserId,
          builders: widget.builders,
          groupAvatarStyle: widget.groupAvatarStyle!,
          unreadBubbleEnabled: widget.unreadBubbleEnabled),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Specify the generic type of the data in the list.
    return NotificationListener<ScrollNotification>(
        onNotification: (ScrollNotification scroll) {
          if (widget.scrollHandler != null) widget.scrollHandler!.call(scroll);
          return null!;
        },
        child: ImplicitlyAnimatedList<ChatBase>(
            // The current items in the list.
            items: widget.controller.items,
            areItemsTheSame: (ChatBase a, ChatBase b) {
              if (widget.areItemsTheSame != null)
                return widget.areItemsTheSame!(a, b);
              return a.id == b.id;
            },
            // Called, as needed, to build list item .
            // List items are only built when they're scrolled into view.
            itemBuilder: _buildItem));
  }
}
