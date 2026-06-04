import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/prayer_settings_model.dart';
import '../models/prayer_time_model.dart';

@pragma('vm:entry-point')
void prayerNotificationTapBackground(NotificationResponse response) {}

class PrayerNotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const _notificationBaseId = 7400;
  static const _legacyNotificationBaseId = 7300;
  static const _notificationDays = 30;
  static const _adhanChannelId = 'prayer_adhan_channel_v3';
  static const _alarmChannelId = 'prayer_alarm_channel_v2';
  static const _notificationChannelId = 'prayer_notification_channel_v2';
  static const _silentChannelId = 'prayer_silent_channel_v2';
  static const _disabledChannelId = 'prayer_disabled_channel_v2';
  static const _stopAdhanActionId = 'stop_adhan';
  static const _flagInsistent = 4;
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
      onDidReceiveBackgroundNotificationResponse:
          prayerNotificationTapBackground,
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
    final androidScheduleMode = await _resolveAndroidScheduleMode();

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
        await _scheduleEntry(
          entry,
          sound,
          scheduledDate,
          dayIndex,
          androidScheduleMode,
        );
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
    AndroidScheduleMode androidScheduleMode,
  ) async {
    await init();

    final id = _notificationId(entry.type, dayIndex);
    final details = _details(sound);
    try {
      await _notifications.zonedSchedule(
        id: id,
        title: 'Waktu ${entry.type.label}',
        body: 'Telah masuk waktu ${entry.type.label}.',
        scheduledDate: scheduledDate,
        notificationDetails: details,
        androidScheduleMode: androidScheduleMode,
      );
    } catch (e) {
      if (androidScheduleMode == AndroidScheduleMode.exactAllowWhileIdle) {
        debugPrint('Exact prayer notification failed, retrying inexact: $e');
        await _notifications.zonedSchedule(
          id: id,
          title: 'Waktu ${entry.type.label}',
          body: 'Telah masuk waktu ${entry.type.label}.',
          scheduledDate: scheduledDate,
          notificationDetails: details,
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } else {
        rethrow;
      }
    }
  }

  static Future<void> _cancelPrayerIds(PrayerTimeType type) async {
    await _notifications.cancel(id: _legacyNotificationId(type));
    for (var dayIndex = 0; dayIndex < _notificationDays; dayIndex++) {
      await _notifications.cancel(id: _notificationId(type, dayIndex));
    }
  }

  static NotificationDetails _details(PrayerNotificationSound sound) {
    final playSound =
        sound == PrayerNotificationSound.adhan ||
        sound == PrayerNotificationSound.alarm ||
        sound == PrayerNotificationSound.notification;
    final channelId = switch (sound) {
      PrayerNotificationSound.adhan => _adhanChannelId,
      PrayerNotificationSound.alarm => _alarmChannelId,
      PrayerNotificationSound.notification => _notificationChannelId,
      PrayerNotificationSound.silent => _silentChannelId,
      PrayerNotificationSound.disabled => _disabledChannelId,
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
            sound == PrayerNotificationSound.adhan ||
                    sound == PrayerNotificationSound.alarm
                ? AndroidNotificationCategory.alarm
                : AndroidNotificationCategory.reminder,
        playSound: playSound,
        sound:
            sound == PrayerNotificationSound.adhan
                ? const RawResourceAndroidNotificationSound('adhan')
                : null,
        autoCancel: sound != PrayerNotificationSound.adhan,
        ongoing: sound == PrayerNotificationSound.adhan,
        additionalFlags:
            sound == PrayerNotificationSound.adhan
                ? Int32List.fromList(const [_flagInsistent])
                : null,
        actions:
            sound == PrayerNotificationSound.adhan
                ? const [
                  AndroidNotificationAction(
                    _stopAdhanActionId,
                    'Stop Adzan',
                    cancelNotification: true,
                    semanticAction: SemanticAction.mute,
                  ),
                ]
                : null,
        audioAttributesUsage:
            sound == PrayerNotificationSound.adhan ||
                    sound == PrayerNotificationSound.alarm
                ? AudioAttributesUsage.alarm
                : AudioAttributesUsage.notification,
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

  static Future<AndroidScheduleMode> _resolveAndroidScheduleMode() async {
    final androidPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidPlugin == null) {
      return AndroidScheduleMode.exactAllowWhileIdle;
    }

    try {
      if (await androidPlugin.canScheduleExactNotifications() ?? false) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
      await androidPlugin.requestExactAlarmsPermission();
      if (await androidPlugin.canScheduleExactNotifications() ?? false) {
        return AndroidScheduleMode.exactAllowWhileIdle;
      }
    } catch (e) {
      debugPrint('Exact alarm permission unavailable: $e');
    }

    return AndroidScheduleMode.inexactAllowWhileIdle;
  }

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
