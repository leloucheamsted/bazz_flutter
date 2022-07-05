import 'dart:async';

import 'package:bazz_flutter/models/group_model.dart';
import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/services/localization_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/p2p_video_signaling.dart';
import 'package:bazz_flutter/shared_widgets/entity_details_info.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_incall_manager/flutter_incall_manager.dart';
import 'package:flutter_webrtc/media_stream.dart';
import 'package:flutter_webrtc/rtc_video_view.dart';

import 'package:get/get.dart';
import 'package:bazz_flutter/services/snack_bar_display.dart';
import 'package:logger/logger.dart' as log;

import '../../app_theme.dart';

class VideoChatController extends GetxController
    with SingleGetTickerProviderMixin {
  static VideoChatController get to => Get.find();

  String displayName = "";
  List<dynamic>? _peers;

  // ignore: prefer_typing_uninitialized_variables
  var _currentPeer;

  late Rx<VideoSignalingState> _callState$;
  final _connected = false.obs;
  final _localRenderer = RTCVideoRenderer();
  final _remoteRenderer = RTCVideoRenderer();
  final incall = IncallManager();
  final _currentPeerName = "".obs;
  late Rx<RxGroup> activeGroup$;
  final _clientId = "".obs;

  VideoSignalingState get callState => _callState$.value;

  bool get connected => _connected.value;

  RTCVideoRenderer get localRenderer => _localRenderer;

  RTCVideoRenderer get remoteRenderer => _remoteRenderer;

  String get currentPeerName => _currentPeerName.value;

  String get clientId => _clientId.value;

  RxGroup get activeGroup => activeGroup$.value;
  StreamSubscription? _activeGroupSub;
  StreamSubscription? _groupsSub;

  @override
  Future<void> onInit() async {
    incall.checkRecordPermission();
    incall.requestRecordPermission();
    incall.checkCameraPermission();
    incall.requestCameraPermission();

    activeGroup$.value = HomeController.to.activeGroup$.value;

    _activeGroupSub = HomeController.to.activeGroup$.listen((aGroup) async {
      if (aGroup == null) return;

      activeGroup$.value = aGroup;
      await syncPeers(_peers!);
    });

    _groupsSub = HomeController.to.groups$.listen((groups) async {
      //await syncPeers(_peers);
    });

    await init();
    await connect();
    currentUser$!.listen((u) async {
      if (u != null) {
        await VideoSignaling().createLocalStream();
      } else {
        await VideoSignaling().closeLocalStream();
        _localRenderer.srcObject = null!;
      }
    });
    super.onInit();
  }

  @override
  Future<void> onClose() async {
    hangUp();
    _activeGroupSub?.cancel();
    _groupsSub?.cancel();
    _localRenderer.dispose();
    _remoteRenderer.dispose();
    VideoSignaling().dispose();
    super.onClose();
  }

  Future<void> init() async {
    await _localRenderer.initialize();
    await _remoteRenderer.initialize();
  }

  Future<void> connect() async {
    _clientId.value = Session.user!.id;
    displayName = Session.user!.fullName!;

    VideoSignaling().init(clientId, displayName);
    VideoSignaling().onStateChange =
        (VideoSignalingState state, String peerId) {
      TelloLogger()
          .i("######################### _signaling.onStateChange $state");
      switch (state) {
        case VideoSignalingState.CallStateOutgoing:
          incall.stopRingback();
          incall.stopRingtone();
          incall.start(media: MediaType.VIDEO, auto: true, ringback: '_DTMF_');
          _callState$.value = state;
          HomeController.to.stopPrivateCall();
          break;
        case VideoSignalingState.CallStateIdle:
          if (_currentPeer != null) {
            updateCandidateVideoState(_currentPeer["id"] as String, false);
          }
          _currentPeer = null;
          _currentPeerName.value = null as String;
          _remoteRenderer.srcObject = null as MediaStream;
          _callState$.value = state;
          incall.stopRingtone();
          incall.stop(busytone: '_DTMF_');

          break;
        case VideoSignalingState.CallStateConnected:
          updateCandidateVideoState(_currentPeer["id"] as String, true);
          incall.stopRingback();
          incall.stopRingtone();
          incall.start(media: MediaType.VIDEO, auto: true, ringback: '');
          _callState$.value = state;

          HomeController.to.stopPrivateCall();
          break;
        case VideoSignalingState.CallStateIncoming:
          TelloLogger().i(
              "######################### VideoSignalingState.CallStateIncoming $state");
          _currentPeer = _peers?.singleWhere((i) => i['id'] == peerId);
          _currentPeerName.value = _currentPeer["name"] as String;
          incall.startRingtone(RingtoneUriType.DEFAULT, 'default', 30);
          TelloLogger().i(
              "######################### 00000 _signaling.onStateChange $state");
          _callState$.value = state;
          HomeController.to.stopPrivateCall();
          break;
        case VideoSignalingState.ConnectionClosed:
          _callState$.value = state;
          _connected.value = false;
          closeVideoChatView();
          break;
        case VideoSignalingState.ConnectionError:
          _callState$.value = state;
          _connected.value = false;
          break;
        case VideoSignalingState.ConnectionOpen:
          _callState$.value = state;
          _connected.value = true;
          break;
        case VideoSignalingState.CallStateBusy:
          // TODO: Handle this case.
          break;
      }
    };

    VideoSignaling().onPeersUpdate = (event) async {
      TelloLogger().i("CALL _signaling.onPeersUpdate data = $event");
      _clientId.value = event['self'] as String;
      _peers = event['peers'] as List<dynamic>;
      await syncPeers(_peers!);
    };

    VideoSignaling().onLocalStream = (stream) {
      TelloLogger().i("CALL _signaling.onLocalStream");
      _localRenderer.srcObject = stream;
    };

    VideoSignaling().onAddRemoteStream = (stream) {
      TelloLogger().i("CALL _signaling.onAddRemoteStream");
      _remoteRenderer.srcObject = stream;
    };

    VideoSignaling().onRemoveRemoteStream = (stream) {
      TelloLogger().i("CALL _signaling.onRemoveRemoteStream");
      _remoteRenderer.srcObject = null as MediaStream;
      closeVideoChatView();
    };

    VideoSignaling().onAnswer = (String peerId) {
      TelloLogger().i("CALL _signaling.onAnswer peerId = $peerId");
    };

    VideoSignaling().onLeave = (String peerId) {
      TelloLogger().i("CALL _signaling.onLeave peerId = $peerId");
      hangUp();
    };

    VideoSignaling().onCandidate = (String peerId) async {
      TelloLogger().i("CALL _signaling.onCandidate peerId = $peerId");
      await updateCandidate(peerId);
    };

    VideoSignaling().onBye = (String peerId) {
      TelloLogger().i("CALL _signaling.onBye  peerId = $peerId");
      hangUp();
    };

    VideoSignaling().onBusy = (String peerId) async {
      hangUp();
    };

    VideoSignaling().onError = () {
      Get.showSnackbar(GetBar(
        backgroundColor: Colors.red,
        message: 'Video Channel error',
        duration: const Duration(seconds: 3),
      ));
      TelloLogger().e("CALL _signaling.onError");
    };

    VideoSignaling().connect();
  }

  Future<void> syncPeers(List<dynamic> peers) async {
    if (_peers != null) {
      TelloLogger().i("CALL syncPeers");
      HomeController.to.groups
          .map((e) => e.members.users.map((u) => u.isVideoActive(false)));
      HomeController.to.groups.map((e) =>
          e.members.positions.map((p) => p.worker().isVideoActive(false)));
      peers.forEach((peer) {
        TelloLogger().i("SYC USERS WITH PEERS ${peer['name']}, ${peer['id']}");
        syncUsers(peer["id"] as String);
        syncPositions(peer["id"] as String);
      });
    }
  }

  Future<RxUser> getUser(String userId) async {
    RxUser? user;
    HomeController.to.groups.forEach((gr) {
      user = gr.members.users.firstWhere(
        (u) => u.id == userId,
        orElse: () => null!,
      );
    });
    if (user == null) {
      HomeController.to.groups
          // ignore: avoid_function_literals_in_foreach_calls
          .forEach((gr) => user = gr.members.positions
              .firstWhere(
                (u) => u.worker().id == userId,
                orElse: () => null!,
              )
              .worker());
    }

    return user!;
  }

  Future<void> updateCandidate(String userId) async {
    syncUsers(userId);
    syncPositions(userId);
  }

  Future<void> updateCandidateVideoState(String userId, bool state) async {
    syncUsersVideoState(userId, state);
    syncPositionsVideoState(userId, state);
  }

  void syncUsers(String userId) {
    TelloLogger().i(
        "@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 1111111111111 syncUsers $userId ${HomeController.to.groups.length}");
    // ignore: avoid_function_literals_in_foreach_calls
    HomeController.to.groups.forEach((gr) {
      gr.members.users
          .firstWhere(
            (u) => u.id == userId && u.isOnline(),
            orElse: () => null!,
          )
          .isVideoActive(true);
    });
  }

  void syncPositions(String userId) {
    TelloLogger()
        .i("@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ 1111111111111 syncPositions $userId");
    HomeController.to.groups
        // ignore: avoid_function_literals_in_foreach_calls
        .forEach((gr) => gr.members.positions
            .firstWhere(
              (u) => u.worker().id == userId && u.worker().isOnline(),
              orElse: () => null!,
            )
            .worker()
            .isVideoActive(true));
  }

  void syncUsersVideoState(String userId, bool state) {
    // ignore: avoid_function_literals_in_foreach_calls
    HomeController.to.groups.forEach((gr) => gr.members.users
        .firstWhere(
          (u) => u.id == userId,
          orElse: () => null!,
        )
        .isVideoConnected(state));
  }

  void syncPositionsVideoState(String userId, bool state) {
    HomeController.to.groups
        // ignore: avoid_function_literals_in_foreach_calls
        .forEach((gr) => gr.members.positions
            .firstWhere(
              (u) => u.worker().id == userId,
              orElse: () => null!,
            )
            .worker()
            .isVideoConnected(state));
  }

  Future<void> invitePeer(RxUser user) async {
    String errorMessage = "";
    if (user == null) {
      errorMessage = LocalizationService().of().positionIsNotAvailable;
    } else if (user.isVideoActive.value && !user.isVideoConnected.value) {
      if (user.id != _clientId.value &&
          _callState$.value == VideoSignalingState.CallStateIdle) {
        _currentPeer = _peers!.singleWhere((i) => i['id'] == user.id);
        _currentPeerName.value = _currentPeer["name"] as String;
        await VideoSignaling().invite(user.id);
      } else if (user.id != _clientId.value &&
          _callState$.value == VideoSignalingState.CallStateConnected) {
        errorMessage = LocalizationService().of().videoCallIsConnected;
      } else if (user.id != _clientId.value &&
          _callState$.value == VideoSignalingState.CallStateIncoming) {
        errorMessage = LocalizationService().of().videoCallIsIncoming;
      } else if (user.id != _clientId.value &&
          _callState$.value == VideoSignalingState.CallStateOutgoing) {
        errorMessage = LocalizationService().of().videoCallIsOutgoing;
      } else if (user.id != _clientId.value &&
          _callState$.value == VideoSignalingState.ConnectionClosed) {
        errorMessage = LocalizationService().of().videoServiceIsNotAvailable;
      }
    }

    if (errorMessage.isNotEmpty) {
      Get.showSnackbarEx(GetBar(
        backgroundColor: AppColors.error,
        message: errorMessage,
        titleText: Text(LocalizationService().of().system,
            style: AppTypography.captionTextStyle),
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppColors.brightIcon),
      ));
    }
  }

  void hangUp() {
    TelloLogger().i("hangUp()");
    if (_currentPeer != null) {
      VideoSignaling().bye(_currentPeer["id"] as String);
      VideoSignaling().raiseStateChange(VideoSignalingState.CallStateIdle);
    }
    if (Get.isDialogOpen!) {
      Get.back();
    }
    closeVideoChatView();
  }

  void closeVideoChatView() {
    if (Get.isRegistered<HomeController>() &&
        HomeController.to.isVideoChatVisible) {
      HomeController.to.gotoBottomNavTab(BottomNavTab.ptt);
    }
  }

  Rx<RxUser>? currentUser$;

  RxUser get currentUser => currentUser$!();

  set currentUser(RxUser value) {
    currentUser$!(value);
  }

  Future<void> pickUp() async {
    await HomeController.to.gotoBottomNavTab(BottomNavTab.videoChat);
    VideoSignaling().answer();
    VideoSignaling().raiseStateChange(VideoSignalingState.CallStateConnected);
  }

  void switchCamera() {
    VideoSignaling().switchCamera();
  }

  Future<void> showUserInfo(RxUser user) async {
    await Get.bottomSheet(
        Center(child: EntityDetailsInfo.createDetails(user: user)));
  }

  Future<void> showPositionInfo(RxPosition position) async {
    await Get.bottomSheet(
        Center(child: EntityDetailsInfo.createDetails(pos: position)));
  }
}

mixin _ {}
