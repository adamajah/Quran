enum PrayerCalculationMethod {
  kemenagIndonesia,
  muslimWorldLeague,
  ummAlQura,
  egyptian,
  karachi,
  dubai,
  qatar,
  kuwait,
  singapore,
}

enum PrayerAsrMethod { standard, hanafi }

enum HijriCalculationMethod { ummAlQura, localAdjustment }

enum PrayerNotificationSound { adhan, alarm, notification, silent, disabled }

extension PrayerCalculationMethodLabel on PrayerCalculationMethod {
  String get label {
    return switch (this) {
      PrayerCalculationMethod.kemenagIndonesia => 'Kemenag / Indonesia',
      PrayerCalculationMethod.muslimWorldLeague => 'Muslim World League',
      PrayerCalculationMethod.ummAlQura => 'Umm Al-Qura',
      PrayerCalculationMethod.egyptian => 'Egyptian',
      PrayerCalculationMethod.karachi => 'Karachi',
      PrayerCalculationMethod.dubai => 'Dubai',
      PrayerCalculationMethod.qatar => 'Qatar',
      PrayerCalculationMethod.kuwait => 'Kuwait',
      PrayerCalculationMethod.singapore => 'Singapore',
    };
  }
}

extension PrayerAsrMethodLabel on PrayerAsrMethod {
  String get label {
    return switch (this) {
      PrayerAsrMethod.standard => "Syafi'i, Maliki, Hanbali",
      PrayerAsrMethod.hanafi => 'Hanafi',
    };
  }
}

extension HijriCalculationMethodLabel on HijriCalculationMethod {
  String get label {
    return switch (this) {
      HijriCalculationMethod.ummAlQura => 'Umm Al-Qura',
      HijriCalculationMethod.localAdjustment => 'Lokal + Penyesuaian',
    };
  }
}

extension PrayerNotificationSoundLabel on PrayerNotificationSound {
  String get label {
    return switch (this) {
      PrayerNotificationSound.adhan => 'Suara adzan',
      PrayerNotificationSound.alarm => 'Suara standar alarm',
      PrayerNotificationSound.notification => 'Suara standar notifikasi',
      PrayerNotificationSound.silent => 'Tanpa suara (notif saja)',
      PrayerNotificationSound.disabled => 'Nonaktif',
    };
  }

  bool get enabled => this != PrayerNotificationSound.disabled;
}

class PrayerSettings {
  final bool automaticCalculation;
  final PrayerCalculationMethod calculationMethod;
  final PrayerAsrMethod asrMethod;
  final Map<String, int> adjustments;
  final bool automaticHijri;
  final HijriCalculationMethod hijriMethod;
  final int hijriAdjustment;
  final bool use24HourFormat;
  final double adhanVolume;
  final bool disableDhuhrOnFriday;
  final bool forceNotification;
  final Map<String, PrayerNotificationSound> notifications;
  final Map<String, bool> visible30DayColumns;

  const PrayerSettings({
    this.automaticCalculation = true,
    this.calculationMethod = PrayerCalculationMethod.kemenagIndonesia,
    this.asrMethod = PrayerAsrMethod.standard,
    this.adjustments = const {
      'imsak': 0,
      'subuh': 0,
      'terbit': 0,
      'dzuhur': 0,
      'ashar': 0,
      'maghrib': 0,
      'isya': 0,
    },
    this.automaticHijri = true,
    this.hijriMethod = HijriCalculationMethod.ummAlQura,
    this.hijriAdjustment = 0,
    this.use24HourFormat = true,
    this.adhanVolume = 0.8,
    this.disableDhuhrOnFriday = false,
    this.forceNotification = false,
    this.notifications = const {
      'imsak': PrayerNotificationSound.disabled,
      'subuh': PrayerNotificationSound.adhan,
      'terbit': PrayerNotificationSound.disabled,
      'dzuhur': PrayerNotificationSound.adhan,
      'ashar': PrayerNotificationSound.adhan,
      'maghrib': PrayerNotificationSound.adhan,
      'isya': PrayerNotificationSound.adhan,
    },
    this.visible30DayColumns = const {
      'hijri': true,
      'imsak': true,
      'subuh': true,
      'terbit': true,
      'dzuhur': true,
      'ashar': true,
      'maghrib': true,
      'isya': true,
    },
  });

  PrayerNotificationSound notificationFor(String key) {
    return notifications[key] ?? PrayerNotificationSound.disabled;
  }

  int adjustmentFor(String key) => adjustments[key] ?? 0;

