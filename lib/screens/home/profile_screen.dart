import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/vault_provider.dart';
import '../../providers/vitals_provider.dart';
import '../../providers/reminders_provider.dart';
import '../../utils/display_utils.dart';
import '../../widgets/kinsu_widgets.dart';
import '../settings/health_connect_settings_screen.dart';
import '../track/medications/medications_list_screen.dart';
import '../track/vitals/vitals_trends_screen.dart';
import '../upload_record_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _darkMode = false;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final displayName = user?.displayName ?? user?.email?.split('@').first ?? 'User';
    final email = user?.email ?? '';
    final provider = user?.providerData.isNotEmpty == true
        ? user!.providerData.first.providerId
        : 'email';
    final initials = user?.displayName != null
        ? initialsFromName(user!.displayName!)
        : (email.isNotEmpty ? initialsFromEmail(email) : 'U');

    final vaultProvider = context.watch<VaultProvider>();
    final remindersProvider = context.watch<RemindersProvider>();
    final vitalsProvider = context.watch<VitalsProvider>();

    final activeReminders = remindersProvider.reminders.where((r) => r.isEnabled).length;
    final vitalsCount = vitalsProvider.vitals.length;
    final recordsCount = vaultProvider.records.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        leading: IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      backgroundColor: KinsuTheme.background,
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── Profile card ───────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(20),
            decoration: KinsuTheme.cardDecoration,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 34,
                  backgroundColor: KinsuTheme.primaryLight,
                  child: Text(
                    initials,
                    style: const TextStyle(
                      color: KinsuTheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 22,
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: KinsuTheme.textPrimary,
                        ),
                      ),
                      if (email.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          email,
                          style: const TextStyle(
                            fontSize: 14,
                            color: KinsuTheme.textSecondary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 2),
                      Text(
                        provider,
                        style: const TextStyle(
                          fontSize: 12,
                          color: KinsuTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // ── Stats grid ─────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                  child: _StatCard(
                      label: 'Records',
                      value: recordsCount.toString())),
              const SizedBox(width: 8),
              Expanded(
                  child: _StatCard(
                      label: 'Reminders',
                      value: activeReminders.toString())),
              const SizedBox(width: 8),
              const Expanded(
                  child: _StatCard(
                      label: 'Adherence',
                      value: '0%')),
              const SizedBox(width: 8),
              Expanded(
                  child: _StatCard(
                      label: 'Vitals',
                      value: vitalsCount.toString())),
            ],
          ),
          const SizedBox(height: 16),

          // ── Dark mode toggle ───────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: KinsuTheme.cardDecoration,
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: KinsuTheme.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.dark_mode_outlined,
                      color: KinsuTheme.primary, size: 18),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dark Mode',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: KinsuTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Appearance setting (coming soon)',
                        style: TextStyle(
                          fontSize: 12,
                          color: KinsuTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _darkMode,
                  onChanged: (v) => setState(() => _darkMode = v),
                  activeThumbColor: KinsuTheme.primary,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // ── Health section ─────────────────────────────────────────
          const KinsuSectionHeader(title: 'Health'),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.folder_outlined,
            iconBg: KinsuTheme.primaryLight,
            iconColor: KinsuTheme.primary,
            title: 'My health records',
            subtitle: 'Lab reports, prescriptions, imaging',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const UploadRecordScreen()),
            ),
          ),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.show_chart_rounded,
            iconBg: const Color(0xFFF5F3FF),
            iconColor: const Color(0xFF8B5CF6),
            title: 'Vitals & tracking',
            subtitle: 'Blood pressure, sugar, heart rate',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const VitalsTrendsScreen()),
            ),
          ),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.notifications_outlined,
            iconBg: const Color(0xFFFFF3CD),
            iconColor: const Color(0xFFB45309),
            title: 'Reminder hub',
            subtitle: 'Medication and appointment reminders',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const MedicationsListScreen()),
            ),
          ),
          const SizedBox(height: 16),

          // ── Account section ────────────────────────────────────────
          const KinsuSectionHeader(title: 'Account'),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.privacy_tip_outlined,
            iconBg: const Color(0xFFD1FAE5),
            iconColor: const Color(0xFF047857),
            title: 'Privacy & consent',
            subtitle: 'Manage data sharing and consent',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Privacy settings coming soon')),
            ),
          ),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.health_and_safety_outlined,
            iconBg: const Color(0xFFEFF6FF),
            iconColor: const Color(0xFF3B82F6),
            title: 'Connected apps',
            subtitle: 'Health Connect, wearables & devices',
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const HealthConnectSettingsScreen(),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Preferences section ────────────────────────────────────
          const KinsuSectionHeader(title: 'Preferences'),
          const SizedBox(height: 8),
          _MenuTile(
            icon: Icons.settings_outlined,
            iconBg: KinsuTheme.panel,
            iconColor: KinsuTheme.textSecondary,
            title: 'App settings',
            subtitle: 'Notifications, language, units',
            onTap: () => ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('App settings coming soon')),
            ),
          ),
          const SizedBox(height: 16),

          // ── Sign out ───────────────────────────────────────────────
          OutlinedButton.icon(
            onPressed: () async {
              await FirebaseAuth.instance.signOut();
              if (!context.mounted) return;
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
            icon: const Icon(Icons.logout, size: 18),
            label: const Text('Sign out'),
            style: OutlinedButton.styleFrom(
              foregroundColor: KinsuTheme.destructive,
              side: const BorderSide(color: KinsuTheme.destructive),
              padding: const EdgeInsets.symmetric(vertical: 14),
            ),
          ),
          const SizedBox(height: 16),

          // ── DPDP notice ────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: KinsuTheme.panel,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: KinsuTheme.divider),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.security_outlined,
                    size: 16, color: KinsuTheme.textSecondary),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your data is protected under the DPDP Act 2023 (India). '
                    'Kinsu Health stores and processes your health data securely. '
                    'You may request data deletion at any time.',
                    style: TextStyle(
                      fontSize: 11,
                      color: KinsuTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;

  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: KinsuTheme.cardDecoration,
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: KinsuTheme.primary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: KinsuTheme.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}


class _MenuTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _MenuTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.subtitle,
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
          padding: const EdgeInsets.all(14),
          decoration: KinsuTheme.cardDecoration,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: iconBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: KinsuTheme.textPrimary,
                        fontSize: 14,
                      ),
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
