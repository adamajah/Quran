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
    final params = _parametersFor(settings);
    final prayerTimes = PrayerTimes(
      coordinates,
      DateComponents.from(date),
      params,
      utcOffset: date.timeZoneOffset,
    );

    final entries = [
      PrayerTimeEntry(
        type: PrayerTimeType.imsak,
        time: prayerTimes.fajr.add(
          Duration(minutes: -10 + settings.adjustmentFor('imsak')),
        ),
      ),
      PrayerTimeEntry(
        type: PrayerTimeType.subuh,
        time: prayerTimes.fajr.add(
          Duration(minutes: settings.adjustmentFor('subuh')),
        ),
      ),
      PrayerTimeEntry(
        type: PrayerTimeType.terbit,
        time: prayerTimes.sunrise.add(
          Duration(minutes: settings.adjustmentFor('terbit')),
        ),
      ),
      PrayerTimeEntry(
        type: PrayerTimeType.dzuhur,
        time: prayerTimes.dhuhr.add(
          Duration(minutes: settings.adjustmentFor('dzuhur')),
        ),
      ),
      PrayerTimeEntry(
        type: PrayerTimeType.ashar,
        time: prayerTimes.asr.add(
          Duration(minutes: settings.adjustmentFor('ashar')),
        ),
      ),
      PrayerTimeEntry(
        type: PrayerTimeType.maghrib,
        time: prayerTimes.maghrib.add(
          Duration(minutes: settings.adjustmentFor('maghrib')),
        ),
      ),
      PrayerTimeEntry(
        type: PrayerTimeType.isya,
        time: prayerTimes.isha.add(
          Duration(minutes: settings.adjustmentFor('isya')),
        ),
      ),
    ];

    return PrayerDaySchedule(
      date: date,
      hijriDate: hijriDateFor(date, settings),
      entries: entries,
    );
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
    final adjusted = date.add(Duration(days: settings.hijriAdjustment));
    HijriCalendar.setLocal('en');
    final hijri = HijriCalendar.fromDate(adjusted);
    return '${hijri.hDay} ${_indonesianHijriMonth(hijri.hMonth)} ${hijri.hYear} H';
  }

  CalculationParameters _parametersFor(PrayerSettings settings) {
    final params = switch (settings.calculationMethod) {
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
