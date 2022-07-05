import 'dart:math' as Math;

class KalmanLatLong {
  final double _minAccuracy = 1;

  double? _qMetresPerSecond;
  double? _timeStampMilliseconds;
  double? _lat;
  double? _lng;
  double?
      _variance; // P matrix.  Negative means object uninitialised.  NB: units irrelevant, as long as same units used throughout

  KalmanLatLong(double qMetresPerSecond) {
    _qMetresPerSecond = qMetresPerSecond;
    _variance = -1;
  }

  double? get timeStamp {
    return _timeStampMilliseconds;
  }

  double? get latitude {
    return _lat;
  }

  double? get longitude {
    return _lng;
  }

  double get accuracy {
    return Math.sqrt(_variance!);
  }

  void setState(
      double lat, double lng, double accuracy, double timeStampMilliseconds) {
    _lat = lat;
    _lng = lng;
    _variance = accuracy * accuracy;
    _timeStampMilliseconds = timeStampMilliseconds;
  }

  ///
  /// Kalman filter processing for lattitude and longitude.
  ///
  /// latMeasurement: New measurement of lattidude.
  ///
  /// lngMeasurement: New measurement of longitude.
  ///
  /// accuracy: Measurement of 1 standard deviation error in metres.
  ///
  /// timeStampMilliseconds: Time of measurement.
  ///
  /// returns: new state.
  ///
  void process(double latMeasurement, double lngMeasurement, double accuracy,
      double timeStampMilliseconds) {
    if (accuracy < _minAccuracy) accuracy = _minAccuracy;
    if (_variance! < 0) {
      // if variance < 0, object is unitialised, so initialise with current values
      _timeStampMilliseconds = timeStampMilliseconds;
      _lat = latMeasurement;
      _lng = lngMeasurement;
      _variance = accuracy * accuracy;
    } else {
      // else apply Kalman filter methodology

      final double timeIncMilliseconds =
          timeStampMilliseconds - _timeStampMilliseconds!;
      if (timeIncMilliseconds > 0) {
        // time has moved on, so the uncertainty in the current position increases
        _variance = _variance! +
            timeIncMilliseconds *
                _qMetresPerSecond! *
                _qMetresPerSecond! /
                1000;
        _timeStampMilliseconds = timeStampMilliseconds;
        // TO DO: USE VELOCITY INFORMATION HERE TO GET A BETTER ESTIMATE OF CURRENT POSITION
      }

      // Kalman gain matrix K = Covarariance * Inverse(Covariance + MeasurementVariance)
      // NB: because K is dimensionless, it doesn't matter that variance has different units to lat and lng
      double K = _variance! / (_variance! + accuracy * accuracy);
      // apply K
      _lat = _lat! + K * (latMeasurement - _lat!);
      _lng = _lat! + K * (lngMeasurement - _lng!);
      // new Covarariance  matrix is (IdentityMatrix - K) * Covarariance
      _variance = (1 - K) * _variance!;
    }
  }
}
