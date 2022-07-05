import 'package:flutter/widgets.dart';

class PopupContainer {
  late double width;
  late double height;
  late double left;
  late double top;
  late double right;
  late double bottom;
  late Alignment alignment;

  PopupContainer({
    size,
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.alignment,
  })  : width = size?.x as double,
        height = size?.y as double;
}
