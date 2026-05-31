import 'package:flutter/material.dart';

import '../../constants/app_colors.dart';

class BottomBar extends StatelessWidget {
  final bool playing, showTajwid;
  final String reciter, surahName;
  final int pageNum, playVerse;
  final VoidCallback onPlay, onStop;
  final double fontScale;
  final VoidCallback onZoomIn, onZoomOut, onZoomReset;
  final VoidCallback onToggleTajwid;
  final VoidCallback onTajwidLongPress;
  final VoidCallback? onReciterTap;

  const BottomBar({
    super.key,
    required this.playing,
    required this.reciter,
    required this.surahName,
    required this.pageNum,
    required this.playVerse,
    required this.onPlay,
    required this.onStop,
    required this.fontScale,
    required this.onZoomIn,
    required this.onZoomOut,
    required this.onZoomReset,
    required this.showTajwid,
    required this.onToggleTajwid,
    required this.onTajwidLongPress,
    this.onReciterTap,
  });

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.gold;
    final bgTop = const Color(0xFFF7F1E5);
    final bgBottom = const Color(0xFFE8DCC8);
    final textColor = AppColors.dark;
    final muted = textColor.withValues(alpha: 0.6);

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [bgTop, bgBottom],
          ),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
          border: Border.all(color: gold.withValues(alpha: 0.35), width: 0.9),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.14),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                final compact = constraints.maxWidth < 430;

                final controls = Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _LuxuryButton(
                      icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      active: playing,
                      filled: true,
                      size: 44,
                      onTap: onPlay,
                    ),
                    _LuxuryButton(
                      icon: Icons.stop_rounded,
                      active: false,
                      size: 40,
                      onTap: onStop,
                    ),
                    _LuxuryButton(
                      icon: Icons.remove_rounded,
                      active: false,
                      size: 36,
                      onTap: onZoomOut,
                    ),
                    _ZoomPill(
                      percent: (fontScale * 100).round(),
                      active: fontScale != 1.0,
                      onTap: onZoomReset,
                    ),
                    _LuxuryButton(
                      icon: Icons.add_rounded,
                      active: false,
                      size: 36,
                      onTap: onZoomIn,
                    ),
                    GestureDetector(
                      onTap: onToggleTajwid,
                      onLongPress: onTajwidLongPress,
                      child: _LuxuryButton(
                        icon: Icons.palette_outlined,
                        active: showTajwid,
                        size: 40,
                        onTap: onToggleTajwid,
                      ),
                    ),
                  ],
                );

                final info = compact
                    ? Column(
                        children: [
                          _ReciterTile(
                            reciter: reciter,
                            surahName: surahName,
                            playVerse: playVerse,
                            showTajwid: showTajwid,
                            textColor: textColor,
                            muted: muted,
                            onTap: onReciterTap,
                          ),
                          const SizedBox(height: 8),
                          _PageTile(pageNum: pageNum, gold: gold, textColor: textColor),
                        ],
                      )
                    : Row(
                        children: [
                          Expanded(
                            child: _ReciterTile(
                              reciter: reciter,
                              surahName: surahName,
                              playVerse: playVerse,
                              showTajwid: showTajwid,
                              textColor: textColor,
                              muted: muted,
                              onTap: onReciterTap,
                            ),
                          ),
                          const SizedBox(width: 10),
                          _PageTile(pageNum: pageNum, gold: gold, textColor: textColor),
                        ],
                      );

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    controls,
                    const SizedBox(height: 8),
                    info,
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PageTile extends StatelessWidget {
  final int pageNum;
  final Color gold;
  final Color textColor;

  const _PageTile({
    required this.pageNum,
    required this.gold,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: gold.withValues(alpha: 0.42), width: 0.8),
      ),
      child: Text(
        'Hal. $pageNum',
        style: TextStyle(
          fontSize: 10.8,
          color: textColor.withValues(alpha: 0.88),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ReciterTile extends StatelessWidget {
  final String reciter, surahName;
  final int playVerse;
  final bool showTajwid;
  final Color textColor;
  final Color muted;
  final VoidCallback? onTap;

  const _ReciterTile({
    required this.reciter,
    required this.surahName,
    required this.playVerse,
    required this.showTajwid,
    required this.textColor,
    required this.muted,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.gold;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: gold.withValues(alpha: 0.32), width: 0.8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      reciter,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.1,
                        fontWeight: FontWeight.w700,
                        color: textColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 16,
                    color: AppColors.gold,
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
              '$surahName · Ayat $playVerse',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9.0,
                color: gold,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 2),
              Text(
                showTajwid
                    ? 'Tajwid aktif · tekan lama untuk panduan'
                    : 'Audio qari aktif',
                style: TextStyle(fontSize: 8.5, color: muted),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LuxuryButton extends StatelessWidget {
  final IconData icon;
  final bool active;
  final bool filled;
  final double size;
  final VoidCallback onTap;

  const _LuxuryButton({
    required this.icon,
    required this.active,
    required this.size,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.gold;
    final bg = filled ? (active ? gold : Colors.white) : Colors.white;
    final border = active ? gold : gold.withValues(alpha: 0.42);
    final iconColor = filled && active ? const Color(0xFF171717) : (active ? gold : AppColors.dark);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(size / 2),
          child: Container(
            width: size,
            height: size,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(size / 2),
            border: Border.all(color: border, width: 0.9),
            boxShadow: [
              if (active)
                BoxShadow(
                  color: gold.withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
            ],
          ),
          child: Icon(icon, size: size * 0.48, color: iconColor),
        ),
      ),
    );
  }
}

class _ZoomPill extends StatelessWidget {
  final int percent;
  final bool active;
  final VoidCallback onTap;

  const _ZoomPill({
    required this.percent,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gold = AppColors.gold;
    final textColor = active ? gold : AppColors.dark;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: active ? gold.withValues(alpha: 0.12) : Colors.white,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: gold.withValues(alpha: 0.42), width: 0.8),
          ),
          child: Text(
            '$percent%',
            style: TextStyle(
              fontSize: 9.7,
              color: textColor,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }
}
