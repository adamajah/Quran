import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/prayer_settings_model.dart';
import '../../models/prayer_time_model.dart';
import 'prayer_time_row.dart';

class PrayerTimeCard extends StatelessWidget {
  final PrayerDaySchedule schedule;
  final PrayerTimeEntry? activeEntry;
  final PrayerSettings settings;
  final void Function(PrayerTimeEntry entry) onNotificationTap;

  const PrayerTimeCard({
    super.key,
    required this.schedule,
    required this.activeEntry,
    required this.settings,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.34)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children:
            schedule.entries.map((entry) {
              return PrayerTimeRow(
                entry: entry,
                active: activeEntry?.type == entry.type,
                use24HourFormat: settings.use24HourFormat,
                notificationSound: settings.notificationFor(entry.type.key),
                onNotificationTap: () => onNotificationTap(entry),
              );
            }).toList(),
      ),
    );
  }
}
