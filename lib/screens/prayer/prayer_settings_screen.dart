import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';
import '../../models/prayer_settings_model.dart';
import '../../models/prayer_time_model.dart';
import '../../services/prayer_time_service.dart';
import '../../widgets/prayer/prayer_setting_tile.dart';

class PrayerSettingsScreen extends StatefulWidget {
  const PrayerSettingsScreen({super.key});

  @override
  State<PrayerSettingsScreen> createState() => _PrayerSettingsScreenState();
}

class _PrayerSettingsScreenState extends State<PrayerSettingsScreen> {
  final _service = PrayerTimeService();
  PrayerSettings _settings = const PrayerSettings();
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await _service.loadSettings();
    if (!mounted) return;
    setState(() {
      _settings = settings;
      _loading = false;
    });
  }

  Future<void> _save(PrayerSettings settings) async {
    setState(() => _settings = settings);
    await _service.saveSettings(settings);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: const Text('Pengaturan Jadwal Sholat')),
      body:
          _loading
              ? const Center(
                child: CircularProgressIndicator(color: AppColors.gold),
              )
              : ListView(
                padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
                children: [
                  _Section(
                    title: 'Perhitungan Jadwal Sholat',
                    children: [
                      _SwitchRow(
                        title: 'Otomatis',
                        subtitle: 'Gunakan metode default yang aman',
                        icon: Icons.auto_awesome_rounded,
                        value: _settings.automaticCalculation,
                        onChanged:
                            (value) => _save(
                              _settings.copyWith(automaticCalculation: value),
                            ),
                      ),
                      PrayerSettingTile(
                        title: 'Metode Perhitungan',
                        subtitle: _settings.calculationMethod.label,
                        icon: Icons.calculate_rounded,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white54,
                        ),
                        onTap: _pickCalculationMethod,
                      ),
                      PrayerSettingTile(
                        title: 'Perhitungan Waktu Ashar',
                        subtitle: _settings.asrMethod.label,
                        icon: Icons.wb_sunny_rounded,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white54,
                        ),
                        onTap: _pickAsrMethod,
                      ),
                      _AdjustmentPanel(
                        settings: _settings,
                        onChanged: (key, value) {
                          final adjustments = Map<String, int>.from(
                            _settings.adjustments,
                          )..[key] = value;
                          _save(_settings.copyWith(adjustments: adjustments));
                        },
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Perhitungan Tanggal Hijriah',
                    children: [
                      _SwitchRow(
                        title: 'Otomatis',
                        subtitle: 'Hitung Hijriah dari tanggal perangkat',
                        icon: Icons.event_available_rounded,
                        value: _settings.automaticHijri,
                        onChanged:
                            (value) => _save(
                              _settings.copyWith(automaticHijri: value),
                            ),
                      ),
                      PrayerSettingTile(
                        title: 'Metode Perhitungan Hijriah',
                        subtitle: _settings.hijriMethod.label,
                        icon: Icons.calendar_month_rounded,
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white54,
                        ),
                        onTap: _pickHijriMethod,
                      ),
                      _HijriAdjustmentRow(
                        value: _settings.hijriAdjustment,
                        onChanged:
                            (value) => _save(
                              _settings.copyWith(hijriAdjustment: value),
                            ),
                      ),
                    ],
                  ),
                  _Section(
                    title: 'Lainnya',
                    children: [
                      _SwitchRow(
                        title: 'Format waktu 24 jam',
                        subtitle:
                            _settings.use24HourFormat
                                ? 'Menampilkan 04:35'
                                : 'Menampilkan 04:35 AM',
                        icon: Icons.schedule_rounded,
                        value: _settings.use24HourFormat,
                        onChanged:
                            (value) => _save(
                              _settings.copyWith(use24HourFormat: value),
                            ),
                      ),
                      _VolumeRow(
                        value: _settings.adhanVolume,
                        onChanged:
                            (value) =>
                                _save(_settings.copyWith(adhanVolume: value)),
                      ),
                      _SwitchRow(
                        title: 'Disable Dzuhur Hari Jumat',
                        subtitle: 'Jangan jadwalkan notifikasi Dzuhur Jumat',
                        icon: Icons.mosque_rounded,
                        value: _settings.disableDhuhrOnFriday,
                        onChanged:
                            (value) => _save(
                              _settings.copyWith(disableDhuhrOnFriday: value),
                            ),
                      ),
                      _SwitchRow(
                        title: 'Force Notifikasi',
                        subtitle:
                            'Tetap simpan jadwal saat permission belum aktif',
                        icon: Icons.notifications_active_rounded,
                        value: _settings.forceNotification,
                        onChanged:
                            (value) => _save(
                              _settings.copyWith(forceNotification: value),
                            ),
                      ),
                      PrayerSettingTile(
                        title: 'Info Jadwal Sholat',
                        subtitle:
                            'Kemenag memakai pendekatan Fajr 20 derajat dan Isya 18 derajat.',
                        icon: Icons.info_outline_rounded,
                        onTap: _showInfo,
                      ),
                    ],
                  ),
                ],
              ),
    );
  }

  Future<void> _pickCalculationMethod() async {
    final result = await _pickEnum(
      title: 'Metode Perhitungan',
      values: PrayerCalculationMethod.values,
      selected: _settings.calculationMethod,
      label: (value) => value.label,
    );
    if (result != null) {
      await _save(_settings.copyWith(calculationMethod: result));
    }
  }

  Future<void> _pickAsrMethod() async {
    final result = await _pickEnum(
      title: 'Perhitungan Waktu Ashar',
      values: PrayerAsrMethod.values,
      selected: _settings.asrMethod,
      label: (value) => value.label,
    );
    if (result != null) await _save(_settings.copyWith(asrMethod: result));
  }

  Future<void> _pickHijriMethod() async {
    final result = await _pickEnum(
      title: 'Metode Perhitungan Hijriah',
      values: HijriCalculationMethod.values,
      selected: _settings.hijriMethod,
      label: (value) => value.label,
    );
    if (result != null) await _save(_settings.copyWith(hijriMethod: result));
  }

  Future<T?> _pickEnum<T>({
    required String title,
    required List<T> values,
    required T selected,
    required String Function(T value) label,
  }) {
    return showDialog<T>(
      context: context,
      builder:
          (context) => SimpleDialog(
            title: Text(title),
            children:
                values.map((value) {
                  return RadioListTile<T>(
                    value: value,
                    groupValue: selected,
                    activeColor: AppColors.goldLt,
                    title: Text(label(value)),
                    onChanged: (value) => Navigator.pop(context, value),
                  );
                }).toList(),
          ),
    );
  }

  void _showInfo() {
    showDialog<void>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Info Jadwal Sholat'),
            content: const Text(
              'Jadwal dihitung dari tanggal, koordinat lokasi, timezone perangkat, metode perhitungan, madhab Ashar, dan penyesuaian menit personal.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Tutup'),
              ),
            ],
          ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final List<Widget> children;

  const _Section({required this.title, required this.children});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(2, 0, 2, 10),
            child: Text(
              title,
              style: const TextStyle(
                color: AppColors.goldLt,
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          ...children.expand((child) => [child, const SizedBox(height: 10)]),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return PrayerSettingTile(
      title: title,
      subtitle: subtitle,
      icon: icon,
      trailing: Switch(
        value: value,
        activeColor: AppColors.goldLt,
        onChanged: onChanged,
      ),
    );
  }
}

