import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/medication.dart';
import '../../../providers/medications_provider.dart';
import 'add_medication_screen.dart';

class MedicationsListScreen extends StatefulWidget {
  const MedicationsListScreen({super.key});

  @override
  State<MedicationsListScreen> createState() => _MedicationsListScreenState();
}

class _MedicationsListScreenState extends State<MedicationsListScreen> {
  String _selectedView = 'daily';
  final DateTime _referenceDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    final provider = context.read<MedicationsProvider>();
    await provider.loadMedications();
    await provider.loadDashboard(targetDate: _referenceDate);
    if (_selectedView != 'daily') {
      await provider.loadAdherence(
        view: _selectedView,
        referenceDate: _referenceDate,
      );
    }
  }

  Future<void> _changeView(String view) async {
    if (_selectedView == view) {
      return;
    }
    setState(() => _selectedView = view);

    final provider = context.read<MedicationsProvider>();
    if (view == 'daily') {
      await provider.loadDashboard(targetDate: _referenceDate);
    } else {
      await provider.loadAdherence(view: view, referenceDate: _referenceDate);
    }
  }

  Future<void> _openAddMedication() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
    );
    if (result == true && mounted) {
      await _loadData();
    }
  }

  Future<void> _logDose(MedicationDashboardItem item, String status) async {
    final provider = context.read<MedicationsProvider>();
    final success = await provider.logDose(
      item.medication.id!,
      status: status,
      scheduledFor: _referenceDate,
      takenAt: status == 'taken' ? DateTime.now() : null,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 'taken'
                ? '${item.medication.name} marked as taken.'
                : '${item.medication.name} marked as missed.',
          ),
          backgroundColor: status == 'taken'
              ? KinsuTheme.statusActive
              : KinsuTheme.statusError,
        ),
      );
      if (_selectedView != 'daily') {
        await provider.loadAdherence(
          view: _selectedView,
          referenceDate: _referenceDate,
        );
      }
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(provider.error ?? 'Unable to update medication status.'),
        backgroundColor: KinsuTheme.statusError,
      ),
    );
  }

  String _displayDoctor(String? doctor) {
    if (doctor == null || doctor.trim().isEmpty) {
      return 'Doctor not added';
    }
    final cleaned = doctor.trim();
    return cleaned.toLowerCase().startsWith('dr') ? cleaned : 'Dr. $cleaned';
  }

  String _displayFrequency(String value) {
    switch (value) {
      case 'once_daily':
        return 'Daily';
      case 'twice_daily':
        return 'Twice/day';
      case 'weekly':
        return 'Weekly';
      case 'monthly':
        return 'Monthly';
      case 'as_needed':
        return 'SOS';
      default:
        return value.replaceAll('_', ' ');
    }
  }

  String _monthLabel(DateTime value) {
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${months[value.month - 1]} ${value.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Medications'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: KinsuTheme.primary),
            onPressed: _openAddMedication,
          ),
        ],
      ),
      body: Consumer<MedicationsProvider>(
        builder: (context, provider, _) {
          final dashboard = provider.dashboard;
          final adherence = provider.adherence;
          final isBusy = provider.isLoading ||
              provider.isLoadingDashboard ||
              provider.isLoadingAdherence;
          final topError = provider.dashboardError ??
              provider.adherenceError ??
              provider.error;

          return RefreshIndicator(
            onRefresh: _loadData,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                _MedicationSummaryCard(
                  adherencePct: dashboard?.adherencePct ?? 0,
                  taken: dashboard?.taken ?? 0,
                  missed: dashboard?.missed ?? 0,
                  left: dashboard?.left ?? 0,
                ),
                const SizedBox(height: 18),
                _AdherenceTabs(
                  selectedView: _selectedView,
                  onChanged: _changeView,
                ),
                const SizedBox(height: 18),
                if (topError != null)
                  _ErrorCard(message: topError)
                else if (isBusy && dashboard == null && adherence == null)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (_selectedView == 'daily')
                  _DailyMedicationView(
                    items: dashboard?.items ?? const [],
                    onMarkTaken: (item) => _logDose(item, 'taken'),
                    onMarkMissed: (item) => _logDose(item, 'missed'),
                    displayDoctor: _displayDoctor,
                    displayFrequency: _displayFrequency,
                  )
                else if (_selectedView == 'weekly')
                  _WeeklyMedicationView(
                    rows: adherence?.weeklyRows ?? const [],
                  )
                else
                  _MonthlyMedicationView(
                    days: adherence?.monthlyDays ?? const [],
                    monthLabel: _monthLabel(_referenceDate),
                    referenceDate: _referenceDate,
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddMedication,
        backgroundColor: KinsuTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _MedicationSummaryCard extends StatelessWidget {
  final int adherencePct;
  final int taken;
  final int missed;
  final int left;

  const _MedicationSummaryCard({
    required this.adherencePct,
    required this.taken,
    required this.missed,
    required this.left,
  });

  @override
  Widget build(BuildContext context) {
    final total = math.max(taken + missed + left, 1);
    final takenFlex = math.max(taken, 0);
    final missedFlex = math.max(missed, 0);
    final leftFlex = math.max(left, 0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          colors: [KinsuTheme.primary, KinsuTheme.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: KinsuTheme.primary.withValues(alpha: 0.2),
            blurRadius: 24,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Progress",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$adherencePct%',
                      style: const TextStyle(
                        fontSize: 38,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              _MetricPill(label: 'Taken', value: '$taken'),
              const SizedBox(width: 10),
              _MetricPill(
                label: 'Missed',
                value: '$missed',
                background: Colors.white.withValues(alpha: 0.22),
              ),
              const SizedBox(width: 10),
              _MetricPill(label: 'Left', value: '$left'),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                flex: total == 0 ? 1 : math.max(takenFlex, 1),
                child: const _ProgressSegment(
                  color: Color(0xFF4ADE80),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: total == 0 ? 1 : math.max(missedFlex, 1),
                child: const _ProgressSegment(
                  color: Color(0xFFFB7185),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: total == 0 ? 1 : math.max(leftFlex, 1),
                child: _ProgressSegment(
                  color: Colors.white.withValues(alpha: 0.28),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            children: [
              const _ProgressDot(
                  icon: Icons.check,
                  color: Colors.white,
                  background: Colors.white),
              const _ProgressDot(
                  icon: Icons.close,
                  color: Colors.white,
                  background: Color(0xFFFB7185)),
              _ProgressDot(
                  icon: null,
                  color: Colors.transparent,
                  background: Colors.white.withValues(alpha: 0.25)),
              _ProgressDot(
                  icon: null,
                  color: Colors.transparent,
                  background: Colors.white.withValues(alpha: 0.25)),
              _ProgressDot(
                  icon: null,
                  color: Colors.transparent,
                  background: Colors.white.withValues(alpha: 0.25)),
            ],
          ),
        ],
      ),
    );
  }
}

class _AdherenceTabs extends StatelessWidget {
  final String selectedView;
  final ValueChanged<String> onChanged;

  const _AdherenceTabs({
    required this.selectedView,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KinsuTheme.divider.withValues(alpha: 0.65)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          for (final option in const [
            ('daily', 'Daily'),
            ('weekly', 'Weekly'),
            ('monthly', 'Monthly'),
          ])
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(option.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  decoration: BoxDecoration(
                    color: selectedView == option.$1
                        ? KinsuTheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Text(
                    option.$2,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: selectedView == option.$1
                          ? Colors.white
                          : KinsuTheme.textSecondary,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _DailyMedicationView extends StatelessWidget {
  final List<MedicationDashboardItem> items;
  final Future<void> Function(MedicationDashboardItem item) onMarkTaken;
  final Future<void> Function(MedicationDashboardItem item) onMarkMissed;
  final String Function(String?) displayDoctor;
  final String Function(String) displayFrequency;

  const _DailyMedicationView({
    required this.items,
    required this.onMarkTaken,
    required this.onMarkMissed,
    required this.displayDoctor,
    required this.displayFrequency,
  });

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const _EmptyCard(
        message:
            'No medications scheduled right now. Add one to start tracking adherence.',
      );
    }

    return Column(
      children: items
          .map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: _DailyMedicationCard(
                item: item,
                onMarkTaken: () => onMarkTaken(item),
                onMarkMissed: () => onMarkMissed(item),
                displayDoctor: displayDoctor,
                displayFrequency: displayFrequency,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _DailyMedicationCard extends StatelessWidget {
  final MedicationDashboardItem item;
  final VoidCallback onMarkTaken;
  final VoidCallback onMarkMissed;
  final String Function(String?) displayDoctor;
  final String Function(String) displayFrequency;

  const _DailyMedicationCard({
    required this.item,
    required this.onMarkTaken,
    required this.onMarkMissed,
    required this.displayDoctor,
    required this.displayFrequency,
  });

  @override
  Widget build(BuildContext context) {
    final medication = item.medication;
    final status = item.latestStatus;
    final statusColor = switch (status) {
      'taken' => KinsuTheme.statusActive,
      'missed' => KinsuTheme.statusError,
      _ => KinsuTheme.primary,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: KinsuTheme.divider.withValues(alpha: 0.75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F0FE),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.medication_outlined,
              color: Color(0xFF2563EB),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  medication.name,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.scheduleLabel ?? displayFrequency(medication.frequency),
                  style: const TextStyle(
                    fontSize: 15,
                    color: KinsuTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${medication.dosage} • ${displayDoctor(medication.prescribingDoctor)}',
                  style: const TextStyle(
                    fontSize: 14,
                    color: KinsuTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              PopupMenuButton<String>(
                onSelected: (value) {
                  if (value == 'taken') {
                    onMarkTaken();
                  } else if (value == 'missed') {
                    onMarkMissed();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'taken', child: Text('Mark as taken')),
                  PopupMenuItem(value: 'missed', child: Text('Mark as missed')),
                ],
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.expand_more_rounded,
                    color: KinsuTheme.textSecondary,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              status == 'pending'
                  ? ElevatedButton(
                      onPressed: onMarkTaken,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(92, 46),
                        backgroundColor: KinsuTheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(22),
                        ),
                      ),
                      child: const Text('Take'),
                    )
                  : Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: statusColor.withValues(alpha: 0.25),
                        ),
                      ),
                      child: Text(
                        status == 'taken' ? 'Taken' : 'Missed',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: statusColor,
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

class _WeeklyMedicationView extends StatelessWidget {
  final List<MedicationWeeklyMatrixEntry> rows;

  const _WeeklyMedicationView({required this.rows});

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const _EmptyCard(message: 'No weekly adherence data yet.');
    }

    const dayLabels = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KinsuTheme.divider.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(width: 110),
              for (final day in dayLabels)
                Expanded(
                  child: Text(
                    day,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 13,
                      color: KinsuTheme.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          ...rows.map(
            (row) => Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          row.medicationName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          row.dosage,
                          style: const TextStyle(
                            color: KinsuTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ...row.dayStatuses.map(
                    (status) => Expanded(
                      child: Center(child: _WeeklyStatusDot(status: status)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthlyMedicationView extends StatelessWidget {
  final List<MedicationMonthlyCalendarDay> days;
  final String monthLabel;
  final DateTime referenceDate;

  const _MonthlyMedicationView({
    required this.days,
    required this.monthLabel,
    required this.referenceDate,
  });

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) {
      return const _EmptyCard(message: 'No monthly adherence data yet.');
    }

    const headers = ['S', 'M', 'T', 'W', 'T', 'F', 'S'];
    final firstDay = DateTime(referenceDate.year, referenceDate.month, 1);
    final leadingEmpty = firstDay.weekday % 7;
    final gridChildren = <Widget>[
      for (var i = 0; i < leadingEmpty; i++) const SizedBox.shrink(),
      ...days.map((day) => _MonthlyCell(day: day)),
    ];

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KinsuTheme.divider.withValues(alpha: 0.7)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$monthLabel - Monthly Adherence',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (final header in headers)
                Expanded(
                  child: Text(
                    header,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: KinsuTheme.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          GridView.count(
            crossAxisCount: 7,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1,
            children: gridChildren,
          ),
          const SizedBox(height: 16),
          const Row(
            children: [
              _LegendDot(color: Color(0xFF22C55E), label: '≥90%'),
              SizedBox(width: 18),
              _LegendDot(color: Color(0xFFF59E0B), label: '70-89%'),
              SizedBox(width: 18),
              _LegendDot(color: Color(0xFFFB7185), label: '<70%'),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricPill extends StatelessWidget {
  final String label;
  final String value;
  final Color? background;

  const _MetricPill({
    required this.label,
    required this.value,
    this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 96,
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: background ?? Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProgressSegment extends StatelessWidget {
  final Color color;

  const _ProgressSegment({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 10,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(999),
      ),
    );
  }
}

class _ProgressDot extends StatelessWidget {
  final IconData? icon;
  final Color color;
  final Color background;

  const _ProgressDot({
    required this.icon,
    required this.color,
    required this.background,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: background,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: icon == null ? null : Icon(icon, color: KinsuTheme.primary),
    );
  }
}

class _WeeklyStatusDot extends StatelessWidget {
  final String status;

  const _WeeklyStatusDot({required this.status});

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (status) {
      'taken' => (const Color(0xFF22C55E), Icons.check_rounded),
      'missed' => (const Color(0xFFFB7185), Icons.close_rounded),
      'pending' => (KinsuTheme.primaryLight, Icons.circle),
      _ => (Colors.grey.shade200, Icons.circle),
    };

    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      child: Icon(
        icon,
        size: status == 'pending' || status == 'none' ? 12 : 20,
        color: status == 'taken' || status == 'missed'
            ? Colors.white
            : Colors.white70,
      ),
    );
  }
}

class _MonthlyCell extends StatelessWidget {
  final MedicationMonthlyCalendarDay day;

  const _MonthlyCell({required this.day});

  @override
  Widget build(BuildContext context) {
    final color = switch (day.adherenceBucket) {
      'high' => const Color(0xFF22C55E),
      'medium' => const Color(0xFFFBBF24),
      'low' => const Color(0xFFFB7185),
      _ => Colors.grey.shade100,
    };
    final textColor =
        day.adherenceBucket == 'none' ? KinsuTheme.textSecondary : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Text(
          '${day.day}',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: textColor,
          ),
        ),
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 18,
          height: 18,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: KinsuTheme.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;

  const _ErrorCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: KinsuTheme.statusError.withValues(alpha: 0.18)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: KinsuTheme.textSecondary),
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  final String message;

  const _EmptyCard({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: KinsuTheme.divider.withValues(alpha: 0.7)),
      ),
      child: Text(
        message,
        style: const TextStyle(color: KinsuTheme.textSecondary),
      ),
    );
  }
}
