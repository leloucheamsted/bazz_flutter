import 'package:serializable/serializable.dart';
import 'fingerprint.dart';

part 'dtls_parameters.g.dart';

@serializable
class DtlsParameters extends _$DtlsParametersSerializable {
  late String role;
  late List<Fingerprint> fingerprints;

  DtlsParameters();

  factory DtlsParameters.fromJson(json) =>
      DtlsParameters()..fromMap(json as Map<dynamic, dynamic>);

  @override
  void operator []=(key, value) {
    // TODO: implement []=
  }
}
