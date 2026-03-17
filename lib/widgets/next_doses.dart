import 'package:flutter/material.dart';
import '../models/next_dose.dart';

class NextDoses extends StatelessWidget {
  const NextDoses({
    super.key,
    required this.doses,
    this.onTap,
    this.onMarkTaken,
    this.onSeeAll,
  });

  final List<NextDose> doses;
  final void Function(NextDose)? onTap;
  final void Function(NextDose)? onMarkTaken;
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Next doses',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              if (onSeeAll != null)
                TextButton(
                  onPressed: onSeeAll,
                  child: Text(
                    'See all',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ...doses.take(5).map(
              (d) => _DoseTile(
                dose: d,
                theme: theme,
                onTap: () => onTap?.call(d),
                onMarkTaken: onMarkTaken != null ? () => onMarkTaken!(d) : null,
              ),
            ),
      ],
    );
  }
}

class _DoseTile extends StatelessWidget {
  const _DoseTile({
    required this.dose,
    required this.theme,
    this.onTap,
    this.onMarkTaken,
  });

  final NextDose dose;
  final ThemeData theme;
  final VoidCallback? onTap;
  final VoidCallback? onMarkTaken;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        elevation: 0,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: dose.isOverdue
                        ? theme.colorScheme.errorContainer.withOpacity(0.5)
                        : theme.colorScheme.primaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.schedule_rounded,
                    color: dose.isOverdue
                        ? theme.colorScheme.error
                        : theme.colorScheme.primary,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        dose.medicationName,
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        dose.dosage,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      dose.timeOfDay,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      dose.timeLabel,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: dose.isOverdue
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
                if (onMarkTaken != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onMarkTaken,
                    icon: Icon(
                      Icons.check_circle_outline_rounded,
                      color: theme.colorScheme.primary,
                      size: 26,
                    ),
                    tooltip: 'Mark as taken',
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
