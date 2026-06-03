import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../constants/app_colors.dart';
import '../models/settings_model.dart';
import '../models/reciter.dart';
import '../controllers/settings_controller.dart';
import '../widgets/common/premium_card.dart';
import 'package:flutter/cupertino.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Consumer<SettingsController>(
        builder: (context, controller, child) {
          final settings = controller.settings;
          return Column(
            children: [
              _buildHeader(context),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSection('Tampilan Mushaf', [
                      _buildSettingTile(
                        Icons.text_fields_rounded,
                        'Ukuran Font Arab',
                        '${settings.arabicFontSize.toInt()} px',
                        () => _showFontSizeSlider(context, controller),
                      ),
                      _buildSettingTile(
                        Icons.font_download_rounded,
                        'Jenis Font Mushaf',
                        settings.mushafFontName,
                        () => _showFontPicker(context, controller),
                      ),
                      _buildSettingTile(
                        Icons.format_line_spacing_rounded,
                        'Jarak Antar Ayat',
                        settings.lineSpacingName,
                        () => _showSpacingPicker(context, controller),
                      ),
                      _buildToggleTile(
                        Icons.pin_rounded,
                        'Nomor Ayat',
                        settings.showVerseNumbers,
                        (v) => controller.toggleVerseNumbers(v),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Audio & Qari', [
                      _buildSettingTile(
                        Icons.volume_up_rounded,
                        'Volume Default',
                        '${(settings.defaultVolume * 100).toInt()}%',
                        () => _showVolumeSlider(context, controller),
                      ),
                      _buildToggleTile(
                        Icons.play_circle_fill_rounded,
                        'Auto Play Ayat',
                        settings.autoPlay,
                        (v) => controller.toggleAutoPlay(v),
                      ),
                      _buildSettingTile(
                        Icons.speed_rounded,
                        'Kecepatan Putar',
                        '${settings.playbackSpeed}x',
                        () => _showSpeedPicker(context, controller),
                      ),
                      _buildSettingTile(
                        Icons.person_pin_rounded,
                        'Qari Default',
                        () {
                          final current = availableReciters.where(
                            (reciter) =>
                                reciter.id == settings.defaultReciterId,
                          );
                          return current.isNotEmpty
                              ? current.first.name
                              : 'Mishary Rashid Alafasy';
                        }(),
                        () => _showQariPicker(context, controller),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Notifikasi Reminder', [
                      _buildToggleTile(
                        Icons.notifications_active_rounded,
                        'Pengingat Baca Quran',
                        settings.readReminder,
                        (v) => controller.toggleReadReminder(v),
                      ),
                      _buildSettingTile(
                        Icons.access_time_rounded,
                        'Waktu Pengingat',
                        settings.reminderTime?.format(context) ?? "05:00",
                        () => _showTimePicker(context, controller),
                      ),
                      _buildToggleTile(
                        Icons.auto_awesome_rounded,
                        'Motivasi Islami Harian',
                        settings.dailyMotivation,
                        (v) => controller.toggleDailyMotivation(v),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Akun & Backup', [
                      _buildSettingTile(
                        Icons.cloud_upload_rounded,
                        'Sinkron Bookmark',
                        'Terakhir: Baru saja',
                        () => _handleSync(context, controller),
                      ),
                      _buildSettingTile(
                        Icons.backup_rounded,
                        'Backup Data',
                        'Pilih Media',
                        () => _showBackupOptions(context, controller),
                      ),
                    ]),
                    const SizedBox(height: 24),
                    _buildSection('Tentang', [
                      _buildSettingTile(
                        Icons.info_outline_rounded,
                        'Versi Aplikasi',
                        'v2.4.0 (Premium)',
                        () => _showAppInfo(context),
                      ),
                      _buildSettingTile(
                        Icons.policy_rounded,
                        'Kebijakan Privasi',
                        '',
                        () {},
                      ),
                      _buildSettingTile(
                        Icons.star_outline_rounded,
                        'Beri Rating',
                        '',
                        () {},
                      ),
                    ]),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return const PremiumHeader(
      title: 'Pengaturan',
      subtitle: 'Personalisasi pengalaman ibadah Anda',
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 12),
          child: Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ),
        PremiumCard(
          padding: EdgeInsets.zero,
          child: Column(children: children),
        ),
      ],
    );
  }

  Widget _buildSettingTile(
    IconData icon,
    String title,
    String value,
    VoidCallback onTap,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      onTap: onTap,
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.gold, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (value.isNotEmpty)
            Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.white60 : Colors.grey.shade600,
              ),
            ),
          const SizedBox(width: 8),
          Icon(
            Icons.arrow_forward_ios_rounded,
            size: 14,
            color: isDark ? Colors.white30 : Colors.grey,
          ),
        ],
      ),
    );
  }

  Widget _buildToggleTile(
    IconData icon,
    String title,
    bool value,
    ValueChanged<bool> onChanged,
  ) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppColors.gold.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.gold, size: 20),
      ),
      title: Text(
        title,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
      ),
      trailing: CupertinoSwitch(
        value: value,
        onChanged: onChanged,
        activeTrackColor: AppColors.gold,
      ),
    );
  }

  // --- Modal Helpers ---

  void _showFontSizeSlider(
    BuildContext context,
    SettingsController controller,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _buildBottomModal(
            context,
            'Ukuran Font Arab',
            StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  children: [
                    const SizedBox(height: 20),
                    Text(
                      '${controller.settings.arabicFontSize.toInt()} px',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Slider(
                      value: controller.settings.arabicFontSize,
                      min: 18,
                      max: 40,
                      divisions: 22,
                      activeColor: AppColors.gold,
                      onChanged: (v) {
                        setModalState(() {});
                        controller.updateArabicFontSize(v);
                      },
                    ),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [Text('Kecil (18)'), Text('Besar (40)')],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }

  void _showFontPicker(BuildContext context, SettingsController controller) {
    final fonts = [
      {'name': 'Hafs Madinah', 'value': MushafFont.hafs},
      {'name': 'Naskh Arabic', 'value': MushafFont.naskh},
      {'name': 'LPMQ Isep Misbah', 'value': MushafFont.lpmqIsepMisbah},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _buildBottomModal(
            context,
            'Pilih Jenis Font',
            ListView.builder(
              shrinkWrap: true,
              itemCount: fonts.length,
              itemBuilder: (context, i) {
                final f = fonts[i];
                final active = controller.settings.mushafFont == f['value'];
                return ListTile(
                  title: Text(
                    f['name'] as String,
                    style: TextStyle(
                      fontWeight: active ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                  trailing:
                      active
                          ? const Icon(
                            Icons.check_circle_rounded,
                            color: AppColors.gold,
                          )
                          : null,
                  onTap: () {
                    controller.updateMushafFont(f['value'] as MushafFont);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
    );
  }

  void _showSpacingPicker(BuildContext context, SettingsController controller) {
    final options = [
      {'label': 'Rapat', 'value': 1.6},
      {'label': 'Normal', 'value': 2.2},
      {'label': 'Lebar', 'value': 3.0},
    ];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _buildBottomModal(
            context,
            'Jarak Antar Ayat',
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children:
                  options.map((opt) {
                    final active =
                        controller.settings.lineSpacing == opt['value'];
                    return ChoiceChip(
                      label: Text(opt['label'] as String),
                      selected: active,
                      onSelected: (s) {
                        if (s) {
                          controller.updateLineSpacing(opt['value'] as double);
                        }
                        Navigator.pop(context);
                      },
                      selectedColor: AppColors.gold.withValues(alpha: 0.2),
                      labelStyle: TextStyle(
                        color: active ? AppColors.gold : Colors.black,
                      ),
                    );
                  }).toList(),
            ),
          ),
    );
  }

  void _showVolumeSlider(BuildContext context, SettingsController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _buildBottomModal(
            context,
            'Volume Default',
            StatefulBuilder(
              builder: (context, setModalState) {
                return Column(
                  children: [
                    const SizedBox(height: 20),
                    Icon(
                      controller.settings.defaultVolume == 0
                          ? Icons.volume_off
                          : Icons.volume_up,
                      size: 40,
                      color: AppColors.gold,
                    ),
                    Slider(
                      value: controller.settings.defaultVolume,
                      activeColor: AppColors.gold,
                      onChanged: (v) {
                        setModalState(() {});
                        controller.updateVolume(v);
                      },
                    ),
                  ],
                );
              },
            ),
          ),
    );
  }

  void _showSpeedPicker(BuildContext context, SettingsController controller) {
    final speeds = [0.5, 0.75, 1.0, 1.25, 1.5, 2.0];
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _buildBottomModal(
            context,
            'Kecepatan Putar',
            Wrap(
              spacing: 12,
              children:
                  speeds.map((s) {
                    final active = controller.settings.playbackSpeed == s;
                    return ChoiceChip(
                      label: Text('${s}x'),
                      selected: active,
                      onSelected: (sel) {
                        if (sel) controller.updatePlaybackSpeed(s);
                        Navigator.pop(context);
                      },
                    );
                  }).toList(),
            ),
          ),
    );
  }

  void _showQariPicker(BuildContext context, SettingsController controller) {
    final qaris = availableReciters;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _buildBottomModal(
            context,
            'Pilih Qari Default',
            StatefulBuilder(
              builder: (context, setModalState) {
                return SizedBox(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Cari nama qari...',
                            prefixIcon: const Icon(
                              Icons.search,
                              color: AppColors.gold,
                            ),
                            filled: true,
                            fillColor: AppColors.gold.withValues(alpha: 0.05),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                          ),
                          onChanged: (v) {
                            // In a real app, you'd filter the list here
                            setModalState(() {});
                          },
                        ),
                      ),
                      Expanded(
                        child: ListView.separated(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          itemCount: qaris.length,
                          separatorBuilder:
                              (_, _) => Divider(
                                color: Colors.grey.withValues(alpha: 0.1),
                                height: 1,
                              ),
                          itemBuilder: (context, i) {
                            final reciter = qaris[i];
                            final active =
                                controller.settings.defaultReciterId ==
                                reciter.id;
                            return ListTile(
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: AppColors.gold.withValues(
                                  alpha: active ? 1 : 0.1,
                                ),
                                child: Text(
                                  reciter.name[0],
                                  style: TextStyle(
                                    color:
                                        active ? Colors.white : AppColors.gold,
                                  ),
                                ),
                              ),
                              title: Text(
                                reciter.name,
                                style: TextStyle(
                                  fontWeight:
                                      active
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                ),
                              ),
                              trailing:
                                  active
                                      ? const Icon(
                                        Icons.check_circle_rounded,
                                        color: AppColors.gold,
                                      )
                                      : null,
                              onTap: () {
                                controller.updateDefaultReciter(reciter.id);
                                Navigator.pop(context);
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
    );
  }

  void _showBackupOptions(BuildContext context, SettingsController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (ctx) => _buildBottomModal(
            ctx,
            'Backup & Restore',
            Column(
              children: [
                _buildActionTile(
                  Icons.cloud_upload_rounded,
                  'Backup ke Cloud',
                  'Simpan pengaturan ke server',
                  () {
                    Navigator.pop(ctx);
                    _confirmAction(
                      context,
                      'Backup Data',
                      'Apakah Anda yakin ingin mencadangkan data ke cloud?',
                      () {
                        _handleBackup(context, controller, true);
                      },
                    );
                  },
                ),
                _buildActionTile(
                  Icons.storage_rounded,
                  'Backup Lokal',
                  'Simpan file backup di perangkat',
                  () {
                    Navigator.pop(ctx);
                    _handleBackup(context, controller, false);
                  },
                ),
                _buildActionTile(
                  Icons.settings_backup_restore_rounded,
                  'Restore Data',
                  'Kembalikan data dari backup terakhir',
                  () {
                    Navigator.pop(ctx);
                    _confirmAction(
                      context,
                      'Restore Data',
                      'Data saat ini akan ditimpa dengan data backup. Lanjutkan?',
                      () {
                        _handleSync(
                          context,
                          controller,
                        ); // Reusing sync for restore mock
                      },
                    );
                  },
                ),
              ],
            ),
          ),
    );
  }

  Widget _buildActionTile(
    IconData icon,
    String title,
    String subtitle,
    VoidCallback onTap,
  ) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppColors.gold),
      title: Text(
        title,
        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
      ),
      subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      trailing: const Icon(Icons.chevron_right_rounded),
    );
  }

  void _confirmAction(
    BuildContext context,
    String title,
    String message,
    VoidCallback onConfirm,
  ) {
    showDialog(
      context: context,
      builder:
          (dialogCtx) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Text(title, style: const TextStyle(fontFamily: 'Amiri')),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogCtx),
                child: const Text(
                  'Batal',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogCtx);
                  onConfirm();
                },
                child: const Text(
                  'Ya, Lanjutkan',
                  style: TextStyle(
                    color: AppColors.gold,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
    );
  }

  void _showTimePicker(BuildContext context, SettingsController controller) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder:
          (context) => _buildBottomModal(
            context,
            'Waktu Pengingat',
            SizedBox(
              height: 200,
              child: CupertinoDatePicker(
                mode: CupertinoDatePickerMode.time,
                initialDateTime: DateTime(
                  2024,
                  1,
                  1,
                  controller.settings.reminderTime?.hour ?? 5,
                  controller.settings.reminderTime?.minute ?? 0,
                ),
                onDateTimeChanged: (dt) {
                  controller.updateReminderTime(
                    TimeOfDay(hour: dt.hour, minute: dt.minute),
                  );
                },
              ),
            ),
          ),
    );
  }

  void _handleSync(BuildContext context, SettingsController controller) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => const Center(child: CupertinoActivityIndicator(radius: 20)),
    );

    try {
      await controller.syncData();
    } finally {
      // Safely close dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sinkronisasi Berhasil!'),
            backgroundColor: AppColors.gold,
          ),
        );
      }
    }
  }

  void _handleBackup(
    BuildContext context,
    SettingsController controller,
    bool cloud,
  ) async {
    // Show loading
    showDialog(
      context: context,
      barrierDismissible: false,
      builder:
          (ctx) => const Center(child: CupertinoActivityIndicator(radius: 20)),
    );

    try {
      await controller.backupData(cloud);
    } finally {
      // Safely close dialog
      if (context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Backup ke ${cloud ? "Cloud" : "Storage"} Berhasil!'),
            backgroundColor: AppColors.gold,
          ),
        );
      }
    }
  }

  void _showAppInfo(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'Al-Quran App',
      applicationVersion: '2.4.0 (Premium)',
      applicationLegalese: '© 2024 Premium Islamic Apps',
      children: [
        const Text(
          'Aplikasi Al-Quran premium dengan fitur terlengkap untuk menemani ibadah Anda.',
        ),
      ],
    );
  }

  Widget _buildBottomModal(BuildContext context, String title, Widget content) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          content,
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
