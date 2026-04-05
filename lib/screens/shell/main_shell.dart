import 'package:flutter/material.dart';

import '../../core/theme.dart';
import '../ai/ai_screen.dart';
import '../family/family_screen.dart';
import '../home/home_screen.dart';
import '../track/medications/add_medication_screen.dart';
import '../track/reminders/add_reminder_screen.dart';
import '../track/symptoms/quick_symptom_log_screen.dart';
import '../track/track_home.dart';
import '../track/vitals/log_vital_screen.dart';
import '../vault_screen.dart';
import 'app_shell_bottom_nav.dart';

/// Main app shell with bottom navigation bar.
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(),
    const VaultScreen(),
    const TrackHome(),
    const FamilyScreen(),
    const AiScreen(),
  ];

  void _openAddMenu() {
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
                _addActionTile(
                  icon: Icons.monitor_heart_outlined,
                  label: 'Log Vitals',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const LogVitalScreen()),
                    );
                  },
                ),
                _addActionTile(
                  icon: Icons.medication_outlined,
                  label: 'Log Medicine',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
                    );
                  },
                ),
                _addActionTile(
                  icon: Icons.spa_outlined,
                  label: 'Log Symptoms',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const QuickSymptomLogScreen()),
                    );
                  },
                ),
                _addActionTile(
                  icon: Icons.notifications_active_outlined,
                  label: 'Add Reminder',
                  onTap: () {
                    Navigator.of(sheetContext).pop();
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const AddReminderScreen()),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _addActionTile({
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
            color: KinsuTheme.panel,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: KinsuTheme.divider),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: KinsuTheme.primaryLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: KinsuTheme.primaryDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.chevron_right_rounded, color: KinsuTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _pages),
      backgroundColor: KinsuTheme.background,
      bottomNavigationBar: AppShellBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        onAddTap: _openAddMenu,
      ),
    );
  }
}
