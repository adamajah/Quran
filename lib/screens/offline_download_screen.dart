import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:quran/quran.dart' as q;
import '../providers/audio_provider.dart';
import '../providers/download_provider.dart';
import '../providers/storage_provider.dart';
import '../models/download_item.dart';
import '../models/reciter.dart';

import '../constants/app_colors.dart';

class OfflineDownloadScreen extends StatefulWidget {
  const OfflineDownloadScreen({super.key});

  @override
  State<OfflineDownloadScreen> createState() => _OfflineDownloadScreenState();
}

class _OfflineDownloadScreenState extends State<OfflineDownloadScreen> {
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  int _filterIndex = 0; // 0=Semua, 1=Belum Download, 2=Sudah Download
  bool _showAllSurah = false;

  String _formatSize(double gb) {
    if (gb < 1) return '${(gb * 1024).toStringAsFixed(1)} MB';
    return '${gb.toStringAsFixed(1)} GB';
  }

  List<int> _filteredSurahs(DownloadProvider provider) {
    List<int> all = List.generate(q.totalSurahCount, (i) => i + 1);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      all =
          all
              .where(
                (s) =>
                    q
                        .getSurahName(s)
                        .toLowerCase()
                        .contains(_searchQuery.toLowerCase()) ||
                    '$s'.contains(_searchQuery),
              )
              .toList();
    }

    // Apply download filter
    if (_filterIndex == 1) {
      all =
          all
              .where(
                (s) => provider.statusForSurah(s) != DownloadStatus.completed,
              )
              .toList();
    } else if (_filterIndex == 2) {
      all =
          all
              .where(
                (s) => provider.statusForSurah(s) == DownloadStatus.completed,
              )
              .toList();
    }

