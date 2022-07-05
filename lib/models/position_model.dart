import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/models/coordinates_model.dart';
import 'package:bazz_flutter/models/group_model.dart';
import 'package:bazz_flutter/models/perimeter.dart';
import 'package:bazz_flutter/models/position_type_model.dart';
import 'package:bazz_flutter/models/user_model.dart';
import 'package:get/get_rx/get_rx.dart';

class RxPosition {
  RxPosition(
      {required this.id,
      required this.parentId,
      required this.parentPosition,
      required this.parentGroup,
      required this.title,
      required this.coordinates,
      required this.workerLocation,
      required this.positionType,
      required this.worker,
      required this.customer,
      required this.status,
      required this.perimeter,
      required this.shiftStartedAt,
      required this.statusUpdatedAt,
      required this.alertCheckStateUpdatedAt,
      required this.shiftDuration,
      required this.alertCheckState,
      required this.imageSrc,
      required this.hasTours,
      required this.qrCode,
      required this.distance});

  final String id;
  final String parentId;
  RxPosition parentPosition;
  final String title;
  final String imageSrc;

  //TODO: not sure if we need it, check later
  final Coordinates coordinates;
  final Rx<Coordinates> workerLocation;
  final PositionType positionType;
  final Rx<PositionStatus> status;
  final Perimeter perimeter;
  final RxBool isTransmitting = false.obs;
  final RxBool sos = false.obs;
  final Rx<AlertCheckState> alertCheckState;
  final int shiftDuration;
  final bool hasTours;
  Rx<RxUser> worker, customer;
  RxGroup parentGroup;
  int shiftStartedAt;
  int statusUpdatedAt;
  int alertCheckStateUpdatedAt;
  int distance;
  String qrCode;
  Map<String, dynamic>? _rawData;

  Map<String, dynamic> get rawData => _rawData!;

  bool get hasWorker => worker() != null;

  bool get hasNoWorker => !hasWorker;

  RxPosition clone() {
    return RxPosition.fromMap(toMap());
  }

  factory RxPosition.fromMap(Map<String, dynamic> map,
      {bool listFromJson = false}) {
    final position = RxPosition(
      id: map["id"] as String,
      parentId: map["parentId"] != null ? map["parentId"] as String : null!,
      title: map["title"] as String,
      coordinates: map["baseCoordinate"] != null
          ? Coordinates.fromMap(map["baseCoordinate"] as Map<String, dynamic>)
          : null!,
      workerLocation: map["coordinate"] != null
          ? Coordinates.fromMap(map["coordinate"] as Map<String, dynamic>).obs
          : null!,
      positionType: PositionType.fromMap(map["type"] as Map<String, dynamic>),
      worker: map["worker"] != null
          ? RxUser.fromMap(map["worker"] as Map<String, dynamic>).obs
          : null!,
      customer: map["customer"] != null
          ? RxUser.fromMap(map["customer"] as Map<String, dynamic>).obs
          : null!,
      status: map["status"] != null
          ? PositionStatus.values[map["status"] as int].obs
          : PositionStatus.values[1].obs,
      perimeter: map["perimeter"] != null
          ? Perimeter.fromMap(map["perimeter"] as Map<String, dynamic>,
              listFromJson: listFromJson)
          : null!,
      shiftStartedAt: map["shiftStartedAt"] as int,
      statusUpdatedAt: map["statusUpdatedAt"] as int,
      hasTours: map["hasTours"] as bool,
      qrCode: map["qrCode"] != null ? map["qrCode"] as String : null!,
      alertCheckStateUpdatedAt: map["checkStateUpdatedAt"] as int,
      shiftDuration: map["shiftDuration"] as int,
      imageSrc: map["imageSrc"] != null ? map["imageSrc"] as String : null!,
      // yes, the checkState enum on the server starts from 1
      alertCheckState:
          AlertCheckState.values[(map['checkState'] as int) - 1].obs,
      distance: map["distance"] != null ? map["distance"] as int : 0,
      parentGroup: null as RxGroup, parentPosition: null as RxPosition,
    );
    // ignore: prefer_initializing_formals
    position._rawData = map;
    return position;
  }

