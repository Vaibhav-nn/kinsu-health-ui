import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../medications/add_medication_screen.dart';
import '../reminders/add_reminder_screen.dart';
import '../symptoms/quick_symptom_log_screen.dart';
import '../track_home.dart';
import '../vitals/log_vital_screen.dart';

enum TrackFlowNavTab { hub, vitals, meds, symptoms }

class TrackFlowBottomNav extends StatelessWidget {
  final TrackFlowNavTab selectedTab;

  const TrackFlowBottomNav({super.key, required this.selectedTab});

  void _navigateTo(BuildContext context, TrackFlowNavTab tab) {
    if (tab == selectedTab) {
      return;
    }

    final route = switch (tab) {
      TrackFlowNavTab.hub =>
        MaterialPageRoute(builder: (_) => const TrackHome()),
      TrackFlowNavTab.vitals =>
        MaterialPageRoute(builder: (_) => const LogVitalScreen()),
      TrackFlowNavTab.meds =>
        MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
      TrackFlowNavTab.symptoms =>
        MaterialPageRoute(builder: (_) => const QuickSymptomLogScreen()),
    };

    Navigator.of(context).pushReplacement(route);
  }

  void _openAddMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Quick Add',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Jump straight into the log you want to create.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: KinsuTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 18),
                _AddActionTile(
                  icon: Icons.monitor_heart_outlined,
                  color: const Color(0xFFF4EEFF),
                  iconColor: const Color(0xFF8B5CF6),
                  label: 'Log Vitals',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _navigateTo(context, TrackFlowNavTab.vitals);
                  },
                ),
                _AddActionTile(
                  icon: Icons.medication_outlined,
                  color: const Color(0xFFEAF2FF),
                  iconColor: const Color(0xFF3B82F6),
                  label: 'Log Medicine',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _navigateTo(context, TrackFlowNavTab.meds);
                  },
                ),
                _AddActionTile(
                  icon: Icons.notifications_active_outlined,
                  color: const Color(0xFFE8F5F7),
                  iconColor: const Color(0xFF149C97),
                  label: 'Add Reminder',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const AddReminderScreen(),
                      ),
                    );
                  },
                ),
                _AddActionTile(
                  icon: Icons.favorite_border_rounded,
                  color: const Color(0xFFFFF1E7),
                  iconColor: const Color(0xFFF97316),
                  label: 'Log Symptoms',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    _navigateTo(context, TrackFlowNavTab.symptoms);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 104,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          Positioned.fill(
            top: 16,
            child: Container(
              padding: const EdgeInsets.fromLTRB(14, 16, 14, 10),
              decoration: const BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: KinsuTheme.divider)),
                boxShadow: [
                  BoxShadow(
                    color: Color(0x100F172A),
                    blurRadius: 18,
                    offset: Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _NavItem(
                    icon: Icons.dashboard_outlined,
                    label: 'Hub',
                    selected: selectedTab == TrackFlowNavTab.hub,
                    onTap: () => _navigateTo(context, TrackFlowNavTab.hub),
                  ),
                  _NavItem(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Vitals',
                    selected: selectedTab == TrackFlowNavTab.vitals,
                    onTap: () => _navigateTo(context, TrackFlowNavTab.vitals),
                  ),
                  const SizedBox(width: 84),
                  _NavItem(
                    icon: Icons.medication_outlined,
                    label: 'Meds',
                    selected: selectedTab == TrackFlowNavTab.meds,
                    onTap: () => _navigateTo(context, TrackFlowNavTab.meds),
                  ),
                  _NavItem(
                    icon: Icons.spa_outlined,
                    label: 'Symptoms',
                    selected: selectedTab == TrackFlowNavTab.symptoms,
                    onTap: () => _navigateTo(context, TrackFlowNavTab.symptoms),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: -8,
            child: GestureDetector(
              onTap: () => _openAddMenu(context),
              child: Container(
                width: 62,
                height: 62,
                decoration: BoxDecoration(
                  color: KinsuTheme.primaryDark,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: KinsuTheme.primaryDark.withValues(alpha: 0.24),
                      blurRadius: 24,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: const Icon(Icons.add_rounded,
                    color: Colors.white, size: 32),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? KinsuTheme.primaryDark : const Color(0xFFA4AFC0);

    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? KinsuTheme.primaryLight : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: color,
                letterSpacing: 0.55,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddActionTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color iconColor;
  final String label;
  final VoidCallback onTap;

  const _AddActionTile({
    required this.icon,
    required this.color,
    required this.iconColor,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: KinsuTheme.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: KinsuTheme.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: iconColor),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                  ),
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: KinsuTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
