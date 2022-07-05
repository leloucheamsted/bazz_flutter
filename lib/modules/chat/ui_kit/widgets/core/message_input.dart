import 'dart:async';

import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/modules/chat/chat_controller.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/enums.dart';
import 'package:bazz_flutter/services/snack_bar_display.dart';
import 'package:bazz_flutter/shared_widgets/circular_icon_button.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';

/// A typing handler that will emit a [TypingEvent] when necessary
/// Four steps are required to use it:
/// 1. Add [MessageInputTypingHandler] as a mixin to your class
/// 2. Override [typingCallback]
/// 3. Override [textController]
/// 4. Call [attachTypingListener] when creating your class
/// [ChatMessageInput] will give you an example.
abstract class MessageInputTypingHandler {
  /// If the user starts typing and stops for [idleStopDelay],
  /// a [TypingEvent.stop] will be emitted
  /// Defaults to 5 seconds, override at will;
  Duration idleStopDelay = const Duration(seconds: 3);

  /// Called when the user starts typing or stops typing
  Function(TypingEvent event) get typingCallback;

  TextEditingController get textController;

  /// Keep track internally of the current typing status
  bool _isTyping = false;

  /// The internal timer called after [idleStopDelay] to trigger [TypingEvent.stop]
  Timer? _timer;

  /// Call this method in your [initState]
  void attachTypingListener() =>
      textController.addListener(_onTextChangedTypingListener);

  void _onTextChangedTypingListener() {
    if (textController.text != null && textController.text.isNotEmpty) {
      if (!_isTyping) {
        //set status to typing and emit new status
        _isTyping = true;
        if (typingCallback != null) typingCallback(TypingEvent.start);
      }
      //start or reset the stop delay
      _timer?.cancel();
      _timer = Timer(idleStopDelay, () {
        _isTyping = false;
        if (typingCallback != null) typingCallback(TypingEvent.stop);
      });
    } else {
      //text changed to nothing, emit stop event
      _isTyping = false;
      if (typingCallback != null) typingCallback(TypingEvent.stop);
    }
  }
}

class ChatMessageInput extends StatefulWidget {
  ChatMessageInput({
    Key? key,
    required this.textController,
    required this.sendCallback,
    required this.height,
    this.typingCallback,
    this.focusNode,
  }) : super(key: key);

  final double height;

  /// Called when the user sends a (non empty) message
  final Function(String text, ChatMessage quotedMessage) sendCallback;

  /// Triggered by [MessageInputTypingHandler] on typing events
  late Function(TypingEvent event)? typingCallback;
  final TextEditingController textController;
  late FocusNode? focusNode;

  @override
  _ChatMessageInputState createState() => _ChatMessageInputState();
}

