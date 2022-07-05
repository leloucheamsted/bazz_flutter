import 'dart:ui' as ui;

import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:flutter/material.dart';

/// Wrapper that builds a FAB menu on top of [body] in a [Stack]
class HawkFabMenu extends StatefulWidget {
  final Widget body;
  final List<HawkFabMenuItem> items;
  final double fabSize;
  final double blur;
  final double? left;
  final double? top;
  final double? right;
  final double? bottom;
  final Widget? icon;
  final Color? fabColor;
  final Color? iconColor;
  final Alignment? alignment;

  HawkFabMenu({
    required this.body,
    required this.items,
    required this.fabSize,
    this.blur = 5.0,
    this.icon,
    this.fabColor,
    this.iconColor,
    this.left,
    this.top,
    this.right,
    this.bottom,
    this.alignment,
  }) {
    assert(items.isNotEmpty);
  }

  @override
  _HawkFabMenuState createState() => _HawkFabMenuState();
}

class _HawkFabMenuState extends State<HawkFabMenu>
    with TickerProviderStateMixin {
  /// To check if the menu is open
  bool _isOpen = false;

  /// The [Duration] for every animation
  final Duration _duration = const Duration(milliseconds: 500);

  /// Animation controller that animates the menu item
  late AnimationController _iconAnimationCtrl;

  @override
  void initState() {
    super.initState();
    _iconAnimationCtrl = AnimationController(
      vsync: this,
      duration: _duration,
    );
  }

  /// Closes the menu if open and vice versa
  void _toggleMenu() {
    setState(() {
      _isOpen = !_isOpen;
    });
    if (_isOpen) {
      _iconAnimationCtrl.forward();
    } else {
      _iconAnimationCtrl.reverse();
    }
  }

  /// If the menu is open and the device's back button is pressed then menu gets closed instead of going back.
  Future<bool> _preventPopIfOpen() async {
    if (_isOpen) {
      _toggleMenu();
      return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      child: Stack(
        children: <Widget>[
          widget.body,
          _isOpen ? _buildBlurWidget() : Container(),
          _isOpen ? _buildMenuItemList() : Container(),
          _buildMenuButton(context),
        ],
      ),
      onWillPop: _preventPopIfOpen,
    );
  }

  /// Returns animated list of menu items
  Widget _buildMenuItemList() {
    return Positioned(
      left: widget.left,
      top: widget.top,
      right: widget.right,
      bottom: widget.bottom! + widget.fabSize + 10,
      child: ScaleTransition(
        scale: AnimationController(
          vsync: this,
          value: 0.7,
          duration: _duration,
        )..forward(),
        child: SizeTransition(
          axis: Axis.vertical,
          sizeFactor: AnimationController(
            vsync: this,
            value: 0.5,
            duration: _duration,
          )..forward(),
          child: FadeTransition(
            opacity: AnimationController(
              vsync: this,
              value: 0.0,
              duration: _duration,
            )..forward(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: this
                  .widget
                  .items
                  .map<Widget>(
                    (item) => _MenuItemWidget(
                      item: item,
                      toggleMenu: _toggleMenu,
                      parentAlignment: widget.alignment as Alignment,
                    ),
                  )
                  .toList(),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the blur effect when the menu is opened
  Widget _buildBlurWidget() {
    return InkWell(
      onTap: _toggleMenu,
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(
          sigmaX: this.widget.blur,
          sigmaY: this.widget.blur,
        ),
        child: Container(
          color: Colors.black12,
        ),
      ),
    );
  }

  /// Builds the main floating action button of the menu to the bottom right
  /// On clicking of which the menu toggles
  Widget _buildMenuButton(BuildContext context) {
    return Positioned(
      left: widget.left,
      top: widget.top,
      right: widget.right,
      bottom: widget.bottom,
      child: CircularIconButton(
        buttonSize: widget.fabSize,
        color: widget.fabColor ?? Theme.of(context).primaryColor,
        onTap: _toggleMenu,
        child: widget.icon as Widget,
      ),
    );
  }
}

/// Builds widget for a single menu item
class _MenuItemWidget extends StatelessWidget {
  /// Contains details for a single menu item
  final HawkFabMenuItem item;
  final Alignment parentAlignment;

  /// A callback that toggles the menu
  final Function toggleMenu;

  _MenuItemWidget({
    required this.item,
    required this.toggleMenu,
    required this.parentAlignment,
  });

  /// Closes the menu and calls the function for a particular menu item
  void onTap() {
    this.toggleMenu();
    this.item.ontap();
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: this.onTap,
      child: Row(
        children: <Widget>[
          if (parentAlignment == Alignment.bottomRight)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: item.labelBackgroundColor,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10),
                  bottomLeft: Radius.circular(10),
                ),
              ),
              child: Text(
                this.item.label,
                style: TextStyle(color: item.labelColor),
              ),
            ),
          CircularIconButton(
            buttonSize: 50,
            onTap: this.onTap,
            color: this.item.color,
            child: this.item.icon,
          ),
          if (parentAlignment == Alignment.bottomLeft)
            Container(
              padding: EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: this.item.labelBackgroundColor,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(10),
                  bottomRight: Radius.circular(10),
                ),
              ),
              child: Text(
                this.item.label,
                style: TextStyle(color: this.item.labelColor),
              ),
            ),
        ],
      ),
    );
  }
}

/// Model for single menu item
class HawkFabMenuItem {
  /// Text label for for the menu item
  String label;

  /// Corresponding icon for the menu item
  Icon icon;

  /// Action that is to be performed on tapping the menu item
  Function ontap;

  /// Background color for icon
  Color color;

  /// Text color for label
  Color labelColor;

  /// Background color for label
  Color labelBackgroundColor;

  HawkFabMenuItem({
    required this.label,
    required this.ontap,
    required this.icon,
    required this.color,
    required this.labelBackgroundColor,
    required this.labelColor,
  });
}
