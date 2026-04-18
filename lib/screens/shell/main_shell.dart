import 'package:flutter/foundation.dart' show kIsWeb;
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
import 'app_shell_web_nav.dart';

/// Main app shell.
///
/// Mobile / narrow web (< 900 px): 4-tab bottom nav + centre FAB.
/// Desktop web (≥ 900 px): left sidebar with 5 tabs (adds Family).
class MainShell extends StatefulWidget {
  final int initialIndex;

  const MainShell({super.key, this.initialIndex = 0});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  // Mobile: 4 tabs — Home(0), Track(1), Vault(2), AI(3)
  late int _mobileIndex;
  // Desktop web: 5 tabs — Home(0), Track(1), Vault(2), Family(3), AI(4)
  late int _webIndex;

  static const List<Widget> _mobilePages = [
    HomeScreen(),
    TrackHome(),
    VaultScreen(),
    AiScreen(),
  ];

  static const List<Widget> _webPages = [
    HomeScreen(),
    TrackHome(),
    VaultScreen(),
    FamilyScreen(),
    AiScreen(),
  ];

  bool _isDesktopWeb(BuildContext context) =>
      kIsWeb && MediaQuery.of(context).size.width >= 900;

  @override
  void initState() {
    super.initState();
    _mobileIndex = widget.initialIndex.clamp(0, _mobilePages.length - 1);
    _webIndex = widget.initialIndex.clamp(0, _webPages.length - 1);
  }

  void _openAddMenu() {
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
                      MaterialPageRoute(
                          builder: (_) => const AddMedicationScreen()),
                    );
                  },
                ),
                _addActionTile(
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
                _addActionTile(
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
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: KinsuTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isDesktopWeb(context)) {
      return _buildDesktopLayout();
    }
    return _buildMobileLayout();
  }

  Widget _buildMobileLayout() {
    return Scaffold(
      body: IndexedStack(index: _mobileIndex, children: _mobilePages),
      backgroundColor: KinsuTheme.background,
      bottomNavigationBar: AppShellBottomNav(
        currentIndex: _mobileIndex,
        onTap: (index) => setState(() => _mobileIndex = index),
        onAddTap: _openAddMenu,
      ),
    );
  }

  Widget _buildDesktopLayout() {
    return Scaffold(
      backgroundColor: KinsuTheme.background,
      body: Row(
        children: [
          AppShellWebNav(
            currentIndex: _webIndex,
            onTap: (index) => setState(() => _webIndex = index),
            onAddTap: _openAddMenu,
          ),
          Expanded(
            child: IndexedStack(
              index: _webIndex,
              children: _webPages,
            ),
          ),
        ],
      ),
    );
  }
}
