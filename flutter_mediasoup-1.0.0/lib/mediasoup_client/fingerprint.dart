import 'package:serializable/serializable.dart';

part 'fingerprint.g.dart';

@serializable
class Fingerprint extends _$FingerprintSerializable {
  late String algorithm;
  late String value;

  @override
  void operator []=(key, value) {
    // TODO: implement []=
  }
}
