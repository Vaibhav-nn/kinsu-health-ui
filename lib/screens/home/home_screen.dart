import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/medication.dart';
import '../../models/vital.dart';
import '../../providers/medications_provider.dart';
import '../../models/family_member_profile.dart';
import '../../providers/family_provider.dart';
import '../../providers/theme_provider.dart';
import '../../providers/vitals_provider.dart';
import '../ai/ai_screen.dart';
import '../track/medications/medications_list_screen.dart';
import '../track/vitals/vitals_trends_screen.dart';
import '../upload_record_screen.dart';
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
  final Map<String, bool> _todayMeds = <String, bool>{};
  late final List<_AppointmentData> _appointments;

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();

    final now = DateTime.now();
    _appointments = [
      _AppointmentData(
        doctor: 'Dr. R. Kapoor',
        specialty: 'Cardiologist',
        at: DateTime(now.year, now.month, now.day + 2, 10, 30),
        place: 'Apollo Hospital',
        notes: 'Bring latest BP logs and medication list.',
      ),
      _AppointmentData(
        doctor: 'Dr. A. Mehta',
        specialty: 'Endocrinologist',
        at: DateTime(now.year, now.month, now.day + 5, 14, 0),
        place: 'Max Hospital',
        notes: 'Follow-up on blood sugar trends and diet plan.',
      ),
    ];

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationsProvider>().loadMedications(isActive: true);
      context.read<VitalsProvider>().loadVitals();
      context.read<FamilyProvider>().loadFamilyData();
    });
  }

  @override
  void dispose() {
    _heroController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _medicationKey(Medication medication) {
    if (medication.id != null) {
      return 'id:${medication.id}';
    }
    return 'name:${medication.name.toLowerCase()}';
  }

  void _syncTodayMedicationMap(List<Medication> medications) {
    final keys = medications.map(_medicationKey).toSet();
    _todayMeds.removeWhere((key, _) => !keys.contains(key));
    for (final key in keys) {
      _todayMeds.putIfAbsent(key, () => false);
    }
  }

  int _computeStreakDay({
    required List<Medication> medications,
    required List<VitalLog> vitals,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? start;

    for (final medication in medications) {
      final candidate = DateTime(
        medication.startDate.year,
        medication.startDate.month,
        medication.startDate.day,
      );
      if (start == null || candidate.isBefore(start)) {
        start = candidate;
      }
    }

    for (final vital in vitals) {
      final candidate = DateTime(
        vital.recordedAt.year,
        vital.recordedAt.month,
        vital.recordedAt.day,
      );
      if (start == null || candidate.isBefore(start)) {
        start = candidate;
      }
    }

    if (start == null) {
      final startOfYear = DateTime(now.year, 1, 1);
      return today.difference(startOfYear).inDays + 1;
    }

    final normalizedStart = start.isAfter(today) ? today : start;
    return today.difference(normalizedStart).inDays + 1;
  }

  String _formatAppointmentDateTime(DateTime dateTime) {
    final localizations = MaterialLocalizations.of(context);
    final dateLabel = localizations.formatMediumDate(dateTime);
    final timeLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(dateTime),
    );
    return '$dateLabel · $timeLabel';
  }

  Future<void> _showAppointmentOverview(_AppointmentData appointment) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.doctor,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.specialty,
                  style: const TextStyle(
                    fontSize: 14,
                    color: KinsuTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                _AppointmentDetailRow(
                  label: 'When',
                  value: _formatAppointmentDateTime(appointment.at),
                ),
                _AppointmentDetailRow(label: 'Where', value: appointment.place),
                if (appointment.notes != null &&
                    appointment.notes!.trim().isNotEmpty)
                  _AppointmentDetailRow(
                      label: 'Notes', value: appointment.notes!),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showHomeVitalOverview({
    required String title,
    required String vitalType,
  }) async {
    final items = context
        .read<VitalsProvider>()
        .vitals
        .where((v) => v.vitalType == vitalType)
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  const Text(
                    'No readings available yet for this trend.',
                    style: TextStyle(color: KinsuTheme.textSecondary),
                  )
                else
                  ...items.take(6).map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${entry.value}${entry.valueSecondary != null ? '/${entry.valueSecondary!.toStringAsFixed(0)}' : ''} ${entry.unit}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(
                                '${entry.recordedAt.day}/${entry.recordedAt.month} ${entry.recordedAt.hour.toString().padLeft(2, '0')}:${entry.recordedAt.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: KinsuTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  AccountProfileOption? _activeProfileOption(FamilyProvider familyProvider) {
    final profiles = familyProvider.profiles;
    if (profiles.isEmpty) {
      return null;
    }

    final activeId = familyProvider.activeFamilyProfileId;
    for (final option in profiles) {
      if (option.profileId == activeId) {
        return option;
      }
    }

    for (final option in profiles) {
      if (option.isSelf) {
        return option;
      }
    }
    return profiles.first;
  }

  String _initialsFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'U';
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _switchProfile(int? profileId) async {
    final familyProvider = context.read<FamilyProvider>();
    final medicationsProvider = context.read<MedicationsProvider>();
    final vitalsProvider = context.read<VitalsProvider>();
    familyProvider.setActiveProfileId(profileId);

    await medicationsProvider.loadMedications(isActive: true);
    await vitalsProvider.loadVitals();

    if (!mounted) {
      return;
    }

    final label =
        profileId == null ? 'Self profile active' : 'Family profile switched';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<AppThemeProvider>().themeMode;
    final medicationsProvider = context.watch<MedicationsProvider>();
    final vitalsProvider = context.watch<VitalsProvider>();
    final familyProvider = context.watch<FamilyProvider>();
    final activeProfile = _activeProfileOption(familyProvider);
    final profileDisplayName = activeProfile?.displayName ?? 'Priya Sharma';
    final avatarInitials = _initialsFromName(profileDisplayName);

    final activeMedications = medicationsProvider.medications
        .where((medication) => medication.isActive)
        .toList();
    _syncTodayMedicationMap(activeMedications);

    final taken = activeMedications
        .where((medication) => _todayMeds[_medicationKey(medication)] ?? false)
        .length;
    final total = activeMedications.length;
    final progress = total == 0 ? 0.0 : taken / total;
    final streakDay = _computeStreakDay(
      medications: activeMedications,
      vitals: vitalsProvider.vitals,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          children: [
            Row(
              children: [
                PopupMenuButton<int?>(
                  tooltip: 'Switch account',
                  padding: EdgeInsets.zero,
                  onSelected: _switchProfile,
                  itemBuilder: (context) {
                    final profiles = familyProvider.profiles;
                    if (profiles.isEmpty) {
                      return const [
                        PopupMenuItem<int>(
                          value: -1,
                          enabled: false,
                          child: Text('No linked accounts'),
                        ),
                      ];
                    }

                    return profiles.map((profile) {
                      final isActive = profile.profileId ==
                          familyProvider.activeFamilyProfileId;
                      final label = profile.subtitle == null ||
                              profile.subtitle!.trim().isEmpty
                          ? profile.displayName
                          : '${profile.displayName} (${profile.subtitle})';
                      return PopupMenuItem<int?>(
                        value: profile.profileId,
                        child: Row(
                          children: [
                            Icon(
                              isActive
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              size: 16,
                              color: isActive
                                  ? KinsuTheme.primary
                                  : KinsuTheme.textSecondary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                label,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList();
                  },
                  child: CircleAvatar(
                    radius: 20,
                    child: Text(avatarInitials),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Good Morning',
                        style: TextStyle(
                          color: KinsuTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        profileDisplayName,
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                        ),
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
            _AnimatedHeroCard(
              controller: _heroController,
              dayNumber: streakDay,
            ),
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
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _appointments.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, index) {
                  final appointment = _appointments[index];
                  return _AppointmentCard(
                    appointment: appointment,
                    dateTimeLabel: _formatAppointmentDateTime(appointment.at),
                    onTap: () => _showAppointmentOverview(appointment),
                  );
                },
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
                        '${(progress * 100).round()}%',
                        style: const TextStyle(
                          color: KinsuTheme.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    borderRadius: BorderRadius.circular(8),
                    backgroundColor: KinsuTheme.divider,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            if (medicationsProvider.isLoading && activeMedications.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (activeMedications.isEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: KinsuTheme.cardDecoration,
                child: const Text(
                  'No active medications yet. Add medications in Track to show them here.',
                  style: TextStyle(color: KinsuTheme.textSecondary),
                ),
              )
            else
              ...activeMedications.map((medication) {
                final key = _medicationKey(medication);
                final isTaken = _todayMeds[key] ?? false;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: KinsuTheme.cardDecoration,
                    child: Row(
                      children: [
                        Checkbox.adaptive(
                          value: isTaken,
                          onChanged: (value) {
                            setState(() {
                              _todayMeds[key] = value ?? false;
                            });
                          },
                          activeColor: KinsuTheme.statusActive,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                medication.name,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              Text(
                                '${medication.dosage} · ${medication.frequency.replaceAll('_', ' ')}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: KinsuTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            setState(() {
                              _todayMeds[key] = !isTaken;
                            });
                          },
                          child: Text(isTaken ? 'Undo' : 'Take'),
                        ),
                      ],
                    ),
                  ),
                );
              }),
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
              height: 160,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: [
                  _InsightCard(
                    title: 'Blood Sugar',
                    value: '142 mg/dL',
                    trend: '↑ 8%',
                    warning: true,
                    note: 'A bit high this week',
                    onTap: () => _showHomeVitalOverview(
                      title: 'Blood Sugar Trend',
                      vitalType: 'blood_sugar',
                    ),
                  ),
                  const SizedBox(width: 10),
                  _InsightCard(
                    title: 'Blood Pressure',
                    value: '128/84',
                    trend: '↓ 3%',
                    warning: false,
                    note: 'Meds are working',
                    onTap: () => _showHomeVitalOverview(
                      title: 'Blood Pressure Trend',
                      vitalType: 'blood_pressure',
                    ),
                  ),
                  const SizedBox(width: 10),
                  _InsightCard(
                    title: 'Heart Rate',
                    value: '72 bpm',
                    trend: '↓ 0.4',
                    warning: false,
                    note: 'Stable this week',
                    onTap: () => _showHomeVitalOverview(
                      title: 'Heart Rate Trend',
                      vitalType: 'heart_rate',
                    ),
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
  final int dayNumber;

  const _AnimatedHeroCard({
    required this.controller,
    required this.dayNumber,
  });

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
                child: _bubble(40, Colors.white.withValues(alpha: 0.16)),
              ),
              Positioned(
                left: 30 + (math.cos(t * 1.1) * 9),
                bottom: 12 + (math.sin(t * 1.2) * 6),
                child: _bubble(28, Colors.white.withValues(alpha: 0.15)),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Day $dayNumber — Keep it up!',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
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
  final _AppointmentData appointment;
  final String dateTimeLabel;
  final VoidCallback onTap;

  const _AppointmentCard({
    required this.appointment,
    required this.dateTimeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 240,
          padding: const EdgeInsets.all(12),
          decoration: KinsuTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                appointment.doctor,
                style:
                    const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
              ),
              Text(
                appointment.specialty,
                style: const TextStyle(
                  color: KinsuTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                dateTimeLabel,
                style: const TextStyle(color: KinsuTheme.primary, fontSize: 12),
              ),
              Text(
                appointment.place,
                style: const TextStyle(
                  color: KinsuTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
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
  final VoidCallback? onTap;

  const _InsightCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.warning,
    required this.note,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(12),
        decoration: KinsuTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: KinsuTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
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
                  color: warning
                      ? const Color(0xFF92400E)
                      : const Color(0xFF047857),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              note,
              style: const TextStyle(
                fontSize: 10,
                color: KinsuTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _AppointmentData {
  final String doctor;
  final String specialty;
  final DateTime at;
  final String place;
  final String? notes;

  const _AppointmentData({
    required this.doctor,
    required this.specialty,
    required this.at,
    required this.place,
    this.notes,
  });
}

class _AppointmentDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _AppointmentDetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: KinsuTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
