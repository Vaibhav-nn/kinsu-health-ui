import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/medication.dart';
import '../../../providers/medications_provider.dart';
import '../../../providers/reminders_provider.dart';
import 'add_medication_screen.dart';

/// Medications list with Today's Progress header, tab selector, and grouped daily view.
class MedicationsListScreen extends StatefulWidget {
  const MedicationsListScreen({super.key});

  @override
  State<MedicationsListScreen> createState() => _MedicationsListScreenState();
}

class _MedicationsListScreenState extends State<MedicationsListScreen> {
  int _tabIndex = 0; // 0=Daily, 1=Weekly, 2=Monthly
  // Local taken state: med id → bool
  final Map<String, bool> _taken = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationsProvider>().loadMedications();
      context
          .read<RemindersProvider>()
          .loadReminders(reminderType: 'medication');
    });
  }

  String _formatFrequency(String frequency) {
    switch (frequency) {
      case 'once_daily':
        return 'Once daily';
      case 'twice_daily':
        return 'Twice/day';
      case 'thrice_daily':
        return 'Three/day';
      case 'weekly':
        return 'Weekly';
      case 'as_needed':
        return 'As needed';
      default:
        return frequency;
    }
  }

  String _mealTimeLabel(String? mealTime) {
    switch (mealTime?.toLowerCase()) {
      case 'before_breakfast':
        return 'Before Breakfast';
      case 'after_breakfast':
        return 'After Breakfast';
      case 'before_lunch':
        return 'Before Lunch';
      case 'after_lunch':
        return 'After Lunch';
      case 'before_dinner':
        return 'Before Dinner';
      case 'after_dinner':
        return 'After Dinner';
      case 'bedtime':
        return 'Bedtime';
      default:
        return 'Anytime';
    }
  }

  String _mealTimeTime(String? mealTime) {
    switch (mealTime?.toLowerCase()) {
      case 'before_breakfast':
        return '7:30 AM';
      case 'after_breakfast':
        return '9:00 AM';
      case 'before_lunch':
        return '1:00 PM';
      case 'after_lunch':
        return '2:00 PM';
      case 'before_dinner':
        return '7:00 PM';
      case 'after_dinner':
        return '9:00 PM';
      case 'bedtime':
        return '10:30 PM';
      default:
        return '';
    }
  }

  String _formatDate(DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _formatDoctor(String doctor) {
    final cleaned = doctor.trim();
    if (cleaned.toLowerCase().startsWith('dr')) return cleaned;
    return 'Dr. $cleaned';
  }

  String _medKey(Medication m) => m.id?.toString() ?? m.name;

  Future<void> _openMedicationPreview(Medication medication) async {
    final remindersProvider = context.read<RemindersProvider>();
    final linkedReminders = remindersProvider.reminders
        .where((reminder) => reminder.linkedMedicationId == medication.id)
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        medication.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: medication.isActive
                            ? KinsuTheme.statusActive.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        medication.isActive ? 'Active' : 'Stopped',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: medication.isActive
                              ? KinsuTheme.statusActive
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetailRow(label: 'Dosage', value: medication.dosage),
                _DetailRow(
                    label: 'Frequency',
                    value: _formatFrequency(medication.frequency)),
                _DetailRow(label: 'Route', value: medication.route),
                _DetailRow(
                    label: 'Start Date',
                    value: _formatDate(medication.startDate)),
                if (medication.endDate != null)
                  _DetailRow(
                      label: 'End Date',
                      value: _formatDate(medication.endDate!)),
                if (medication.prescribingDoctor != null &&
                    medication.prescribingDoctor!.trim().isNotEmpty)
                  _DetailRow(
                      label: 'Prescribing Doctor',
                      value: _formatDoctor(medication.prescribingDoctor!)),
                if (linkedReminders.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  const Text(
                    'Scheduled Times',
                    style:
                        TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: linkedReminders
                        .map(
                          (reminder) => Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: KinsuTheme.primary.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              reminder.displayTime,
                              style: const TextStyle(
                                color: KinsuTheme.primary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
                if (medication.notes != null &&
                    medication.notes!.trim().isNotEmpty) ...[
                  const SizedBox(height: 14),
                  const Text(
                    'Notes',
                    style: TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    medication.notes!,
                    style: const TextStyle(
                        color: KinsuTheme.textSecondary, height: 1.4),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<MedicationsProvider>(
      builder: (context, provider, _) {
        final activeMeds =
            provider.activeMedications;
        final takenCount =
            activeMeds.where((m) => _taken[_medKey(m)] == true).length;
        final total = activeMeds.length;

        final leftCount = (total - takenCount).clamp(0, total);
        final adherencePct =
            total == 0 ? 0 : ((takenCount / total) * 100).round();

        return Scaffold(
          backgroundColor: KinsuTheme.background,
          body: SafeArea(
            child: Column(
              children: [
                // ── Custom header ──────────────────────────────────────
                Container(
                  color: Colors.white,
                  child: Column(
                    children: [
                      // Title row
                      Padding(
                        padding: const EdgeInsets.fromLTRB(4, 8, 8, 0),
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chevron_left),
                              onPressed: () => Navigator.pop(context),
                              color: KinsuTheme.textPrimary,
                            ),
                            const Expanded(
                              child: Text(
                                'Medications',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w700,
                                  color: KinsuTheme.textPrimary,
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add),
                              color: KinsuTheme.primary,
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const AddMedicationScreen()),
                                );
                                if (result == true && context.mounted) {
                                  context
                                      .read<MedicationsProvider>()
                                      .loadMedications();
                                  context.read<RemindersProvider>().loadReminders(
                                      reminderType: 'medication');
                                }
                              },
                            ),
                          ],
                        ),
                      ),

                      // Progress card
                      Container(
                        margin: const EdgeInsets.fromLTRB(12, 4, 12, 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: KinsuTheme.primary,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                // Left side
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        "Today's Progress",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white70,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '$adherencePct',
                                            style: const TextStyle(
                                              fontSize: 28,
                                              fontWeight: FontWeight.w700,
                                              color: Colors.white,
                                            ),
                                          ),
                                          const Text(
                                            '%',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.white70,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                // Right: 3 mini stat boxes
                                Row(
                                  children: [
                                    _MiniStatBox(
                                        label: 'Taken',
                                        value: '$takenCount'),
                                    const SizedBox(width: 6),
                                    const _MiniStatBox(
                                        label: 'Missed',
                                        value: '0'),
                                    const SizedBox(width: 6),
                                    _MiniStatBox(
                                        label: 'Left',
                                        value: '$leftCount'),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            TweenAnimationBuilder<double>(
                              tween: Tween(
                                  begin: 0, end: total == 0 ? 0 : takenCount / total),
                              duration: const Duration(milliseconds: 500),
                              builder: (_, value, __) => ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: LinearProgressIndicator(
                                  value: value,
                                  minHeight: 8,
                                  backgroundColor:
                                      Colors.white.withValues(alpha: 0.25),
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Tab selector
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                        child: Row(
                          children: [
                            Expanded(
                                child: _TabButton(
                              label: 'Daily',
                              isSelected: _tabIndex == 0,
                              onTap: () => setState(() => _tabIndex = 0),
                            )),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _TabButton(
                              label: 'Weekly',
                              isSelected: _tabIndex == 1,
                              onTap: () => setState(() => _tabIndex = 1),
                            )),
                            const SizedBox(width: 8),
                            Expanded(
                                child: _TabButton(
                              label: 'Monthly',
                              isSelected: _tabIndex == 2,
                              onTap: () => setState(() => _tabIndex = 2),
                            )),
                          ],
                        ),
                      ),

                      Container(height: 1, color: KinsuTheme.divider),
                    ],
                  ),
                ),

                // ── Body ────────────────────────────────────────────────
                Expanded(
                  child: provider.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : provider.medications.isEmpty
                          ? _EmptyState(
                              onAdd: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          const AddMedicationScreen()),
                                );
                                if (result == true && context.mounted) {
                                  context
                                      .read<MedicationsProvider>()
                                      .loadMedications();
                                }
                              },
                            )
                          : _tabIndex == 0
                              ? _DailyView(
                                  medications: provider.medications,
                                  taken: _taken,
                                  onToggle: (key, val) =>
                                      setState(() => _taken[key] = val),
                                  onTap: _openMedicationPreview,
                                  mealTimeLabel: _mealTimeLabel,
                                  mealTimeTime: _mealTimeTime,
                                  formatFrequency: _formatFrequency,
                                  medKey: _medKey,
                                )
                              : _tabIndex == 1
                                  ? _WeeklyView(medications: provider.medications)
                                  : _MonthlyView(
                                      medications: provider.medications),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ── Mini Stat Box ─────────────────────────────────────────────────────────────

class _MiniStatBox extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStatBox({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: const TextStyle(
              fontSize: 9,
              color: Colors.white70,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Tab Button ────────────────────────────────────────────────────────────────

class _TabButton extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _TabButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? KinsuTheme.primaryLight : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? KinsuTheme.primary : KinsuTheme.divider,
          ),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            fontWeight:
                isSelected ? FontWeight.w600 : FontWeight.w400,
            color: isSelected ? KinsuTheme.primary : KinsuTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

// ── Daily View ────────────────────────────────────────────────────────────────

class _DailyView extends StatelessWidget {
  final List<Medication> medications;
  final Map<String, bool> taken;
  final void Function(String key, bool val) onToggle;
  final Future<void> Function(Medication) onTap;
  final String Function(String?) mealTimeLabel;
  final String Function(String?) mealTimeTime;
  final String Function(String) formatFrequency;
  final String Function(Medication) medKey;

  const _DailyView({
    required this.medications,
    required this.taken,
    required this.onToggle,
    required this.onTap,
    required this.mealTimeLabel,
    required this.mealTimeTime,
    required this.formatFrequency,
    required this.medKey,
  });

  @override
  Widget build(BuildContext context) {
    // Group by frequency since Medication has no mealTime field.
    final groups = <String, List<Medication>>{};
    for (final med in medications) {
      final group = mealTimeLabel(med.frequency.toLowerCase().contains('morning')
          ? 'morning'
          : med.frequency.toLowerCase().contains('evening')
              ? 'evening'
              : med.frequency.toLowerCase().contains('night')
                  ? 'night'
                  : null);
      groups.putIfAbsent(group, () => []);
      groups[group]!.add(med);
    }

    return RefreshIndicator(
      onRefresh: () async =>
          context.read<MedicationsProvider>().loadMedications(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: groups.entries.map((entry) {
          final groupLabel = entry.key;
          final meds = entry.value;
          final time = mealTimeTime(null);

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Group header
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: KinsuTheme.primaryLight,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.access_time_rounded,
                          size: 16, color: KinsuTheme.primary),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      groupLabel,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: KinsuTheme.textPrimary,
                      ),
                    ),
                    if (time.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      Text(
                        time,
                        style: const TextStyle(
                          fontSize: 12,
                          color: KinsuTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              ...meds.map((med) {
                final key = medKey(med);
                final isTaken = taken[key] ?? false;
                final now = DateTime.now();
                final isPast = med.endDate != null && med.endDate!.isBefore(now);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: GestureDetector(
                    onTap: () => onTap(med),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: KinsuTheme.cardDecoration,
                      child: Row(
                        children: [
                          // Status dot
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isTaken
                                  ? KinsuTheme.success
                                  : isPast
                                      ? KinsuTheme.statusError.withValues(alpha: 0.1)
                                      : Colors.transparent,
                              border: Border.all(
                                color: isTaken
                                    ? KinsuTheme.success
                                    : isPast
                                        ? KinsuTheme.statusError
                                        : KinsuTheme.textSecondary,
                                width: 2,
                              ),
                            ),
                            child: isTaken
                                ? const Icon(Icons.check,
                                    size: 12, color: Colors.white)
                                : isPast
                                    ? const Icon(Icons.close,
                                        size: 12, color: KinsuTheme.statusError)
                                    : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.name,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: KinsuTheme.textPrimary,
                                  ),
                                ),
                                Text(
                                  '${med.dosage} · ${formatFrequency(med.frequency)}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: KinsuTheme.textSecondary,
                                  ),
                                ),
                                if (med.prescribingDoctor != null &&
                                    med.prescribingDoctor!.isNotEmpty)
                                  Text(
                                    med.prescribingDoctor!,
                                    style: const TextStyle(
                                      fontSize: 11,
                                      color: KinsuTheme.textSecondary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Action badge
                          _MedActionButton(
                            isTaken: isTaken,
                            isPast: isPast,
                            onTake: () => onToggle(key, true),
                            onUndo: () => onToggle(key, false),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
              const SizedBox(height: 6),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class _MedActionButton extends StatelessWidget {
  final bool isTaken;
  final bool isPast;
  final VoidCallback onTake;
  final VoidCallback onUndo;

  const _MedActionButton({
    required this.isTaken,
    required this.isPast,
    required this.onTake,
    required this.onUndo,
  });

  @override
  Widget build(BuildContext context) {
    if (isPast && !isTaken) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: KinsuTheme.statusError.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Text(
          'Missed',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: KinsuTheme.statusError,
          ),
        ),
      );
    }

    if (isTaken) {
      return GestureDetector(
        onTap: onUndo,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: KinsuTheme.success.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'Taken · Undo',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: KinsuTheme.success,
            ),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: onTake,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: KinsuTheme.primaryLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: KinsuTheme.primary),
        ),
        child: const Text(
          'Take',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: KinsuTheme.primary,
          ),
        ),
      ),
    );
  }
}

// ── Weekly View ───────────────────────────────────────────────────────────────

class _WeeklyView extends StatelessWidget {
  final List<Medication> medications;

  const _WeeklyView({required this.medications});

  @override
  Widget build(BuildContext context) {
    const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header row
        Row(
          children: [
            const SizedBox(width: 120),
            ...days.map(
              (d) => Expanded(
                child: Text(
                  d,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: KinsuTheme.textSecondary,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ...medications.take(10).map((med) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
              decoration: KinsuTheme.cardDecoration,
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      med.name,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  ...List.generate(7, (_) {
                    // No local adherence history — show neutral pending dots.
                    return Expanded(
                      child: Center(
                        child: Container(
                          width: 16,
                          height: 16,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.transparent,
                            border: Border.all(
                              color: KinsuTheme.divider,
                              width: 1.5,
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

// ── Monthly View ──────────────────────────────────────────────────────────────

class _MonthlyView extends StatelessWidget {
  final List<Medication> medications;

  const _MonthlyView({required this.medications});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    const dayHeaders = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    // Offset so first day aligns correctly (Mon=0)
    int startOffset = firstDay.weekday - 1; // 0=Mon

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          '${_monthName(now.month)} ${now.year}',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: KinsuTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: dayHeaders
              .map((d) => Expanded(
                    child: Text(
                      d,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: KinsuTheme.textSecondary,
                      ),
                    ),
                  ))
              .toList(),
        ),
        const SizedBox(height: 6),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1,
          ),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (_, idx) {
            if (idx < startOffset) return const SizedBox.shrink();
            final day = idx - startOffset + 1;
            final date = DateTime(now.year, now.month, day);
            final isFuture = date.isAfter(now);
            final isToday = date.year == now.year &&
                date.month == now.month &&
                date.day == now.day;

            // Simulate adherence: logged days = green, today = outline, future = white
            final hasMeds = medications.isNotEmpty;
            Color cellColor;
            if (isFuture) {
              cellColor = Colors.transparent;
            } else if (hasMeds) {
              cellColor = KinsuTheme.success.withValues(alpha: 0.2);
            } else {
              cellColor = KinsuTheme.divider.withValues(alpha: 0.4);
            }

            return Container(
              margin: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                color: cellColor,
                shape: BoxShape.circle,
                border: isToday
                    ? Border.all(color: KinsuTheme.primary, width: 2)
                    : null,
              ),
              child: Center(
                child: Text(
                  '$day',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                    color: isFuture
                        ? KinsuTheme.textSecondary
                        : KinsuTheme.textPrimary,
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  String _monthName(int month) {
    const names = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return names[month];
  }
}

// ── Empty State ───────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  final VoidCallback onAdd;

  const _EmptyState({required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.medication_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'No medications added yet',
            style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
          ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add),
            label: const Text('Add Medication'),
          ),
        ],
      ),
    );
  }
}

// ── Detail Row ────────────────────────────────────────────────────────────────

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 132,
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 13, color: KinsuTheme.textSecondary),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}
