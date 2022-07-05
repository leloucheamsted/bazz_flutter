import 'dart:async';

import 'package:flutter/services.dart';
import 'gnss_status_model.dart';

class GnssStatus {
  /// This channel hooks onto the stream for GnssStatus events
  static const EventChannel _gnssStatusEventChannel =
      EventChannel('dev.jorgeho1995.gnss_status/gnss_status');

  Stream<GnssStatusModel> _gnssStatusEvents;

  /// Getter for GnssStatus events
  Stream<GnssStatusModel> get gnssStatusEvents {
    if (_gnssStatusEvents == null) {
      _gnssStatusEvents = _gnssStatusEventChannel.receiveBroadcastStream().map(
          (dynamic event) => GnssStatusModel.fromJson(
              new Map<String, dynamic>.from(event as Map<dynamic, dynamic>)));
    }
    return _gnssStatusEvents;
  }
}
