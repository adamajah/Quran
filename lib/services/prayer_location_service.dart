import 'dart:async';
import 'dart:convert';

import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_location_model.dart';

class PrayerLocationResult {
  final PrayerLocation location;
  final String? message;

  const PrayerLocationResult({required this.location, this.message});
}

class PrayerLocationService {
  static const _storageKey = 'prayer_location_v1';

  static const manualLocations = [
    PrayerLocation.defaultLocation,
    PrayerLocation(
      city: 'Jakarta',
      region: 'DKI Jakarta',
      country: 'Indonesia',
      latitude: -6.2088,
      longitude: 106.8456,
    ),
    PrayerLocation(
      city: 'Bandung',
      region: 'Jawa Barat',
      country: 'Indonesia',
      latitude: -6.9175,
      longitude: 107.6191,
    ),
    PrayerLocation(
      city: 'Surabaya',
      region: 'Jawa Timur',
      country: 'Indonesia',
      latitude: -7.2575,
      longitude: 112.7521,
    ),
    PrayerLocation(
      city: 'Yogyakarta',
      region: 'DI Yogyakarta',
      country: 'Indonesia',
      latitude: -7.7956,
      longitude: 110.3695,
    ),
    PrayerLocation(
      city: 'Medan',
      region: 'Sumatera Utara',
      country: 'Indonesia',
      latitude: 3.5952,
      longitude: 98.6722,
    ),
    PrayerLocation(
      city: 'Makassar',
      region: 'Sulawesi Selatan',
      country: 'Indonesia',
      latitude: -5.1477,
      longitude: 119.4327,
    ),
  ];

  Future<PrayerLocation> loadLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return PrayerLocation.defaultLocation;
    try {
      return PrayerLocation.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return PrayerLocation.defaultLocation;
    }
  }

  Future<PrayerLocationResult> loadActiveLocation() async {
    final saved = await loadLocation();
    if (!saved.automatic) return PrayerLocationResult(location: saved);
    return useCurrentLocation();
  }

  Future<void> saveLocation(PrayerLocation location) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_storageKey, jsonEncode(location.toJson()));
  }

  Future<PrayerLocationResult> useManualLocation(
    PrayerLocation location,
  ) async {
    final selected = location.copyWith(automatic: false);
    await saveLocation(selected);
    return PrayerLocationResult(location: selected);
  }

  Future<PrayerLocationResult> useCurrentLocation() async {
    final saved = await loadLocation();
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return PrayerLocationResult(
        location: saved,
        message: 'Layanan lokasi belum aktif. Menggunakan lokasi terakhir.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      return PrayerLocationResult(
        location: saved,
        message: 'Izin lokasi ditolak. Menggunakan lokasi terakhir.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      return PrayerLocationResult(
        location: saved,
        message:
            'Izin lokasi ditolak permanen. Aktifkan dari pengaturan perangkat.',
      );
    }

    try {
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 12),
        ),
      );
      final placemark = await _placemarkFor(position);
      final location = _locationFromPosition(position, placemark);
      await saveLocation(location);
      return PrayerLocationResult(location: location);
    } catch (_) {
      return PrayerLocationResult(
        location: saved,
        message: 'Gagal membaca lokasi. Menggunakan lokasi terakhir.',
      );
    }
  }

  Future<Placemark?> _placemarkFor(Position position) async {
    try {
      final placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      ).timeout(const Duration(seconds: 8));
      if (placemarks.isEmpty) return null;
      return placemarks.first;
    } catch (_) {
      return null;
    }
  }

  PrayerLocation _locationFromPosition(Position position, Placemark? place) {
    if (place == null) {
      return PrayerLocation(
        city: 'Lokasi Saat Ini',
        region: 'Koordinat Perangkat',
        country: 'Lokasi Perangkat',
        latitude: position.latitude,
        longitude: position.longitude,
        automatic: true,
      );
    }

    final city = _firstFilled([
      place.street,
      place.name,
      place.subLocality,
      place.locality,
      'Lokasi Saat Ini',
    ]);
    final region = _joinUnique([
      place.subLocality,
      place.locality,
      place.subAdministrativeArea,
      place.administrativeArea,
    ], skip: city);
    final country = _firstFilled([place.country, 'Lokasi Perangkat']);

    return PrayerLocation(
      city: city,
      region: region.isEmpty ? 'Koordinat Perangkat' : region,
      country: country,
      latitude: position.latitude,
      longitude: position.longitude,
      automatic: true,
    );
  }

  String _firstFilled(List<String?> values) {
    for (final value in values) {
      final cleaned = _cleanPlacePart(value);
      if (cleaned.isNotEmpty) return cleaned;
    }
    return '';
  }

  String _joinUnique(List<String?> values, {required String skip}) {
    final parts = <String>[];
    final skipped = skip.toLowerCase();
    for (final value in values) {
      final cleaned = _cleanPlacePart(value);
      if (cleaned.isEmpty) continue;
      if (cleaned.toLowerCase() == skipped) continue;
      if (parts.any((part) => part.toLowerCase() == cleaned.toLowerCase())) {
        continue;
      }
      parts.add(cleaned);
    }
    return parts.join(', ');
  }

  String _cleanPlacePart(String? value) {
    final cleaned = value?.trim() ?? '';
    if (cleaned.isEmpty) return '';
    if (cleaned.toLowerCase() == 'unnamed road') return '';
    return cleaned;
  }
}
