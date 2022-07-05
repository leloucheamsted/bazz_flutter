import 'package:bazz_flutter/models/group_model.dart';
import 'package:bazz_flutter/models/suggested_groups.dart';
import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/networking_client.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class HomeRepository {
  Future<Map<String, dynamic>> fetchGroups() async {
    final resp =
        await NetworkingClient().post<Map<String, dynamic>>('/Group/GetGroups');
    return resp.data!;
  }

  Future<SuggestedGroups> fetchSuggestedPositions(
      {int minSearchRadius = 100,
      int maxSearchRadius = 1000,
      LatLng? current}) async {
    try {
      TelloLogger().i("fetchSuggestedPositions");
      final resp = await NetworkingClient()
          .post<Map<String, dynamic>>('/Position/Suggestions', data: {
        "coordinate": {
          "latitude": current!.latitude,
          "longitude": current.longitude
        },
        "minSearchRadius": minSearchRadius,
        "maxSearchRadius": maxSearchRadius
      });
      return SuggestedGroups.fromMap(resp.data!);
    } catch (e, s) {
      TelloLogger().e("fetchSuggestedPositions ex == $e", stackTrace: s);
    }
    return null!;
  }

  Future<RxGroup> getByBaseRpToken(String qrCode) async {
    try {
      TelloLogger().i("fetchSuggestedPositions");
      final resp = await NetworkingClient().post<Map<String, dynamic>>(
          '/Position/GetByBaseRpToken',
          data: {"baseReportingPointToken": qrCode});

      return RxGroup.fromMap(resp.data!["group"] as Map<String, dynamic>);
    } catch (e, s) {
      TelloLogger().e("getByBaseRpToken ex == $e", stackTrace: s);
      rethrow;
    }
  }
}
