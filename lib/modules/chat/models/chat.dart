import 'dart:async';

import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/models/chat_user.dart';
import 'package:bazz_flutter/modules/chat/chat_controller.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/enums.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/selection_event.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:bazz_flutter/services/logger.dart';

class Chat {
  Chat(this._chatController, this.id,
      {required this.interlocutor, List<ChatMessage>? items}) {
    if (items != null) addAll(items);
  }

  final String id;

  final ChatUser interlocutor;

  final ChatController _chatController;

  final RxList<ChatMessage> _items$ = <ChatMessage>[].obs;

  int get unseenCounter$ => _items$.where((i) => i.isUnread).length;

  bool get hasPending => items.any((i) => i.isPending);

  bool allMessagesLoaded = false;

  List<ChatMessage> get items => _items$;

  List<ChatMessage> get unseenItems =>
      _items$.where((it) => it.isUnread).toList();

  bool get isPrivate => interlocutor != null;

  bool get isEmpty => _items$.isEmpty;

  String get title => interlocutor.name;

  String get imageUrl => interlocutor.avatar;

  int get firstUnreadIndex => items.lastIndexWhere((msg) => msg.isUnread);

  int get length => items.length;

  void refreshItems() {
    TelloLogger().i('refreshing chat items...');
    _items$.refresh();
  }

  void clearAll({bool update = true}) {
    _items$.clear();
    _chatController.update(['messagesList$id']);
  }

  void addAll(List<ChatMessage> items) {
    _items$.addAll(items);
    _chatController.update(['messagesList$id']);
  }

  void insertAll(int index, List<ChatMessage> items) {
    _items$.insertAll(index, items);
    _chatController.update(['messagesList$id']);
  }

  void removeSelectedItems() {
    for (final ChatMessage item in _selectedItems) {
      _items$.remove(item);
    }
    _selectedItems.clear();
    _chatController.update(['messagesList$id']);
  }

  void removeItem(ChatMessage item) {
    _items$.remove(item);
    _chatController.update(['messagesList$id']);
  }

  void removeItems(List<ChatMessage> items) {
    for (final ChatMessage item in items) {
      _items$.remove(item);
    }
    _chatController.update(['messagesList$id']);
  }

  void updateItem(ChatMessage item) {
    final index = _items$.indexWhere((element) => element.id == item.id);
    if (index > -1) {
      _items$[index] = item;
      _chatController.update(['messagesList$id']);
    }
  }

  ChatMessage getById(String id) {
    return _items$.firstWhere((element) => element.id == id,
        orElse: () => null!);
  }

  void notifyChanges() => _chatController.update(['messagesList$id']);

  ///************************************************* Action management *************************************************************

  void onItemTap(BuildContext context, int index, ChatMessage item) {
    if (isSelectionModeActive) toggleSelection(item);
  }

  void onItemLongPress(BuildContext context, int index, ChatMessage item) {
    if (!isSelectionModeActive) select(item);
  }

  ///************************************************* Selection management *************************************************************

  final List<ChatMessage> _selectedItems = [];

  List<ChatMessage> get selectedItems => _selectedItems;

  final StreamController<SelectionEvent> _controller =
      StreamController<SelectionEvent>.broadcast();

  /// Listen to this stream to catch any selection/unSelection events
  Stream<SelectionEvent> get selectionEventStream => _controller.stream;

  /// Whether at least one item is currently selected
  bool get isSelectionModeActive => _selectedItems.isNotEmpty;

  bool isItemSelected(ChatMessage item) {
    return _selectedItems.contains(item);
  }

  void select(ChatMessage item) {
    _selectedItems.add(item);
    _chatController.update(['messagesList$id']);
    _controller.sink.add(
        SelectionEvent(SelectionType.select, [item], _selectedItems.length));
  }

  void unSelect(ChatMessage item) {
    _selectedItems.remove(item);
    _chatController.update(['messagesList$id']);
    _controller.sink.add(
        SelectionEvent(SelectionType.unSelect, [item], _selectedItems.length));
  }

  void toggleSelection(ChatMessage item) {
    if (_selectedItems.contains(item)) {
      unSelect(item);
    } else {
      select(item);
    }
  }

  void unSelectAll() {
    _selectedItems.clear();
    _chatController.update(['messagesList$id']);
    _controller.sink.add(SelectionEvent(SelectionType.unSelect, [], 0));
  }

  void selectAll() {
    _selectedItems.addAll(_items$);
    _chatController.update(['messagesList$id']);
    _controller.sink.add(SelectionEvent(
        SelectionType.select, _selectedItems, _selectedItems.length));
  }
}
