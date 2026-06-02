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
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;

    tzdata.initializeTimeZones();
    try {
      final timeZoneName = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(timeZoneName));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
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
    required PrayerSettings settings,
  }) async {
    final allowed = await requestPermission();
    if (!allowed && !settings.forceNotification) {
      throw StateError('Izin notifikasi belum aktif.');
    }

    for (final entry in schedule.entries) {
      final sound = settings.notificationFor(entry.type.key);
      await _notifications.cancel(id: _notificationId(entry.type));
      if (!sound.enabled) continue;
      if (settings.disableDhuhrOnFriday &&
          entry.type == PrayerTimeType.dzuhur &&
          entry.time.weekday == DateTime.friday) {
        continue;
      }
      await _scheduleEntry(entry, sound);
    }
  }

  static Future<void> cancelPrayer(PrayerTimeType type) async {
    await init();
    await _notifications.cancel(id: _notificationId(type));
  }

  static Future<void> _scheduleEntry(
    PrayerTimeEntry entry,
    PrayerNotificationSound sound,
  ) async {
    await init();
    var scheduledDate = tz.TZDateTime.from(entry.time, tz.local);
    final now = tz.TZDateTime.now(tz.local);
    if (!scheduledDate.isAfter(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id: _notificationId(entry.type),
      title: 'Waktu ${entry.type.label}',
      body: 'Telah masuk waktu ${entry.type.label}.',
      scheduledDate: scheduledDate,
      notificationDetails: _details(sound),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
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

  static int _notificationId(PrayerTimeType type) => 7300 + type.index;
}
