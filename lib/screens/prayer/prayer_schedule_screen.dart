import 'dart:async';

import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/prayer_location_model.dart';
import '../../models/prayer_settings_model.dart';
import '../../models/prayer_time_model.dart';
import '../../services/prayer_location_service.dart';
import '../../services/prayer_notification_service.dart';
import '../../services/prayer_time_service.dart';
import '../../widgets/prayer/prayer_time_card.dart';
import 'prayer_30_days_screen.dart';
import 'prayer_settings_screen.dart';
import 'qibla_screen.dart';

class PrayerScheduleScreen extends StatefulWidget {
  const PrayerScheduleScreen({super.key});

  @override
  State<PrayerScheduleScreen> createState() => _PrayerScheduleScreenState();
}

class _PrayerScheduleScreenState extends State<PrayerScheduleScreen> {
  final _timeService = PrayerTimeService();
  final _locationService = PrayerLocationService();
  Timer? _timer;

  PrayerLocation _location = PrayerLocation.defaultLocation;
  PrayerSettings _settings = const PrayerSettings();
  PrayerDaySchedule? _schedule;
  DateTime _now = DateTime.now();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      setState(() => _now = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    final location = await _locationService.loadLocation();
    final settings = await _timeService.loadSettings();
    final schedule = _timeService.scheduleForDate(
      date: DateTime.now(),
      location: location,
      settings: settings,
    );
    if (!mounted) return;
    setState(() {
      _location = location;
      _settings = settings;
      _schedule = schedule;
      _loading = false;
      _now = DateTime.now();
    });
  }

