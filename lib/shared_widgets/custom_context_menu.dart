import 'package:flutter/material.dart' hide showMenu;
import 'package:flutter/material.dart' as material show showMenu;
import 'package:get/get_state_manager/src/simple/get_controllers.dart';
import 'package:get/get_state_manager/src/simple/get_view.dart';

/// A mixin to provide convenience methods to record a tap position and show a popup menu.
mixin CustomPopupMenu<T extends GetxController> on GetView<T> {
  late Offset _tapPosition;

  /// Pass this method to an onTapDown parameter to record the tap position.
  void storePosition(TapDownDetails details) =>
      _tapPosition = details.globalPosition;

  /// Use this method to show the menu.
  Future<T?> showMenu<T>({
    required BuildContext context,
    required List<PopupMenuEntry<T>> items,
    required T initialValue,
    required double elevation,
    required String semanticLabel,
    required ShapeBorder shape,
    required Color color,
    bool captureInheritedThemes = true,
    bool useRootNavigator = false,
  }) {
    final RenderBox overlay = context.findRenderObject() as RenderBox;

    return material.showMenu<T>(
      context: context,
      position: RelativeRect.fromLTRB(
        _tapPosition.dx,
        _tapPosition.dy,
        overlay.size.width - _tapPosition.dx,
        overlay.size.height - _tapPosition.dy,
      ),
      items: items,
      initialValue: initialValue,
      elevation: elevation,
      semanticLabel: semanticLabel,
      shape: shape,
      color: color,
      //captureInheritedThemes  : captureInheritedThemes,
      useRootNavigator: useRootNavigator,
    );
  }
}
