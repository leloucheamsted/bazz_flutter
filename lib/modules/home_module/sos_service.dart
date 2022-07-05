import 'dart:async';
import 'dart:typed_data';

import 'package:assorted_layout_widgets/assorted_layout_widgets.dart';
import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/incoming_event.dart';
import 'package:bazz_flutter/models/location.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/sos_repo.dart';
import 'package:bazz_flutter/modules/location_tracking/location_service.dart';
import 'package:bazz_flutter/services/event_handling_service.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/networking_client.dart';
import 'package:bazz_flutter/services/vibrator.dart';
import 'package:bazz_flutter/shared_widgets/primary_button.dart';
import 'package:bazz_flutter/shared_widgets/system_dialog.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:custom_timer/custom_timer.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_sound_lite/flutter_sound.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:intl/intl.dart';

class SosService extends GetxController {
  static SosService get to => Get.find();

  final _sosRepository = SosRepository();

  FlutterSoundPlayer sosSendPlayerModule = FlutterSoundPlayer();
  FlutterSoundPlayer sosReceivePlayerModule = FlutterSoundPlayer();
  FlutterSoundPlayer sosSendingPlayerModule = FlutterSoundPlayer();

  String sosSentAlarmFilePath = 'assets/sounds/sos_send_alarm.mp3';
  String sosSendingAlarmFilePath = 'assets/sounds/sos_sending_alarm.mp3';
  String sosReceiveAlarmFilePath = 'assets/sounds/sos_receive_alarm.mp3';

  late Uint8List sosSentSoundBuffer;
  late Uint8List sosSendingSoundBuffer;
  late Uint8List sosReceiveSoundBuffer;

  late GetStorage _offlineEventsBox;

  final timerController = CustomTimerController();

  late StreamSubscription _activeGroupSub;

  final _loadingState = ViewState.idle.obs;

  ViewState get loadingState => _loadingState.value;

  @override
  Future<void> onInit() async {
    _offlineEventsBox = GetStorage(StorageKeys.offlineEventsBox);

    await sosReceivePlayerModule.openAudioSession(
      focus: AudioFocus.requestFocusAndDuckOthers,
      audioFlags: outputToSpeaker,
    );
    await sosSendPlayerModule.openAudioSession(
      focus: AudioFocus.requestFocusAndDuckOthers,
      audioFlags: outputToSpeaker,
    );
    await sosSendingPlayerModule.openAudioSession(
      focus: AudioFocus.requestFocusAndDuckOthers,
      audioFlags: outputToSpeaker,
    );

    await sosReceivePlayerModule
        .setSubscriptionDuration(const Duration(milliseconds: 100));
    await sosSendPlayerModule
        .setSubscriptionDuration(const Duration(milliseconds: 100));
    await sosSendingPlayerModule
        .setSubscriptionDuration(const Duration(milliseconds: 100));

    sosSentSoundBuffer =
        (await rootBundle.load(sosSentAlarmFilePath)).buffer.asUint8List();
    sosSendingSoundBuffer =
        (await rootBundle.load(sosSendingAlarmFilePath)).buffer.asUint8List();
    sosReceiveSoundBuffer =
        (await rootBundle.load(sosReceiveAlarmFilePath)).buffer.asUint8List();

    _activeGroupSub = HomeController.to.activeGroup$.listen((aGroup) {
      if (sosReceivePlayerModule.isPlaying) _dismissSosCheck();
    });

    super.onInit();
  }

  Future<void> treatUnconfirmedSos(IncomingEvent event) async {
    if (Get.isDialogOpen!) {
      if (sosReceivePlayerModule.isStopped) {
        await playSosReceiveSound();
        Vibrator.startNotificationVibration();
      }
      await buildSosConfirmDialog(event);
    }
    if (sosReceivePlayerModule.isPlaying) {
      sosReceivePlayerModule.stopPlayer();
      Vibrator.stopNotificationVibration();
    }
  }

  @override
  Future<void> onClose() async {
    sosSendPlayerModule.closeAudioSession();
    sosReceivePlayerModule.closeAudioSession();
    sosSendingPlayerModule.closeAudioSession();
    _activeGroupSub.cancel();
    super.onClose();
  }

