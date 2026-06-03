import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer_settings_model.dart';
import '../models/prayer_time_model.dart';

class PrayerNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const _notificationBaseId = 7400;
  static const _legacyNotificationBaseId = 7300;
  static const _notificationDays = 30;
  static bool _initialized = false;
  static String? _lastAppliedSignature;

  static Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      final fallback = _fallbackTimezoneName(DateTime.now().timeZoneOffset);
      tz.setLocalLocation(tz.getLocation(fallback));
    }

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _notifications.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
    );
    _initialized = true;
  }

  static Future<bool> requestPermission() async {
    await init();
    var allowed = true;

    final androidPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidPlugin != null) {
      allowed = await androidPlugin.requestNotificationsPermission() ?? true;
      try {
        await androidPlugin.requestExactAlarmsPermission();
      } catch (e) {
        debugPrint('Exact alarm permission request skipped: $e');
      }
    }

    final iosPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin
            >();
    if (iosPlugin != null) {
      allowed =
          await iosPlugin.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          allowed;
    }

    return allowed;
  }

  static Future<void> scheduleDailyPrayers({
    required PrayerDaySchedule schedule,
    List<PrayerDaySchedule>? schedules,
    required PrayerSettings settings,
  }) async {
    await init();

    final upcomingSchedules =
        (schedules == null || schedules.isEmpty) ? [schedule] : schedules;
    final signature = _scheduleSignature(upcomingSchedules, settings);
    if (_lastAppliedSignature == signature) return;

    final now = tz.TZDateTime.now(tz.local);
    final activeTypes = <PrayerTimeType>[];

    for (final type in PrayerTimeType.values) {
      await _cancelPrayerIds(type);
      if (settings.notificationFor(type.key).enabled) activeTypes.add(type);
    }

    if (activeTypes.isEmpty) {
      _lastAppliedSignature = signature;
      return;
    }

    final allowed = await requestPermission();
    if (!allowed && !settings.forceNotification) {
      throw StateError('Izin notifikasi belum aktif.');
    }

    for (final type in activeTypes) {
      final sound = settings.notificationFor(type.key);
      for (
        var dayIndex = 0;
        dayIndex < upcomingSchedules.length && dayIndex < _notificationDays;
        dayIndex++
      ) {
        final entry = upcomingSchedules[dayIndex].entryFor(type);
        if (settings.disableDhuhrOnFriday &&
            entry.type == PrayerTimeType.dzuhur &&
            entry.time.weekday == DateTime.friday) {
          continue;
        }
        final scheduledDate = tz.TZDateTime.from(entry.time, tz.local);
        if (!scheduledDate.isAfter(now)) continue;
        await _scheduleEntry(entry, sound, scheduledDate, dayIndex);
      }
    }
    _lastAppliedSignature = signature;
  }

  static Future<void> cancelPrayer(PrayerTimeType type) async {
    await init();
    await _cancelPrayerIds(type);
  }

  static Future<void> _scheduleEntry(
    PrayerTimeEntry entry,
    PrayerNotificationSound sound,
    tz.TZDateTime scheduledDate,
    int dayIndex,
  ) async {
    await init();

    await _notifications.zonedSchedule(
      id: _notificationId(entry.type, dayIndex),
      title: 'Waktu ${entry.type.label}',
      body: 'Telah masuk waktu ${entry.type.label}.',
      scheduledDate: scheduledDate,
      notificationDetails: _details(sound),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static Future<void> _cancelPrayerIds(PrayerTimeType type) async {
    await _notifications.cancel(id: _legacyNotificationId(type));
    for (var dayIndex = 0; dayIndex < _notificationDays; dayIndex++) {
      await _notifications.cancel(id: _notificationId(type, dayIndex));
    }
  }

  static NotificationDetails _details(PrayerNotificationSound sound) {
    final playSound = sound != PrayerNotificationSound.silent;
    final channelId = switch (sound) {
      PrayerNotificationSound.adhan => 'prayer_adhan_channel',
      PrayerNotificationSound.alarm => 'prayer_alarm_channel',
      PrayerNotificationSound.notification => 'prayer_notification_channel',
      PrayerNotificationSound.silent => 'prayer_silent_channel',
      PrayerNotificationSound.disabled => 'prayer_disabled_channel',
    };
    final channelName = switch (sound) {
      PrayerNotificationSound.adhan => 'Adzan Sholat',
      PrayerNotificationSound.alarm => 'Alarm Sholat',
      PrayerNotificationSound.notification => 'Notifikasi Sholat',
      PrayerNotificationSound.silent => 'Notifikasi Sholat Tanpa Suara',
      PrayerNotificationSound.disabled => 'Notifikasi Sholat Nonaktif',
    };

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: 'Pengingat harian waktu sholat',
        importance: Importance.max,
        priority: Priority.high,
        category:
            sound == PrayerNotificationSound.alarm
                ? AndroidNotificationCategory.alarm
                : AndroidNotificationCategory.reminder,
        playSound: playSound,
        enableVibration: true,
        showWhen: true,
      ),
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: playSound,
      ),
    );
  }

  static int _notificationId(PrayerTimeType type, int dayIndex) =>
      _notificationBaseId + type.index * _notificationDays + dayIndex;

  static int _legacyNotificationId(PrayerTimeType type) =>
      _legacyNotificationBaseId + type.index;

  static String _fallbackTimezoneName(Duration offset) {
    return switch (offset.inHours) {
      7 => 'Asia/Jakarta',
      8 => 'Asia/Makassar',
      9 => 'Asia/Jayapura',
      _ => 'UTC',
    };
  }

  static String _scheduleSignature(
    List<PrayerDaySchedule> schedules,
    PrayerSettings settings,
  ) {
    final buffer =
        StringBuffer()
          ..write(settings.forceNotification)
          ..write('|')
          ..write(settings.disableDhuhrOnFriday);
    for (final type in PrayerTimeType.values) {
      buffer
        ..write('|')
        ..write(type.key)
        ..write(':')
        ..write(settings.notificationFor(type.key).name);
    }
    for (final schedule in schedules.take(_notificationDays)) {
      buffer
        ..write('|')
        ..write(schedule.date.year)
        ..write('-')
        ..write(schedule.date.month)
        ..write('-')
        ..write(schedule.date.day);
      for (final entry in schedule.entries) {
        buffer
          ..write(',')
          ..write(entry.type.key)
          ..write('@')
          ..write(entry.time.millisecondsSinceEpoch);
      }
    }
    return buffer.toString();
  }
}