  @override
  Widget build(BuildContext context) {
    final schedule = _schedule;
    final activeEntry = schedule?.activeEntry(_now);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Jadwal Sholat'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            tooltip: 'Jadwal 30 Hari',
            icon: const Icon(Icons.calendar_month_rounded),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const Prayer30DaysScreen()),
              );
            },
          ),
          IconButton(
            tooltip: 'Ubah Lokasi',
            icon: const Icon(Icons.explore_rounded),
            onPressed: _showLocationDialog,
          ),
          IconButton(
            tooltip: 'Pengaturan Jadwal',
            icon: const Icon(Icons.settings_rounded),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const PrayerSettingsScreen()),
              );
              await _load();
            },
          ),
        ],
      ),
      body:
          _loading || schedule == null
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              )
              : RefreshIndicator(
                color: AppColors.gold,
                backgroundColor: const Color(0xFF1B1B1B),
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(18, 10, 18, 28),
                  children: [
                    _HeaderPanel(
                      gregorianDate: _gregorianDate(schedule.date),
                      hijriDate: schedule.hijriDate,
                      location: _location.displayName,
                      status: _statusText(schedule),
                      onQibla: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const QiblaScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 18),
                    PrayerTimeCard(
                      schedule: schedule,
                      activeEntry: activeEntry,
                      settings: _settings,
                      onNotificationTap: _showNotificationDialog,
                    ),
                  ],
                ),
              ),
    );
  }

  Future<void> _showNotificationDialog(PrayerTimeEntry entry) async {
    var selected = _settings.notificationFor(entry.type.key);
    final result = await showDialog<PrayerNotificationSound>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text('Atur Notifikasi ${entry.type.label}'),
            content: StatefulBuilder(
              builder: (context, setDialogState) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children:
                      PrayerNotificationSound.values.map((sound) {
                        return RadioListTile<PrayerNotificationSound>(
                          value: sound,
                          groupValue: selected,
                          activeColor: AppColors.goldLt,
                          contentPadding: EdgeInsets.zero,
                          title: Text(sound.label),
                          onChanged: (value) {
                            if (value != null) {
                              setDialogState(() => selected = value);
                            }
                          },
                        );
                      }).toList(),
                );
              },
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => Navigator.pop(context, selected),
                child: const Text('Simpan'),
              ),
            ],
          ),
    );

    if (result == null) return;
    final notifications = Map<String, PrayerNotificationSound>.from(
      _settings.notifications,
    )..[entry.type.key] = result;
    final updated = _settings.copyWith(notifications: notifications);
    await _timeService.saveSettings(updated);
    if (!mounted) return;
    setState(() => _settings = updated);

    try {
      final schedule = _schedule;
      if (schedule != null) {
        await PrayerNotificationService.scheduleDailyPrayers(
          schedule: schedule,
          settings: updated,
        );
      }
      if (mounted) _snack('Notifikasi ${entry.type.label} disimpan.');
    } catch (e) {
      if (mounted) _snack('Pengaturan tersimpan, tapi notifikasi belum aktif.');
    }
  }

  Future<void> _showLocationDialog() async {
    final mode = await showDialog<String>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Ubah Lokasi Anda'),
            children: [
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, 'auto'),
                child: const Row(
                  children: [
                    Icon(Icons.my_location_rounded, color: AppColors.gold),
                    SizedBox(width: 12),
                    Text('Otomatis (Lokasi saat ini)'),
                  ],
                ),
              ),
              SimpleDialogOption(
                onPressed: () => Navigator.pop(context, 'manual'),
                child: const Row(
                  children: [
                    Icon(Icons.location_city_rounded, color: AppColors.gold),
                    SizedBox(width: 12),
                    Text('Manual (Pilih dari daftar)'),
                  ],
                ),
              ),
            ],
          ),
    );

    if (mode == 'auto') {
      final result = await _locationService.useCurrentLocation();
      if (result.message != null && mounted) _snack(result.message!);
      await _load();
    } else if (mode == 'manual') {
      await _showManualLocationDialog();
    }
  }

  Future<void> _showManualLocationDialog() async {
    final selected = await showDialog<PrayerLocation>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: const Text('Pilih Lokasi'),
            children:
                PrayerLocationService.manualLocations.map((location) {
                  return SimpleDialogOption(
                    onPressed: () => Navigator.pop(context, location),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          location.city,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        Text(
                          '${location.region} - ${location.country}',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.58),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
          ),
    );
    if (selected == null) return;
    await _locationService.useManualLocation(selected);
    await _load();
  }

  String _statusText(PrayerDaySchedule schedule) {
    final next = schedule.nextEntry(_now);
    final active = schedule.activeEntry(_now);
    if (active != null && _now.difference(active.time).inMinutes <= 20) {
      final minutes = _now.difference(active.time).inMinutes.abs();
      return 'Baru saja waktu ${active.type.label}\n± $minutes menit yang lalu';
    }
    if (next != null) {
      final duration = next.time.difference(_now);
      return 'Menuju ${next.type.label} dalam ${_durationText(duration)}';
    }

    final tomorrow = _timeService.scheduleForDate(
      date: _now.add(const Duration(days: 1)),
      location: _location,
      settings: _settings,
    );
    final first = tomorrow.entries.first;
    return 'Menuju ${first.type.label} dalam ${_durationText(first.time.difference(_now))}';
  }

  String _durationText(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    if (hours <= 0) return '$minutes menit';
    return '$hours jam $minutes menit';
  }

  String _gregorianDate(DateTime date) {
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}

class _HeaderPanel extends StatelessWidget {
  final String gregorianDate;
  final String hijriDate;
  final String location;
  final String status;
  final VoidCallback onQibla;

  const _HeaderPanel({
    required this.gregorianDate,
    required this.hijriDate,
    required this.location,
    required this.status,
    required this.onQibla,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.26)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  hijriDate,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 14,
                  ),
                ),
              ),
              Text(
                gregorianDate,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.72),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  status,
                  style: const TextStyle(
                    color: AppColors.goldLt,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    height: 1.22,
                  ),
                ),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.black,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                    side: BorderSide(
                      color: AppColors.gold.withValues(alpha: 0.45),
                    ),
                  ),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                ),
                onPressed: onQibla,
                icon: const Icon(Icons.explore_rounded, size: 18),
                label: const Text('Qiblat'),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              const Icon(
                Icons.location_on_rounded,
                color: AppColors.gold,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  location,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.72),
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
