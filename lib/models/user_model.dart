import 'package:bazz_flutter/models/device_card.dart';
import 'package:bazz_flutter/models/user_location_model.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RxUser {
  late String id, nickName, firstName, lastName, avatar, email, phone;
  RxBool isOnline = false.obs,
      isTransmitting = false.obs,
      sos = false.obs,
      isVideoActive = false.obs,
      isVideoConnected = false.obs,
      tracking = false.obs,
      drawingPath = false.obs,
      hasActiveSession = false.obs;
  Role role;
  Rx<UserLocation> location;
  int rating;
  DeviceCard deviceCard;
  int onlineUpdatedAt;
  bool hasGPSSignal;
  bool faceIdLoginEnabled = true;

  String? get fullName => '$firstName $lastName'.capitalize;

  bool? get isSupervisor => role.id == 'Supervisor';

  bool? get isGuard => role.id == 'Guard';

  bool? get isAdmin => role.id == 'Admin';

  bool? get isDriver => role.id == 'Driver';

  bool? get isCustomer => role.id == 'Customer';

  RxUser({
    required this.id,
    required this.nickName,
    required this.firstName,
    required this.lastName,
    required this.avatar,
    required this.role,
    required this.location,
    required this.deviceCard,
    required this.rating,
    required this.onlineUpdatedAt,
    required this.hasGPSSignal,
  });

  // void updateUserDetailsFromMap(Map<String, dynamic> m) {
  //   nickName = m['profile']['nickname'] as String;
  //   firstName = m['profile']['firstName'] as String;
  //   lastName = m['profile']['lastName'] as String;
  //   rating = m['rating'] == null
  //       ? 0.0
  //       : m['rating'] as int;
  //   avatar = m['profile']['avatar'] as String;
  //   location = m['userLocation'] != null
  //       ? UserLocation.fromMap(m['userLocation'] as Map<String, dynamic>).obs
  //       : Rx<UserLocation>();
  //   deviceInfo = m['device'] != null
  //       ? DeviceInfo.fromMap(m['device'] as Map<String, dynamic>).obs
  //       : DeviceInfo.createEmpty().obs;
  //   role = Role.fromMap(m["role"] as Map<String, dynamic>);
  //   isOnline.value = m['isOnline'] as bool;
  //   onlineUpdatedAt = m['onlineUpdatedAt'] as int;
  // }

  void updateFromUser(RxUser user, {bool completely = true}) {
    nickName = user.nickName;
    firstName = user.firstName;
    lastName = user.lastName;
    rating = user.rating;
    avatar = user.avatar;
    //deviceInfo.value = user.deviceInfo.value;
    role = user.role;
    hasGPSSignal = user.hasGPSSignal;
    if (completely) {
      location.value = user.location.value;
      isOnline.value = user.isOnline.value;
      onlineUpdatedAt = user.onlineUpdatedAt;
    }
  }

  RxUser clone() {
    return RxUser.fromMap(toMap());
  }

  RxUser.fromMap(Map<String, dynamic> m)
      : id = m['id'] as String,
        email = m['email'] as String,
        phone = m['phone'] as String,
        nickName = m['profile']['nickname'] as String,
        firstName = m['profile']['firstName'] as String,
        lastName = m['profile']['lastName'] as String,
        avatar = m['profile']['avatar'] as String,
        // ignore: avoid_bool_literals_in_conditional_expressions
        hasGPSSignal = m['noGps'] != null ? !(m['noGps'] as bool) : false,
        location = m['userLocation'] != null
            ? UserLocation.fromMap(m['userLocation']).obs
            : null as Rx<UserLocation>,
        deviceCard = m['deviceCard'] != null
            ? DeviceCard.fromMap(m['deviceCard'] as Map<String, dynamic>)
            : null!,
        role = Role.fromMap(m['role'] as Map<String, dynamic>),
        rating = m['rating'] != null ? m['rating'] as int : 0,
        onlineUpdatedAt =
            m['onlineUpdatedAt'] != null ? m['onlineUpdatedAt'] as int : 0 {
    isOnline.value = m['isOnline'] as bool;
    if (m['hasActiveSession'] != null) {
      hasActiveSession.value = m['hasActiveSession'] as bool;
    } else {
      hasActiveSession.value = false;
    }
  }

  Map<String, Object?> toMap() {
    final map = {
      'id': id,
      'email': email,
      'phone': phone,
      'profile': {
        'nickname': nickName,
        'firstName': firstName,
        'lastName': lastName,
        'avatar': avatar,
      },
      'userLocation': location().toMap(),
      'role': role.toMap(),
      'rating': rating,
      'deviceCard': deviceCard.toMap(),
      'isOnline': isOnline(),
      'hasGPSSignal': hasGPSSignal,
      'onlineUpdatedAt': onlineUpdatedAt,
      'hasActiveSession': hasActiveSession.value
    };
    return map;
  }

  Map<String, Object?> toMapForServer() {
    final map = toMap()
      ..remove('deviceCard')
      ..['device'] = deviceCard.deviceState().toMap();
    return map;
  }

  // ignore: prefer_constructors_over_static_methods
  static RxUser unknownUser(String userId) {
    return RxUser(
        id: userId,
        nickName: "Unknown User",
        firstName: "Unknown",
        lastName: "Unknown",
        avatar: "",
        hasGPSSignal: false,
        location: null as Rx<UserLocation>,
        deviceCard: null as DeviceCard,
        role: Role.fromMap({"id": "", "title": ""}),
        rating: 0,
        onlineUpdatedAt: 0);
  }
}

class Role {
  Role({
    required this.id,
    required this.title,
  });

  final String id;
  final String title;

  factory Role.fromMap(Map<String, dynamic> json) => Role(
        id: json["id"] as String,
        title: json["title"] as String,
      );

  Map<String, dynamic> toMap() => {
        "id": id,
        "title": title,
      };
}
