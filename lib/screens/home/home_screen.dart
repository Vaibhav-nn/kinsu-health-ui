import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/medications_provider.dart';
import '../../providers/vitals_provider.dart';
import '../../providers/vault_provider.dart';
import '../../providers/family_provider.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  final Map<String, bool> _todayMeds = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationsProvider>().loadMedications(isActive: true);
      context.read<VitalsProvider>().loadVitals();
      context.read<VaultProvider>().loadRecords();
      context.read<FamilyProvider>().loadFamilyData();
    });
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤';
    return 'Good Evening 🌙';
  }

  String _initialsFromName(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    if (parts.isEmpty) return 'U';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final medsProvider = context.watch<MedicationsProvider>();
    final vitalsProvider = context.watch<VitalsProvider>();
    final vaultProvider = context.watch<VaultProvider>();
    final familyProvider = context.watch<FamilyProvider>();

    final activeProfile = familyProvider.profiles.isEmpty
        ? null
        : familyProvider.profiles.firstWhere(
            (p) => p.profileId == familyProvider.activeFamilyProfileId,
            orElse: () => familyProvider.profiles.firstWhere(
              (p) => p.isSelf,
              orElse: () => familyProvider.profiles.first,
            ),
          );
    final displayName = activeProfile?.displayName ?? 'there';
    final firstName = displayName.split(' ').first;
    final initials = _initialsFromName(displayName);

    final activeMeds = medsProvider.medications.where((m) => m.isActive).toList();
    // sync map
    final keys = activeMeds.map((m) => m.id?.toString() ?? m.name).toSet();
    _todayMeds.removeWhere((k, _) => !keys.contains(k));
    for (final m in activeMeds) {
      final key = m.id?.toString() ?? m.name;
      _todayMeds.putIfAbsent(key, () => false);
    }
    final taken = activeMeds.where((m) => _todayMeds[m.id?.toString() ?? m.name] ?? false).length;
    final total = activeMeds.length;
    final adherencePct = total == 0 ? 0 : ((taken / total) * 100).round();

    final bpVitals = vitalsProvider.vitals.where((v) => v.vitalType == 'blood_pressure').toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final bsVitals = vitalsProvider.vitals.where((v) => v.vitalType == 'blood_sugar').toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    final recentRecords = vaultProvider.records.take(2).toList();

    return Scaffold(
      backgroundColor: KinsuTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            // ── Top bar ──────────────────────────────────────────────
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: KinsuTheme.primaryLight,
                    child: Text(
                      initials,
                      style: const TextStyle(
                        color: KinsuTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: const TextStyle(
                          fontSize: 12,
                          color: KinsuTheme.textSecondary,
                        ),
                      ),
                      Text(
                        displayName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: KinsuTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.settings_outlined),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  ),
                  color: KinsuTheme.textPrimary,
                ),
                Stack(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const NotificationsScreen()),
                      ),
                      color: KinsuTheme.primary,
                    ),
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: const BoxDecoration(
                          color: KinsuTheme.primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // ── Search bar ───────────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const NotificationsScreen()),
              ),
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: KinsuTheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KinsuTheme.divider),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: const Row(
                  children: [
                    Icon(Icons.search, color: KinsuTheme.textSecondary, size: 20),
                    SizedBox(width: 10),
                    Text(
                      'Search records, meds, doctors...',
                      style: TextStyle(color: KinsuTheme.textSecondary, fontSize: 14),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),

            // ── Hero card ────────────────────────────────────────────
            Container(
              height: 130,
              decoration: BoxDecoration(
                color: KinsuTheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              clipBehavior: Clip.hardEdge,
              child: Stack(
                children: [
                  Positioned(
                    right: -20,
                    top: -30,
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withValues(alpha: 0.12),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Welcome to Kinsu',
                          style: TextStyle(
                            color: Colors.white60,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Hi $firstName, let\'s build\nyour health routine',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // ── Quick Actions ─────────────────────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
              decoration: KinsuTheme.cardDecoration,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickActionTile(
                    icon: Icons.upload_file_outlined,
                    label: 'Upload',
                    bg: KinsuTheme.primaryLight,
                    color: KinsuTheme.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UploadRecordScreen()),
                    ),
                  ),
                  _QuickActionTile(
                    icon: Icons.medication_outlined,
                    label: 'Meds',
                    bg: const Color(0xFFEFF6FF),
                    color: const Color(0xFF3B82F6),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MedicationsListScreen()),
                    ),
                  ),
                  _QuickActionTile(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Vitals',
                    bg: const Color(0xFFF5F3FF),
                    color: const Color(0xFF8B5CF6),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VitalsTrendsScreen()),
                    ),
                  ),
                  _QuickActionTile(
                    icon: Icons.sos_outlined,
                    label: 'SOS',
                    bg: const Color(0xFFFEE2E2),
                    color: KinsuTheme.destructive,
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('SOS flow coming soon.')),
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Today's Medicines ─────────────────────────────────────
            _SectionHeader(
              title: "Today's Medicines",
              trailing: total > 0
                  ? Text(
                      '$adherencePct%',
                      style: const TextStyle(
                        color: KinsuTheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            if (total > 0) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: KinsuTheme.cardDecoration,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text(
                          '$taken/$total taken',
                          style: const TextStyle(
                            fontSize: 13,
                            color: KinsuTheme.textSecondary,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          '$adherencePct% adherence',
                          style: const TextStyle(
                            fontSize: 13,
                            color: KinsuTheme.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: LinearProgressIndicator(
                        value: total == 0 ? 0 : taken / total,
                        minHeight: 8,
                        backgroundColor: KinsuTheme.divider,
                        color: KinsuTheme.primary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              ...activeMeds.take(4).map((med) {
                final key = med.id?.toString() ?? med.name;
                final isTaken = _todayMeds[key] ?? false;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: KinsuTheme.cardDecoration,
                    child: Row(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isTaken ? KinsuTheme.success : KinsuTheme.divider,
                            border: isTaken
                                ? null
                                : Border.all(color: KinsuTheme.textSecondary),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                med.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                med.dosage,
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
                            setState(() => _todayMeds[key] = !isTaken);
                          },
                          style: TextButton.styleFrom(
                            foregroundColor:
                                isTaken ? KinsuTheme.textSecondary : KinsuTheme.primary,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            backgroundColor:
                                isTaken ? KinsuTheme.panel : KinsuTheme.primaryLight,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: Text(isTaken ? 'Done' : 'Take'),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ] else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: KinsuTheme.cardDecoration,
                child: const Text(
                  'No active medications. Add medications in Track.',
                  style: TextStyle(color: KinsuTheme.textSecondary),
                ),
              ),
            const SizedBox(height: 16),

            // ── Health Insights ────────────────────────────────────────
            const _SectionHeader(title: 'Health Insights'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _InsightCard(
                    title: 'Blood Sugar',
                    value: bsVitals.isNotEmpty
                        ? '${bsVitals.first.value.toStringAsFixed(0)} ${bsVitals.first.unit}'
                        : '—',
                    isEmpty: bsVitals.isEmpty,
                    bgColor: KinsuTheme.primaryLight,
                    iconColor: KinsuTheme.primary,
                    icon: Icons.water_drop_outlined,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _InsightCard(
                    title: 'Blood Pressure',
                    value: bpVitals.isNotEmpty
                        ? '${bpVitals.first.value.toStringAsFixed(0)}/${bpVitals.first.valueSecondary?.toStringAsFixed(0) ?? '—'}'
                        : '—',
                    isEmpty: bpVitals.isEmpty,
                    bgColor: const Color(0xFFFEE2E2),
                    iconColor: KinsuTheme.destructive,
                    icon: Icons.favorite_border,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Recent Records ─────────────────────────────────────────
            _SectionHeader(
              title: 'Recent Records',
              trailing: TextButton(
                onPressed: () {},
                child: const Text('View All', style: TextStyle(color: KinsuTheme.primary)),
              ),
            ),
            const SizedBox(height: 8),
            if (recentRecords.isEmpty)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: KinsuTheme.cardDecoration,
                child: Column(
                  children: [
                    const Icon(Icons.folder_outlined, size: 40, color: KinsuTheme.textSecondary),
                    const SizedBox(height: 8),
                    const Text(
                      'No records yet',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Upload your first health record',
                      style: TextStyle(color: KinsuTheme.textSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 12),
                    ElevatedButton.icon(
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const UploadRecordScreen()),
                      ),
                      icon: const Icon(Icons.upload, size: 16),
                      label: const Text('Upload'),
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 40),
                        textStyle: const TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              )
            else
              ...recentRecords.map((record) => Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: KinsuTheme.cardDecoration,
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: KinsuTheme.primaryLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.description_outlined,
                                color: KinsuTheme.primary, size: 20),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  record.title,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  record.recordType,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: KinsuTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${record.recordDate.day}/${record.recordDate.month}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: KinsuTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )),
            const SizedBox(height: 16),

            // ── Ask Kinsu AI promo ─────────────────────────────────────
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KinsuTheme.primary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.auto_awesome, color: Colors.white, size: 22),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Ask Kinsu AI',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            'Insights from your own data',
                            style: TextStyle(color: Colors.white70, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Open',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // ── Security notice ────────────────────────────────────────
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
                  Icon(Icons.security_outlined, size: 16, color: KinsuTheme.textSecondary),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Your data is encrypted and stored securely in compliance with DPDP Act 2023.',
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
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;

  const _SectionHeader({required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: KinsuTheme.textPrimary,
            ),
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.bg,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: KinsuTheme.textPrimary,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String value;
  final bool isEmpty;
  final Color bgColor;
  final Color iconColor;
  final IconData icon;

  const _InsightCard({
    required this.title,
    required this.value,
    required this.isEmpty,
    required this.bgColor,
    required this.iconColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(height: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: iconColor.withValues(alpha: 0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: isEmpty ? KinsuTheme.textSecondary : KinsuTheme.textPrimary,
            ),
          ),
          if (isEmpty)
            const Text(
              'No data yet',
              style: TextStyle(fontSize: 11, color: KinsuTheme.textSecondary),
            ),
        ],
      ),
    );
  }
}
