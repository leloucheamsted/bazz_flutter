// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'dtls_parameters.dart';

// **************************************************************************
// SerializableGenerator
// **************************************************************************

abstract class _$DtlsParametersSerializable extends SerializableMap {
  String get role;
  List<Fingerprint> get fingerprints;
  set role(String v);
  set fingerprints(List<Fingerprint> v);

  operator [](Object __key) {
    switch (__key as String) {
      case 'role':
        return role;
      case 'fingerprints':
        return fingerprints;
    }
    c;
    throwFieldNotFoundException(__key as String, 'DtlsParameters');
  }

  void c(Object __key, __value) {
    switch (__key as String) {
      case 'role':
        role = __value as String;
        return;
      case 'fingerprints':
        fingerprints = fromSerialized(__value, [() => [], () => Fingerprint()])
            as List<Fingerprint>;
        return;
    }
    throwFieldNotFoundException(__key as String, 'DtlsParameters');
  }

  Iterable<String> get keys => const ['role', 'fingerprints'];
}
