import 'package:bazz_flutter/modules/chat/ui_kit/models/chat_base.dart';
import 'package:flutter/material.dart';

/// A class that manages the item list; as such, this class should be the only one holding the list of items it controls
/// You should perform all add/remove items with the api this class provides.
/// There is no selection management since usually tapping simply means navigating to the chat
/// and longPressing will trigger single item actions;
class ChatsListController extends ChangeNotifier {
  ChatsListController({List<ChatBase>? items}) {
    if (items != null) addAll(items);
  }

  final List<ChatBase> _items = [];

  List<ChatBase> get items => _items;

  void addAll(List<ChatBase> items) {
    this._items.addAll(items);
    notifyListeners();
  }

  void insertAll(int index, List<ChatBase> items) {
    this._items.insertAll(index, items);
    notifyListeners();
  }

  void removeItem(ChatBase item) {
    this._items.remove(item);
    notifyListeners();
  }

  void removeAt(int index) {
    this._items.removeAt(index);
    notifyListeners();
  }

  /// Update a given item by comparing their respective id.
  /// If [pushToStart] is true, the item will be repositioned to index 0;
  /// If [pushToEnd] is true, the item will be repositioned to the end of the list;
  void updateById(ChatBase item,
      {bool pushToStart = true, bool pushToEnd = false}) {
    final index = _items.indexWhere((element) => element.id == item.id);
    if (index > -1) {
      if (pushToStart || pushToEnd) {
        _items.removeAt(index);
        if (pushToStart) {
          _items.insert(0, item);
        } else {
          _items.add(item);
        }
      } else {
        _items[index] = item;
      }
      notifyListeners();
    }
  }

  ChatBase getById(String id) {
    return _items.firstWhere((element) => element.id == id,
        orElse: () => null!);
  }

  void notifyChanges() => notifyListeners();
}
