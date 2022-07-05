import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/models/chat_base.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/build_avatar.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/build_separator.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/group_avatar.dart';
import 'package:flutter/material.dart';

class BuildGroupAvatar<T> extends StatelessWidget {
  const BuildGroupAvatar(this.style, this.items, this.builder, {Key? key})
      : super(key: key);

  final GroupAvatarStyle style;
  final List<T> items;
  final Widget Function(BuildContext, int, Size, List<dynamic>) builder;

  @override
  Widget build(BuildContext context) {
    if (items.length == 1) {
      return builder.call(context, 0, Size(style.size, style.size), items);
    }
    final separatorSize = style.withSeparator ? style.separatorThickness : 0;
    if (items.length == 2) {
      final _size = Size((style.size - separatorSize) / 2, style.size);
      return Row(
        children: [
          BuildAvatar(items, builder, 0, _size),
          if (style.withSeparator)
            BuildSeparator(style,
                width: style.separatorThickness, height: style.size),
          BuildAvatar(items, builder, 1, _size)
        ],
      );
    }
    if (items.length == 3) {
      return Row(
        children: [
          BuildAvatar(items, builder, 0,
              Size((style.size - separatorSize) / 2, style.size)),
          if (style.withSeparator)
            BuildSeparator(style,
                width: style.separatorThickness, height: style.size),
          Column(
            children: [
              BuildAvatar(
                  items,
                  builder,
                  1,
                  Size((style.size - separatorSize) / 2,
                      (style.size - separatorSize) / 2)),
              if (style.withSeparator)
                BuildSeparator(style,
                    width: (style.size - separatorSize) / 2,
                    height: style.separatorThickness),
              BuildAvatar(
                  items,
                  builder,
                  2,
                  Size((style.size - separatorSize) / 2,
                      (style.size - separatorSize) / 2))
            ],
          )
        ],
      );
    }
    //4 or more
    final Size _size = Size(
        (style.size - separatorSize) / 2, (style.size - separatorSize) / 2);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            BuildAvatar(items, builder, 0, _size),
            if (style.withSeparator)
              BuildSeparator(style,
                  width: style.separatorThickness, height: _size.height),
            BuildAvatar(items, builder, 1, _size)
          ],
        ),
        if (style.withSeparator)
          BuildSeparator(style,
              width: style.size, height: style.separatorThickness),
        Row(
          children: [
            BuildAvatar(items, builder, 2, _size),
            if (style.withSeparator)
              BuildSeparator(style,
                  width: style.separatorThickness, height: _size.height),
            BuildAvatar(items, builder, 3, _size)
          ],
        )
      ],
    );
  }
}