  Map<String, dynamic> toMap({bool listToJson = false}) => {
        "id": id,
        "parentId": parentId,
        "status": status().index,
        "title": title,
        "imageSrc": imageSrc,
        "baseCoordinate": coordinates.toMap(),
        "coordinate": workerLocation().toMap(),
        "perimeter": perimeter.toMap(listToJson: listToJson),
        "type": positionType.toMap(),
        "worker": worker().toMap(),
        "shiftDuration": shiftDuration,
        // we increment it because we use toMap() for deserializing both from server and local storage
        "checkState": alertCheckState().index + 1,
        "shiftStartedAt": shiftStartedAt,
        "alertCheckStateUpdatedAt": alertCheckStateUpdatedAt,
        "statusUpdatedAt": statusUpdatedAt,
        "checkStateUpdatedAt": alertCheckStateUpdatedAt,
        "hasTours": hasTours,
        "qrCode": qrCode
      };

  RxPosition copyWith({
    String? id,
    String? parentId,
    RxPosition? parentPosition,
    String? title,
    String? imageSrc,
    Coordinates? coordinates,
    Rx<Coordinates>? workerLocation,
    PositionType? positionType,
    Rx<PositionStatus>? status,
    Perimeter? perimeter,
    Rx<AlertCheckState>? alertCheckState,
    int? shiftDuration,
    bool? hasTours,
    Rx<RxUser>? worker,
    Rx<RxUser>? customer,
    RxGroup? parentGroup,
    int? shiftStartedAt,
    int? statusUpdatedAt,
    int? alertCheckStateUpdatedAt,
    int? distance,
    String? qrCode,
  }) {
    return RxPosition(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      parentPosition: parentPosition ?? this.parentPosition.copyWith(),
      title: title ?? this.title,
      imageSrc: imageSrc ?? this.imageSrc,
      coordinates: coordinates ?? this.coordinates,
      workerLocation: workerLocation ?? this.workerLocation().obs,
      positionType: positionType ??
          this.positionType.copyWith(
              id: "id",
              title: "title",
              mobilityType: null as MobilityType,
              locationType: null as LocationType),
      status: status ?? this.status().obs,
      perimeter: perimeter ?? this.perimeter,
      alertCheckState: alertCheckState ?? this.alertCheckState().obs,
      shiftDuration: shiftDuration ?? this.shiftDuration,
      hasTours: hasTours ?? this.hasTours,
      worker: worker ?? this.worker().obs,
      customer: customer ?? this.customer().obs,
      parentGroup: parentGroup ?? this.parentGroup,
      shiftStartedAt: shiftStartedAt ?? this.shiftStartedAt,
      statusUpdatedAt: statusUpdatedAt ?? this.statusUpdatedAt,
      alertCheckStateUpdatedAt:
          alertCheckStateUpdatedAt ?? this.alertCheckStateUpdatedAt,
      distance: distance ?? this.distance,
      qrCode: qrCode ?? this.qrCode,
    );
  }
// Map<String, dynamic> toInfoCardMap() => {
//       "id": id,
//       "title": title,
//       "status": status().index,
//     };
}

class PositionInfoCard {
  final String id, title;
  final PositionStatus status;
  final AlertCheckState alertCheckState;
  final int statusUpdatedAt, alertCheckStateUpdatedAt;

  PositionInfoCard.fromPosition(RxPosition pos)
      : id = pos.id,
        title = pos.title,
        status = pos.status(),
        alertCheckState = pos.alertCheckState(),
        statusUpdatedAt = pos.statusUpdatedAt,
        alertCheckStateUpdatedAt = pos.alertCheckStateUpdatedAt;

  PositionInfoCard.fromMap(Map<String, dynamic> map)
      : id = map['id'] as String,
        title = map['title'] as String,
        status = PositionStatus.values[map['status'] as int],
        alertCheckState =
            AlertCheckState.values[(map['checkState'] as int) - 1],
        statusUpdatedAt = map['statusUpdatedAt'] as int,
        alertCheckStateUpdatedAt = map['checkStateUpdatedAt'] as int;

  Map<String, dynamic> toMap() => {
        'id': id,
        'title': title,
        'status': status.index,
        'checkState': alertCheckState.index + 1,
        'statusUpdatedAt': statusUpdatedAt,
        'checkStateUpdatedAt': alertCheckStateUpdatedAt,
      };
}
