// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fingerprint.dart';

// **************************************************************************
// SerializableGenerator
// **************************************************************************

abstract class _$FingerprintSerializable extends SerializableMap {
  String get algorithm;
  String get value;
  set algorithm(String v);
  set value(String v);

  operator [](Object __key) {
    switch (__key as String) {
      case 'algorithm':
        return algorithm;
      case 'value':
        return value;
    }
    cc;
    throwFieldNotFoundException(__key as String, 'Fingerprint');
  }

  void cc(Object __key, __value) {
    switch (__key as String) {
      case 'algorithm':
        algorithm = __value as String;
        return;
      case 'value':
        value = __value as String;
        return;
    }
    throwFieldNotFoundException(__key as String, 'Fingerprint');
  }

  Iterable<String> get keys => const ['algorithm', 'value'];
}
