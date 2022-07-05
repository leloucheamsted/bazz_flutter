import 'dart:async';

import 'package:bazz_flutter/app_theme.dart';
import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/group_model.dart';
import 'package:bazz_flutter/models/incoming_event.dart';
import 'package:bazz_flutter/models/location.dart';
import 'package:bazz_flutter/models/outgoing_event.dart';
import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/modules/home_module/events_repo.dart';
import 'package:bazz_flutter/modules/home_module/home_controller.dart';
import 'package:bazz_flutter/modules/home_module/sos_service.dart';
import 'package:bazz_flutter/modules/home_module/views/map/flutter_map_controller.dart';
import 'package:bazz_flutter/modules/location_tracking/location_service.dart';
import 'package:bazz_flutter/modules/media_uploading/media_upload_service.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/notification_service.dart' as ns;
import 'package:bazz_flutter/services/snack_bar_display.dart';
import 'package:bazz_flutter/services/vibrator.dart';
import 'package:bazz_flutter/shared_widgets/loader.dart';
import 'package:bazz_flutter/shared_widgets/system_dialog.dart';
import 'package:bazz_flutter/utils/back_button_locker.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:flutter/material.dart';
// import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';
import 'package:uuid/uuid.dart';

class EventHandlingService extends GetxController {
  static EventHandlingService? get to =>
      Get.isRegistered<EventHandlingService>() ? Get.find() : null;

  final _eventsRepo = EventsRepository();
  GetStorage? cachedIncomingEventsBox;

  final _isPostponed = false.obs;

  PanelController newEventDrawerController = PanelController();
  final TextEditingController newEventCommentController =
      TextEditingController();

  double scrollOffset = 0.0;

  String? currentEventMediaUploadId;

  final List<OutgoingEvent> userEvents = [];

  StreamSubscription? _activeGroupSub;

  final _loadingState = ViewState.idle.obs;

  ViewState get loadingState => _loadingState.value;

  bool get isPostponed => _isPostponed.value;

  bool get isAddEventDrawerClosed =>
      !newEventDrawerController.isAttached ||
      newEventDrawerController.isPanelClosed;

  bool get isAddEventDrawerOpen => !isAddEventDrawerClosed;

  void togglePostponed() => _isPostponed.toggle();

  final Rx<OutgoingEvent> _currentUserEvent$ = Rx<OutgoingEvent>(null!);

  /// Calling with no args will set it to null
  void setCurrentUserEvent([OutgoingEvent? event]) {
    if (event != null) {
      _currentUserEvent$;
    } else {
      _currentUserEvent$.isNull;
    }
    currentEventMediaUploadId = event?.typeId;
  }

  OutgoingEvent get currentUserEvent$ => _currentUserEvent$ as OutgoingEvent;

  @override
  void onInit() {
    assert(AppSettings().eventSettings != null);

    populateUserEvents();

    _activeGroupSub = HomeController.to.activeGroup$.listen((aGroup) async {
      final isEventsTabVisible =
          HomeController.to.bottomNavBarIndex == BottomNavTab.events.index;
      if (aGroup == null ||
          !HomeController.to.showEventsDialogAfterSettingGroup ||
          isEventsTabVisible) return;

      var unresolvedLength = 0;
      var unconfirmedLength = 0;

      for (final a in aGroup.roleDependentEvents$) {
        if (a.isConfirmed$.value) {
          unresolvedLength++;
        } else {
          unconfirmedLength++;
        }
      }

      if (aGroup.hasEvents) {
        String message;
        if (unconfirmedLength == 0) {
          final suffix = unresolvedLength > 1 ? 's' : '';
          message =
              " AppLocalizations.of(Get.context).unresolvedEventsDialogText('$unresolvedLength', suffix)";
        } else if (unresolvedLength == 0) {
          final suffix = unconfirmedLength > 1 ? 's' : '';
          message =
              "AppLocalizations.of(Get.context).unconfirmedEventsDialogText('$unconfirmedLength', suffix)";
        } else {
          message =
              " AppLocalizations.of(Get.context).eventsDialogText('$unconfirmedLength', '$unresolvedLength')";
        }
        SystemDialog.showConfirmDialog(
          title: " AppLocalizations.of(Get.context).attention.capitalizeFirst",
          cancelCallback: Get.back,
          confirmCallback: () =>
              HomeController.to.gotoBottomNavTab(BottomNavTab.events),
          confirmButtonText:
              "AppLocalizations.of(Get.context).yes.capitalizeFirst",
          cancelButtonText:
              "AppLocalizations.of(Get.context).later.capitalizeFirst",
          message: message,
          titleFillColor: "white" as Color,
        );
      }
    });
    super.onInit();
  }

