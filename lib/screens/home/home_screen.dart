import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/theme_provider.dart';
import '../ai/ai_screen.dart';
import '../track/medications/medications_list_screen.dart';
import '../track/vitals/vitals_trends_screen.dart';
import '../vault/upload_record_screen.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heroController;
  final TextEditingController _searchController = TextEditingController();
  final Map<String, bool> _todayMeds = {
    'Metformin 500mg': true,
    'Ecosprin 75mg': false,
    'Amlodipine 5mg': false,
    'Atorvastatin 10mg': false,
  };

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<AppThemeProvider>().themeMode;
    final taken = _todayMeds.values.where((v) => v).length;
    final total = _todayMeds.length;

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          children: [
            Row(
              children: [
                const CircleAvatar(
                  radius: 20,
                  child: Text('PS'),
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Good Morning',
                        style: TextStyle(
                          color: KinsuTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        'Priya Sharma',
                        style: TextStyle(
                            fontSize: 17, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
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
                IconButton(
                  icon: const Icon(Icons.person_outline),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Search records, meds, doctors...',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 10),
            _ThemeModeSelector(currentMode: themeMode),
            const SizedBox(height: 12),
            _AnimatedHeroCard(controller: _heroController),
            const SizedBox(height: 14),
            const _SectionTitle(title: 'Quick Actions'),
            const SizedBox(height: 8),
            GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _ActionTile(
                  icon: Icons.upload_file_outlined,
                  label: 'Upload Record',
                  bg: const Color(0xFFE6F7F6),
                  color: KinsuTheme.primary,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const UploadRecordScreen(),
                      ),
                    );
                  },
                ),
                _ActionTile(
                  icon: Icons.medication_outlined,
                  label: 'Medications',
                  bg: const Color(0xFFEFF6FF),
                  color: const Color(0xFF3B82F6),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const MedicationsListScreen(),
                      ),
                    );
                  },
                ),
                _ActionTile(
                  icon: Icons.monitor_heart_outlined,
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
                _ActionTile(
                  icon: Icons.sos_outlined,
                  label: 'SOS',
                  bg: const Color(0xFFFEF2F2),
                  color: const Color(0xFFDC2626),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('SOS flow coming next.')),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                'Exercise',
                'Diet',
                'Sleep',
                'Mood',
                'Community',
                'Settings',
              ]
                  .map(
                    (item) => ActionChip(
                      label: Text(item),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('$item screen coming next.')),
                        );
                      },
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 16),
            const _SectionTitle(title: 'Upcoming Appointments'),
            const SizedBox(height: 8),
            SizedBox(
              height: 130,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _AppointmentCard(
                    doctor: 'Dr. R. Kapoor',
                    specialty: 'Cardiologist',
                    dateTime: 'Thu, 5 Mar · 10:30 AM',
                    place: 'Apollo Hospital',
                  ),
                  SizedBox(width: 10),
                  _AppointmentCard(
                    doctor: 'Dr. A. Mehta',
                    specialty: 'Endocrinologist',
                    dateTime: 'Mon, 8 Mar · 2:00 PM',
                    place: 'Max Hospital',
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            const _SectionTitle(title: 'Today\'s Medicines'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: KinsuTheme.cardDecoration,
              child: Column(
                children: [
                  Row(
                    children: [
                      Text('$taken/$total medicines taken'),
                      const Spacer(),
                      Text(
                        '${((taken / total) * 100).round()}%',
                        style: const TextStyle(
                          color: KinsuTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: taken / total,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                    backgroundColor: KinsuTheme.divider,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            ..._todayMeds.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: KinsuTheme.cardDecoration,
                  child: Row(
                    children: [
                      Icon(
                        entry.value
                            ? Icons.check_circle
                            : Icons.radio_button_unchecked,
                        color: entry.value
                            ? KinsuTheme.statusActive
                            : KinsuTheme.textSecondary,
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(entry.key)),
                      if (!entry.value)
                        TextButton(
                          onPressed: () {
                            setState(() => _todayMeds[entry.key] = true);
                          },
                          child: const Text('Take'),
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Expanded(
                  child: _SectionTitle(title: 'Health Insights'),
                ),
                TextButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AiScreen()),
                    );
                  },
                  icon: const Icon(Icons.auto_awesome, size: 16),
                  label: const Text('AI Summary'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 130,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: const [
                  _InsightCard(
                    title: 'Blood Sugar',
                    value: '142 mg/dL',
                    trend: '↑ 8%',
                    warning: true,
                    note: 'A bit high this week',
                  ),
                  SizedBox(width: 10),
                  _InsightCard(
                    title: 'Blood Pressure',
                    value: '128/84',
                    trend: '↓ 3%',
                    warning: false,
                    note: 'Meds are working',
                  ),
                  SizedBox(width: 10),
                  _InsightCard(
                    title: 'HbA1c',
                    value: '6.8%',
                    trend: '↓ 0.4',
                    warning: false,
                    note: 'Down from last cycle',
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode currentMode;

  const _ThemeModeSelector({required this.currentMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: KinsuTheme.cardDecoration,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          const Icon(Icons.brightness_6_outlined, size: 18),
          _modeChip(context, ThemeMode.system, 'System'),
          _modeChip(context, ThemeMode.light, 'Light'),
          _modeChip(context, ThemeMode.dark, 'Dark'),
        ],
      ),
    );
  }

  Widget _modeChip(BuildContext context, ThemeMode mode, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: currentMode == mode,
      onSelected: (_) => context.read<AppThemeProvider>().setThemeMode(mode),
    );
  }
}

class _AnimatedHeroCard extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedHeroCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value * 2 * math.pi;
        return Container(
          height: 130,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: const LinearGradient(
              colors: [KinsuTheme.primary, KinsuTheme.primaryDark],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 16 + (math.sin(t) * 8),
                top: 16 + (math.cos(t) * 6),
                child: _bubble(40, Colors.white.withOpacity(0.16)),
              ),
              Positioned(
                left: 30 + (math.cos(t * 1.1) * 9),
                bottom: 12 + (math.sin(t * 1.2) * 6),
                child: _bubble(28, Colors.white.withOpacity(0.15)),
              ),
              const Padding(
                padding: EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day 15 — Keep it up!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your health habit streak is active. Log vitals today to continue.',
                      style: TextStyle(color: Colors.white70),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.bg,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final String doctor;
  final String specialty;
  final String dateTime;
  final String place;

  const _AppointmentCard({
    required this.doctor,
    required this.specialty,
    required this.dateTime,
    required this.place,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 240,
      padding: const EdgeInsets.all(12),
      decoration: KinsuTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            doctor,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          ),
          Text(
            specialty,
            style:
                const TextStyle(color: KinsuTheme.textSecondary, fontSize: 12),
          ),
          const SizedBox(height: 8),
          Text(
            dateTime,
            style: const TextStyle(color: KinsuTheme.primary, fontSize: 12),
          ),
          Text(
            place,
            style:
                const TextStyle(color: KinsuTheme.textSecondary, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool warning;
  final String note;

  const _InsightCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.warning,
    required this.note,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.all(12),
      decoration: KinsuTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              color: KinsuTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color:
                  warning ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              trend,
              style: TextStyle(
                color:
                    warning ? const Color(0xFF92400E) : const Color(0xFF047857),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            note,
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
