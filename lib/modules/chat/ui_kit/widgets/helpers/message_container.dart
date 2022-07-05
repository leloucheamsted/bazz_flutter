import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/styling/message_style.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/enums.dart';
import 'package:flutter/material.dart';

class MessageContainerStyle {}

class MessageContainer extends StatelessWidget {
  final Widget child;

  final EdgeInsets? padding;

  final BoxDecoration? decoration;

  final BoxConstraints? constraints;

  final Color? color;

  const MessageContainer({
    required this.child,
    this.padding,
    this.decoration,
    this.constraints,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
        clipBehavior: Clip.antiAlias,
        constraints: constraints ??
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        padding:
            padding ?? const MessageStyle(selectionColor: Colors.black).padding,
        decoration: decoration ?? messageDecoration(context, color: color!),
        child: child);
  }
}

BoxDecoration messageDecoration(BuildContext context,
    {Color? color,
    double radius = 8.0,
    double tightRadius = 0.0,
    MessagePosition messagePosition = MessagePosition.isolated,
    MessageFlow messageFlow = MessageFlow.outgoing}) {
  double topLeftRadius;
  double topRightRadius;
  double botLeftRadius;
  double botRightRadius;

  final bool isTopSurrounded = messagePosition == MessagePosition.surrounded ||
      messagePosition == MessagePosition.surroundedTop;
  if (messageFlow == MessageFlow.outgoing) {
    botLeftRadius = radius;
    botRightRadius = 0;
    topLeftRadius = radius;
    topRightRadius = isTopSurrounded ? tightRadius : radius;
  } else {
    botLeftRadius = 0;
    botRightRadius = radius;
    topLeftRadius = isTopSurrounded ? tightRadius : radius;
    topRightRadius = radius;
  }

  return BoxDecoration(
      color: color ??
          (messageFlow == MessageFlow.outgoing
              ? AppTheme().colors.outgoingChatMsg
              : AppTheme().colors.incomingChatMsg),
      borderRadius: BorderRadius.only(
          topLeft: Radius.circular(topLeftRadius),
          topRight: Radius.circular(topRightRadius),
          bottomLeft: Radius.circular(botLeftRadius),
          bottomRight: Radius.circular(botRightRadius)));
}
