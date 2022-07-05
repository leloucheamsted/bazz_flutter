import 'package:bazz_flutter/constants.dart';
import 'package:bazz_flutter/services/networking_client.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

class EventsRepository {
  Future<Future<Response<Map<String, dynamic>>>> createEvent(
      Map<String, dynamic> eventData) async {
    return NetworkingClient().post<Map<String, dynamic>>(
      '/Event/CreateV2',
      data: eventData as Map<String, Object>,
    );
  }

  Future<Response<Map<String, dynamic>>> confirmEvent(String id) {
    return NetworkingClient().post<Map<String, dynamic>>(
      '/Event/Confirm',
      data: {
        "eventId": id,
      },
    );
  }

  Future<void> closeEvent({
    required String id,
    required String description,
    required List<String> imageUrls,
    required List<String> videoUrls,
    required EventResolveStatus resolveStatus,
    required bool isPostponed,
  }) async {
    await NetworkingClient().post<Map<String, dynamic>>(
      '/Event/Close',
      data: {
        "eventId": id,
        "description": description,
        "imageUrls": imageUrls,
        "videoUrls": videoUrls,
        "resolveStatus": resolveStatus.index,
        "isPostponed": isPostponed,
      },
    );
  }

  Future<Map<String, dynamic>> fetchEventTypesConfig() async {
    final resp =
        await NetworkingClient().post<Map<String, dynamic>>('/Event/GetTypes');
    return resp.data!;
  }
}
