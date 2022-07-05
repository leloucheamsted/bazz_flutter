import 'dart:math' as math show sqrt;

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/animation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_neumorphic/flutter_neumorphic.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_webrtc/webrtc.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:get/get.dart';
import 'package:line_awesome_flutter/line_awesome_flutter.dart';

class PTTButton extends StatefulWidget {
  const PTTButton({Key? key}) : super(key: key);

  @override
  _PTTButtonState createState() => _PTTButtonState();
}

class _PTTButtonState extends State<PTTButton> with TickerProviderStateMixin {
  late AnimationController _animController;
  final animationWidth = 10;
  final _buttonSizeCoefficient = 0.85;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: LayoutBuilder(
        builder: (_, constraints) {
          final buttonDiameter = constraints.maxHeight * _buttonSizeCoefficient;
          return Obx(() {
            final streamingState = HomeController.to.txState$.value.state;
            final broadcastingUser = HomeController.to.txState$.value.user;
            final shouldAnimate = HomeController.to.isRecordingOfflineMessage ||
                streamingState == StreamingState.sending ||
                streamingState == StreamingState.receiving;
            final isPttDisabled = HomeController.to.isPttDisabled;

            final ringColor = () {
              if (isPttDisabled) return AppTheme().colors.disabledButton;

              switch (streamingState) {
                case StreamingState.preparing:
                  return Colors.amber;
                case StreamingState.sending:
                  return AppColors.pttTransmitting;
                case StreamingState.receiving:
                  return AppColors.pttReceiving;
                case StreamingState.cleaning:
                  return AppTheme().colors.disabledButton;
                default:
                  return AppColors.pttIdle;
              }
            }();

            if (shouldAnimate) {
              _animController.repeat();
            } else {
              _animController.stop();
            }
            return Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  painter: CirclePainter(
                    // CurvedAnimation(parent: _animController, curve: Curves.ease),
                    _animController,
                    color: ringColor,
                    waves: 4,
                  ),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: shouldAnimate
                        ? buttonDiameter + animationWidth
                        : buttonDiameter - (animationWidth * 5),
                    height: shouldAnimate
                        ? buttonDiameter + animationWidth
                        : buttonDiameter - (animationWidth * 5),
                  ),
                ),
                _buildPttButton(streamingState, broadcastingUser!,
                    buttonDiameter, ringColor),
              ],
            );
          });
        },
      ),
    );
  }

  Widget _buildPttButton(
    StreamingState streamingState,
    RxUser broadcastingUser,
    double buttonDiameter,
    Color color,
  ) {
    return Obx(
      () {
        return Listener(
          onPointerDown: (_) {
            if (!HomeController.to.canTalk ||
                HomeController.to.isPttKeyPressed$) return;
            HomeController.to.onPttPress();
          },
          onPointerUp: (_) {
            //if (HomeController.to.isPttKeyPressed$) return;
            //HomeController.to.onPttRelease();
          },
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: buttonDiameter,
                height: buttonDiameter,
                decoration: BoxDecoration(
                  border: Border.all(
                    width: 15,
                    color: color,
                  ),
                  shape: BoxShape.circle,
                  color: AppTheme().colors.mainBackground,
                ),
              ),
              SizedBox(
                width: buttonDiameter - 38,
                height: buttonDiameter - 38,
                child: Neumorphic(
                  duration: Duration.zero,
                  style: NeumorphicStyle(
                    color: AppTheme().colors.pttBackground,
                    boxShape: const NeumorphicBoxShape.circle(),
                    depth: HomeController.to.isPttPressed$ ? -2.0 : 2.0,
                    shape: NeumorphicShape.convex,
                    surfaceIntensity: .5,
                    oppositeShadowLightSource: true,
                    shadowLightColor: AppTheme().colors.mainBackground,
                  ),
                  child: Center(
                    child: HomeController.to.isInRecordingMode
                        ? Padding(
                            padding: const EdgeInsets.only(top: 11),
                            child: Icon(
                              LineAwesomeIcons.microphone,
                              color: color,
                              size: 70,
                            ),
                          )
                        : SvgPicture.asset(
                            'assets/images/mic_broadcast_icon.svg',
                            color: color,
                            width: 70),
                  ),
                ),
              ),
              if (streamingState == StreamingState.receiving &&
                  broadcastingUser != null &&
                  (!AppSettings().videoModeEnabled ||
                      (AppSettings().videoModeEnabled &&
                          !HomeController.to.remoteVideoDisplay.value)))
                ClipOval(
                  child: Container(
                    height: buttonDiameter - 20,
                    width: buttonDiameter - 20,
                    color: AppTheme().colors.mainBackground,
                    child: broadcastingUser.avatar != null &&
                            broadcastingUser.avatar.isNotEmpty
                        ? CachedNetworkImage(imageUrl: broadcastingUser.avatar)
                        : const FittedBox(
                            child: Icon(
                            Icons.person,
                            color: AppColors.primaryAccent,
                          )),
                  ),
                ),
              if (streamingState == StreamingState.receiving &&
                  broadcastingUser != null &&
                  AppSettings().videoModeEnabled &&
                  HomeController.to.remoteVideoDisplay.value)
                ClipOval(
                  child: Container(
                    height: buttonDiameter - 20,
                    width: buttonDiameter - 20,
                    color: AppTheme().colors.mainBackground,
                    child: GetBuilder<HomeController>(
                        id: 'videoDisplayId',
                        builder: (_) {
                          return FutureBuilder(builder: (context, snapshot) {
                            return Container(
                                width: 90.0,
                                height: 120.0,
                                decoration:
                                    const BoxDecoration(color: Colors.black54),
                                child: RTCVideoView(
                                    HomeController.to.remoteRenderer));
                          });
                        },
                        dispose: (_) {}),
                  ),
                ),
              if (streamingState == StreamingState.receiving)
                Positioned(
                  top: 36,
                  right: 36,
                  child: Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: const BoxDecoration(
                      color: AppColors.darkIcon,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 20,
                          offset: Offset(0, 10),
                        )
                      ],
                      shape: BoxShape.circle,
                    ),
                    child: const FaIcon(
                      FontAwesomeIcons.volumeUp,
                      size: 22,
                      color: AppColors.pttReceiving,
                    ),
                  ),
                ),
              if (streamingState == StreamingState.receiving)
                Positioned(
                  bottom: 45,
                  child: SizedBox(
                    width: buttonDiameter - 50,
                    child: Text(
                      '${broadcastingUser.firstName.capitalize} ${broadcastingUser.lastName.capitalize}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.center,
                      style: AppTypography.subtitle6TextStyle.copyWith(
                        fontSize: 16,
                        height: 1.2,
                        shadows: [
                          const Shadow(
                            blurRadius: 15.0,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              /*if (HomeController.to.isRecordingOfflineMessage || streamingState == StreamingState.sending)
                Positioned(
                  top: 60,
                  child: Text(
                    HomeController.to.isRecordingOfflineMessage
                        ? LocalizationService().localizationContext().recording.toUpperCase()
                        : streamingState == StreamingState.sending
                            ? LocalizationService().localizationContext().broadcasting.toUpperCase()
                            : '',
                    textAlign: TextAlign.center,
                    style: AppTypography.caption2TextStyle.copyWith(color: color, fontSize: 14),
                  ),
                ),*/
            ],
          ),
        );
      },
    );
  }
}

