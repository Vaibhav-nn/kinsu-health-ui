import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'illness/illness_list_screen.dart';
import 'medications/medications_list_screen.dart';
import 'reminders/reminders_timeline_screen.dart';
import 'symptoms/symptoms_list_screen.dart';
import 'vitals/vitals_trends_screen.dart';

class TrackHome extends StatelessWidget {
  const TrackHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
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
            children: const [
              _VitalMiniCard(
                label: 'BP',
                value: '128/84',
                unit: 'mmHg',
                color: Color(0xFFDC2626),
                trend: '↓ 3%',
              ),
              _VitalMiniCard(
                label: 'Sugar',
                value: '142',
                unit: 'mg/dL',
                color: Color(0xFFF59E0B),
                trend: '↑ 8%',
              ),
              _VitalMiniCard(
                label: 'HR',
                value: '72',
                unit: 'bpm',
                color: Color(0xFF009688),
                trend: '→ 0%',
              ),
            ],
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
          _FlowTile(
            icon: Icons.medication_outlined,
            color: const Color(0xFF3B82F6),
            title: 'Metformin 500mg',
            subtitle: 'Morning, after breakfast · 92% adherence',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MedicationsListScreen(),
                ),
              );
            },
          ),
          _FlowTile(
            icon: Icons.medication_outlined,
            color: const Color(0xFF3B82F6),
            title: 'Amlodipine 5mg',
            subtitle: 'Morning · 88% adherence',
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const MedicationsListScreen(),
                ),
              );
            },
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
            ],
          ),
          const SizedBox(height: 16),
          const _SectionTitle(title: 'Routine Tracking'),
          const SizedBox(height: 8),
          SizedBox(
            height: 100,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: const [
                _RoutineChip(
                    title: 'Sleep', value: '7.5 hrs', color: Color(0xFF6366F1)),
                SizedBox(width: 8),
                _RoutineChip(
                    title: 'Mood', value: 'Good', color: Color(0xFFF59E0B)),
                SizedBox(width: 8),
                _RoutineChip(
                    title: 'Stress', value: 'Low', color: Color(0xFFEF4444)),
                SizedBox(width: 8),
                _RoutineChip(
                    title: 'Vitamins',
                    value: '2/3 taken',
                    color: Color(0xFF10B981)),
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

  const _VitalMiniCard({
    required this.label,
    required this.value,
    required this.unit,
    required this.color,
    required this.trend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: KinsuTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                const TextStyle(fontSize: 11, color: KinsuTheme.textSecondary),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          Text(
            unit,
            style:
                const TextStyle(fontSize: 10, color: KinsuTheme.textSecondary),
          ),
          const SizedBox(height: 2),
          Text(
            trend,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w600, color: color),
          ),
        ],
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
                  color: color.withOpacity(0.12),
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

  const _RoutineChip({
    required this.title,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
    );
  }
}
