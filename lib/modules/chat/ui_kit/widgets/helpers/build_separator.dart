import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/group_avatar.dart';
import 'package:flutter/material.dart';

class BuildSeparator extends StatelessWidget {
  const BuildSeparator(this.style, {Key? key, this.width = 0, this.height = 0})
      : super(key: key);

  final GroupAvatarStyle style;
  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      color: style.separatorColor ?? Theme.of(context).backgroundColor,
    );
  }
}