/// Uses [MessageInputTypingHandler] as a mixin to handle typing events
class _ChatMessageInputState extends State<ChatMessageInput>
    with TickerProviderStateMixin, MessageInputTypingHandler {
  late AnimationController _animationControllerCheckMark;
  late AnimationController _animationControllerSend;
  late Animation<double> _animationCheckmark;
  late Animation<double> _animationSend;
  bool isAnimating = false;
  final double extendedHeight = 80;

  /// Supply the [TextEditingController] to [MessageInputTypingHandler]
  @override
  TextEditingController get textController => widget.textController;

  /// Supply the callback to [MessageInputTypingHandler]
  @override
  Function(TypingEvent event) get typingCallback => widget.typingCallback!;

  late StreamSubscription<ChatMessage> _quotedMessageSub;

  @override
  void initState() {
    /// Attach the [MessageInputTypingHandler] listener to the [TextEditingController].
    /// This step is mandatory to make MessageInputTypingHandler work.
    attachTypingListener();
    _quotedMessageSub = ChatController.to.quotedMessage$.listen((item) {
      if (item != null) openKeyboard();
    });
    _animationControllerCheckMark = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _animationControllerSend = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 150));
    _animationCheckmark =
        Tween<double>(begin: 0, end: 1).animate(_animationControllerCheckMark);
    _animationSend =
        Tween<double>(begin: 1, end: 0).animate(_animationControllerSend);
    super.initState();
  }

  @override
  void dispose() {
    _quotedMessageSub.cancel();
    _animationControllerCheckMark.dispose();
    _animationControllerSend.dispose();
    super.dispose();
  }

  void sendMessage() {
    if (textController.text != null &&
        textController.text.isNotEmpty &&
        !isAnimating) {
      widget.sendCallback(textController.text, ChatController.to.quotedMessage);
      textController.clear();

      isAnimating = true;
      _animationControllerSend
          .forward()
          .then((value) => _animationControllerCheckMark.forward());

      Future.delayed(const Duration(seconds: 2), () {
        _animationControllerCheckMark.reverse().then((value) =>
            _animationControllerSend
                .reverse()
                .then((value) => isAnimating = false));
      });
    }
  }

  void openKeyboard() {
    FocusScope.of(context).requestFocus(widget.focusNode);
  }

  @override
  Widget build(BuildContext context) {
    const inputBorder = UnderlineInputBorder(
      borderSide: BorderSide(color: AppColors.inputBorder),
    );
    return Obx(() {
      final isQuoting = ChatController.to.quotedMessage != null;
      return Container(
        color: AppTheme().colors.inputBg,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isQuoting) _buildQuoteContainer(),
            if (isQuoting) Divider(height: 1, color: AppTheme().colors.divider),
            Row(
              children: [
                CircularIconButton(
                  onTap: () {
                    if (ChatController.to.isUploading) {
                      Get.showSnackbarEx(
                        GetBar(
                          //TODO: localize message
                          message: 'Please, wait until uploading is finished',
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    } else {
                      _buildBottomSheetPicker();
                    }
                  },
                  buttonSize: 40,
                  child: const Icon(Icons.attach_file_outlined,
                      color: AppColors.greyIcon),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: textController,
                    focusNode: widget.focusNode,
                    // keyboardType: TextInputType.multiline,
                    // scrollPhysics: const AlwaysScrollableScrollPhysics(),
                    // minLines: 2,
                    // maxLines: 2,
                    decoration: const InputDecoration(
                      enabledBorder: inputBorder,
                      focusedBorder: inputBorder,
                    ),
                    style: AppTheme().typography.inputTextStyle,
                    onSubmitted: (_) => sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                CircularIconButton(
                  onTap: sendMessage,
                  color: ChatController.to.isConnecting$() &&
                          ChatController.to.isCurrentChatEmpty
                      ? AppTheme().colors.disabledButton
                      : AppColors.primaryAccent,
                  buttonSize: 32,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      ScaleTransition(
                          scale: _animationCheckmark,
                          child: const Icon(
                            Icons.check_rounded,
                            color: AppColors.brightText,
                          )),
                      ScaleTransition(
                          scale: _animationSend,
                          child: const Icon(
                            Icons.send_rounded,
                            color: AppColors.brightText,
                          )),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
            const SizedBox(height: 12),
          ],
        ),
      );
    });
  }

  Widget _buildQuoteContainer() {
    return Container(
        padding: const EdgeInsets.fromLTRB(5, 8, 5, 8),
        decoration: BoxDecoration(
          border: Border(
            left: BorderSide(width: 3, color: AppTheme().colors.primaryButton),
          ),
        ),
        child: Row(children: [
          const SizedBox(width: 5),
          Expanded(
              child: Stack(children: [
            Row(children: [
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                FitHorizontally(
                    alignment: Alignment.centerLeft,
                    shrinkLimit: .9,
                    child: TextOneLine(
                        ChatController.to.quotedMessage.author.name,
                        style: AppTheme().typography.chatQuoteTitleStyle)),
                FitHorizontally(
                    alignment: Alignment.centerLeft,
                    shrinkLimit: .9,
                    child: TextOneLine(ChatController.to.quotedMessage.text,
                        style: AppTheme().typography.bgText4Style))
              ]),
            ]),
            Positioned(
              right: 20,
              top: -5,
              child: SizedBox(
                height: 30,
                width: 50,
                child: CachedNetworkImage(
                    imageUrl: ChatController.to.quotedMessage.attachmentUrl),
              ),
            ),
            Positioned(
              right: -1,
              top: -5,
              child: CircularIconButton(
                onTap: ChatController.to.clearQuotedMessage,
                buttonSize: 25,
                child: Icon(Icons.close,
                    color: AppTheme().colors.primaryButton, size: 15),
              ),
            ),
          ]))
        ]));
  }

  void _buildBottomSheetPicker() {
    Get.bottomSheet(
      Container(
        color: AppTheme().colors.infoWindowBg,
        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 15),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            GestureDetector(
              onTap: () {
                ChatController.to.takePhoto();
              },
              child: Row(
                children: [
                  Container(
                    alignment: Alignment.center,
                    width: 40,
                    child: const Icon(
                      Icons.photo_camera_rounded,
                      color: AppColors.greyIcon,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "AppLocalizations.of(context).takePhoto",
                    style: AppTheme().typography.bgText3Style,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                ChatController.to.takeVideo();
              },
              child: Row(
                children: [
                  Container(
                    alignment: Alignment.center,
                    width: 40,
                    child: const Icon(
                      Icons.videocam_rounded,
                      color: AppColors.greyIcon,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    " AppLocalizations.of(context).shootVideo",
                    style: AppTheme().typography.bgText3Style,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                ChatController.to.pickMedia();
              },
              child: Row(
                children: [
                  Container(
                    alignment: Alignment.center,
                    width: 40,
                    child: const FaIcon(
                      FontAwesomeIcons.photoVideo,
                      color: AppColors.greyIcon,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "AppLocalizations.of(context).chooseFromGallery",
                    style: AppTheme().typography.bgText3Style,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            GestureDetector(
              onTap: () {
                ChatController.to.pickPdf();
              },
              child: Row(
                children: [
                  Container(
                    alignment: Alignment.center,
                    width: 40,
                    child: const FaIcon(
                      FontAwesomeIcons.filePdf,
                      color: AppColors.greyIcon,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    "AppLocalizations.of(context).choosePdfDocument",
                    style: AppTheme().typography.bgText3Style,
                  ),
                ],
              ),
            ),
            // const SizedBox(width: 20),
            // Column(
            //   mainAxisSize: MainAxisSize.min,
            //   children: [
            //     CircularIconButton(
            //       color: AppColors.primarySwatch,
            //       buttonSize: 40,
            //       onTap: () {
            //         ChatController.to.pickFile();
            //       },
            //       child: const Icon(
            //         Icons.attach_file_rounded,
            //         color: AppColors.brightText,
            //       ),
            //     ),
            //     const SizedBox(height: 5),
            //     Text(
            //       'File',
            //       style: AppTheme().typography.buttonTextStyle.copyWith(color: AppColors.primaryText),
            //     ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }
}