  @override
  void onClose() {
    _activeGroupSub?.cancel();
    super.onClose();
  }

  void populateUserEvents() {
    final List<OutgoingEvent> outEvents = [];

    for (final cfg in AppSettings().eventSettings.eventTypeConfigs) {
      if (cfg.policy.canCreate && cfg.isNotSos)
        outEvents.add(OutgoingEvent(cfg.typeId));
    }

    userEvents
      ..clear()
      ..addAll(outEvents);
    update(['userEventsList']);
  }

  void resetCurrentNewEventForm() {
    MediaUploadService.to.deleteAllById(currentEventMediaUploadId!);
    newEventCommentController.clear();
    setCurrentUserEvent();
    update(['mediaUploadButton']);
  }

  void selectNewEvent(OutgoingEvent newEvent) {
    // To to make the event unique in the local storage
    newEvent.id = Uuid().v1();
    MediaUploadService.to
        .changeMediaParent(currentEventMediaUploadId!, newEvent.typeId!);
    setCurrentUserEvent(newEvent);
    update(['mediaUploadButton']);
  }

  Future<void> sendEvent() async {
    BackButtonLocker.lockBackButton();
    _loadingState(ViewState.loading);

    final media =
        MediaUploadService.to.allMediaByEventId[currentEventMediaUploadId] ??
            [];
    final position =
        await LocationService().getCurrentPosition(ignoreLastKnownPos: false);

    try {
      currentUserEvent$
        ..ownerPositionId = Session.shift!.positionId
        ..groupId = HomeController.to.activeGroup.id
        ..comment = newEventCommentController.text
        ..createdAt =
            millisecondsToSeconds(DateTime.now().millisecondsSinceEpoch)
        ..location =
            (position != null ? Location.fromPosition(position) : null)!;

      for (final m in media) {
        if (m.isUploadDeferred()) {
          currentUserEvent$.addDeferredUploadMedia(m);
        } else if (m.publicUrl != null) {
          currentUserEvent$.addMediaUrl(m);
        }
      }

      if (HomeController.to.isOnline &&
          currentUserEvent$.hasNoDeferredUploadMedia) {
        await _eventsRepo.createEvent(currentUserEvent$.toMap(forServer: true));
        removeEvent(currentUserEvent$.id!);
      } else {
        saveCurrentNewEvent();
      }
    } catch (e, s) {
      saveCurrentNewEvent();
      TelloLogger()
          .e('EventHandlingService new event sending error: $e', stackTrace: s);
    } finally {
      resetCurrentNewEventForm();
      closePanel();
      // We need to repopulate user events and update the UI, because we need different event ids
      // to discriminate them in the local storage
      populateUserEvents();

      BackButtonLocker.unlockBackButton();
      _loadingState(ViewState.idle);
    }
  }

  void onCancel() {
    closePanel();
    resetCurrentNewEventForm();
  }

  void openPanel() {
    newEventDrawerController.open();
  }

  void closePanel() {
    newEventDrawerController.close();
  }

  void saveCurrentNewEvent() {
    if (currentUserEvent$ == null) return;
    GetStorage(StorageKeys.offlineEventsBox)
        .writeIfNull(currentUserEvent$.id!, currentUserEvent$.toMap());
  }

