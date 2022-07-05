import 'dart:convert';

import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/incoming_event.dart';
import 'package:bazz_flutter/models/position_model.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:bazz_flutter/models/zone.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

class RxGroup {
  RxGroup({
    this.id,
    this.title,
    this.image,
    this.supervisor,
    this.region,
    this.zone,
    this.lastMessageAt,
  });

  final String? id, title, image;
  final members = Members();
  final RxList<IncomingEvent> events$ = RxList<IncomingEvent>();

  final RxUser? supervisor;
  final Region? region;
  final Zone? zone;
  final RxInt? lastMessageAt;
  Map<String, dynamic>? _rawData;

  Map<String, dynamic> get rawData => _rawData!;

  RxBool get isReceiving => (members.users.any((u) => u.isTransmitting.value) ||
          members.positions.any((p) => p.isTransmitting.value))
      .obs;

  List<IncomingEvent> get roleDependentEvents$ => Session.user!.isGuard!
      ? events$.where((e) => e.isNotSystem).toList()
      : events$;

  /// Unconfirmed and of higher priority go first
  List<IncomingEvent> get sortedEvents {
    final unconfirmed = <IncomingEvent>[];
    final unresolved = <IncomingEvent>[];

    for (final event in roleDependentEvents$) {
      if (event.isNotConfirmed$) {
        unconfirmed.add(event);
      } else {
        unresolved.add(event);
      }
    }

    unresolved.shuffle();
    unconfirmed.sort((a, b) {
      final val = b.priority.index.compareTo(a.priority.index);
      return b.priority.index == a.priority.index
          ? a.createdAt!.compareTo(b.createdAt!)
          : val;
    });
    unresolved.sort((a, b) {
      final val = b.priority.index.compareTo(a.priority.index);
      return b.priority.index == a.priority.index
          ? a.createdAt!.compareTo(b.createdAt!)
          : val;
    });
    return unconfirmed + unresolved;
  }

  List<IncomingEvent> get sosEvents => events$.where((ev) => ev.isSos).toList();

  bool get hasEvents => events$.isNotEmpty;

  bool get hasNoEvents => events$.isEmpty;

  bool get hasUnconfirmedEvents => events$.any((ev) => ev.isNotConfirmed$);

  bool get hasSos => events$.any((ev) => ev.isSos);

  bool get hasNoSos => events$.every((ev) => ev.isNotSos);

  bool get hasUnconfirmedSos =>
      events$.any((ev) => ev.isSos && ev.isNotConfirmed$);

  bool get isCustomerGroup => members.users.any((u) => u.isCustomer!);

  factory RxGroup.fromMap(Map<String, dynamic> map,
      {bool listFromJson = false}) {
    final users = (listFromJson
            ? json.decode(map["users"] as String) as List<dynamic>
            : map["users"] as List<dynamic>)
        .map((x) => RxUser.fromMap(x as Map<String, dynamic>));
    final positions = map["positions"] != null
        ? (listFromJson
                ? json.decode(map["positions"] as String) as List<dynamic>
                : map["positions"] as List<dynamic>)
            .map((x) => RxPosition.fromMap(x as Map<String, dynamic>,
                listFromJson: listFromJson))
        : null;
    final group = RxGroup(
      id: map["id"] as String,
      title: map["title"] as String,
      image: map["photoUrl"] as String,
      supervisor: map["supervisor"] != null
          ? RxUser.fromMap(map["supervisor"] as Map<String, dynamic>)
          : null,
      region: map["region"] != null
          ? Region.fromMap(map["region"] as Map<String, dynamic>,
              listFromJson: listFromJson)
          : null,
      zone: map["zone"] != null
          ? Zone.fromMap(map["zone"] as Map<String, dynamic>,
              listFromJson: listFromJson)
          : null,
      lastMessageAt: (map["lastMessageAt"] as int).obs,
    );
    group.members.users.addAll(users);
    if (positions?.isNotEmpty ?? false)
      group.members.positions.addAll(positions!);
    group.members.sortMembers();

    if (map["events"] != null) {
      group.events$.addAll((map["events"] as List<dynamic>)
          .map((x) => IncomingEvent.fromMap(x)));
      group.saveEvents();
    }

    group.zone!.regionId = group.region?.id;

    // setting sos boolean for every user and position in the group, who emitted sos
    for (final event in group.sosEvents) {
      if (event.ownerPositionId != null) {
        group.members.positions
            .firstWhere((pos) => pos.id == event.ownerPositionId,
                orElse: () => null!)
            .sos(true);
      } else {
        group.members.users
            .firstWhere((user) => user.id == event.ownerId, orElse: () => null!)
            .sos(true);
      }
    }

    for (final position in group.members.positions) {
      if (position.parentId != null) {
        position.parentPosition = group.members.positions.firstWhere(
            (element) => element.id == position.parentId,
            orElse: () => null!);
      }
    }
    // ignore: prefer_initializing_formals
    group._rawData = map;

    return group;
  }

