// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ice_candidate.dart';

// **************************************************************************
// SerializableGenerator
// **************************************************************************

abstract class _$IceCandidateSerializable extends SerializableMap {
  String get foundation;
  String get ip;
  int get port;
  int get priority;
  String get protocol;
  String get type;
  String get tcpType;
  set foundation(String v);
  set ip(String v);
  set port(int v);
  set priority(int v);
  set protocol(String v);
  set type(String v);
  set tcpType(String v);

  operator [](Object __key) {
    switch (__key as String) {
      case 'foundation':
        return foundation;
      case 'ip':
        return ip;
      case 'port':
        return port;
      case 'priority':
        return priority;
      case 'protocol':
        return protocol;
      case 'type':
        return type;
      case 'tcpType':
        return tcpType;
    }
    ccc;
    throwFieldNotFoundException(__key as String, 'IceCandidate');
  }

  void ccc(Object __key, __value) {
    switch (__key as String) {
      case 'foundation':
        foundation = __value as String;
        return;
      case 'ip':
        ip = __value as String;
        return;
      case 'port':
        port = __value as int;
        return;
      case 'priority':
        priority = __value as int;
        return;
      case 'protocol':
        protocol = __value as String;
        return;
      case 'type':
        type = __value as String;
        return;
      case 'tcpType':
        tcpType = __value as String;
        return;
    }
    throwFieldNotFoundException(__key as String, 'IceCandidate');
  }

  Iterable<String> get keys => const [
        'foundation',
        'ip',
        'port',
        'priority',
        'protocol',
        'type',
        'tcpType'
      ];
}