  void _dismissSosCheck() {
    sosReceivePlayerModule.stopPlayer();
    if (Get.isDialogOpen!) {
      Get.back();
    }
  }

  Future<void> _sendSos() async {
    if (AppSettings().sosAutoBroadcastPeriod > 0) {
      TelloLogger().i("START SOS AUTO BROADCAST");
      if (HomeController.to.canTalk && !HomeController.to.isPttKeyPressed$)
        HomeController.to.onPttPress(auto: true);
      Future.delayed(
        Duration(seconds: AppSettings().sosAutoBroadcastPeriod),
        () {
          TelloLogger().i("STOP SOS AUTO BROADCAST");
          HomeController.to.onPttRelease(auto: true);
        },
      );
    }

    final sosExists =
        _offlineEventsBox.read<Map<String, dynamic>>(StorageKeys.sosEvent) !=
            null;

    if (sosExists) {
      return SystemDialog.showConfirmDialog(
          message: LocalizationService().of().sosAlertHasAlreadyBeenSent);
    }

    final position =
        await LocationService().getCurrentPosition(ignoreLastKnownPos: false);
    final locationData =
        position != null ? Location.fromPosition(position).toMap() : null;
    final sosData = {
      "typeId": AppSettings().eventSettings.sosTypeConfigId,
      "groupId": HomeController.to.activeGroup.id,
      "positionId": Session.shift?.groupId == HomeController.to.activeGroup.id
          ? Session.shift?.positionId
          : null,
      "location": locationData,
      "createdAt": millisecondsToSeconds(DateTime.now().millisecondsSinceEpoch),
    };

    try {
      if (HomeController.to.isOnline) {
        await _sosRepository.createSos(sosData);
        clearSos();
      } else {
        saveSos(sosData);
      }

      Get.rawSnackbar(
        duration: 3.seconds,
        animationDuration: 500.milliseconds,
        messageText: Column(
          children: [
            Center(
                child: Text(
              LocalizationService().of().sosAlertHasBeenSentTo,
              style: AppTypography.appBarTimerTextStyle,
            )),
            Center(
              child: Text(
                HomeController.to.activeGroup.zone?.title ??
                    LocalizationService().of().noActiveGroup,
                style: AppTypography.appBarTimerTextStyle,
              ),
            ),
          ],
        ),
      );
    } catch (e, s) {
      var message = e.toString();
      if (e is TelloError) {
        final errorCode = (e).code;
        if (errorCode == 701) {
          message = '${LocalizationService().of().sosAlertHasAlreadyBeenSent}!';
          clearSos();
        } else {
          saveSos(sosData);
        }
      }
      SystemDialog.showConfirmDialog(message: message);
      TelloLogger().e('SosService sos sending error: $e', stackTrace: s);
    }
  }

  void saveSos(Map<String, dynamic> data) {
    _offlineEventsBox.writeIfNull(StorageKeys.sosEvent, data);
  }

  void clearSos() {
    _offlineEventsBox.remove(StorageKeys.sosEvent);
  }

  Future<void> playSosSendingSound() async {
    try {
      TelloLogger().i("AppSettings().sosMode == ${AppSettings().sosMode}");
      if (AppSettings().sosMode == SosMode.Silence) {
        return;
      }
      await sosSendingPlayerModule.startPlayer(
        fromDataBuffer: sosSendingSoundBuffer,
        codec: Codec.mp3,
        whenFinished: () {
          TelloLogger().i('Play finished');
        },
      );
    } catch (e, s) {
      TelloLogger().e('playSosSendingSound() error: $e', stackTrace: s);
    }
  }

  Future<void> stopSosSendingSound() async {
    try {
      if (AppSettings().sosMode == SosMode.Silence ||
          !sosSendingPlayerModule.isPlaying) return;
      await sosSendingPlayerModule.stopPlayer();
    } catch (e, s) {
      TelloLogger().e('stopSosSendingSound() error: $e', stackTrace: s);
    }
  }

  Future<void> playSosIsSentSound() async {
    try {
      if (AppSettings().sosMode == SosMode.Silence) {
        return;
      }
      await sosSendingPlayerModule.stopPlayer();
      await sosSendPlayerModule.startPlayer(
        fromDataBuffer: sosSentSoundBuffer,
        codec: Codec.mp3,
        whenFinished: () {
          TelloLogger().i('Play finished');
        },
      );
    } catch (e, s) {
      TelloLogger().e('playSosIsSentSound() error: $e', stackTrace: s);
    }
  }

