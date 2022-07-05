import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/modules/auth_module/auth_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

//TODO: pass external FocusNode to manage focus selectively
class BazzTextInput extends StatefulWidget {
  final BorderRadius? cornerRadius;
  final double? height;
  final Color? backgroundColor, accentColor, textColor, prefixIconColor;
  final String? placeholder;
  final Icon? prefixIcon;
  final Widget? suffixWidget;
  final TextInputType? inputType;
  final Duration? duration;
  final VoidCallback? onClickSuffix;
  final TextStyle? textStyle;
  final bool? autofocus, autocorrect, enabled, shadow, isPasswordVisible;
  final int? maxLength;
  final ValueChanged<String>? onChanged, onSubmitted;
  final VoidCallback? onEditingComplete;
  final VoidCallback? togglePasswordVisibility;
  final GestureTapCallback? onTap;
  final TextEditingController? controller;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  const BazzTextInput({
    this.height,
    this.prefixIcon,
    this.inputType,
    this.controller,
    this.suffixWidget,
    this.duration = const Duration(milliseconds: 100),
    this.backgroundColor,
    this.prefixIconColor,
    this.cornerRadius = const BorderRadius.all(Radius.circular(7)),
    this.textColor,
    this.accentColor,
    this.placeholder = "Placeholder",
    this.onClickSuffix,
    this.textStyle,
    this.autofocus = false,
    this.autocorrect = false,
    this.enabled = true,
    this.shadow = false,
    this.isPasswordVisible = false,
    this.maxLength = 36,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.onEditingComplete,
    this.togglePasswordVisibility,
    this.textInputAction,
    this.focusNode,
  })  : assert(height != null),
        assert(prefixIcon != null);

  @override
  _BazzTextInputState createState() => _BazzTextInputState();
}

class _BazzTextInputState extends State<BazzTextInput> {
  late FocusNode _focusNode;

  @override
  void initState() {
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode.addListener(() => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  Widget _suffixButton() {
    return InkWell(
      onTap: () {
        widget.togglePasswordVisibility!();
        FocusManager.instance.primaryFocus?.requestFocus();
      },
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 15, 10),
        child: FaIcon(
          widget.isPasswordVisible!
              ? FontAwesomeIcons.eye
              : FontAwesomeIcons.eyeSlash,
          color: AppColors.lightText,
          size: 17,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      height: widget.height,
      decoration: BoxDecoration(
        boxShadow: [
          if (widget.shadow!)
            const BoxShadow(
              color: Colors.black12,
              blurRadius: 3,
            )
        ],
        borderRadius: widget.cornerRadius,
        border: Border.all(color: AppColors.inputBorder),
        color: widget.backgroundColor ?? AppTheme().colors.inputBg,
      ),
      duration: widget.duration!,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.only(left: 5),
            width: 50,
            alignment: Alignment.center,
            child: FaIcon(
              widget.prefixIcon?.icon,
              color: _focusNode.hasFocus
                  ? widget.accentColor ?? AppColors.primaryAccent
                  : widget.prefixIconColor ?? AppTheme().colors.inputText,
              size: 18,
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              obscureText: widget.inputType == TextInputType.visiblePassword &&
                  !widget.isPasswordVisible!,
              keyboardType: widget.inputType,
              inputFormatters: [FilteringTextInputFormatter.deny(' ')],
              style: widget.textStyle ?? AppTheme().typography.inputTextStyle,
              autofocus: widget.autofocus!,
              autocorrect: widget.autocorrect!,
              focusNode: _focusNode,
              enabled: widget.enabled,
              maxLength: widget.maxLength,
              onChanged: widget.onChanged,
              onTap: widget.onTap,
              onSubmitted: widget.onSubmitted,
              onEditingComplete: widget.onEditingComplete,
              textInputAction: widget.textInputAction,
              decoration: InputDecoration(
                floatingLabelBehavior: FloatingLabelBehavior.never,
                alignLabelWithHint: true,
                hintStyle: AppTheme().typography.inputTextStyle,
                hintText: widget.placeholder,
                counterText: '',
                border: InputBorder.none,
              ),
              cursorColor: AppTheme().colors.inputCursor,
            ),
          ),
          widget.suffixWidget ??
              (widget.inputType == TextInputType.visiblePassword
                  ? _focusNode.hasFocus
                      ? _suffixButton()
                      : widget.controller!.text.isNotEmpty
                          ? _suffixButton()
                          : const SizedBox()
                  : const SizedBox()),
        ],
      ),
    );
  }
}
