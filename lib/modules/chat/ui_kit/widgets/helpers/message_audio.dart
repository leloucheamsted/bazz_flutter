import 'package:bazz_flutter/models/chat_message.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/enums.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/utils/extensions.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_container.dart';
import 'package:bazz_flutter/modules/chat/ui_kit/widgets/helpers/message_footer.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

/// A default Widget that can be used to play audio files
/// This is more an example to give you an idea how to structure your own Widget
class ChatMessageAudio extends StatefulWidget {
  final int index;
  final ChatMessage message;
  final MessagePosition messagePosition;
  final MessageFlow messageFlow;

  const ChatMessageAudio(
      this.index, this.message, this.messagePosition, this.messageFlow);

  @override
  _ChatMessageAudioState createState() => _ChatMessageAudioState();
}

class _ChatMessageAudioState extends State<ChatMessageAudio> {
  AudioPlayer? _audioPlayer;
  Future<Duration>? _duration;
  Duration? _position;

  Duration get _timeLeft {
    final Duration _totalDuration = _audioPlayer?.duration ?? Duration();
    final Duration _currentPosition = _position ?? Duration();
    return Duration(
        milliseconds:
            _totalDuration.inMilliseconds - _currentPosition.inMilliseconds);
  }

  @override
  void initState() {
    _audioPlayer = AudioPlayer();
    _duration = _audioPlayer!.setFilePath(widget.message.attachmentUrl)
        as Future<Duration>?;

    _audioPlayer?.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        //pause & seek position 0
        if (mounted) {
          _audioPlayer!.pause();
          _audioPlayer!.seek(Duration()).then((e) => setState(() {}));
        }
      }
    });

    _audioPlayer!.positionStream.listen((event) {
      if (mounted)
        setState(() {
          _position = event;
        });
    });
    super.initState();
  }

  /// Called when the user interacts with the slider.
  /// -seek the new value in the audio file
  /// -play the audio file if it was paused/not started
  void onSliderValueChanged(double milliseconds) {
    _audioPlayer!.seek(Duration(milliseconds: milliseconds.toInt()));
    _audioPlayer!.play();
  }

  void onPlayPausePressed() {
    if (_audioPlayer!.playing) {
      _audioPlayer!.pause();
    } else {
      _audioPlayer!.play();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: _duration,
        builder: (BuildContext context, snapshot) {
          Widget _durationWidget;
          final Duration _dur = snapshot.data as Duration;
          if (snapshot.connectionState == ConnectionState.done &&
              snapshot.data != null) {
            _durationWidget = Text(_timeLeft.verboseDuration,
                style: const TextStyle(color: Colors.black));
          } else {
            _durationWidget = Container();
          }

          final Widget _footer = Row(
            children: [
              _durationWidget,
              const Spacer(),
              MessageFooter(widget.message)
            ],
          );

          return MessageContainer(
              constraints: BoxConstraints(
                  maxHeight: 80,
                  maxWidth: MediaQuery.of(context).size.width * 0.8),
              decoration: messageDecoration(context,
                  messagePosition: widget.messagePosition,
                  messageFlow: widget.messageFlow),
              child: Row(
                children: [
                  GestureDetector(
                      onTap: onPlayPausePressed,
                      child: Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: Icon(
                              _audioPlayer!.playing
                                  ? Icons.pause
                                  : Icons.play_arrow,
                              size: 48,
                              color: Colors.black))),
                  Expanded(
                      child: Stack(
                    children: [
                      SliderTheme(
                          data: SliderThemeData.fromPrimaryColors(
                                  primaryColor: Colors.black87,
                                  primaryColorDark: Colors.black87,
                                  primaryColorLight: Colors.black87,
                                  valueIndicatorTextStyle: const TextStyle())
                              .copyWith(
                                  overlayShape: SliderComponentShape.noOverlay),
                          child: Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: Slider.adaptive(
                                  value:
                                      _position?.inMilliseconds.toDouble() ?? 0,
                                  max: _dur.inMilliseconds.toDouble(),
                                  onChanged: onSliderValueChanged))),
                      Align(alignment: Alignment.bottomCenter, child: _footer)
                    ],
                  ))
                ],
              ));
        });
  }

  @override
  void dispose() {
    _audioPlayer!.dispose();
    super.dispose();
  }
}
