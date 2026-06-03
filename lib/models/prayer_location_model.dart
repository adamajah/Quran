class PrayerLocation {
  final String city;
  final String region;
  final String country;
  final double latitude;
  final double longitude;
  final bool automatic;

  const PrayerLocation({
    required this.city,
    required this.region,
    required this.country,
    required this.latitude,
    required this.longitude,
    this.automatic = false,
  });

  static const defaultLocation = PrayerLocation(
    city: 'Solear',
    region: 'Kab. Tangerang',
    country: 'Indonesia',
    latitude: -6.2635,
    longitude: 106.4381,
  );

  String get coordinateText {
    final latDirection = latitude >= 0 ? 'LU' : 'LS';
    final lngDirection = longitude >= 0 ? 'BT' : 'BB';
    return '${latitude.abs().toStringAsFixed(4)}°$latDirection, '
        '${longitude.abs().toStringAsFixed(4)}°$lngDirection';
  }

  String get displayName {
    if (automatic) return '$city - $coordinateText';
    return '$city, $region - $country';
  }

  String get modeLabel =>
      automatic ? 'Lokasi perangkat aktif' : 'Lokasi manual';

  Map<String, Object> toJson() => {
    'city': city,
    'region': region,
    'country': country,
    'latitude': latitude,
    'longitude': longitude,
    'automatic': automatic,
  };

  factory PrayerLocation.fromJson(Map<String, dynamic> json) {
    return PrayerLocation(
      city: json['city'] as String? ?? defaultLocation.city,
      region: json['region'] as String? ?? defaultLocation.region,
      country: json['country'] as String? ?? defaultLocation.country,
      latitude:
          (json['latitude'] as num?)?.toDouble() ?? defaultLocation.latitude,
      longitude:
          (json['longitude'] as num?)?.toDouble() ?? defaultLocation.longitude,
      automatic: json['automatic'] as bool? ?? false,
    );
  }

  PrayerLocation copyWith({
    String? city,
    String? region,
    String? country,
    double? latitude,
    double? longitude,
    bool? automatic,
  }) {
    return PrayerLocation(
      city: city ?? this.city,
      region: region ?? this.region,
      country: country ?? this.country,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      automatic: automatic ?? this.automatic,
    );
  }
}