class _AdjustmentPanel extends StatelessWidget {
  final PrayerSettings settings;
  final void Function(String key, int value) onChanged;

  const _AdjustmentPanel({required this.settings, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1B1B1B),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.gold.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Penyesuaian Personal',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 10),
          ...PrayerTimeType.values.map((type) {
            final value = settings.adjustmentFor(type.key);
            return _StepperRow(
              label: type.label,
              value: value,
              onChanged: (newValue) => onChanged(type.key, newValue),
            );
          }),
        ],
      ),
    );
  }
}

class _StepperRow extends StatelessWidget {
  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  const _StepperRow({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: Colors.white.withValues(alpha: 0.82)),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline_rounded),
            color: AppColors.goldLt,
            onPressed: () => onChanged((value - 1).clamp(-30, 30)),
          ),
          SizedBox(
            width: 54,
            child: Text(
              '${value > 0 ? '+' : ''}$value m',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_circle_outline_rounded),
            color: AppColors.goldLt,
            onPressed: () => onChanged((value + 1).clamp(-30, 30)),
          ),
        ],
      ),
    );
  }
}

class _HijriAdjustmentRow extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;

  const _HijriAdjustmentRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PrayerSettingTile(
      title: 'Penyesuaian Tanggal Hijriah',
      subtitle: 'Dari -2 sampai +2 hari',
      icon: Icons.tune_rounded,
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_rounded),
            color: AppColors.goldLt,
            onPressed: () => onChanged((value - 1).clamp(-2, 2)),
          ),
          SizedBox(
            width: 38,
            child: Text(
              '${value > 0 ? '+' : ''}$value',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.add_rounded),
            color: AppColors.goldLt,
            onPressed: () => onChanged((value + 1).clamp(-2, 2)),
          ),
        ],
      ),
    );
  }
}

class _VolumeRow extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;

  const _VolumeRow({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return PrayerSettingTile(
      title: 'Volume Adzan',
      subtitle: '${(value * 100).round()}%',
      icon: Icons.volume_up_rounded,
      trailing: SizedBox(
        width: 150,
        child: Slider(
          value: value,
          activeColor: AppColors.goldLt,
          inactiveColor: Colors.white24,
          onChanged: onChanged,
        ),
      ),
    );
  }
}
