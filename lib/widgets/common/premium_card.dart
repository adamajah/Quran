import 'package:flutter/material.dart';
import '../../constants/app_colors.dart';

class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;
  final VoidCallback? onDelete;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.width,
    this.height,
    this.onTap,
    this.color,
    this.borderRadius = 20,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: color ?? (isDark ? const Color(0xFF1E1E1E) : Colors.white),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        children: [
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(borderRadius),
              child: Padding(
                padding: padding ?? const EdgeInsets.all(16),
                child: child,
              ),
            ),
          ),
          if (onDelete != null)
            Positioned(
              top: 4,
              right: 4,
              child: IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.close_rounded,
                  size: 16,
                  color: (isDark ? Colors.white70 : AppColors.dark).withValues(
                    alpha: 0.3,
                  ),
                ),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ),
        ],
      ),
    );
  }
}

class PremiumHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;
  final bool showBackButton;

  const PremiumHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
    this.showBackButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : AppColors.dark;

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 10,
        20,
        20,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (showBackButton)
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color:
                          isDark
                              ? Colors.white.withValues(alpha: 0.05)
                              : AppColors.pageBg,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 18,
                      color: textColor,
                    ),
                  ),
                )
              else
                const SizedBox(height: 34), // Spacer if no back button
              if (actions != null) Row(children: actions!),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: -0.5,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle!,
              style: TextStyle(
                fontSize: 12,
                color: textColor.withValues(alpha: 0.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
