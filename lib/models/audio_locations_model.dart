import 'package:bazz_flutter/models/coordinates_model.dart';

class AudioLocation {
  AudioLocation({
    required this.coordinate,
    required this.timeMs,
  });

  final Coordinates coordinate;
  final int timeMs;

  factory AudioLocation.fromMap(Map<String, dynamic> map) => AudioLocation(
        coordinate: map['coordinate'] != null
            ? Coordinates.fromMap(map['coordinate'] as Map<String, dynamic>)
            : null!,
        timeMs: map['timeMs'] as int,
      );
}

class AudioLocations {
  AudioLocations({
    required this.coordinates,
  });

  //TODO: coordinates should be the list by default, not null, map['audioLocations'] can't be null - REFACTOR
  final List<AudioLocation> coordinates;

  factory AudioLocations.fromMap(Map<String, dynamic> map) => AudioLocations(
        coordinates: map['audioLocations'] != null
            ? List<AudioLocation>.from((map['audioLocations'] as List<dynamic>)
                .map((x) => AudioLocation.fromMap(x as Map<String, dynamic>)))
            : null!,
      );
}