  Map<String, Object> toJson() => {
    'automaticCalculation': automaticCalculation,
    'calculationMethod': calculationMethod.name,
    'asrMethod': asrMethod.name,
    'adjustments': adjustments,
    'automaticHijri': automaticHijri,
    'hijriMethod': hijriMethod.name,
    'hijriAdjustment': hijriAdjustment,
    'use24HourFormat': use24HourFormat,
    'adhanVolume': adhanVolume,
    'disableDhuhrOnFriday': disableDhuhrOnFriday,
    'forceNotification': forceNotification,
    'notifications': notifications.map(
      (key, value) => MapEntry(key, value.name),
    ),
    'visible30DayColumns': visible30DayColumns,
  };

  factory PrayerSettings.fromJson(Map<String, dynamic> json) {
    final defaults = const PrayerSettings();
    return PrayerSettings(
      automaticCalculation:
          json['automaticCalculation'] as bool? ??
          defaults.automaticCalculation,
      calculationMethod: _enumByName(
        PrayerCalculationMethod.values,
        json['calculationMethod'] as String?,
        defaults.calculationMethod,
      ),
      asrMethod: _enumByName(
        PrayerAsrMethod.values,
        json['asrMethod'] as String?,
        defaults.asrMethod,
      ),
      adjustments: _intMap(json['adjustments'], defaults.adjustments),
      automaticHijri:
          json['automaticHijri'] as bool? ?? defaults.automaticHijri,
      hijriMethod: _enumByName(
        HijriCalculationMethod.values,
        json['hijriMethod'] as String?,
        defaults.hijriMethod,
      ),
      hijriAdjustment:
          (json['hijriAdjustment'] as num?)?.toInt() ??
          defaults.hijriAdjustment,
      use24HourFormat:
          json['use24HourFormat'] as bool? ?? defaults.use24HourFormat,
      adhanVolume:
          (json['adhanVolume'] as num?)?.toDouble() ?? defaults.adhanVolume,
      disableDhuhrOnFriday:
          json['disableDhuhrOnFriday'] as bool? ??
          defaults.disableDhuhrOnFriday,
      forceNotification:
          json['forceNotification'] as bool? ?? defaults.forceNotification,
      notifications: _notificationMap(
        json['notifications'],
        defaults.notifications,
      ),
      visible30DayColumns: _boolMap(
        json['visible30DayColumns'],
        defaults.visible30DayColumns,
      ),
    );
  }

  PrayerSettings copyWith({
    bool? automaticCalculation,
    PrayerCalculationMethod? calculationMethod,
    PrayerAsrMethod? asrMethod,
    Map<String, int>? adjustments,
    bool? automaticHijri,
    HijriCalculationMethod? hijriMethod,
    int? hijriAdjustment,
    bool? use24HourFormat,
    double? adhanVolume,
    bool? disableDhuhrOnFriday,
    bool? forceNotification,
    Map<String, PrayerNotificationSound>? notifications,
    Map<String, bool>? visible30DayColumns,
  }) {
    return PrayerSettings(
      automaticCalculation: automaticCalculation ?? this.automaticCalculation,
      calculationMethod: calculationMethod ?? this.calculationMethod,
      asrMethod: asrMethod ?? this.asrMethod,
      adjustments: adjustments ?? this.adjustments,
      automaticHijri: automaticHijri ?? this.automaticHijri,
      hijriMethod: hijriMethod ?? this.hijriMethod,
      hijriAdjustment: hijriAdjustment ?? this.hijriAdjustment,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
      adhanVolume: adhanVolume ?? this.adhanVolume,
      disableDhuhrOnFriday: disableDhuhrOnFriday ?? this.disableDhuhrOnFriday,
      forceNotification: forceNotification ?? this.forceNotification,
      notifications: notifications ?? this.notifications,
      visible30DayColumns: visible30DayColumns ?? this.visible30DayColumns,
    );
  }

  static T _enumByName<T extends Enum>(
    List<T> values,
    String? name,
    T fallback,
  ) {
    for (final value in values) {
      if (value.name == name) return value;
    }
    return fallback;
  }

  static Map<String, int> _intMap(Object? value, Map<String, int> fallback) {
    final out = Map<String, int>.from(fallback);
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        final raw = entry.value;
        if (raw is num && out.containsKey(key)) out[key] = raw.toInt();
      }
    }
    return out;
  }

  static Map<String, bool> _boolMap(Object? value, Map<String, bool> fallback) {
    final out = Map<String, bool>.from(fallback);
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        final raw = entry.value;
        if (raw is bool && out.containsKey(key)) out[key] = raw;
      }
    }
    return out;
  }

  static Map<String, PrayerNotificationSound> _notificationMap(
    Object? value,
    Map<String, PrayerNotificationSound> fallback,
  ) {
    final out = Map<String, PrayerNotificationSound>.from(fallback);
    if (value is Map) {
      for (final entry in value.entries) {
        final key = entry.key.toString();
        final raw = entry.value?.toString();
        if (out.containsKey(key)) {
          out[key] = _enumByName(
            PrayerNotificationSound.values,
            raw,
            out[key]!,
          );
        }
      }
    }
    return out;
  }
}