  void removeEvent(String id) {
    GetStorage(StorageKeys.offlineEventsBox).remove(id);
  }

  Future<void> confirmEvent(IncomingEvent event) async {
    final events = HomeController.to.activeGroup.events$;
    try {
      BackButtonLocker.lockBackButton();
      Loader.show(Get.context!, themeData: null as ThemeData);

      final resp = await _eventsRepo.confirmEvent(event.id!);
      TelloLogger().i('confirmEvent() resp.data: ${resp.data}');
      final newStatus =
          EventStatus.values[resp.data!['event']['event']['status'] as int];

      final targetEvent = events.firstWhere((ev) => ev.id == event.id,
          orElse: () => null as IncomingEvent);
      if (targetEvent != null) {
        targetEvent
          ..isConfirmed$(true)
          ..status(newStatus);
        HomeController.to.activeGroup.saveEvents();
      }

      if (Get.isOverlaysOpen) Get.back();
      if (Session.isSupervisor && targetEvent != null && event.hasLocation) {
        FlutterMapController.to.showEvent(targetEvent);
      }

      HomeController.to.activeGroup.events$.refresh();
    } catch (e, s) {
      TelloLogger().e('SosService sos confirmation error: $e', stackTrace: s);
    } finally {
      BackButtonLocker.unlockBackButton();
      Loader.hide();
    }
  }

  Future<void> resolveEvent(IncomingEvent event, String comment) async {
    final media = MediaUploadService.to.allMediaByEventId[event.typeId] ?? [];
    try {
      BackButtonLocker.lockBackButton();
      _loadingState(ViewState.loading);

      await _eventsRepo.closeEvent(
        id: event.id!,
        description: comment,
        imageUrls: media.isNotEmpty
            ? media.where((m) => m.isImage).map((m) => m.publicUrl).toList()
            : [],
        videoUrls: media.isNotEmpty
            ? media.where((m) => m.isVideo).map((m) => m.publicUrl).toList()
            : [],
        resolveStatus: event.resolveStatus(),
        isPostponed: event.isPostponed$.value,
      );

      MediaUploadService.to.deleteAllById(event.typeId!);
      _loadingState(ViewState.success);
    } catch (e, s) {
      TelloLogger().e('SosService sos resolving error: $e', stackTrace: s);
      _loadingState(ViewState.error);
    } finally {
      BackButtonLocker.unlockBackButton();
    }
  }

  Future<void> handleEvent(Map<String, dynamic> data) async {
    IncomingEvent event = IncomingEvent.fromMap(data);

    if (event.hasNoConfig) {
      await HomeController.to.fetchEventTypesConfig();
      event = IncomingEvent.fromMap(data);
    }

    final isMyEvent = event.ownerPositionId != null
        ? event.ownerPositionId == Session.shift?.positionId
        : event.ownerId == Session.user!.id;
    final notMyEvent = !isMyEvent;
    final targetGroup = HomeController.to.groups.firstWhere(
        (gr) => gr.id == event.groupId,
        orElse: () => null as RxGroup);

    if (targetGroup == null) {
      throw "Can't find the target group for the event: ${event.title} ${event.id}. Group: ${event.groupId}";
    }

    final alreadyExists = targetGroup.events$.any(
        (ev) => ev.ownerTitle == event.ownerTitle && ev.typeId == event.typeId);
    if (alreadyExists) return;

    var title = event.title;
    final String text = '${event.ownerTitle} reported $title';
    var notificationGroupType = NotificationGroupType.others;

    if (event.isSystem) {
      if (isMyEvent || Session.isNotSupervisor) return;
      notificationGroupType = NotificationGroupType.systemEvents;
    } else {
      title = event.title.toUpperCase();
      notificationGroupType = NotificationGroupType.others;
    }

    if (isMyEvent) event.isConfirmed$(true);

    //We handle SOS events differently
    if (event.isSos) {
      _updateMemberSosStatus(
          event.ownerId, event.ownerPositionId!, targetGroup, true);
      if (event.isNotConfirmed$) SosService.to.treatUnconfirmedSos(event);
    } else if (notMyEvent) {
      final getBar = GetBar(
        backgroundColor: AppColors.error,
        snackPosition: SnackPosition.TOP,
        message: text,
        titleText: Text(
          title,
          style: AppTypography.captionTextStyle,
        ),
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppColors.brightIcon),
        snackbarStatus: (status) {
          if (status == SnackbarStatus.CLOSED) {
            Vibrator.stopNotificationVibration();
          } else if (status == SnackbarStatus.OPEN) {
            Vibrator.startNotificationVibration();
          }
        },
        onTap: (_) async {
          await HomeController.to.setActiveGroup(targetGroup);
          HomeController.to.gotoBottomNavTab(BottomNavTab.events);
          if (Get.isSnackbarOpen) Get.back();
        },
      );

      if (Get.isSnackbarOpen) Get.back();
      Get.showSnackbarEx(getBar);

      ns.NotificationService.to.add(
        ns.Notification(
          icon: getBar.icon!,
          title: title,
          text: text,
          bgColor: getBar.backgroundColor,
          callback: () => getBar.onTap!(getBar),
          groupType: notificationGroupType,
        ),
        allowBodyDuplicates: false,
      );
    }

