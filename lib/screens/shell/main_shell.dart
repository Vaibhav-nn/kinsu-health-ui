import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/router.dart';
import '../../core/theme.dart';
import '../track/medications/add_medication_screen.dart';
import '../track/reminders/add_reminder_screen.dart';
import '../track/symptoms/quick_symptom_log_screen.dart';
import '../track/vitals/log_vital_screen.dart';
import 'app_shell_bottom_nav.dart';
import 'app_shell_web_nav.dart';

/// Main app shell — driven by go_router's [StatefulNavigationShell].
///
/// Layout rules:
///   < 900 px  — 4-tab bottom nav + centre FAB (Home, Track, Vault, AI).
///   ≥ 900 px  — 5-tab left sidebar (adds Family between Vault and AI).
///
/// Branch indices (see [_Branch] in router.dart):
///   0 Home  1 Track  2 Vault  3 Family  4 AI
class MainShell extends StatefulWidget {
  final StatefulNavigationShell navigationShell;

  const MainShell({super.key, required this.navigationShell});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  bool _isDesktopWeb(BuildContext context) =>
      kIsWeb && MediaQuery.of(context).size.width >= 900;

  // ── Navigation helpers ──────────────────────────────────────────────────

  void _goBranch(int branchIndex) {
    widget.navigationShell.goBranch(
      branchIndex,
      // If already on this branch, navigate to its initial location
      // (i.e. pop all sub-routes in that branch).
      initialLocation: branchIndex == widget.navigationShell.currentIndex,
    );
  }

  void _onMobileNavTap(int navIndex) {
    _goBranch(mobileNavToBranch(navIndex));
  }

  // ── Quick-add bottom sheet ──────────────────────────────────────────────

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
                      Navigator.of(context, rootNavigator: true).push(
                        MaterialPageRoute(
                            builder: (_) => const LogVitalScreen()),
                      );
                    },
                  ),
                  _addActionTile(
                    icon: Icons.medication_outlined,
                    label: 'Log Medicine',
                    onTap: () {
                      Navigator.of(sheetContext).pop();
                      Navigator.of(context, rootNavigator: true).push(
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
                      Navigator.of(context, rootNavigator: true).push(
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
                      Navigator.of(context, rootNavigator: true).push(
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

  // ── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_isDesktopWeb(context)) {
      return _buildDesktopLayout();
    }
    return _buildMobileLayout();
  }

  Widget _buildMobileLayout() {
    final navIndex =
        branchToMobileNav(widget.navigationShell.currentIndex);

    return Scaffold(
      body: widget.navigationShell,
      backgroundColor: KinsuTheme.background,
      bottomNavigationBar: AppShellBottomNav(
        currentIndex: navIndex < 0 ? 0 : navIndex,
        onTap: _onMobileNavTap,
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
            currentIndex: widget.navigationShell.currentIndex,
            onTap: _goBranch,
            onAddTap: _openAddMenu,
          ),
          Expanded(child: widget.navigationShell),
        ],
      ),
    );
  }
}
