import 'package:bazz_flutter/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

//TODO: pass external FocusNode to manage focus selectively
class BazzMaterialTextInput extends StatefulWidget {
  final double? height;
  final Color? backgroundColor, accentColor, textColor, prefixIconColor;
  final String? placeholder;
  final Icon? prefixIcon;
  final Widget? suffixWidget;
  final TextInputType? inputType;
  final Duration? duration;
  final VoidCallback? onClickSuffix;
  final TextStyle? textStyle;
  final bool? autofocus, autocorrect, enabled, shadow;
  final int? maxLength;
  final ValueChanged<String>? onChanged, onSubmitted;
  final VoidCallback? onEditingComplete;
  final GestureTapCallback? onTap;
  final TextEditingController? controller;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;

  const BazzMaterialTextInput({
    this.height,
    this.prefixIcon,
    this.inputType,
    this.controller,
    this.suffixWidget,
    this.duration = const Duration(milliseconds: 100),
    this.backgroundColor,
    this.prefixIconColor,
    this.textColor,
    this.accentColor,
    this.placeholder = "Placeholder",
    this.onClickSuffix,
    this.textStyle,
    this.autofocus = false,
    this.autocorrect = false,
    this.enabled = true,
    this.shadow = false,
    this.maxLength = 36,
    this.onChanged,
    this.onTap,
    this.onSubmitted,
    this.onEditingComplete,
    this.textInputAction,
    this.focusNode,
  })  : assert(height != null),
        assert(prefixIcon != null);

  @override
  _BazzMaterialTextInputState createState() => _BazzMaterialTextInputState();
}

class _BazzMaterialTextInputState extends State<BazzMaterialTextInput> {
  bool _isPasswordVisible = false;
  FocusNode? _focusNode;

  @override
  void initState() {
    _focusNode = widget.focusNode ?? FocusNode();
    _focusNode!.addListener(() => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    _focusNode!.dispose();
    super.dispose();
  }

  void _togglePasswordVisibility() =>
      setState(() => _isPasswordVisible = !_isPasswordVisible);

  Widget _suffixButton() {
    return InkWell(
      onTap: _togglePasswordVisibility,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 10, 15, 10),
        child: FaIcon(
          _isPasswordVisible ? FontAwesomeIcons.eye : FontAwesomeIcons.eyeSlash,
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
      color: widget.backgroundColor ?? AppTheme().colors.inputBg,
      duration: widget.duration!,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Container(
            padding: const EdgeInsets.only(left: 5),
            width: 50,
            alignment: Alignment.center,
            child: FaIcon(
              widget.prefixIcon!.icon,
              color: _focusNode!.hasFocus
                  ? widget.accentColor ?? AppColors.primaryAccent
                  : widget.prefixIconColor ?? AppTheme().colors.inputText,
              size: 18,
            ),
          ),
          Expanded(
            child: TextField(
              controller: widget.controller,
              obscureText: widget.inputType == TextInputType.visiblePassword &&
                  !_isPasswordVisible,
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
                  ? _focusNode!.hasFocus
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
