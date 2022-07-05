import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/models/chat_base.dart';
import 'package:flutter/material.dart';

class BuildAvatar<T> extends StatelessWidget {
  const BuildAvatar(this.items, this.builder, this.index, this.size, {Key? key})
      : super(key: key);

  final List<T> items;
  final Widget Function(BuildContext, int, Size, List<dynamic>) builder;
  final int index;
  final Size size;

  @override
  Widget build(BuildContext context) {
    return Expanded(child: builder(context, index, size, items));
  }
}