    targetGroup.addEvent(event);
    targetGroup.saveEvents();
    TelloLogger().i('NewEvent ${event.id}, ${event.title} has been added');
  }

  void handleEventUpdate(Map<String, dynamic> data) {
    final eventId = data['eventId'] as String;
    final groupId = data['groupId'] as String;
    final isPostponed =
        data['isPostponed'] != null ? data['isPostponed'] as bool : false;
    final newStatus = EventStatus.values[data['status'] as int];
    final targetGroup = HomeController.to.groups
        .firstWhere((gr) => gr.id == groupId, orElse: () => null as RxGroup);

    if (targetGroup == null) {
      throw "Can't find the target group for the event: $eventId. Group: $groupId";
    }

    final targetEvent = targetGroup.events$.firstWhere((ev) => ev.id == eventId,
        orElse: () => null as IncomingEvent);

    if (targetEvent == null) return;
    targetEvent.isPostponed$(isPostponed);
    targetEvent.isPostponedCheckboxDisabled = isPostponed;

    if (newStatus == EventStatus.ongoing) {
      targetEvent.status(newStatus);
    } else if (newStatus == EventStatus.closed) {
      targetGroup.removeEvent(eventId);
      if (targetEvent.isSos) {
        _updateMemberSosStatus(data['ownerId'] as String,
            data['ownerPositionId'] as String, targetGroup, false);
      }
    }
    targetGroup.saveEvents();
    targetGroup.events$.refresh();
    TelloLogger().i(
        'UpdatedEvent id: $eventId, title: ${targetEvent.title}, status: ${newStatus.toString()}');
  }

  void _updateMemberSosStatus(
      String userId, String positionId, RxGroup targetGroup, bool value) {
    if (positionId != null) {
      targetGroup.members.positions
          .firstWhere((pos) => pos.id == positionId,
              orElse: () => null as RxPosition)
          .sos(value);
    } else {
      targetGroup.members.users
          .firstWhere((user) => user.id == userId, orElse: () => null as RxUser)
          .sos(value);
    }
  }

  void onPanelOpened() {
    HomeController.to.update(['homePageScaffold']);
  }

  void onPanelClosed() {
    resetCurrentNewEventForm();
    HomeController.to.update(['homePageScaffold']);
  }

  void onScroll(ScrollNotification scroll) {
    if (scroll is ScrollUpdateNotification) {
      scrollOffset = scroll.metrics.pixels;
    }
  }

  void onNewEventTap(OutgoingEvent event) {
    openPanel();
    selectNewEvent(event);
  }

  void updateUserEventsList() => update(['userEventsList']);
}
