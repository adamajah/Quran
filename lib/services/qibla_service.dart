import 'dart:math' as math;

import '../models/prayer_location_model.dart';

class QiblaInfo {
  final double directionDegrees;
  final double distanceKm;

  const QiblaInfo({required this.directionDegrees, required this.distanceKm});
}

class QiblaService {
  static const kaabaLatitude = 21.4225;
  static const kaabaLongitude = 39.8262;

  QiblaInfo calculate(PrayerLocation location) {
    final lat1 = _toRadians(location.latitude);
    final lat2 = _toRadians(kaabaLatitude);
    final deltaLng = _toRadians(kaabaLongitude - location.longitude);

    final y = math.sin(deltaLng);
    final x =
        math.cos(lat1) * math.tan(lat2) - math.sin(lat1) * math.cos(deltaLng);
    final bearing = (_toDegrees(math.atan2(y, x)) + 360) % 360;

    return QiblaInfo(
      directionDegrees: bearing,
      distanceKm: _distanceKm(location.latitude, location.longitude),
    );
  }

  double _distanceKm(double latitude, double longitude) {
    const earthRadiusKm = 6371.0;
    final dLat = _toRadians(kaabaLatitude - latitude);
    final dLng = _toRadians(kaabaLongitude - longitude);
    final lat1 = _toRadians(latitude);
    final lat2 = _toRadians(kaabaLatitude);

    final a =
        math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(dLng / 2) *
            math.sin(dLng / 2);
    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusKm * c;
  }

  double _toRadians(double degrees) => degrees * math.pi / 180;

  double _toDegrees(double radians) => radians * 180 / math.pi;
}