  Map<String, dynamic> toMap({bool listToJson = false}) {
    final usersList =
        List<Map<String, dynamic>>.from(members.users.map((x) => x.toMap()));
    final positionsList = List<Map<String, dynamic>>.from(
        members.positions.map((x) => x.toMap(listToJson: listToJson)));
    return {
      "id": id,
      "title": title,
      "photoUrl": image,
      "supervisor": supervisor?.toMap(),
      "region": region?.toMap(listToJson: listToJson),
      "zone": zone?.toMap(listToJson: listToJson),
      "lastMessageAt": lastMessageAt,
      "users": listToJson ? json.encode(usersList) : usersList,
      "positions": listToJson ? json.encode(positionsList) : positionsList,
    };
  }

  void addEvent(IncomingEvent event) => events$.add(event);

  void removeEvent(String id) => events$.removeWhere((ev) => ev.id == id);

  void saveEvents() {
    final encodedEvents = json.encode(events$.map((e) => e.toMap()).toList());
    GetStorage().write(StorageKeys.incomingEvents, encodedEvents);
  }

  void restoreEvents() {
    final eventsData = GetStorage().read<String>(StorageKeys.incomingEvents);
    events$.addAll((json.decode(eventsData!) as List<dynamic>)
        .map((e) => IncomingEvent.fromMap(e as Map<String, dynamic>)));
  }
}

class Members {
  final users = <RxUser>[];
  final positions = <RxPosition>[];

  final activeUsers = <RxUser>[].obs;
  final activePositions = <RxPosition>[].obs;
  final notActiveUsers = <RxUser>[].obs;
  final notActivePositions = <RxPosition>[].obs;
  final outOfRange = <RxPosition>[].obs;
  final alertnessFailed = <RxPosition>[].obs;

  final activeFilteredUsers = <RxUser>[].obs;
  final activeFilteredPositions = <RxPosition>[].obs;
  final notActiveFilteredUsers = <RxUser>[].obs;
  final notActiveFilteredPositions = <RxPosition>[].obs;
  final outOfRangeFiltered = <RxPosition>[].obs;
  final alertnessFailedFiltered = <RxPosition>[].obs;

  void sortMembers({String filter = ""}) {
    activeUsers.clear();
    notActiveUsers.clear();
    activeFilteredUsers.clear();
    notActiveFilteredUsers.clear();
    for (final user in users) {
      if (user.isOnline()) {
        activeUsers.add(user);
        if (filter.isNotEmpty &&
            user.fullName!.toLowerCase().contains(filter.toLowerCase())) {
          activeFilteredUsers.add(user);
        } else if (filter.isEmpty) {
          activeFilteredUsers.add(user);
        }
      } else {
        notActiveUsers.add(user);
        if (filter.isNotEmpty &&
            user.fullName!.toLowerCase().contains(filter.toLowerCase())) {
          TelloLogger()
              .i("filter.isNotEmpty && user.fullName.contains $filter");
          notActiveFilteredUsers.add(user);
        } else if (filter.isEmpty) {
          TelloLogger().i("filter.isEmpty  $filter");
          notActiveFilteredUsers.add(user);
        }
      }
    }

    activePositions.clear();
    notActivePositions.clear();
    outOfRange.clear();
    alertnessFailed.clear();

    activeFilteredPositions.clear();
    notActiveFilteredPositions.clear();
    outOfRangeFiltered.clear();
    alertnessFailedFiltered.clear();

    for (final position in positions) {
      if (position.alertCheckState() == AlertCheckState.failed) {
        alertnessFailed.add(position);
        if (filter.isNotEmpty && position.title.contains(filter)) {
          alertnessFailedFiltered.add(position);
        } else if (filter.isEmpty) {
          alertnessFailedFiltered.add(position);
        }
      }
      if (position.status() == PositionStatus.active) {
        activePositions.add(position);
        if (filter.isNotEmpty && position.title.contains(filter)) {
          activeFilteredPositions.add(position);
        } else if (filter.isEmpty) {
          activeFilteredPositions.add(position);
        }
      } else if (position.status() == PositionStatus.inactive) {
        notActivePositions.add(position);
        if (filter.isNotEmpty && position.title.contains(filter)) {
          notActiveFilteredPositions.add(position);
        } else if (filter.isEmpty) {
          notActiveFilteredPositions.add(position);
        }
      } else {
        outOfRange.add(position);
        if (filter.isNotEmpty && position.title.contains(filter)) {
          outOfRangeFiltered.add(position);
        } else if (filter.isEmpty) {
          outOfRangeFiltered.add(position);
        }
      }
    }
  }
}