/*if(AppSettings().videoModeEnabled)
Positioned(
top: 10,
left: 10,
child:
GetBuilder<HomeController>(
id: 'videoDisplayId',
builder: (_) {
return FutureBuilder(

builder: (context, snapshot) {
*/ /* if (snapshot.connectionState != ConnectionState.done) {
                              return const Center(child: Text('Initializing map...'));
                            }*/ /*

return Container(
width: 90.0,
height: 120.0,
decoration: const BoxDecoration(color: Colors.black54),
child: RTCVideoView(controller.remoteRenderer)
);
});
},
dispose: (_) {})),*/
class CirclePainter extends CustomPainter {
  CirclePainter(
    this._animation, {
    required this.color,
    this.waves,
  }) : super(repaint: _animation);

  final Color color;
  final Animation<double> _animation;
  late int? waves;

  void circle(Canvas canvas, Rect rect, double value) {
    final double opacity = (1 - (value / 5.0)).clamp(0.0, 1.0).toDouble();
    final Color _color = color.withOpacity(opacity);
    final double size = rect.width / 2;
    final double area = size * size;
    final double radius = math.sqrt(area * value / 3.5);
    final Paint paint = Paint()..color = _color;
    canvas.drawCircle(rect.center, radius, paint);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final Rect rect = Rect.fromLTRB(0.0, 0.0, size.width, size.height);
    for (int _waves = waves!; _waves >= 0; _waves--) {
      circle(canvas, rect, _waves + _animation.value);
    }
  }

  @override
  bool shouldRepaint(CirclePainter oldDelegate) => true;
}
