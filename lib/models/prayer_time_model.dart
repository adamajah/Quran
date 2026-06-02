enum PrayerTimeType { imsak, subuh, terbit, dzuhur, ashar, maghrib, isya }

extension PrayerTimeTypeLabel on PrayerTimeType {
  String get key => name;

  String get label {
    return switch (this) {
      PrayerTimeType.imsak => 'Imsak',
      PrayerTimeType.subuh => 'Subuh',
      PrayerTimeType.terbit => 'Terbit',
      PrayerTimeType.dzuhur => 'Dzuhur',
      PrayerTimeType.ashar => 'Ashar',
      PrayerTimeType.maghrib => 'Maghrib',
      PrayerTimeType.isya => 'Isya',
    };
  }
}

class PrayerTimeEntry {
  final PrayerTimeType type;
  final DateTime time;

  const PrayerTimeEntry({required this.type, required this.time});
}

class PrayerDaySchedule {
  final DateTime date;
  final String hijriDate;
  final List<PrayerTimeEntry> entries;

  const PrayerDaySchedule({
    required this.date,
    required this.hijriDate,
    required this.entries,
  });

  PrayerTimeEntry entryFor(PrayerTimeType type) {
    return entries.firstWhere((entry) => entry.type == type);
  }

  PrayerTimeEntry? activeEntry(DateTime now) {
    PrayerTimeEntry? active;
    for (final entry in entries) {
      if (!entry.time.isAfter(now)) active = entry;
    }
    return active;
  }

  PrayerTimeEntry? nextEntry(DateTime now) {
    for (final entry in entries) {
      if (entry.time.isAfter(now)) return entry;
    }
    return null;
  }
}
