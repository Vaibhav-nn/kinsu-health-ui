import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/medication.dart';
import '../../models/vital.dart';
import '../../providers/medications_provider.dart';
import '../../providers/vitals_provider.dart';
import '../home/notifications_screen.dart';
import '../home/wellness_tools_screens.dart';
import 'illness/illness_list_screen.dart';
import 'medications/medications_list_screen.dart';
import 'reminders/reminders_timeline_screen.dart';
import 'symptoms/symptoms_list_screen.dart';
import 'vitals/vitals_trends_screen.dart';

class TrackHome extends StatefulWidget {
  const TrackHome({super.key});

  @override
  State<TrackHome> createState() => _TrackHomeState();
}

class _TrackHomeState extends State<TrackHome> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VitalsProvider>().loadVitals();
      context.read<MedicationsProvider>().loadMedications(isActive: true);
    });
  }

  List<VitalLog> _entriesForType(List<VitalLog> vitals, String type) {
    final list = vitals.where((item) => item.vitalType == type).toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return list;
  }

  String _formatNumber(double value) {
    if ((value - value.roundToDouble()).abs() < 0.05) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _trendLabel(List<VitalLog> entries) {
    if (entries.length < 2) {
      return 'No trend';
    }
    final latest = entries[0].value;
    final previous = entries[1].value;
    if (previous.abs() < 0.0001) {
      return '→ 0%';
    }
    final deltaPct = ((latest - previous) / previous) * 100;
    if (deltaPct.abs() < 0.1) {
      return '→ 0%';
    }
    final arrow = deltaPct > 0 ? '↑' : '↓';
    final pct = deltaPct.abs();
    final pctLabel = (pct - pct.roundToDouble()).abs() < 0.05
        ? pct.round().toString()
        : pct.toStringAsFixed(1);
    return '$arrow $pctLabel%';
  }

  _TrackMiniVital _buildMiniVital({
    required List<VitalLog> vitals,
    required String type,
    required String label,
    required String fallbackUnit,
    required Color color,
  }) {
    final entries = _entriesForType(vitals, type);
    if (entries.isEmpty) {
      return _TrackMiniVital(
        label: label,
        value: '--',
        unit: fallbackUnit,
        color: color,
        trend: 'No data',
      );
    }

    final latest = entries.first;
    final displayValue = type == 'blood_pressure' &&
            latest.valueSecondary != null
        ? '${_formatNumber(latest.value)}/${_formatNumber(latest.valueSecondary!)}'
        : _formatNumber(latest.value);
    final unit = latest.unit.trim().isEmpty ? fallbackUnit : latest.unit;

    return _TrackMiniVital(
      label: label,
      value: displayValue,
      unit: unit,
      color: color,
      trend: _trendLabel(entries),
    );
  }

  String _medicationSubtitle(Medication medication) {
    final doctor = medication.prescribingDoctor;
    if (doctor != null && doctor.trim().isNotEmpty) {
      return '${medication.dosage} · ${medication.frequency} · $doctor';
    }
    return '${medication.dosage} · ${medication.frequency}';
  }

  @override
  Widget build(BuildContext context) {
    final vitalsProvider = context.watch<VitalsProvider>();
    final medicationsProvider = context.watch<MedicationsProvider>();
    final activeMeds =
        medicationsProvider.medications.where((item) => item.isActive).toList();

    final miniVitals = [
      _buildMiniVital(
        vitals: vitalsProvider.vitals,
        type: 'blood_pressure',
        label: 'BP',
        fallbackUnit: 'mmHg',
        color: const Color(0xFFDC2626),
      ),
      _buildMiniVital(
        vitals: vitalsProvider.vitals,
        type: 'blood_sugar',
        label: 'Sugar',
        fallbackUnit: 'mg/dL',
        color: const Color(0xFFF59E0B),
      ),
      _buildMiniVital(
        vitals: vitalsProvider.vitals,
        type: 'heart_rate',
        label: 'HR',
        fallbackUnit: 'bpm',
        color: const Color(0xFF009688),
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Track'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const NotificationsScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _SectionTitle(title: 'Today\'s Vitals'),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: miniVitals
                .map(
                  (item) => _VitalMiniCard(
                    label: item.label,
                    value: item.value,
                    unit: item.unit,
                    color: item.color,
                    trend: item.trend,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const VitalsTrendsScreen(),
                        ),
                      );
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _QuickAction(
                  icon: Icons.addchart,
                  label: 'Log Vitals',
                  bg: const Color(0xFFF5F3FF),
                  color: const Color(0xFF8B5CF6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const VitalsTrendsScreen(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _QuickAction(
                  icon: Icons.bolt,
                  label: 'Log Symptom',
                  bg: const Color(0xFFFFF7ED),
                  color: const Color(0xFFEA580C),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SymptomsListScreen(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Expanded(child: _SectionTitle(title: 'Medications')),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const MedicationsListScreen(),
                    ),
                  );
                },
                child: const Text('View All'),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (medicationsProvider.isLoading && activeMeds.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 10),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (activeMeds.isEmpty)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: KinsuTheme.cardDecoration,
              child: const Text(
                'No active medications yet. Add medications to track adherence.',
                style: TextStyle(color: KinsuTheme.textSecondary),
              ),
            )
          else
            ...activeMeds.take(3).map(
                  (medication) => _FlowTile(
                    icon: Icons.medication_outlined,
                    color: const Color(0xFF3B82F6),
                    title: medication.name,
                    subtitle: _medicationSubtitle(medication),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const MedicationsListScreen(),
                        ),
                      );
                    },
                  ),
                ),
          const SizedBox(height: 16),
          const _SectionTitle(title: 'More Tracking'),
          const SizedBox(height: 8),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            childAspectRatio: 1.45,
            children: [
              _MoreCard(
                icon: Icons.monitor_heart_outlined,
                color: const Color(0xFF16A34A),
                title: 'Vitals Trends',
                subtitle: 'Track historical patterns',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const VitalsTrendsScreen(),
                    ),
                  );
                },
              ),
              _MoreCard(
                icon: Icons.sick_outlined,
                color: const Color(0xFFF59E0B),
                title: 'Chronic Symptoms',
                subtitle: 'Track ongoing conditions',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SymptomsListScreen(),
                    ),
                  );
                },
              ),
              _MoreCard(
                icon: Icons.timeline_outlined,
                color: const Color(0xFF8B5CF6),
                title: 'Illness Episodes',
                subtitle: 'Linked health events',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const IllnessListScreen(),
                    ),
                  );
                },
              ),
              _MoreCard(
                icon: Icons.alarm_on_outlined,
                color: const Color(0xFF009688),
                title: 'Reminder Timeline',
                subtitle: 'Medication adherence',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RemindersTimelineScreen(),
                    ),
                  );
                },
              ),
              _MoreCard(
                icon: Icons.fitness_center_outlined,
                color: const Color(0xFFEF4444),
                title: 'Exercise Log',
                subtitle: 'Track workouts',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const ExerciseScreen(),
                    ),
                  );
                },
              ),
              _MoreCard(
                icon: Icons.bedtime_outlined,
                color: const Color(0xFF6366F1),
                title: 'Sleep Tracker',
                subtitle: 'Log sleep schedule',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SleepScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          const _SectionTitle(title: 'Routine Tracking'),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                _RoutineChip(
                  title: 'Sleep',
                  value: 'Track',
                  color: const Color(0xFF6366F1),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SleepScreen()),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _RoutineChip(
                  title: 'Mood',
                  value: 'Log',
                  color: const Color(0xFFF59E0B),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MoodScreen()),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _RoutineChip(
                  title: 'Diet',
                  value: 'Plan',
                  color: const Color(0xFFEF4444),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const DietScreen()),
                    );
                  },
                ),
                const SizedBox(width: 8),
                _RoutineChip(
                  title: 'Exercise',
                  value: 'Add',
                  color: const Color(0xFF10B981),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ExerciseScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }
}

class _VitalMiniCard extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final String trend;
  final VoidCallback? onTap;

  const _VitalMiniCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.trend,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: KinsuTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 11,
                color: KinsuTheme.textSecondary,
              ),
            ),
            const Spacer(),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            Text(
              unit,
              style: const TextStyle(
                fontSize: 10,
                color: KinsuTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              trend,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color color;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.bg,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: KinsuTheme.cardDecoration,
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlowTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _FlowTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: KinsuTheme.cardDecoration,
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        color: KinsuTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: KinsuTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _MoreCard extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MoreCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: KinsuTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 8),
            Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                color: KinsuTheme.textSecondary,
                fontSize: 11,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoutineChip extends StatelessWidget {
  final String title;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const _RoutineChip({
    required this.title,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 120,
        padding: const EdgeInsets.all(12),
        decoration: KinsuTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.circle, size: 12, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
            Text(
              title,
              style: const TextStyle(
                fontSize: 11,
                color: KinsuTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrackMiniVital {
  final String label;
  final String value;
  final String unit;
  final Color color;
  final String trend;

  const _TrackMiniVital({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.trend,
  });
}
