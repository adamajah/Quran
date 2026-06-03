import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_quran_app/models/prayer_location_model.dart';
import 'package:flutter_quran_app/models/prayer_settings_model.dart';
import 'package:flutter_quran_app/models/prayer_time_model.dart';
import 'package:flutter_quran_app/services/prayer_time_service.dart';

void main() {
  final service = PrayerTimeService();

  test('scheduleForDate includes every prayer time in order', () {
    final schedule = service.scheduleForDate(
      date: DateTime(2026, 6, 3),
      location: PrayerLocation.defaultLocation,
      settings: const PrayerSettings(),
    );

    expect(schedule.entries.map((entry) => entry.type), PrayerTimeType.values);
    expect(schedule.hijriDate, isNotEmpty);
  });

  test('schedulesFor30Days starts from the requested local date', () {
    final startDate = DateTime(2026, 6, 3, 22, 15);
    final schedules = service.schedulesFor30Days(
      location: PrayerLocation.defaultLocation,
      settings: const PrayerSettings(),
      startDate: startDate,
    );

    expect(schedules, hasLength(30));
    expect(schedules.first.date, DateTime(2026, 6, 3));
    expect(schedules.last.date, DateTime(2026, 7, 2));
  });

  test('nextEntry uses local wall-clock prayer times', () {
    final schedule = service.scheduleForDate(
      date: DateTime(2026, 6, 3),
      location: PrayerLocation.defaultLocation,
      settings: const PrayerSettings(),
    );
    final now = DateTime(2026, 6, 3, 13, 32);

    expect(schedule.entryFor(PrayerTimeType.dzuhur).time.isBefore(now), true);
    expect(schedule.nextEntry(now)?.type, PrayerTimeType.ashar);
  });

  test(
    'automatic calculation ignores manual method for Indonesian location',
    () {
      final autoSchedule = service.scheduleForDate(
        date: DateTime(2026, 6, 3),
        location: PrayerLocation.defaultLocation,
        settings: const PrayerSettings(
          automaticCalculation: true,
          calculationMethod: PrayerCalculationMethod.ummAlQura,
        ),
      );
      final manualUmmAlQuraSchedule = service.scheduleForDate(
        date: DateTime(2026, 6, 3),
        location: PrayerLocation.defaultLocation,
        settings: const PrayerSettings(
          automaticCalculation: false,
          calculationMethod: PrayerCalculationMethod.ummAlQura,
        ),
      );

      expect(
        autoSchedule.entryFor(PrayerTimeType.subuh).time,
        isNot(manualUmmAlQuraSchedule.entryFor(PrayerTimeType.subuh).time),
      );
    },
  );

  test(
    'automatic hijri ignores manual offset until local adjustment is chosen',
    () {
      final date = DateTime(2026, 6, 3);
      final automatic = service.hijriDateFor(
        date,
        const PrayerSettings(
          automaticHijri: true,
          hijriMethod: HijriCalculationMethod.localAdjustment,
          hijriAdjustment: 2,
        ),
      );
      final ummAlQura = service.hijriDateFor(
        date,
        const PrayerSettings(
          automaticHijri: false,
          hijriMethod: HijriCalculationMethod.ummAlQura,
          hijriAdjustment: 2,
        ),
      );
      final adjusted = service.hijriDateFor(
        date,
        const PrayerSettings(
          automaticHijri: false,
          hijriMethod: HijriCalculationMethod.localAdjustment,
          hijriAdjustment: 2,
        ),
      );

      expect(automatic, ummAlQura);
      expect(adjusted, isNot(automatic));
    },
  );
}
