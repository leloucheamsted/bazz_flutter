import 'package:bazz_flutter/models/app_settings.dart';
import 'package:bazz_flutter/models/session_model.dart';
import 'package:bazz_flutter/modules/location_tracking/location_service.dart';
import 'package:bazz_flutter/modules/shift_activities/models/reporting_point_visit.dart';
import 'package:bazz_flutter/services/networking_client.dart';
import 'package:bazz_flutter/utils/utils.dart';
import 'package:dio/dio.dart';
import 'package:geolocator/geolocator.dart';

class ShiftRepository {
  Future<Response<Map<String, dynamic>>> createShift() async {
    Map<String, dynamic>? coordinate;
    if (AppSettings().verifyUserLocationForPositionShift) {
      final Position currentPosition =
          await LocationService().getCurrentPosition();
      coordinate = currentPosition != null
          ? {
              "latitude": currentPosition.latitude,
              "longitude": currentPosition.longitude,
            }
          : null;
    }
    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/Shift/Create',
      data: {
        'positionId': Session.shift!.positionId!,
        "coordinate": coordinate!,
      },
    );
    return resp;
  }

  Future<Response<Map<String, dynamic>>> createShiftForSelectedPosition(
      String positionId, Position currentPosition) async {
    Map<String, dynamic>? coordinate;
    if (AppSettings().verifyUserLocationForPositionShift) {
      coordinate = currentPosition != null
          ? {
              "latitude": currentPosition.latitude,
              "longitude": currentPosition.longitude,
            }
          : null;
    }

    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/Shift/Create',
      data: {
        'positionId': positionId,
        "coordinate": coordinate!,
        // "coordinate": null, //for testing purposes
      },
    );
    return resp;
  }

  Future<Response<Map<String, dynamic>>> closeShift(
      DateTime shiftEndTime) async {
    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/Shift/Close',
      data: {
        'shiftId': Session.shift!.id!,
        'closeAt': dateTimeToSeconds(shiftEndTime),
        'withLogout': true,
      },
    );
    return resp;
  }

  Future<Response<Map<String, dynamic>>> sendRPointVisit(
      ReportingPointVisit rPointVisit) async {
    final resp = await NetworkingClient().post<Map<String, dynamic>>(
      '/Shift/ReportPoint',
      data: {
        //TODO: handle the offline shift change case, in this case we can't send current Session.shift.id
        'shiftId': Session.shift!.id!,
        'state': rPointVisit.toMapForServer(),
      },
    );
    return resp;
  }
}
