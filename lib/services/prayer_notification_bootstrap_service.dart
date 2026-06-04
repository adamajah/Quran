import 'package:flutter/foundation.dart';

import 'prayer_location_service.dart';
import 'prayer_notification_service.dart';
import 'prayer_time_service.dart';

class PrayerNotificationBootstrapService {
  static Future<void> reschedule({bool force = false}) async {
    try {
      final locationService = PrayerLocationService();
      final timeService = PrayerTimeService();
      final location = await locationService.loadLocation();
      final settings = await timeService.loadSettings();
      final schedules = timeService.schedulesFor30Days(
        location: location,
        settings: settings,
        startDate: DateTime.now(),
      );
      if (schedules.isEmpty) return;

      await PrayerNotificationService.scheduleDailyPrayers(
        schedule: schedules.first,
        schedules: schedules,
        settings: settings,
        force: force,
      );
    } catch (e) {
      debugPrint('Prayer notification reschedule skipped: $e');
    }
  }
}
