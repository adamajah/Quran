// ─────────────────────────────────────────────────────────────────────────────
// HafalanTab  —  TAB 0: main mushaf view with hide mode + repeat
// (extracted from hafalan_screen.dart)
// ─────────────────────────────────────────────────────────────────────────────
// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:quran/quran.dart' as q;
import 'package:quran_library/quran_library.dart';
import '../../constants/app_colors.dart';
import '../../models/hafalan_models.dart';
import 'hafalan_widgets.dart';

class HafalanTab extends StatefulWidget {
  final int surah, verseCount;
  final HideMode hideMode;
  final bool repeatActive, playing;
  final int playVerse, repeatCurrentVerse, repeatRemaining;
  final RepeatConfig repeatCfg;
  final Animation<double> pulseAnim;
  final VerseState Function(int, int) getState;
  final ValueChanged<int> onChangeSurah;
  final ValueChanged<HideMode> onHideModeChanged;
  final void Function(int, int) onCycleStatus;
  final void Function(int, int) onToggleBookmark;
  final void Function(int, int) onRevealVerse;
  final ValueChanged<RepeatConfig> onRepeatCfgChanged;
  final VoidCallback onStartRepeat, onStopRepeat;
  final ValueChanged<int> onPlayVerse;

  const HafalanTab({
    super.key,
    required this.surah,           required this.verseCount,
    required this.hideMode,        required this.repeatActive,
    required this.playing,         required this.playVerse,
    required this.repeatCurrentVerse, required this.repeatRemaining,
    required this.repeatCfg,       required this.pulseAnim,
    required this.getState,        required this.onChangeSurah,
    required this.onHideModeChanged,
    required this.onCycleStatus,   required this.onToggleBookmark,
    required this.onRevealVerse,   required this.onRepeatCfgChanged,
    required this.onStartRepeat,   required this.onStopRepeat,
    required this.onPlayVerse,
  });

  @override
  State<HafalanTab> createState() => _HafalanTabState();
}

class _HafalanTabState extends State<HafalanTab> {
  bool _showRepeatPanel = false;
  bool _showSurahPicker = false;

  static String _ar(int n) {
    const d = ['٠','١','٢','٣','٤','٥','٦','٧','٨','٩'];
    return n.toString().split('').map((c) => d[int.parse(c)]).join();
  }

  Color _statusColor(HafalanStatus s) => switch (s) {
    HafalanStatus.hafal    => AppColors.clrHafal,
    HafalanStatus.murojaah => AppColors.clrMurojaah,
    HafalanStatus.belum    => AppColors.clrBelum,
  };

  IconData _statusIcon(HafalanStatus s) => switch (s) {
    HafalanStatus.hafal    => Icons.check_circle_rounded,
    HafalanStatus.murojaah => Icons.refresh_rounded,
    HafalanStatus.belum    => Icons.radio_button_unchecked_rounded,
  };

