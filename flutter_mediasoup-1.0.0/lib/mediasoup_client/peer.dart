import 'package:json_annotation/json_annotation.dart';
import 'device.dart';

part 'peer.g.dart';

@JsonSerializable(nullable: false)
class Peer {
  String? id;
  String? displayName;
  Device? device;

  toMap() => _$PeerToJson(this);

  static Peer fromJson(Map json) =>
      _$PeerFromJson(json as Map<String, dynamic>);
}
