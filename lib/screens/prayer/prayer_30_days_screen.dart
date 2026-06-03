import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../constants/app_colors.dart';
import '../../models/prayer_location_model.dart';
import '../../models/prayer_settings_model.dart';
import '../../models/prayer_time_model.dart';
import '../../services/prayer_location_service.dart';
import '../../services/prayer_time_service.dart';

class Prayer30DaysScreen extends StatefulWidget {
  const Prayer30DaysScreen({super.key});

  @override
  State<Prayer30DaysScreen> createState() => _Prayer30DaysScreenState();
}

class _Prayer30DaysScreenState extends State<Prayer30DaysScreen> {
  final _timeService = PrayerTimeService();
  final _locationService = PrayerLocationService();

  PrayerLocation _location = PrayerLocation.defaultLocation;
  PrayerSettings _settings = const PrayerSettings();
  List<PrayerDaySchedule> _schedules = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final locationResult = await _locationService.loadActiveLocation();
    final settings = await _timeService.loadSettings();
    final schedules = _timeService.schedulesFor30Days(
      location: locationResult.location,
      settings: settings,
    );
    if (!mounted) return;
    setState(() {
      _location = locationResult.location;
      _settings = settings;
      _schedules = schedules;
      _loading = false;
    });
    if (locationResult.message != null) _snack(locationResult.message!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Jadwal 30 Hari'),
        actions: [
          TextButton.icon(
            onPressed: _showColumnDialog,
            icon: const Icon(Icons.view_column_rounded, size: 18),
            label: const Text('Perlihatkan'),
          ),
        ],
      ),
      body:
          _loading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              )
              : ListView(
                padding: const EdgeInsets.fromLTRB(14, 8, 14, 24),
                children: [
                  Text(
                    _location.displayName,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.66),
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1B1B1B),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: AppColors.gold.withValues(alpha: 0.28),
                      ),
                    ),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: DataTable(
                        headingTextStyle: const TextStyle(
                          color: AppColors.goldLt,
                          fontWeight: FontWeight.w800,
                        ),
                        dataTextStyle: const TextStyle(color: Colors.white),
                        dividerThickness: 0.4,
                        columns: _columns(),
                        rows: _rows(),
                      ),
                    ),
                  ),
                ],
              ),
    );
  }

  List<DataColumn> _columns() {
    final columns = <DataColumn>[const DataColumn(label: Text('Masehi'))];
    if (_settings.visible30DayColumns['hijri'] ?? true) {
      columns.add(const DataColumn(label: Text('Hijriah')));
    }
    for (final type in PrayerTimeType.values) {
      if (_settings.visible30DayColumns[type.key] ?? true) {
        columns.add(DataColumn(label: Text(type.label)));
      }
    }
    return columns;
  }

  List<DataRow> _rows() {
    final formatter = DateFormat(
      _settings.use24HourFormat ? 'HH:mm' : 'hh:mm a',
    );
    return _schedules.map((schedule) {
      final cells = <DataCell>[DataCell(Text(_shortDate(schedule.date)))];
      if (_settings.visible30DayColumns['hijri'] ?? true) {
        cells.add(DataCell(Text(schedule.hijriDate)));
      }
      for (final type in PrayerTimeType.values) {
        if (_settings.visible30DayColumns[type.key] ?? true) {
          cells.add(
            DataCell(Text(formatter.format(schedule.entryFor(type).time))),
          );
        }
      }
      return DataRow(cells: cells);
    }).toList();
  }

  Future<void> _showColumnDialog() async {
    final values = Map<String, bool>.from(_settings.visible30DayColumns);
    final result = await showDialog<Map<String, bool>>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Kolom Yang Diperlihatkan'),
            content: StatefulBuilder(
              builder: (context, setDialogState) {
                return SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _checkbox(
                        label: 'Hijriah',
                        value: values['hijri'] ?? true,
                        onChanged:
                            (value) => setDialogState(
                              () => values['hijri'] = value ?? true,
                            ),
                      ),
                      ...PrayerTimeType.values.map((type) {
                        return _checkbox(
                          label: type.label,
                          value: values[type.key] ?? true,
                          onChanged:
                              (value) => setDialogState(
                                () => values[type.key] = value ?? true,
                              ),
                        );
                      }),
                    ],
                  ),
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
                onPressed: () => Navigator.pop(context, values),
                child: const Text('Simpan'),
              ),
            ],
          ),
    );

    if (result == null) return;
    final updated = _settings.copyWith(visible30DayColumns: result);
    await _timeService.saveSettings(updated);
    setState(() => _settings = updated);
  }

  Widget _checkbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return CheckboxListTile(
      value: value,
      activeColor: AppColors.goldLt,
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      onChanged: onChanged,
    );
  }

  String _shortDate(DateTime date) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  void _snack(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
