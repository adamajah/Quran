import 'dart:convert';

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
      final location = PrayerLocation(
        city: 'Lokasi Saat Ini',
        region: 'Koordinat Perangkat',
        country: 'Lokasi Perangkat',
        latitude: position.latitude,
        longitude: position.longitude,
        automatic: true,
      );
      await saveLocation(location);
      return PrayerLocationResult(location: location);
    } catch (_) {
      return PrayerLocationResult(
        location: saved,
        message: 'Gagal membaca lokasi. Menggunakan lokasi terakhir.',
      );
    }
  }
}
