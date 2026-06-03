import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quran_app/models/prayer_location_model.dart';

void main() {
  test('automatic geocoded location displays the place name', () {
    const location = PrayerLocation(
      city: 'Jalan Merdeka 10',
      region: 'Gambir, Jakarta Pusat, DKI Jakarta',
      country: 'Indonesia',
      latitude: -6.175392,
      longitude: 106.827153,
      automatic: true,
    );

    expect(
      location.displayName,
      'Jalan Merdeka 10, Gambir, Jakarta Pusat, DKI Jakarta - Indonesia',
    );
    expect(location.displayName, isNot(contains('6.1754')));
  });

  test('automatic fallback location still displays coordinates', () {
    const location = PrayerLocation(
      city: 'Lokasi Saat Ini',
      region: 'Koordinat Perangkat',
      country: 'Lokasi Perangkat',
      latitude: -6.175392,
      longitude: 106.827153,
      automatic: true,
    );

    expect(location.displayName, contains('6.1754°LS'));
    expect(location.displayName, contains('106.8272°BT'));
  });
}
