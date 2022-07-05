import 'package:bazz_flutter/services/logger.dart';
import 'package:bazz_flutter/services/networking_client.dart';
import 'package:latlong/latlong.dart';

class ApiOSRM {
  Future<List<List<LatLng>>> getRoute(
      double longini, double latini, double longend, double latend) async {
    final List<List<LatLng>> routesResult = <List<LatLng>>[];
    try {
      final dataToSend = {
        "startPoint": {"latitude": latini, "longitude": longini},
        "endPoint": {"latitude": latend, "longitude": longend}
      };
      TelloLogger().i("ApiOSRM getRoute dataToSend: $dataToSend");
      final resp = await NetworkingClient2()
          .post<Map<String, dynamic>>('/General/GetRouteV2', data: dataToSend);

      final routes = resp.data!['routes'] != null
          ? resp.data!['routes']['routes'] as List<dynamic>
          : [];

      if (routes.isNotEmpty) {
        List<LatLng> llena = [];
        TelloLogger().i("getpoints 0000 == $routes");
        final coordinates =
            routes[0]["geometry"]["coordinates"] as List<dynamic>;
        TelloLogger().i("getpoints 111 == ${coordinates}");
        for (final coordinate in coordinates) {
          final location = List<double>.from(coordinate as List<dynamic>);
          llena.add(LatLng(location[1], location[0]));
        }
        TelloLogger().i("getpoints llena.length == ${llena.length}");
        routesResult.add(llena);
      }
    } catch (e, s) {
      TelloLogger().e("fetchSuggestedPositions ex == $e", stackTrace: s);
    }
    return routesResult;
  }
}
