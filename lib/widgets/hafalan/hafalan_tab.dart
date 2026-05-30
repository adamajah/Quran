// FULL FINAL VERSION
// FILE: lib/widgets/hafalan/hafalan_tab.dart
//
// FIX:
// - double nomor ayat
// - bubble kosong
// - nomor ayat hilang
// - partial mode rusak
// - tarteel nomor hilang

import 'package:flutter/material.dart';
import 'package:quran/quran.dart' as q;
import 'package:quran_library/quran_library.dart';

import '../../constants/app_colors.dart';
import '../../models/hafalan_models.dart';
import '../../models/reciter.dart';
import '../../utils/quran_utils.dart';
import 'hafalan_widgets.dart';

class HafalanTab extends StatefulWidget {
  final int surah;
  final int verseCount;

  final HideMode hideMode;

  final bool repeatActive;
  final bool playing;

  final int playVerse;
  final int repeatCurrentVerse;
  final int repeatRemaining;

  final RepeatConfig repeatCfg;

  final Animation<double> pulseAnim;

  final VerseState Function(int, int) getState;

  final ValueChanged<int> onChangeSurah;

  final ValueChanged<HideMode> onHideModeChanged;

  final void Function(int, int) onCycleStatus;

  final ValueChanged<int> onResetSurahStatus;

  final void Function(int, int) onToggleBookmark;

  final void Function(int, int) onRevealVerse;

  final ValueChanged<RepeatConfig> onRepeatCfgChanged;

  final VoidCallback onStartRepeat;

  final VoidCallback onStopRepeat;

  final void Function(int) onPlayVerse;
  final Reciter selectedReciter;
  final ValueChanged<Reciter> onReciterChanged;

  const HafalanTab({
    super.key,
    required this.surah,
    required this.verseCount,
    required this.hideMode,
    required this.repeatActive,
    required this.playing,
    required this.playVerse,
    required this.repeatCurrentVerse,
    required this.repeatRemaining,
    required this.repeatCfg,
    required this.pulseAnim,
    required this.getState,
    required this.onChangeSurah,
    required this.onHideModeChanged,
    required this.onCycleStatus,
    required this.onResetSurahStatus,
    required this.onToggleBookmark,
    required this.onRevealVerse,
    required this.onRepeatCfgChanged,
    required this.onStartRepeat,
    required this.onStopRepeat,
    required this.onPlayVerse,
    required this.selectedReciter,
    required this.onReciterChanged,
  });

  @override
  State<HafalanTab> createState() => _HafalanTabState();
}