  String _statusLabel(HafalanStatus s) => switch (s) {
    HafalanStatus.hafal    => 'Hafal',
    HafalanStatus.murojaah => 'Murojaah',
    HafalanStatus.belum    => 'Belum',
  };

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      // ── Tool bar
      _buildToolBar(),
      if (_showRepeatPanel) _buildRepeatPanel(),
      if (_showSurahPicker) _buildSurahPickerBar(),
      // ── Mushaf body
      Expanded(child: _buildMushafBody()),
    ]);
  }

  // ── Tool bar ────────────────────────────────────────────────────────────────
  Widget _buildToolBar() => Container(
    color: AppColors.pageBg,
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
    child: Row(children: [
      // Surah name button
      Expanded(child: GestureDetector(
        onTap: () => setState(() => _showSurahPicker = !_showSurahPicker),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.gold.withOpacity(0.08),
            border: Border.all(color: AppColors.gold.withOpacity(0.5)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(q.getSurahNameArabic(widget.surah),
                style: QuranLibrary().hafsStyle.copyWith(fontSize: 14, color: AppColors.dark)),
              Text('${q.getSurahName(widget.surah)} · ${widget.verseCount} Ayat',
                style: TextStyle(fontSize: 9, color: AppColors.dark.withOpacity(0.5))),
            ])),
            Icon(Icons.expand_more_rounded, size: 18, color: AppColors.gold),
          ]),
        ),
      )),
      const SizedBox(width: 8),
      // Hide mode toggle
      ToolBtn(
        icon: widget.hideMode == HideMode.none ? Icons.visibility_off_outlined : Icons.visibility_rounded,
        label: widget.hideMode == HideMode.none ? 'Sembunyikan' : 'Tampilkan',
        active: widget.hideMode != HideMode.none,
        onTap: () => _showHideModeDialog(),
      ),
      const SizedBox(width: 6),
      // Repeat
      ToolBtn(
        icon: Icons.repeat_rounded,
        label: 'Ulangi',
        active: widget.repeatActive,
        onTap: () {
          if (widget.repeatActive) {
            widget.onStopRepeat();
          } else {
            setState(() => _showRepeatPanel = !_showRepeatPanel);
          }
        },
      ),
    ]),
  );

  // ── Hide mode dialog ────────────────────────────────────────────────────────
  void _showHideModeDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
          Text('Mode Sembunyikan Ayat',
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.dark)),
          const SizedBox(height: 16),
          HideModeOption(
            icon: Icons.visibility_rounded, title: 'Tampilkan Semua',
            subtitle: 'Baca teks mushaf normal',
            active: widget.hideMode == HideMode.none,
            onTap: () { widget.onHideModeChanged(HideMode.none); Navigator.pop(ctx); },
          ),
          const SizedBox(height: 10),
          HideModeOption(
            icon: Icons.visibility_off_rounded, title: 'Sembunyikan Semua Ayat',
            subtitle: 'Pengguna membaca dari hafalan, tap ayat untuk tampilkan',
            active: widget.hideMode == HideMode.allText,
            onTap: () { widget.onHideModeChanged(HideMode.allText); Navigator.pop(ctx); },
          ),
          const SizedBox(height: 10),
          HideModeOption(
            icon: Icons.text_fields_rounded, title: 'Sembunyikan Sebagian Kata',
            subtitle: 'Sebagian kata disembunyikan untuk latihan',
            active: widget.hideMode == HideMode.partialWords,
            onTap: () { widget.onHideModeChanged(HideMode.partialWords); Navigator.pop(ctx); },
          ),
          const SizedBox(height: 8),
        ]),
      ),
    );
  }

  // ── Repeat panel ────────────────────────────────────────────────────────────
  Widget _buildRepeatPanel() => AnimatedContainer(
    duration: const Duration(milliseconds: 250),
    color: const Color(0xFFEDE3CE),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Icon(Icons.repeat_rounded, color: AppColors.gold, size: 16),
        const SizedBox(width: 6),
        Text('Pengaturan Pengulangan',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.dark)),
        const Spacer(),
        GestureDetector(
          onTap: () => setState(() => _showRepeatPanel = false),
          child: Icon(Icons.close_rounded, size: 18, color: AppColors.dark.withOpacity(0.5)),
        ),
      ]),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: RangeField(
          label: 'Dari Ayat',
          value: widget.repeatCfg.fromVerse,
          min: 1, max: widget.verseCount,
          onChange: (v) => widget.onRepeatCfgChanged(RepeatConfig(
            count: widget.repeatCfg.count,
            delaySeconds: widget.repeatCfg.delaySeconds,
            fromVerse: v,
            toVerse: widget.repeatCfg.toVerse,
          )),
        )),
        const SizedBox(width: 8),
        Expanded(child: RangeField(
          label: 'Sampai Ayat',
          value: widget.repeatCfg.toVerse,
          min: 1, max: widget.verseCount,
          onChange: (v) => widget.onRepeatCfgChanged(RepeatConfig(
            count: widget.repeatCfg.count,
            delaySeconds: widget.repeatCfg.delaySeconds,
            fromVerse: widget.repeatCfg.fromVerse,
            toVerse: v,
          )),
        )),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Ulang', style: TextStyle(fontSize: 10, color: AppColors.dark.withOpacity(0.6))),
          const SizedBox(height: 4),
          DropdownButtonFormField<int>(
            value: widget.repeatCfg.count,
            decoration: _inputDeco(),
            style: TextStyle(fontSize: 13, color: AppColors.dark),
            items: [3, 5, 7, 10].map((n) => DropdownMenuItem(value: n, child: Text('${n}x'))).toList(),
            onChanged: (v) => widget.onRepeatCfgChanged(RepeatConfig(
              count: v ?? 3,
              delaySeconds: widget.repeatCfg.delaySeconds,
              fromVerse: widget.repeatCfg.fromVerse,
              toVerse: widget.repeatCfg.toVerse,
            )),
          ),
        ])),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Jeda (dtk)', style: TextStyle(fontSize: 10, color: AppColors.dark.withOpacity(0.6))),
          const SizedBox(height: 4),
          DropdownButtonFormField<int>(
            value: widget.repeatCfg.delaySeconds,
            decoration: _inputDeco(),
            style: TextStyle(fontSize: 13, color: AppColors.dark),
            items: [1, 2, 3, 5].map((n) => DropdownMenuItem(value: n, child: Text('${n}s'))).toList(),
            onChanged: (v) => widget.onRepeatCfgChanged(RepeatConfig(
              count: widget.repeatCfg.count,
              delaySeconds: v ?? 2,
              fromVerse: widget.repeatCfg.fromVerse,
              toVerse: widget.repeatCfg.toVerse,
            )),
          ),
        ])),
      ]),
      const SizedBox(height: 10),
      SizedBox(width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            widget.onStartRepeat();
            setState(() => _showRepeatPanel = false);
          },
          icon: const Icon(Icons.play_arrow_rounded, size: 18),
          label: const Text('Mulai Pengulangan'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.dark,
            foregroundColor: AppColors.gold,
            padding: const EdgeInsets.symmetric(vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
          ),
        ),
      ),
    ]),
  );

  InputDecoration _inputDeco() => InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.gold.withOpacity(0.4)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.gold.withOpacity(0.4)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.gold, width: 1.5),
    ),
    filled: true,
    fillColor: AppColors.pageBg,
  );

  // ── Surah picker bar ────────────────────────────────────────────────────────
  Widget _buildSurahPickerBar() => Container(
    height: 200,
    color: AppColors.frameBg,
    child: ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      itemCount: q.totalSurahCount,
      itemBuilder: (_, i) {
        final s = i + 1;
        final active = s == widget.surah;
        return GestureDetector(
          onTap: () {
            widget.onChangeSurah(s);
            setState(() => _showSurahPicker = false);
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 2),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
            decoration: BoxDecoration(
              color: active ? AppColors.gold.withOpacity(0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(8),
              border: active ? Border.all(color: AppColors.gold.withOpacity(0.5)) : null,
            ),
            child: Row(children: [
              Container(
                width: 24, height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? AppColors.gold : AppColors.gold.withOpacity(0.12),
                ),
                child: Center(child: Text('$s',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold,
                    color: active ? Colors.white : AppColors.dark))),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(q.getSurahName(s),
                style: TextStyle(fontSize: 13, color: AppColors.dark, fontWeight: FontWeight.w500))),
              Text(q.getSurahNameArabic(s),
                style: QuranLibrary().hafsStyle.copyWith(fontSize: 16, color: active ? AppColors.gold : AppColors.dark.withOpacity(0.6))),
            ]),
          ),
        );
      },
    ),
  );

  // ── Mushaf body ─────────────────────────────────────────────────────────────
  Widget _buildMushafBody() {
    // Repeat progress header
    return Column(children: [
      if (widget.repeatActive) _buildRepeatProgress(),
      Expanded(child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          border: Border.all(color: AppColors.gold.withOpacity(0.35), width: 0.8),
          boxShadow: [BoxShadow(color: AppColors.dark.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          // Page-style header
          Container(
            color: const Color(0xFFEDE3CE),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text(q.getSurahNameArabic(widget.surah),
                style: QuranLibrary().hafsStyle.copyWith(fontSize: 13, color: AppColors.dark)),
              Container(width: 5, height: 5, decoration: const BoxDecoration(color: AppColors.gold, shape: BoxShape.circle)),
              Text('${q.getVerseCount(widget.surah)} Ayat',
                style: TextStyle(fontSize: 11, color: AppColors.dark.withOpacity(0.6))),
            ]),
          ),
          const HrGold(),
          Expanded(child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            itemCount: widget.verseCount,
            itemBuilder: (_, i) => _buildVerseRow(i + 1),
          )),
        ]),
      )),
      // Legend
      _buildLegend(),
    ]);
  }

  Widget _buildRepeatProgress() => AnimatedBuilder(
    animation: widget.pulseAnim,
    builder: (_, child) => Transform.scale(
      scaleY: widget.pulseAnim.value,
      child: child,
    ),
    child: Container(
      color: AppColors.dark,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      child: Row(children: [
        ScaleTransition(
          scale: widget.pulseAnim,
          child: Icon(Icons.graphic_eq_rounded, color: AppColors.gold, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Pengulangan Aktif — Ayat ${widget.repeatCurrentVerse}',
            style: TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600)),
          Text('Sisa ulangan: ${widget.repeatRemaining} · Ayat ${widget.repeatCfg.fromVerse}–${widget.repeatCfg.toVerse}',
            style: TextStyle(fontSize: 10, color: AppColors.goldLt)),
        ])),
        GestureDetector(
          onTap: widget.onStopRepeat,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.gold.withOpacity(0.6)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text('Stop', style: TextStyle(fontSize: 11, color: AppColors.gold, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    ),
  );

  // ── Verse row ───────────────────────────────────────────────────────────────
  Widget _buildVerseRow(int verse) {
    final st  = widget.getState(widget.surah, verse);
    final isActivePlay   = widget.playing && widget.playVerse == verse;
    final isRepeatVerse  = widget.repeatActive && widget.repeatCurrentVerse == verse;
    final hidden = widget.hideMode == HideMode.allText && !st.isRevealed;

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
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: isActivePlay || isRepeatVerse
              ? AppColors.hl.withOpacity(0.07)
              : st.isBookmarked ? AppColors.gold.withOpacity(0.07) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border(
            left: BorderSide(
              color: _statusColor(st.status),
              width: 3,
            ),
          ),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
          // Status dot + verse number
          Column(mainAxisSize: MainAxisSize.min, children: [
            GestureDetector(
              onTap: () => widget.onCycleStatus(widget.surah, verse),
              child: Icon(_statusIcon(st.status), size: 14, color: _statusColor(st.status)),
            ),
            const SizedBox(height: 3),
            VerseNum(verse: verse, active: isActivePlay || isRepeatVerse),
          ]),
          const SizedBox(width: 10),
          // Arabic text
          Expanded(child: _buildVerseText(verse, st, isActivePlay || isRepeatVerse)),
          // Bookmark icon
          if (st.isBookmarked)
            Padding(padding: const EdgeInsets.only(left: 4),
              child: Icon(Icons.bookmark_rounded, size: 12, color: AppColors.gold)),
        ]),
      ),
    );
  }

  Widget _buildVerseText(int verse, VerseState st, bool active) {
    final text = q.getVerse(widget.surah, verse, verseEndSymbol: false);

    if (widget.hideMode == HideMode.allText && !st.isRevealed) {
      return Container(
        height: 36,
        decoration: BoxDecoration(
          color: AppColors.dark.withOpacity(0.07),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: AppColors.dark.withOpacity(0.15)),
        ),
        child: Center(child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.visibility_off_outlined, size: 13, color: AppColors.dark.withOpacity(0.35)),
          const SizedBox(width: 5),
          Text('Tap untuk tampilkan',
            style: TextStyle(fontSize: 11, color: AppColors.dark.withOpacity(0.4), fontStyle: FontStyle.italic)),
        ])),
      );
    }

    if (widget.hideMode == HideMode.partialWords) {
      return PartialHideText(text: text, active: active, fontSize: 20);
    }

    return Text(
      text,
      textAlign: TextAlign.right,
      textDirection: TextDirection.rtl,
      style: QuranLibrary().hafsStyle.copyWith(
        fontSize: 20,
        height: 1.9,
        color: active ? AppColors.hl : AppColors.ink,
        backgroundColor: active ? AppColors.hl.withOpacity(0.05) : null,
      ),
    );
  }

  // ── Verse long-press menu ───────────────────────────────────────────────────
  void _showVerseMenu(int verse, VerseState st) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: AppColors.pageBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          border: Border.all(color: AppColors.gold.withOpacity(0.3)),
        ),
        padding: const EdgeInsets.all(20),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 40, height: 4, margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.4), borderRadius: BorderRadius.circular(2))),
          Text('Ayat $verse — ${q.getSurahName(widget.surah)}',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.dark)),
          const SizedBox(height: 4),
          Text(q.getVerse(widget.surah, verse, verseEndSymbol: false),
            style: QuranLibrary().hafsStyle.copyWith(fontSize: 18, color: AppColors.dark.withOpacity(0.75), height: 1.7),
            textAlign: TextAlign.center, textDirection: TextDirection.rtl,
            maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 16),
          // Status buttons
          Text('Status Hafalan', style: TextStyle(fontSize: 11, color: AppColors.dark.withOpacity(0.5))),
          const SizedBox(height: 8),
          Row(children: HafalanStatus.values.map((s) => Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() => widget.getState(widget.surah, verse).status = s);
                Navigator.pop(ctx);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.symmetric(vertical: 9),
                decoration: BoxDecoration(
                  color: st.status == s ? _statusColor(s).withOpacity(0.15) : Colors.transparent,
                  border: Border.all(
                    color: _statusColor(s).withOpacity(st.status == s ? 1 : 0.4),
                    width: st.status == s ? 1.5 : 1,
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Column(children: [
                  Icon(_statusIcon(s), size: 18, color: _statusColor(s)),
                  const SizedBox(height: 4),
                  Text(_statusLabel(s),
                    style: TextStyle(fontSize: 10, color: _statusColor(s), fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          )).toList()),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(child: MenuBtn(
              icon: st.isBookmarked ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
              label: st.isBookmarked ? 'Hapus Bookmark' : 'Simpan Bookmark',
              color: AppColors.gold,
              onTap: () { widget.onToggleBookmark(widget.surah, verse); Navigator.pop(ctx); },
            )),
            const SizedBox(width: 8),
            Expanded(child: MenuBtn(
              icon: Icons.play_circle_outline_rounded,
              label: 'Putar Audio',
              color: AppColors.hl,
              onTap: () { widget.onPlayVerse(verse); Navigator.pop(ctx); },
            )),
          ]),
        ]),
      ),
    );
  }

  Widget _buildLegend() => Container(
    color: AppColors.pageBg,
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      LegendDot(color: AppColors.clrHafal,    label: 'Hafal'),
      const SizedBox(width: 14),
      LegendDot(color: AppColors.clrMurojaah, label: 'Murojaah'),
      const SizedBox(width: 14),
      LegendDot(color: AppColors.clrBelum,    label: 'Belum'),
      const SizedBox(width: 14),
      Text('· Long press ayat untuk opsi',
        style: TextStyle(fontSize: 9, color: AppColors.dark.withOpacity(0.4))),
    ]),
  );
}
