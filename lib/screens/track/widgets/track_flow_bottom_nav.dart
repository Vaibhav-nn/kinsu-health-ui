import 'package:flutter/material.dart';

import '../../../screens/shell/app_shell_bottom_nav.dart';
import '../medications/add_medication_screen.dart';
import '../reminders/add_reminder_screen.dart';
import '../symptoms/quick_symptom_log_screen.dart';
import '../vitals/log_vital_screen.dart';

enum TrackFlowNavTab {
  home,
  track,
  vault,
  ai,
  hub,
  vitals,
  meds,
  symptoms,
}

class TrackFlowBottomNav extends StatelessWidget {
  final TrackFlowNavTab selectedTab;

  const TrackFlowBottomNav({super.key, required this.selectedTab});

  int _selectedRootIndex() {
    switch (selectedTab) {
      case TrackFlowNavTab.home:
        return 0;
      case TrackFlowNavTab.vault:
        return 2;
      case TrackFlowNavTab.ai:
        return 3;
      case TrackFlowNavTab.track:
      case TrackFlowNavTab.hub:
      case TrackFlowNavTab.vitals:
      case TrackFlowNavTab.meds:
      case TrackFlowNavTab.symptoms:
        return 1;
    }
  }

  void _navigateToRoot(BuildContext context, int index) {
    if (index == _selectedRootIndex()) return;
    // Pop back to the main shell (IndexedStack root).
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openAddMenu(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Container(
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Quick Add',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                _actionTile(
                  icon: Icons.monitor_heart_outlined,
                  label: 'Log Vitals',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LogVitalScreen()),
                    );
                  },
                ),
                _actionTile(
                  icon: Icons.medication_outlined,
                  label: 'Log Medicine',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const AddMedicationScreen()),
                    );
                  },
                ),
                _actionTile(
                  icon: Icons.spa_outlined,
                  label: 'Log Symptoms',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const QuickSymptomLogScreen()),
                    );
                  },
                ),
                _actionTile(
                  icon: Icons.notifications_active_outlined,
                  label: 'Add Reminder',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(
                          builder: (_) => const AddReminderScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
          ),
        );
      },
    );
  }

  Widget _actionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFFF4F6F8),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFDDE4EA)),
          ),
          child: Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF1D5F6A)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: Color(0xFF6B7486)),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppShellBottomNav(
      currentIndex: _selectedRootIndex(),
      onTap: (index) => _navigateToRoot(context, index),
      onAddTap: () => _openAddMenu(context),
    );
  }
}