    return all;
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Offline & Download',
              style: TextStyle(
                color: textColor,
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Text(
              'Kelola bacaan dan audio tanpa internet',
              style: TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStorageCard(context),
            const SizedBox(height: 30),
            _buildSmartDownloadSection(context),
            const SizedBox(height: 30),
            _buildAllSurahSection(context),
            const SizedBox(height: 30),
            _buildAllQariSection(context),
            const SizedBox(height: 100),
          ],
        ),
      ),
      bottomSheet: _buildBottomBar(context),
    );
  }

  // ─── Storage Card ────────────────────────────────────────────────────────────

  Widget _buildStorageCard(BuildContext context) {
    return Consumer<StorageProvider>(
      builder: (context, provider, child) {
        final space = provider.storageSpace;
        if (space == null) return const SizedBox.shrink();

        final progress = space.usageValue;
        final freeStr = space.freeSize;
        final usedStr = space.usedSize;

        final isDark = Theme.of(context).brightness == Brightness.dark;
        final textColor = isDark ? Colors.white : AppColors.dark;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color:
                isDark
                    ? const Color(0xFF2C1A0E)
                    : AppColors.gold.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: AppColors.gold.withValues(alpha: isDark ? 0.3 : 0.15),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Penyimpanan Lokal',
                    style: TextStyle(
                      color: AppColors.goldLt,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Icon(Icons.storage, color: AppColors.gold),
                ],
              ),
              const SizedBox(height: 20),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor:
                      isDark ? Colors.white10 : Colors.grey.shade200,
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.gold,
                  ),
                  minHeight: 8,
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Terpakai: $usedStr',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  Text(
                    'Tersedia: $freeStr',
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                ],
              ),
              Divider(
                color: isDark ? Colors.white10 : Colors.grey.shade200,
                height: 30,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: AppColors.gold,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Data Aplikasi: ${_formatSize(provider.appUsageSize)}',
                        style: TextStyle(color: textColor, fontSize: 14),
                      ),
                    ],
                  ),
                  TextButton(
                    onPressed: () => provider.clearCache(),
                    child: const Text(
                      'Hapus Cache',
                      style: TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Smart Download ──────────────────────────────────────────────────────────

  Widget _buildSmartDownloadSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Smart Download',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark ? Colors.white10 : Colors.grey.shade200,
            ),
          ),
          child: Consumer<DownloadProvider>(
            builder: (context, provider, child) {
              return Column(
                children: [
                  _buildToggleTile(
                    context: context,
                    title: 'Download Hanya WiFi',
                    subtitle: 'Hemat kuota data seluler Anda',
                    value: provider.wifiOnly,
                    onChanged: (val) => provider.setWifiOnly(val),
                  ),
                  Divider(
                    color: isDark ? Colors.white10 : Colors.grey.shade200,
                    height: 1,
                  ),
                  _buildToggleTile(
                    context: context,
                    title: 'Pause Baterai Lemah',
                    subtitle: 'Berhenti saat baterai di bawah 20%',
                    value: provider.pauseLowBattery,
                    onChanged: (val) => provider.setPauseLowBattery(val),
                  ),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildToggleTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 5),
      title: Text(
        title,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.dark,
          fontSize: 16,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: AppColors.gold,
      ),
    );
  }

  // ─── Semua Pilihan Surat ─────────────────────────────────────────────────────

  Widget _buildAllSurahSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;
    final provider = context.watch<DownloadProvider>();
    final filtered = _filteredSurahs(provider);
    final displayCount =
        _showAllSurah
            ? filtered.length
            : (filtered.length > 7 ? 7 : filtered.length);
    final displayed = filtered.take(displayCount).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Semua Pilihan Surat',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Qari offline aktif: ${provider.selectedReciter.name}',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        const SizedBox(height: 12),

        // Search bar
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? Colors.white12 : Colors.grey.shade200,
            ),
          ),
          child: TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _searchQuery = v),
            style: TextStyle(fontSize: 14, color: textColor),
            decoration: InputDecoration(
              hintText: 'Cari nama surat...',
              hintStyle: TextStyle(
                color: textColor.withValues(alpha: 0.35),
                fontSize: 14,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.gold,
                size: 20,
              ),
              suffixIcon:
                  _searchQuery.isNotEmpty
                      ? IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                      : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(vertical: 13),
            ),
          ),
        ),
        const SizedBox(height: 10),

        // Filter chips
        Row(
          children: [
            _buildFilterChip(context, 'Semua', 0, isDark, textColor),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Belum Download', 1, isDark, textColor),
            const SizedBox(width: 8),
            _buildFilterChip(context, 'Sudah Download', 2, isDark, textColor),
          ],
        ),
        const SizedBox(height: 12),

        // Surah list
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: [
              ...List.generate(displayed.length, (i) {
                final surah = displayed[i];
                final isLast =
                    i == displayed.length - 1 &&
                    !(!_showAllSurah && filtered.length > 7);
                final status = provider.statusForSurah(surah);
                return Column(
                  children: [
                    _buildSurahRow(context, surah, status, isDark, textColor),
                    if (!isLast)
                      Divider(
                        height: 1,
                        indent: 60,
                        endIndent: 16,
                        color:
                            isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.grey.shade100,
                      ),
                  ],
                );
              }),

              // "Lihat Semua" toggle button
              if (filtered.length > 7) ...[
                Divider(
                  height: 1,
                  color: isDark ? Colors.white10 : Colors.grey.shade200,
                ),
                InkWell(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(16),
                  ),
                  onTap: () => setState(() => _showAllSurah = !_showAllSurah),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          _showAllSurah
                              ? 'Sembunyikan'
                              : 'Lihat Semua Surat (${filtered.length})',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(
                          _showAllSurah
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          color: textColor,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String label,
    int index,
    bool isDark,
    Color textColor,
  ) {
    final isSelected = _filterIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _filterIndex = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.gold : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                isSelected
                    ? AppColors.gold
                    : (isDark ? Colors.white24 : Colors.grey.shade300),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : textColor.withValues(alpha: 0.7),
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  Widget _buildSurahRow(
    BuildContext context,
    int surah,
    DownloadStatus status,
    bool isDark,
    Color textColor,
  ) {
    return Consumer<DownloadProvider>(
      builder: (context, provider, _) {
        final item = provider.itemForSurah(surah);
        final isDownloaded = status == DownloadStatus.completed;
        final isDownloading = status == DownloadStatus.downloading;
        final isPaused = status == DownloadStatus.paused;
        final audioProvider = context.watch<AudioProvider>();
        final isPlaying =
            item?.savePath != null &&
            audioProvider.currentPath == item!.savePath &&
            audioProvider.playerState == PlayerState.playing;
        final statusText =
            isDownloaded
                ? 'Sudah Download'
                : isDownloading
                ? 'Sedang Download'
                : isPaused
                ? 'Dijeda'
                : 'Belum Download';
        final statusColor =
            isDownloaded
                ? AppColors.gold
                : isDownloading
                ? AppColors.goldLt
                : Colors.grey;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              // Download icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color:
                      isDownloaded
                          ? AppColors.gold.withValues(alpha: 0.15)
                          : (isDark ? Colors.white10 : Colors.grey.shade100),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isDownloaded
                      ? Icons.download_done_rounded
                      : Icons.download_for_offline_outlined,
                  color: isDownloaded ? AppColors.gold : Colors.grey,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Surah info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$surah. ${q.getSurahName(surah)}',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          '${q.getVerseCount(surah)} Ayat',
                          style: const TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                        const Text(
                          ' • ',
                          style: TextStyle(color: Colors.grey, fontSize: 12),
                        ),
                        Text(
                          statusText,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 12,
                            fontWeight:
                                isDownloaded
                                    ? FontWeight.w500
                                    : FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Action icon
              if (isDownloaded)
                IconButton(
                  tooltip: isPlaying ? 'Jeda audio offline' : 'Putar offline',
                  onPressed:
                      item?.savePath == null
                          ? null
                          : () async {
                            final path = await provider.localAudioPathForSurah(
                              surah,
                            );
                            if (!context.mounted) return;
                            if (path == null) {
                              _showAudioMessage(
                                context,
                                'File audio tidak ditemukan. Silakan download ulang.',
                              );
                              return;
                            }
                            final error = await audioProvider.playToggle(path);
                            if (!context.mounted || error == null) return;
                            _showAudioMessage(context, error);
                          },
                  icon: Icon(
                    isPlaying
                        ? Icons.pause_circle_filled_rounded
                        : Icons.play_circle_fill_rounded,
                    color: AppColors.gold,
                    size: 26,
                  ),
                )
              else if (isDownloading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.gold,
                    ),
                    backgroundColor:
                        isDark ? Colors.white12 : Colors.grey.shade200,
                  ),
                )
              else
                GestureDetector(
                  onTap: () => provider.downloadSurah(surah),
                  child: const Icon(
                    Icons.play_arrow_rounded,
                    color: Colors.grey,
                    size: 22,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showAudioMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  // ─── Semua Pilihan Qari ──────────────────────────────────────────────────────

  Widget _buildAllQariSection(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;
    final cardColor = Theme.of(context).cardColor;
    final borderColor = isDark ? Colors.white10 : Colors.grey.shade200;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Semua Pilihan Qari',
          style: TextStyle(
            color: textColor,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: borderColor),
          ),
          child: Column(
            children: List.generate(availableReciters.length, (i) {
              final qari = availableReciters[i];
              final isLast = i == availableReciters.length - 1;
              return Column(
                children: [
                  _buildQariRow(context, qari, isDark, textColor),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 60,
                      endIndent: 16,
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.08)
                              : Colors.grey.shade100,
                    ),
                ],
              );
            }),
          ),
        ),
      ],
    );
  }

  Widget _buildQariRow(
    BuildContext context,
    Reciter qari,
    bool isDark,
    Color textColor,
  ) {
    return Consumer<DownloadProvider>(
      builder: (context, provider, _) {
        final completedCount = provider.completedSurahCountForReciter(qari.id);
        final isCompleted = completedCount == q.totalSurahCount;
        final isSelected = provider.selectedReciter.id == qari.id;
        final canDownload = qari.supportsSurahAudioDownload;
        final subtitle =
            !canDownload
                ? 'Streaming saja • audio offline belum tersedia'
                : isCompleted
                ? 'Semua surat sudah download'
                : completedCount > 0
                ? '$completedCount/${q.totalSurahCount} surat • ${qari.surahAudioBitrate} kbps'
                : '${qari.surahAudioBitrate} kbps • Audio offline';

        return InkWell(
          onTap: canDownload ? () => provider.selectReciter(qari) : null,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 20,
                  backgroundColor:
                      isSelected
                          ? AppColors.gold.withValues(alpha: 0.2)
                          : (isDark ? Colors.white10 : Colors.grey.shade100),
                  child: Text(
                    qari.name[0],
                    style: TextStyle(
                      color: isSelected ? AppColors.gold : textColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        qari.name,
                        style: TextStyle(
                          color: textColor,
                          fontWeight: FontWeight.w600,
                          fontSize: 14,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),

                // Download button
                GestureDetector(
                  onTap:
                      !canDownload || isCompleted
                          ? null
                          : () => provider.downloadReciter(qari),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color:
                          isCompleted
                              ? Colors.transparent
                              : isSelected
                              ? AppColors.gold
                              : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color:
                            isCompleted
                                ? AppColors.gold
                                : isSelected
                                ? AppColors.gold
                                : (isDark
                                    ? Colors.white24
                                    : Colors.grey.shade300),
                      ),
                    ),
                    child: Text(
                      !canDownload
                          ? 'N/A'
                          : isCompleted
                          ? 'Sudah'
                          : 'Download 114',
                      style: TextStyle(
                        color:
                            isCompleted
                                ? AppColors.gold
                                : isSelected
                                ? Colors.white
                                : textColor.withValues(alpha: 0.7),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Bottom Bar ──────────────────────────────────────────────────────────────

  Widget _buildBottomBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Data Quran',
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
              Text(
                'Kira-kira 1.2 GB untuk full audio',
                style: TextStyle(color: Colors.grey[600], fontSize: 12),
              ),
            ],
          ),
          Consumer<DownloadProvider>(
            builder: (context, provider, child) {
              return ElevatedButton.icon(
                onPressed: () => provider.downloadAll(),
                icon: const Icon(Icons.download_rounded, size: 18),
                label: const Text(
                  'Download Semua',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.gold,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
