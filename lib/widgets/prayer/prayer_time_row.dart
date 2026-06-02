import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/prayer_settings_model.dart';
import '../../models/prayer_time_model.dart';

class PrayerTimeRow extends StatelessWidget {
  final PrayerTimeEntry entry;
  final bool active;
  final bool use24HourFormat;
  final PrayerNotificationSound notificationSound;
  final VoidCallback onNotificationTap;

  const PrayerTimeRow({
    super.key,
    required this.entry,
    required this.active,
    required this.use24HourFormat,
    required this.notificationSound,
    required this.onNotificationTap,
  });

  @override
  Widget build(BuildContext context) {
    final primary = active ? AppColors.goldLt : Colors.white;
    final secondary = Colors.white.withValues(alpha: 0.62);
    final formatter = DateFormat(use24HourFormat ? 'HH:mm' : 'hh:mm a');
    final notificationActive = notificationSound.enabled;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
      decoration: BoxDecoration(
        color:
            active
                ? AppColors.gold.withValues(alpha: 0.10)
                : Colors.transparent,
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.07)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.type.label,
              style: TextStyle(
                color: primary,
                fontSize: 18,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          Text(
            formatter.format(entry.time),
            style: TextStyle(
              color: primary,
              fontSize: 18,
              fontWeight: active ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: 0,
            ),
          ),
          const SizedBox(width: 12),
          IconButton(
            visualDensity: VisualDensity.compact,
            tooltip: 'Atur notifikasi ${entry.type.label}',
            onPressed: onNotificationTap,
            icon: Icon(
              notificationActive
                  ? Icons.notifications_active_rounded
                  : Icons.notifications_off_rounded,
              color: notificationActive ? AppColors.goldLt : secondary,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }
}
