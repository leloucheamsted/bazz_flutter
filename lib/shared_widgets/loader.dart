import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:get/get_rx/src/rx_types/rx_types.dart';
import 'package:screen/screen.dart';
import 'dart:async';

// It's slightly adjusted https://pub.dev/packages/flutter_overlay_loader
class Loader extends StatelessWidget {
  static OverlayEntry? _currentLoader;

  const Loader._(this._progressIndicator, this._themeData);

  final Widget _progressIndicator;
  final ThemeData _themeData;
  static OverlayState? _overlayState;

  static bool get isVisible => _currentLoader != null;
  static final RxString _subTitle = "".obs;
  static double? _currentBrightness;
  static Timer? _keeperTimer;
  static bool _screenKeeper = false;
  static void updateSubTitle(String title) {
    try {
      _subTitle.value = title;
    } catch (e, s) {
      TelloLogger().e("Failed update sub title $e", stackTrace: s);
    }
  }

  static void _startBrightnessKeeper() {
    _keeperTimer?.cancel();
    _keeperTimer = Timer(5.seconds, () async {
      TelloLogger().i('_startBrightnessKeeper status 00000000000000');
      if (_keeperTimer != null) {
        TelloLogger().i('_startBrightnessKeeper status 1111111111111');
        await Screen.setBrightness(0.01);
      }
    });
  }

  static void _stopBrightnessKeeper() {
    TelloLogger().i('_stopBrightnessKeeper status $_currentLoader');
    _keeperTimer?.cancel();
    _keeperTimer = null;
    Screen.setBrightness(_currentBrightness ?? 0.5);
  }

  static Future<void> show(
    BuildContext context, {
    Widget progressIndicator =
        const SpinKitCubeGrid(color: AppColors.loadingIndicator),
    String text = 'Loading...',
    double opacity = 0.0,
    double currentBrightness = 0.5,
    bool showLogo = false,
    bool screenKeeper = false,
    required ThemeData themeData,
  }) async {
    _overlayState = Navigator.of(context).overlay;
    TelloLogger().i('_currentLoader status $_currentLoader');
    if (screenKeeper) {
      _screenKeeper = screenKeeper;
      _currentBrightness = currentBrightness;
      Screen.setBrightness(AppSettings().screenBrightness);
      _startBrightnessKeeper();
    }
    if (_currentLoader == null) {
      TelloLogger().i('_currentLoader status is NULL');
      _currentLoader = OverlayEntry(
          builder: (context) => Scaffold(
              backgroundColor: Colors.transparent.withOpacity(opacity),
              body: GestureDetector(
                onTap: () {
                  if (screenKeeper) {
                    Screen.setBrightness(
                        _currentBrightness ?? AppSettings().screenBrightness);
                    _startBrightnessKeeper();
                  }
                },
                child: Stack(
                  children: <Widget>[
                    SafeArea(
                      child: Container(
                        color: AppColors.overlayBarrier,
                      ),
                    ),
                    if (showLogo)
                      const Positioned(
                          top: 10,
                          left: 10,
                          child: Image(
                            image: AssetImage('assets/images/tello_logo.png'),
                            height: 54,
                          )),
                    if (showLogo)
                      const Positioned(
                          top: 10,
                          right: 10,
                          child: Image(
                            image:
                                AssetImage('assets/images/tello_text_logo.png'),
                            height: 32,
                          )),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Loader._(
                          progressIndicator,
                          themeData,
                        ),
                        const SizedBox(height: 20),
                        Text(
                          text,
                          style: AppTypography.subtitle4TextStyle,
                        ),
                        const SizedBox(height: 20),
                        Obx(() => Text(
                              _subTitle.value,
                              style: AppTypography.subtitle4TextStyle
                                  .copyWith(fontSize: 10.0),
                            )),
                      ],
                    ),
                  ],
                ),
              )));
      try {
        WidgetsBinding.instance.addPostFrameCallback(
            (_) => _overlayState?.insertAll([_currentLoader!]));
        TelloLogger().i('showing loader');
      } catch (e, s) {
        TelloLogger().e('error showing loader: $e', stackTrace: s);
      }
    }
  }

  static void hide() {
    TelloLogger().i('hiding loader');
    if (_currentLoader != null) {
      try {
        if (_screenKeeper) {
          _stopBrightnessKeeper();
        }
        _currentLoader?.remove();
      } catch (e, s) {
        TelloLogger().e('error hiding loader: $e', stackTrace: s);
      } finally {
        _currentLoader = null;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Theme(
        data: _themeData,
        child: _progressIndicator,
      ),
    );
  }
}