  Future<void> playSosReceiveSound() async {
    try {
      await sosReceivePlayerModule.startPlayer(
        fromDataBuffer: sosReceiveSoundBuffer,
        codec: Codec.mp3,
        whenFinished: () {
          if (Get.isDialogOpen!) {
            playSosReceiveSound();
          }
          TelloLogger().i('Play finished');
        },
      );
    } catch (e, s) {
      TelloLogger().e('playSosReceiveSound error: $e', stackTrace: s);
    }
  }

  void buildCountdownSnackBar({VoidCallback? onFinish}) {
    Get.rawSnackbar(
      duration: 4.seconds,
      animationDuration: 500.milliseconds,
      messageText: CustomTimer(
        controller: timerController,
        begin: 3.seconds,
        end: const Duration(),
        // onChangeState: CustomTimerAction.
        //onBuildAction: CustomTimerAction.auto_start,
        builder: (remaining) {
          return RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: '${LocalizationService().of().sosAlertWillBeSentIn} ',
                  style: AppTypography.captionTextStyle.copyWith(
                      fontFamily: 'Poppins', fontWeight: FontWeight.w400),
                ),
                TextSpan(
                  text: remaining.secondsWithoutFill,
                  style: AppTypography.appBarTimerTextStyle,
                ),
              ],
            ),
          );
        },
        // onFinish: () {
        //   onFinish?.call();

        //   HomeController.to.isSosPressed$ = false;
        //   timerController.reset();
        //   timerController.state = CustomTimerState.finished;
        //   HapticFeedback.heavyImpact();
        //   _sendSos();
        //   playSosIsSentSound();
        // },
        // finishedBuilder: (_) {
        //   return Column(
        //     children: [
        //       Center(
        //           child: Text(
        //         LocalizationService().localizationContext().sosAlertHasBeenSentTo,
        //         style: AppTypography.appBarTimerTextStyle,
        //       )),
        //       Center(
        //           child: Text(
        //         HomeController.to.activeGroup?.zone?.title ?? LocalizationService().localizationContext().noActiveGroup,
        //         style: AppTypography.appBarTimerTextStyle,
        //       ))
        //     ],
        //   );
        // },
      ),
    );
  }

  Future<void> buildSosConfirmDialog(IncomingEvent event) async {
    final sosDateTime =
        dateTimeFromSeconds(event.createdAt!, isUtc: true)!.toLocal();

    if (Get.isBottomSheetOpen!) Get.back();

    await Get.generalDialog(
      barrierLabel: 'BarrierLabel',
      pageBuilder: (_, __, ___) {
        return Center(
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(7)),
            child: SizedBox(
              width: Get.width * 0.7,
              height: Get.height * 0.25,
              child: Scaffold(
                backgroundColor: AppTheme().colors.mainBackground,
                body: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 5, vertical: 5),
                      color: AppColors.danger,
                      child: TextOneLine(
                        '${event.ownerTitle} - SOS',
                        textAlign: TextAlign.center,
                        style: AppTheme().typography.dialogTitleStyle,
                      ),
                    ),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        child: Column(
                          children: [
                            Expanded(
                              child: Align(
                                child: Text(
                                  '${event.ownerTitle} ${LocalizationService().of().reportedSOSat} ${DateFormat(AppSettings().timeFormat).format(sosDateTime)}',
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  style: AppTheme().typography.bgText3Style,
                                ),
                              ),
                            ),
                            Obx(() {
                              return FittedBox(
                                child: PrimaryButton(
                                  height: 40,
                                  text: LocalizationService().of().confirm,
                                  icon: loadingState == ViewState.loading
                                      ? null!
                                      : const Icon(
                                          Icons.check,
                                          color: AppColors.brightText,
                                          size: 17,
                                        ),
                                  onTap: loadingState == ViewState.loading
                                      ? null!
                                      : () => EventHandlingService.to!
                                          .confirmEvent(event),
                                  child: loadingState == ViewState.loading
                                      ? SpinKitCubeGrid(
                                          color: AppColors.loadingIndicator,
                                          size: 25,
                                        )
                                      : null,
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
