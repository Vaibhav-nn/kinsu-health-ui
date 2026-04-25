/// Shared Kinsu design-system widgets used across multiple screens.
library;

import 'package:flutter/material.dart';
import '../core/theme.dart';

// ── Drag Handle ──────────────────────────────────────────────────────────────

/// Standard bottom-sheet drag handle.
class KinsuDragHandle extends StatelessWidget {
  const KinsuDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 40,
        height: 4,
        decoration: BoxDecoration(
          color: KinsuTheme.divider,
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ── Icon Box ─────────────────────────────────────────────────────────────────

/// Rounded square container with a single icon — used in tiles, cards, and menus.
class KinsuIconBox extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color backgroundColor;
  final double size;
  final double iconSize;
  final double radius;

  const KinsuIconBox({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.backgroundColor,
    this.size = 40,
    this.iconSize = 20,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Icon(icon, color: iconColor, size: iconSize),
    );
  }
}

// ── Section Header ────────────────────────────────────────────────────────────

/// Section label with optional trailing action text.
class KinsuSectionHeader extends StatelessWidget {
  final String title;
  final String? trailingLabel;
  final VoidCallback? onTrailingTap;

  const KinsuSectionHeader({
    super.key,
    required this.title,
    this.trailingLabel,
    this.onTrailingTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          title.toUpperCase(),
          style: const TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: KinsuTheme.textSecondary,
            letterSpacing: 1.2,
          ),
        ),
        if (trailingLabel != null) ...[
          const Spacer(),
          GestureDetector(
            onTap: onTrailingTap,
            child: Text(
              trailingLabel!,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: KinsuTheme.primary,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

/// Full-area empty state with icon, title, subtitle, and optional action button.
class KinsuEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const KinsuEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: const BoxDecoration(
                color: KinsuTheme.primaryLight,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 36, color: KinsuTheme.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: KinsuTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 13,
                color: KinsuTheme.textSecondary,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── Quick Action Tile ─────────────────────────────────────────────────────────

/// Icon + label column used in quick-action grids on Home and Track screens.
class KinsuQuickActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String label;
  final VoidCallback onTap;

  const KinsuQuickActionTile({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: KinsuTheme.cardDecoration,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            KinsuIconBox(
              icon: icon,
              iconColor: iconColor,
              backgroundColor: iconBg,
              size: 44,
              iconSize: 22,
              radius: 12,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: KinsuTheme.textPrimary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
