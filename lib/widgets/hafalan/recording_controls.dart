import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class RecordingControls extends StatelessWidget {
  final bool isRecording;
  final int mistakes;
  final String timer;
  final VoidCallback onToggle;
  final VoidCallback onStop;
  final VoidCallback onNext;
  final VoidCallback onPrev;
  final VoidCallback onToggleHide;
  final bool isHidden;

  const RecordingControls({
    super.key,
    required this.isRecording,
    required this.mistakes,
    required this.timer,
    required this.onToggle,
    required this.onStop,
    required this.onNext,
    required this.onPrev,
    required this.onToggleHide,
    required this.isHidden,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : AppColors.pageBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.08),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Waveform and Status Area — Symmetrical 3-column layout
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _StatBadge(
                    label: 'Salah',
                    value: '$mistakes',
                    color: mistakes > 0 ? Colors.red : Colors.grey,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isRecording) ...[
                        const _WaveformSimulator(),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        isRecording ? 'Listening' : 'Ready',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color:
                              isRecording
                                  ? Colors.green
                                  : Colors.grey.withValues(alpha: 0.6),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    timer,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      fontFeatures: const [FontFeature.tabularFigures()],
                      color: isDark ? Colors.white : AppColors.dark,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Buttons Area — 5 equal columns for perfect symmetry
          Row(
            children: [
              Expanded(
                child: Center(
                  child: _ActionBtn(
                    icon:
                        isHidden
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                    label: isHidden ? 'Lihat' : 'Sembunyikan',
                    onTap: onToggleHide,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _ActionBtn(
                    icon: Icons.skip_previous_rounded,
                    label: 'Sblm',
                    onTap: onPrev,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: GestureDetector(
                    onTap: onToggle,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color:
                            isRecording
                                ? Colors.orange.shade100
                                : AppColors.gold.withValues(alpha: 0.15),
                        border: Border.all(
                          color: isRecording ? Colors.orange : AppColors.gold,
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        isRecording
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: isRecording ? Colors.orange : AppColors.gold,
                        size: 32,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _ActionBtn(
                    icon: Icons.skip_next_rounded,
                    label: 'Slnt',
                    onTap: onNext,
                  ),
                ),
              ),
              Expanded(
                child: Center(
                  child: _ActionBtn(
                    icon: Icons.stop_rounded,
                    label: 'Akhiri',
                    onTap: onStop,
                    color: Colors.red,
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

class _StatBadge extends StatelessWidget {
  final String label, value;
  final Color color;
  const _StatBadge({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(fontSize: 9, color: color.withValues(alpha: 0.7)),
          ),
          const SizedBox(width: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColor =
        isDark
            ? Colors.white.withValues(alpha: 0.7)
            : AppColors.dark.withValues(alpha: 0.6);

    return InkWell(
      onTap: onTap,
      child: Column(
        children: [
          Icon(icon, color: color ?? defaultColor, size: 22),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              color: color ?? defaultColor.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _WaveformSimulator extends StatefulWidget {
  const _WaveformSimulator();
  @override
  State<_WaveformSimulator> createState() => _WaveformSimulatorState();
}

class _WaveformSimulatorState extends State<_WaveformSimulator>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(
        5,
        (i) => AnimatedBuilder(
          animation: _ctrl,
          builder: (context, child) {
            return Container(
              width: 2,
              height: 10 + (10 * _ctrl.value * (1 - (i - 2).abs() / 3)),
              margin: const EdgeInsets.symmetric(horizontal: 1),
              decoration: BoxDecoration(
                color: Colors.green,
                borderRadius: BorderRadius.circular(1),
              ),
            );
          },
        ),
      ),
    );
  }
}
