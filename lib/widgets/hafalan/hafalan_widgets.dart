import 'package:flutter/material.dart';
import '../../constants/quran_fonts.dart';
import '../../constants/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PartialHideText
// ─────────────────────────────────────────────────────────────────────────────
class PartialHideText extends StatefulWidget {
  final String text;
  final bool active;
  final double fontSize;
  const PartialHideText({
    super.key,
    required this.text,
    required this.active,
    required this.fontSize,
  });

  @override
  State<PartialHideText> createState() => _PartialHideTextState();
}

class _PartialHideTextState extends State<PartialHideText> {
  final Set<int> _revealedWords = {};

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final words = widget.text.split(' ');
    return Wrap(
      alignment: WrapAlignment.end,
      textDirection: TextDirection.rtl,
      children:
          words.asMap().entries.map((entry) {
            final idx = entry.key;
            final word = entry.value;
            final isSymbol = word.contains('\u06DD');

            // hide every other word, but NEVER hide the verse symbol
            final shouldHide =
                idx % 2 == 1 && !isSymbol && !_revealedWords.contains(idx);
            return GestureDetector(
              onTap:
                  shouldHide
                      ? () => setState(() => _revealedWords.add(idx))
                      : null,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
                padding: EdgeInsets.symmetric(
                  horizontal: shouldHide ? 8 : 2,
                  vertical: shouldHide ? 3 : 0,
                ),
                decoration:
                    shouldHide
                        ? BoxDecoration(
                          color: (isDark ? Colors.white : AppColors.dark)
                              .withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: (isDark ? Colors.white : AppColors.dark)
                                .withValues(alpha: 0.2),
                          ),
                        )
                        : null,
                child:
                    shouldHide
                        ? SizedBox(
                          width: 40,
                          height: widget.fontSize,
                          child: Center(
                            child: Icon(
                              Icons.remove_rounded,
                              size: 12,
                              color: (isDark ? Colors.white : Colors.grey)
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        )
                        : Text(
                          word,
                          style: AppQuranFonts.hafsStyle.copyWith(
                            fontSize: widget.fontSize,
                            height: 1.9,
                            color:
                                widget.active
                                    ? AppColors.hl
                                    : (isDark ? Colors.white : AppColors.ink),
                          ),
                          textDirection: TextDirection.rtl,
                        ),
              ),
            );
          }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HideModeOption
// ─────────────────────────────────────────────────────────────────────────────
class HideModeOption extends StatelessWidget {
  final IconData icon;
  final String title, subtitle;
  final bool active;
  final VoidCallback onTap;
  const HideModeOption({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color:
              active
                  ? AppColors.gold.withValues(alpha: 0.1)
                  : Colors.transparent,
          border: Border.all(
            color:
                active
                    ? AppColors.gold
                    : AppColors.gold.withValues(alpha: 0.35),
            width: 1.2,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: active ? AppColors.gold : AppColors.gold,
              size: 22,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      color: textColor.withValues(alpha: 0.55),
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            if (active)
              Icon(Icons.check_circle_rounded, color: AppColors.gold, size: 18),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// RangeField
// ─────────────────────────────────────────────────────────────────────────────
class RangeField extends StatelessWidget {
  final String label;
  final int value, min, max;
  final ValueChanged<int> onChange;
  const RangeField({
    super.key,
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChange,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: textColor.withValues(alpha: 0.6),
          ),
        ),
        const SizedBox(height: 4),
        DropdownButtonFormField<int>(
          value: value.clamp(min, max),
          decoration: inputDecoStatic(context),
          style: TextStyle(fontSize: 13, color: textColor),
          dropdownColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          items:
              List.generate(max - min + 1, (i) => min + i)
                  .map((n) => DropdownMenuItem(value: n, child: Text('$n')))
                  .toList(),
          onChanged: (v) {
            if (v != null) onChange(v);
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TabBtn
// ─────────────────────────────────────────────────────────────────────────────
class TabBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;
  const TabBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.active,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color:
                active
                    ? AppColors.gold
                    : AppColors.gold.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color:
                  active
                      ? AppColors.gold
                      : AppColors.gold.withValues(alpha: 0.35),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 16, color: active ? Colors.white : textColor),
              const SizedBox(height: 3),
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: active ? Colors.white : textColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ToolBtn
// ─────────────────────────────────────────────────────────────────────────────
class ToolBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const ToolBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color:
              active
                  ? AppColors.gold.withValues(alpha: 0.12)
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.grey.shade100),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                active
                    ? AppColors.gold
                    : (isDark ? Colors.white24 : Colors.grey.shade300),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color:
                  active
                      ? AppColors.gold
                      : (isDark ? Colors.white70 : Colors.grey.shade600),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color:
                    active
                        ? AppColors.gold
                        : (isDark ? Colors.white : Colors.grey.shade700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helper widgets for hafalan tabs
// ─────────────────────────────────────────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final IconData icon;
  final String title;
  const SectionHeader({super.key, required this.icon, required this.title});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.gold),
        const SizedBox(width: 7),
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: textColor,
            letterSpacing: 0.2,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(
            height: 0.8,
            color: AppColors.gold.withValues(alpha: 0.3),
          ),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final IconData icon;
  final String label, value, sub;
  final Color color;
  const StatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: textColor.withValues(alpha: 0.6),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: textColor,
              height: 1,
            ),
          ),
          Text(
            sub,
            style: TextStyle(
              fontSize: 10,
              color: textColor.withValues(alpha: 0.5),
            ),
          ),
        ],
      ),
    );
  }
}

class CircularProgress extends StatelessWidget {
  final double value, size;
  final Color color;
  const CircularProgress({
    super.key,
    required this.value,
    required this.size,
    required this.color,
  });
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return SizedBox.square(
      dimension: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: value,
            strokeWidth: size * 0.08,
            backgroundColor: color.withValues(alpha: 0.12),
            valueColor: AlwaysStoppedAnimation(color),
          ),
          Text(
            '${(value * 100).round()}%',
            style: TextStyle(
              fontSize: size * 0.22,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}

class LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const LegendDot({super.key, required this.color, required this.label});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: textColor.withValues(alpha: 0.6),
          ),
        ),
      ],
    );
  }
}

class MenuBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const MenuBtn({
    super.key,
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        border: Border.all(color: color.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    ),
  );
}

class HrGold extends StatelessWidget {
  const HrGold({super.key});
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      height: 1.5,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.gold.withValues(alpha: 0),
            AppColors.gold,
            isDark ? Colors.white : AppColors.dark,
            AppColors.gold,
            AppColors.gold.withValues(alpha: 0),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared helper functions
// ─────────────────────────────────────────────────────────────────────────────
BoxDecoration cardDeco(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return BoxDecoration(
    color: isDark ? const Color(0xFF1E1E1E) : AppColors.pageBg,
    border: Border.all(color: AppColors.gold.withValues(alpha: 0.3)),
    borderRadius: BorderRadius.circular(14),
    boxShadow: [
      BoxShadow(
        color: (isDark ? Colors.black : AppColors.dark).withValues(alpha: 0.07),
        blurRadius: 8,
        offset: const Offset(0, 2),
      ),
    ],
  );
}

InputDecoration inputDecoStatic(BuildContext context) {
  final isDark = Theme.of(context).brightness == Brightness.dark;
  return InputDecoration(
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: AppColors.gold.withValues(alpha: 0.4)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: const BorderSide(color: AppColors.gold, width: 1.5),
    ),
    filled: true,
    fillColor: isDark ? const Color(0xFF1E1E1E) : AppColors.pageBg,
  );
}
