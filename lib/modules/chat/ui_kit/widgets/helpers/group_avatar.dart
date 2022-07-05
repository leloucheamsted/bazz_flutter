import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/build_group_avatar.dart';
import 'package:flutter/material.dart';

/// Builder called to construct the Image widget
/// [imageIndex] is the position of the image inside the [GroupAvatar] as follows:
///
///   index 0 || index 1
///   ----------------
///   index 2 || index 3
///
/// Use [size] to determine the size of the image you should load
typedef GroupAvatarWidgetBuilder<T> = Widget Function(
    BuildContext context, int imageIndex, Size size, List<T> items);

enum GroupAvatarShape { circle, rectangle }

class GroupAvatarStyle {
  /// The shape of your GroupAvatar;
  /// When passing [GroupAvatarShape.rectangle], you can also specify [borderRadius]
  final GroupAvatarShape shape;

  /// The [Radius] when [shape] == [GroupAvatarShape.rectangle]
  /// Ignored if [shape] == [GroupAvatarShape.circle]
  final double borderRadius;

  /// Set to true if you wish to display a separator between avatars
  final bool withSeparator;

  /// If [withSeparator] == false
  final Color? separatorColor;

  /// Ignore if [withSeparator] == false
  final double separatorThickness;

  /// The size of this widget
  final double size;

  const GroupAvatarStyle(
      {this.size = 56.0,
      this.shape = GroupAvatarShape.rectangle,
      this.borderRadius = 20.0,
      this.withSeparator = false,
      this.separatorColor,
      this.separatorThickness = 1.5});
}

/// A widget the display multiple avatars inside a single widget
class GroupAvatar<T> extends StatelessWidget {
  const GroupAvatar(
      {Key? key,
      required this.items,
      required this.builder,
      GroupAvatarStyle? style})
      : style = style ?? const GroupAvatarStyle(),
        super(key: key);

  /// The items, typically a List of Users [IUser]
  final List<T> items;

  /// This builder will be called every time an image needs to be loaded;
  /// It is your image loader
  final GroupAvatarWidgetBuilder builder;

  /// The style configuration for the widget
  final GroupAvatarStyle style;

  @override
  Widget build(BuildContext context) {
    final child = SizedBox(
        width: style.size,
        height: style.size,
        child: BuildGroupAvatar(style, items, builder));

    return style.shape == GroupAvatarShape.circle
        ? ClipOval(clipBehavior: Clip.antiAlias, child: child)
        : ClipRRect(
            child: child,
            clipBehavior: Clip.antiAlias,
            borderRadius:
                BorderRadius.all(Radius.circular(style.borderRadius)));
  }
}