class _HafalanTabState extends State<HafalanTab> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;
    return Column(
      children: [
        // ── Compact Toolbar ──────────────────────────────────────
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : AppColors.pageBg,
            border: Border(
              bottom: BorderSide(color: AppColors.gold.withValues(alpha: 0.18)),
            ),
          ),
          child: Column(
            children: [
              // Row 1: Surah selector + Range (Dari - Sampai)
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      value: widget.surah,
                      dropdownColor:
                          isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 6,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.gold.withValues(alpha: 0.4),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.gold.withValues(alpha: 0.4),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: const BorderSide(
                            color: AppColors.gold,
                            width: 1.5,
                          ),
                        ),
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF1E1E1E) : AppColors.pageBg,
                        prefixIcon: Icon(
                          Icons.menu_book_rounded,
                          size: 14,
                          color: AppColors.gold,
                        ),
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                      items:
                          List.generate(114, (i) => i + 1)
                              .map(
                                (s) => DropdownMenuItem(
                                  value: s,
                                  child: Text(q.getSurahName(s)),
                                ),
                              )
                              .toList(),
                      onChanged: (s) {
                        if (s != null) widget.onChangeSurah(s);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: widget.repeatCfg.fromVerse,
                      dropdownColor:
                          isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.gold.withValues(alpha: 0.2),
                          ),
                        ),
                        labelText: 'Dari',
                        labelStyle: TextStyle(
                          fontSize: 9,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF1E1E1E) : AppColors.pageBg,
                      ),
                      style: TextStyle(fontSize: 11, color: textColor),
                      items:
                          List.generate(widget.verseCount, (i) => i + 1)
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('$v'),
                                ),
                              )
                              .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          final newCfg = widget.repeatCfg;
                          newCfg.fromVerse = v;
                          if (newCfg.toVerse < v) newCfg.toVerse = v;
                          widget.onRepeatCfgChanged(newCfg);
                        }
                      },
                    ),
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      value: widget.repeatCfg.toVerse,
                      dropdownColor:
                          isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      decoration: InputDecoration(
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                          borderSide: BorderSide(
                            color: AppColors.gold.withValues(alpha: 0.2),
                          ),
                        ),
                        labelText: 'Ke',
                        labelStyle: TextStyle(
                          fontSize: 9,
                          color: textColor.withValues(alpha: 0.5),
                        ),
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF1E1E1E) : AppColors.pageBg,
                      ),
                      style: TextStyle(fontSize: 11, color: textColor),
                      items:
                          List.generate(
                                widget.verseCount -
                                    widget.repeatCfg.fromVerse +
                                    1,
                                (i) => i + widget.repeatCfg.fromVerse,
                              )
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text('$v'),
                                ),
                              )
                              .toList(),
                      onChanged: (v) {
                        if (v != null) {
                          final newCfg = widget.repeatCfg;
                          newCfg.toVerse = v;
                          widget.onRepeatCfgChanged(newCfg);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Row 2: Hide mode quick toggles
              Row(
                children: [
                  Text(
                    'Mode:',
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 4),
                  _HideModeChip(
                    label: 'Tampil',
                    icon: Icons.visibility_rounded,
                    active: widget.hideMode == HideMode.none,
                    onTap: () => widget.onHideModeChanged(HideMode.none),
                  ),
                  const SizedBox(width: 4),
                  _HideModeChip(
                    label: 'Sembunyi',
                    icon: Icons.visibility_off_rounded,
                    active: widget.hideMode == HideMode.allText,
                    onTap: () => widget.onHideModeChanged(HideMode.allText),
                  ),
                  const SizedBox(width: 4),
                  _HideModeChip(
                    label: 'Sebagian',
                    icon: Icons.remove_red_eye_rounded,
                    active: widget.hideMode == HideMode.partialWords,
                    onTap:
                        () => widget.onHideModeChanged(HideMode.partialWords),
                  ),
                  const Spacer(),
                  InkWell(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder:
                            (ctx) => AlertDialog(
                              title: const Text('Reset Ceklis Hafalan?'),
                              content: Text(
                                'Apakah Anda ingin mematikan/mereset semua ceklis hafalan untuk Surah ${q.getSurahName(widget.surah)}?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx),
                                  child: const Text('Batal'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(ctx);
                                    widget.onResetSurahStatus(widget.surah);
                                  },
                                  child: const Text(
                                    'Reset',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                      );
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.red.withValues(alpha: 0.2),
                          width: 1,
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.refresh_rounded,
                            size: 14,
                            color: Colors.red,
                          ),
                          SizedBox(width: 4),
                          Text(
                            'Reset Ceklis',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.red,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Row 3: Reciter & Repeat count (NEW)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<Reciter>(
                        value: widget.selectedReciter,
                        dropdownColor:
                            isDark ? const Color(0xFF1E1E1E) : Colors.white,
                        decoration: InputDecoration(
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(6),
                            borderSide: BorderSide(
                              color: AppColors.gold.withValues(alpha: 0.2),
                            ),
                          ),
                          prefixIcon: Icon(
                            Icons.person_rounded,
                            size: 12,
                            color: AppColors.gold,
                          ),
                          filled: true,
                          fillColor:
                              isDark
                                  ? const Color(0xFF1E1E1E)
                                  : AppColors.pageBg,
                        ),
                        style: TextStyle(fontSize: 11, color: textColor),
                        items:
                            availableReciters
                                .map(
                                  (r) => DropdownMenuItem(
                                    value: r,
                                    child: Text(
                                      r.name,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                )
                                .toList(),
                        onChanged: (r) {
                          if (r != null) widget.onReciterChanged(r);
                        },
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Ulang:',
                    style: TextStyle(
                      fontSize: 10,
                      color: textColor.withValues(alpha: 0.5),
                    ),
                  ),
                  const SizedBox(width: 4),
                  ...[3, 5, 10].map(
                    (c) => Padding(
                      padding: const EdgeInsets.only(right: 3),
                      child: InkWell(
                        onTap: () {
                          final newCfg = widget.repeatCfg;
                          newCfg.count = c;
                          widget.onRepeatCfgChanged(newCfg);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color:
                                widget.repeatCfg.count == c
                                    ? AppColors.gold
                                    : AppColors.gold.withValues(alpha: 0.05),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: AppColors.gold.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Text(
                            '${c}x',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color:
                                  widget.repeatCfg.count == c
                                      ? Colors.white
                                      : AppColors.gold,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            itemCount: widget.verseCount,
            itemBuilder: (_, i) {
              final verse = i + 1;
              return _buildVerseRow(verse);
            },
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────
  // BUILD VERSE ROW
  // ─────────────────────────────────────────
  Widget _buildVerseRow(int verse) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final st = widget.getState(widget.surah, verse);

    final isActivePlay = widget.playing && widget.playVerse == verse;

    final isRepeatVerse =
        widget.repeatActive && widget.repeatCurrentVerse == verse;

    return GestureDetector(
      onTap: () {
        if (widget.hideMode != HideMode.none) {
          widget.onRevealVerse(widget.surah, verse);
        } else {
          widget.onPlayVerse(verse);
        }
      },

      onLongPress: () => _showVerseMenu(verse, st),

      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),

        margin: const EdgeInsets.symmetric(vertical: 4),

        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),

        decoration: BoxDecoration(
          color:
              isActivePlay || isRepeatVerse
                  ? AppColors.hl.withValues(alpha: 0.06)
                  : (isDark ? const Color(0xFF222222) : Colors.white),

          borderRadius: BorderRadius.circular(10),

          border: Border.all(
            color: activeBorder(st, isActivePlay, isRepeatVerse),
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),

        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // STATUS
            GestureDetector(
              onTap: () {
                widget.onCycleStatus(widget.surah, verse);
              },

              child: Container(
                width: 26,
                height: 26,

                decoration: BoxDecoration(
                  color: _statusColor(st.status).withValues(alpha: 0.12),

                  shape: BoxShape.circle,
                ),

                child:
                    (widget.hideMode == HideMode.allText &&
                            st.status != HafalanStatus.hafal)
                        ? Center(
                          child: Text(
                            '$verse',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color:
                                  isDark
                                      ? Colors.white70
                                      : AppColors.dark.withValues(alpha: 0.7),
                            ),
                          ),
                        )
                        : Icon(
                          _statusIcon(st.status),
                          size: 14,
                          color: _statusColor(st.status),
                        ),
              ),
            ),

            const SizedBox(width: 12),

            // QURAN TEXT
            Expanded(
              child: _buildVerseText(verse, st, isActivePlay || isRepeatVerse),
            ),

            // BOOKMARK
            if (st.isBookmarked)
              Padding(
                padding: const EdgeInsets.only(left: 6),

                child: Icon(Icons.bookmark, size: 14, color: AppColors.gold),
              ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────
  // BUILD VERSE TEXT
  // ─────────────────────────────────────────
  Widget _buildVerseText(int verse, VerseState st, bool active) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.ink;

    // SINGLE source of truth: get text WITHOUT symbol, add ONE badge via _ar()
    final cleanText = QuranUtils.getCleanVerse(
      widget.surah,
      verse,
      verseEndSymbol: false,
    );

    // HIDE MODE
    if (widget.hideMode == HideMode.allText && !st.isRevealed) {
      return Container(
        height: 38,
        decoration: BoxDecoration(
          color: (isDark ? Colors.white : AppColors.dark).withValues(
            alpha: 0.06,
          ),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Center(
          child: Text(
            'Tap untuk tampilkan ayat',
            style: TextStyle(
              fontSize: 11,
              color: (isDark ? Colors.white : AppColors.dark).withValues(
                alpha: 0.45,
              ),
            ),
          ),
        ),
      );
    }

    // PARTIAL MODE — pass clean text (no symbol), PartialHideText handles display
    if (widget.hideMode == HideMode.partialWords) {
      return PartialHideText(text: cleanText, active: active, fontSize: 21);
    }

    // NORMAL MODE — render text + ONE verse-number badge
    return Text.rich(
      TextSpan(
        children: [
          TextSpan(
            text: cleanText,
            style: QuranLibrary().hafsStyle.copyWith(
              fontSize: 21,
              height: 2.0,
              color: active ? AppColors.hl : textColor,
              backgroundColor:
                  active ? AppColors.hl.withValues(alpha: 0.05) : null,
            ),
          ),
          TextSpan(text: ' '),
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              decoration: BoxDecoration(
                color:
                    active
                        ? AppColors.hl.withValues(alpha: 0.12)
                        : AppColors.gold.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                _arNum(verse),
                style: QuranLibrary().hafsStyle.copyWith(
                  fontSize: 14,
                  color: active ? AppColors.hl : AppColors.gold,
                  fontWeight: FontWeight.bold,
                  height: 1.6,
                ),
              ),
            ),
          ),
        ],
      ),
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
    );
  }

  static String _arNum(int n) {
    const d = ['٠', '١', '٢', '٣', '٤', '٥', '٦', '٧', '٨', '٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  // ─────────────────────────────────────────
  // SHOW MENU
  // ─────────────────────────────────────────
  void _showVerseMenu(int verse, VerseState st) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: Icon(Icons.bookmark, color: AppColors.gold),

                title: Text(
                  st.isBookmarked ? 'Hapus Bookmark' : 'Tambah Bookmark',
                  style: TextStyle(
                    color: isDark ? Colors.white : AppColors.dark,
                  ),
                ),

                onTap: () {
                  Navigator.pop(context);

                  widget.onToggleBookmark(widget.surah, verse);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ─────────────────────────────────────────
  // STATUS ICON
  // ─────────────────────────────────────────
  IconData _statusIcon(HafalanStatus s) {
    switch (s) {
      case HafalanStatus.hafal:
        return Icons.check_circle;
      case HafalanStatus.murojaah:
        return Icons.refresh;
      case HafalanStatus.belum:
        return Icons.radio_button_unchecked;
    }
  }

  // ─────────────────────────────────────────
  // STATUS COLOR
  // ─────────────────────────────────────────
  Color _statusColor(HafalanStatus s) {
    switch (s) {
      case HafalanStatus.hafal:
        return Colors.green;
      case HafalanStatus.murojaah:
        return Colors.orange;
      case HafalanStatus.belum:
        return Colors.grey;
    }
  }

  Color activeBorder(VerseState st, bool active, bool repeat) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (active || repeat) {
      return AppColors.hl.withValues(alpha: 0.25);
    }

    if (st.isBookmarked) {
      return AppColors.gold.withValues(alpha: 0.25);
    }

    return isDark
        ? Colors.white.withValues(alpha: 0.1)
        : Colors.grey.withValues(alpha: 0.12);
  }
}

class _HideModeChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _HideModeChip({
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color:
              active ? AppColors.gold : AppColors.gold.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color:
                active ? AppColors.gold : AppColors.gold.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: active ? Colors.white : AppColors.gold),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: active ? Colors.white : AppColors.gold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
