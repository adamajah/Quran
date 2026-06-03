import 'dart:convert';

import 'package:adhan/adhan.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prayer_location_model.dart';
import '../models/prayer_settings_model.dart';
import '../models/prayer_time_model.dart';

class PrayerTimeService {
  static const _settingsKey = 'prayer_settings_v1';

  Future<PrayerSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_settingsKey);
    if (raw == null) return const PrayerSettings();
    try {
      return PrayerSettings.fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (_) {
      return const PrayerSettings();
    }
  }

  Future<void> saveSettings(PrayerSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_settingsKey, jsonEncode(settings.toJson()));
  }

  PrayerDaySchedule scheduleForDate({
    required DateTime date,
    required PrayerLocation location,
    required PrayerSettings settings,
  }) {
    final coordinates = Coordinates(location.latitude, location.longitude);
    final params = _parametersFor(location: location, settings: settings);
    final prayerTimes = PrayerTimes(
      coordinates,
      DateComponents.from(date),
      params,
      utcOffset: date.timeZoneOffset,
    );

    final entries = [
      PrayerTimeEntry(
        type: PrayerTimeType.imsak,
        time: _localPrayerTime(
          prayerTimes.fajr,
          minutes: -10 + settings.adjustmentFor('imsak'),
        ),
      ),
      PrayerTimeEntry(
        type: PrayerTimeType.subuh,
        time: _localPrayerTime(
          prayerTimes.fajr,
          minutes: settings.adjustmentFor('subuh'),
        ),
      ),
      PrayerTimeEntry(
        type: PrayerTimeType.terbit,
        time: _localPrayerTime(
          prayerTimes.sunrise,
          minutes: settings.adjustmentFor('terbit'),
        ),
      ),
      PrayerTimeEntry(
        type: PrayerTimeType.dzuhur,
        time: _localPrayerTime(
          prayerTimes.dhuhr,
          minutes: settings.adjustmentFor('dzuhur'),
        ),
      ),
      PrayerTimeEntry(
        type: PrayerTimeType.ashar,
        time: _localPrayerTime(
          prayerTimes.asr,
          minutes: settings.adjustmentFor('ashar'),
        ),
      ),
      PrayerTimeEntry(
        type: PrayerTimeType.maghrib,
        time: _localPrayerTime(
          prayerTimes.maghrib,
          minutes: settings.adjustmentFor('maghrib'),
        ),
      ),
      PrayerTimeEntry(
        type: PrayerTimeType.isya,
        time: _localPrayerTime(
          prayerTimes.isha,
          minutes: settings.adjustmentFor('isya'),
        ),
      ),
    ];

    return PrayerDaySchedule(
      date: date,
      hijriDate: hijriDateFor(date, settings),
      entries: entries,
    );
  }

  DateTime _localPrayerTime(DateTime time, {required int minutes}) {
    return DateTime(
      time.year,
      time.month,
      time.day,
      time.hour,
      time.minute,
      time.second,
      time.millisecond,
      time.microsecond,
    ).add(Duration(minutes: minutes));
  }

  List<PrayerDaySchedule> schedulesFor30Days({
    required PrayerLocation location,
    required PrayerSettings settings,
    DateTime? startDate,
  }) {
    final start = startDate ?? DateTime.now();
    return List.generate(30, (index) {
      final date = DateTime(start.year, start.month, start.day + index);
      return scheduleForDate(
        date: date,
        location: location,
        settings: settings,
      );
    });
  }

  String hijriDateFor(DateTime date, PrayerSettings settings) {
    final adjustment =
        settings.automaticHijri ||
                settings.hijriMethod == HijriCalculationMethod.ummAlQura
            ? 0
            : settings.hijriAdjustment;
    final adjusted = date.add(Duration(days: adjustment));
    HijriCalendar.setLocal('en');
    final hijri = HijriCalendar.fromDate(adjusted);
    return '${hijri.hDay} ${_indonesianHijriMonth(hijri.hMonth)} ${hijri.hYear} H';
  }

  CalculationParameters _parametersFor({
    required PrayerLocation location,
    required PrayerSettings settings,
  }) {
    final method = _effectiveCalculationMethod(location, settings);
    final params = switch (method) {
      PrayerCalculationMethod.kemenagIndonesia => CalculationParameters(
        fajrAngle: 20,
        ishaAngle: 18,
        method: CalculationMethod.other,
      ),
      PrayerCalculationMethod.muslimWorldLeague =>
        CalculationMethod.muslim_world_league.getParameters(),
      PrayerCalculationMethod.ummAlQura =>
        CalculationMethod.umm_al_qura.getParameters(),
      PrayerCalculationMethod.egyptian =>
        CalculationMethod.egyptian.getParameters(),
      PrayerCalculationMethod.karachi =>
        CalculationMethod.karachi.getParameters(),
      PrayerCalculationMethod.dubai => CalculationMethod.dubai.getParameters(),
      PrayerCalculationMethod.qatar => CalculationMethod.qatar.getParameters(),
      PrayerCalculationMethod.kuwait =>
        CalculationMethod.kuwait.getParameters(),
      PrayerCalculationMethod.singapore =>
        CalculationMethod.singapore.getParameters(),
    };

    params.madhab =
        settings.asrMethod == PrayerAsrMethod.hanafi
            ? Madhab.hanafi
            : Madhab.shafi;
    return params;
  }

  PrayerCalculationMethod _effectiveCalculationMethod(
    PrayerLocation location,
    PrayerSettings settings,
  ) {
    if (!settings.automaticCalculation) return settings.calculationMethod;

    final lat = location.latitude;
    final lng = location.longitude;
    if (_inBounds(
      lat,
      lng,
      south: -11.2,
      north: 6.4,
      west: 94.6,
      east: 141.1,
    )) {
      return PrayerCalculationMethod.kemenagIndonesia;
    }
    if (_inBounds(lat, lng, south: 1.1, north: 1.6, west: 103.5, east: 104.1)) {
      return PrayerCalculationMethod.singapore;
    }
    if (_inBounds(lat, lng, south: 22.6, north: 26.3, west: 51.4, east: 56.5)) {
      return PrayerCalculationMethod.dubai;
    }
    if (_inBounds(lat, lng, south: 24.4, north: 26.3, west: 50.7, east: 51.7)) {
      return PrayerCalculationMethod.qatar;
    }
    if (_inBounds(lat, lng, south: 28.4, north: 30.2, west: 46.4, east: 48.6)) {
      return PrayerCalculationMethod.kuwait;
    }
    if (_inBounds(lat, lng, south: 16.0, north: 32.5, west: 34.4, east: 55.7)) {
      return PrayerCalculationMethod.ummAlQura;
    }
    if (_inBounds(lat, lng, south: 22.0, north: 31.8, west: 24.6, east: 36.9)) {
      return PrayerCalculationMethod.egyptian;
    }
    if (_inBounds(lat, lng, south: 23.5, north: 37.2, west: 60.8, east: 77.2)) {
      return PrayerCalculationMethod.karachi;
    }
    return PrayerCalculationMethod.muslimWorldLeague;
  }

  bool _inBounds(
    double lat,
    double lng, {
    required double south,
    required double north,
    required double west,
    required double east,
  }) {
    return lat >= south && lat <= north && lng >= west && lng <= east;
  }

  String _indonesianHijriMonth(int month) {
    const names = [
      'Muharram',
      'Safar',
      'Rabiul Awal',
      'Rabiul Akhir',
      'Jumadil Awal',
      'Jumadil Akhir',
      'Rajab',
      'Syaban',
      'Ramadhan',
      'Syawal',
      'Dzulqaidah',
      'Dzulhijjah',
    ];
    return names[(month - 1).clamp(0, names.length - 1)];
  }
}
