import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();
  static const int _readingReminderId = 1;
  static Future<void>? _initFuture;
  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    _initFuture ??= _doInit();
    await _initFuture;
  }

  static Future<void> _doInit() async {
    tz.initializeTimeZones();
    final String timeZoneName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(timeZoneName));

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);

    await _notifications.initialize(
      settings: settings,
      onDidReceiveNotificationResponse: (details) {},
    );

    // Request permissions for Android 13+ (Safe check)
    final androidPlugin =
        _notifications
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
    if (androidPlugin != null) {
      try {
        await androidPlugin.requestNotificationsPermission();
      } catch (e) {
        debugPrint("Request notification permission failed: $e");
      }
    }

    _initialized = true;
  }

  static Future<void> _ensureInitialized() async {
    if (_initialized) return;
    await init();
  }

  static Future<void> scheduleReadingReminder(TimeOfDay time) async {
    await _ensureInitialized();
    final now = tz.TZDateTime.now(tz.local);
    var scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      time.hour,
      time.minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      id: _readingReminderId,
      title: 'Waktunya Membaca Al-Quran',
      body: 'Mari luangkan waktu sejenak untuk membaca kalam Allah hari ini.',
      scheduledDate: scheduledDate,
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'reading_reminder',
          'Quran Reading Reminder',
          channelDescription: 'Daily reminder to read the Holy Quran',
          importance: Importance.max,
          priority: Priority.high,
          showWhen: true,
          styleInformation: BigTextStyleInformation(''),
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  static Future<void> showDownloadProgress({
    required int id,
    required String title,
    required int progress,
    required int maxProgress,
  }) async {
    await _ensureInitialized();
    final AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'download_channel',
          'Downloads',
          channelDescription: 'Notifications for audio downloads',
          importance: Importance.low,
          priority: Priority.low,
          onlyAlertOnce: true,
          showProgress: true,
          maxProgress: maxProgress,
          progress: progress,
          ongoing: true,
          autoCancel: false,
        );

    final NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    await _notifications.show(
      id: id,
      title: 'Mengunduh $title',
      body: '$progress%',
      notificationDetails: details,
    );
  }

  static Future<void> showDownloadCompleted({
    required int id,
    required String title,
  }) async {
    await _ensureInitialized();
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'download_channel',
          'Downloads',
          channelDescription: 'Notifications for audio downloads',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    await _notifications.show(
      id: id,
      title: 'Unduhan Selesai',
      body: '$title telah berhasil diunduh.',
      notificationDetails: details,
    );
  }

  static Future<void> showDownloadError({
    required int id,
    required String title,
    required String error,
  }) async {
    await _ensureInitialized();
    const AndroidNotificationDetails androidDetails =
        AndroidNotificationDetails(
          'download_channel',
          'Downloads',
          channelDescription: 'Notifications for audio downloads',
          importance: Importance.high,
          priority: Priority.high,
        );

    const NotificationDetails details = NotificationDetails(
      android: androidDetails,
    );
    await _notifications.show(
      id: id,
      title: 'Unduhan Gagal',
      body: 'Gagal mengunduh $title: $error',
      notificationDetails: details,
    );
  }

  static Future<void> cancel(int id) async {
    await _ensureInitialized();
    await _notifications.cancel(id: id);
  }

  static Future<void> cancelReadingReminder() async {
    await cancel(_readingReminderId);
  }

  static Future<void> cancelAll() async {
    await _ensureInitialized();
    await _notifications.cancelAll();
  }
}
