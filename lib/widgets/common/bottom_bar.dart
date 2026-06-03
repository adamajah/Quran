import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class BottomBar extends StatelessWidget {
  final bool playing, showTajwid;
  final String reciter, surahName;
  final int pageNum, playVerse;
  final VoidCallback onPlay, onStop;
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
    required this.showTajwid,
    required this.onToggleTajwid,
    required this.onTajwidLongPress,
    this.onReciterTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : AppColors.pageBg,
        border: Border(
          top: BorderSide(
            color: AppColors.gold.withValues(alpha: isDark ? 0.2 : 0.35),
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.25 : 0.07),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      child: Row(
        children: [
          PlayerBtn(
            icon: playing ? Icons.pause_rounded : Icons.play_arrow_rounded,
            active: playing,
            onTap: onPlay,
          ),
          const SizedBox(width: 4),
          PlayerBtn(icon: Icons.stop_rounded, active: false, onTap: onStop),
          const SizedBox(width: 8),
          Tooltip(
            message:
                showTajwid
                    ? 'Tajwid Aktif · Tekan lama untuk panduan'
                    : 'Tajwid Mati · Tekan lama untuk panduan',
            child: GestureDetector(
              onLongPress: onTajwidLongPress,
              child: PlayerBtn(
                icon: Icons.color_lens_outlined,
                active: showTajwid,
                onTap: onToggleTajwid,
              ),
            ),
          ),
          const SizedBox(width: 8),
          const _BarDivider(),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: onReciterTap,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          reciter,
                          style: TextStyle(
                            fontSize: 10,
                            color: textColor,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 2),
                      const Icon(
                        Icons.arrow_drop_down_rounded,
                        size: 14,
                        color: AppColors.gold,
                      ),
                    ],
                  ),
                  if (playing)
                    Text(
                      '$surahName · Ayat $playVerse',
                      style: const TextStyle(
                        fontSize: 9,
                        color: AppColors.gold,
                      ),
                    )
                  else if (showTajwid)
                    Text(
                      'Tajwid aktif · tekan lama untuk panduan',
                      style: TextStyle(
                        fontSize: 9,
                        color: AppColors.tajwidColors['qalqalah']!,
                      ),
                    ),
                ],
              ),
            ),
          ),
          Text(
            'Hal. $pageNum',
            style: TextStyle(
              fontSize: 10,
              color: textColor.withValues(alpha: 0.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarDivider extends StatelessWidget {
  const _BarDivider();
  @override
  Widget build(BuildContext context) => Container(
    width: 1,
    height: 24,
    color: AppColors.gold.withValues(alpha: 0.25),
  );
}

class PlayerBtn extends StatelessWidget {
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const PlayerBtn({
    super.key,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultBg =
        isDark ? Colors.white.withValues(alpha: 0.05) : Colors.grey.shade100;
    final defaultBorder =
        isDark ? Colors.white.withValues(alpha: 0.2) : Colors.grey.shade300;
    final defaultIcon =
        isDark ? Colors.white.withValues(alpha: 0.7) : Colors.grey.shade600;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: active ? AppColors.gold.withValues(alpha: 0.12) : defaultBg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: active ? AppColors.gold : defaultBorder,
            width: 1,
          ),
        ),
        child: Icon(
          icon,
          size: 17,
          color: active ? AppColors.gold : defaultIcon,
        ),
      ),
    );
  }
}
