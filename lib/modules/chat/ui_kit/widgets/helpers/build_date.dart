import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/core/messages_list_tile.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/date_label.dart';
import 'package:flutter/material.dart';

class BuildDate extends StatelessWidget {
  const BuildDate(this.item, this.builders, {Key? key}) : super(key: key);

  final ChatMessage item;
  final MessageTileBuilders builders;

  @override
  Widget build(BuildContext context) {
    if (builders.customDateBuilder != null) {
      return builders.customDateBuilder!.call(context, item.createdAt);
    }
    return DateLabel(date: item.createdAt);
  }
}
