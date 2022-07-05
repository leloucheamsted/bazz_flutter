import 'dart:core';

import 'package:serializable/serializable.dart';

part 'ice_candidate.g.dart';

@serializable
class IceCandidate extends _$IceCandidateSerializable {
  late String foundation;
  late String ip;
  late int port;
  late int priority;
  late String protocol;
  late String type;
  late String tcpType;

  IceCandidate();

  factory IceCandidate.fromJson(json) =>
      IceCandidate()..fromMap(json as Map<dynamic, dynamic>);

  @override
  void operator []=(key, value) {
    // TODO: implement []=
  }
}
