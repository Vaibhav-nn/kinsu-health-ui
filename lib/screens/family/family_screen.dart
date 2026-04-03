import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/family_member_profile.dart';
import '../../providers/family_provider.dart';
import 'add_family_member_screen.dart';

class FamilyScreen extends StatefulWidget {
  const FamilyScreen({super.key});

  @override
  State<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends State<FamilyScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FamilyProvider>().loadFamilyData();
    });
  }

  Future<void> _openAddMember() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const AddFamilyMemberScreen(),
      ),
    );
    if (mounted) {
      await context.read<FamilyProvider>().loadFamilyData();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<FamilyProvider>(
          builder: (context, provider, _) {
            return RefreshIndicator(
              onRefresh: provider.loadFamilyData,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Family',
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      IconButton(
                        onPressed: _openAddMember,
                        icon: const Icon(Icons.person_add_alt_1),
                      ),
                    ],
                  ),
                  const Text(
                    'Manage family members and caregiver access.',
                    style: TextStyle(
                      color: KinsuTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: KinsuTheme.primaryLight.withOpacity(0.22),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: KinsuTheme.primaryLight),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.shield_outlined, color: KinsuTheme.primary),
                        SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Caregiver Mode Available',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: KinsuTheme.primary,
                                ),
                              ),
                              SizedBox(height: 4),
                              Text(
                                'Log health data on behalf of family members.',
                                style: TextStyle(
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
                  if (provider.isLoading)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (provider.error != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: KinsuTheme.cardDecoration,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Unable to load family dashboard',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            provider.error!,
                            style: const TextStyle(
                              color: KinsuTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    )
                  else if (provider.dashboardCards.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: KinsuTheme.cardDecoration,
                      child: const Text(
                        'No family profiles yet. Tap Add Family Member to get started.',
                        style: TextStyle(color: KinsuTheme.textSecondary),
                      ),
                    )
                  else
                    ...provider.dashboardCards.map(
                      (card) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _FamilyDashboardCardView(
                          card: card,
                          onTap: () {
                            provider.setActiveProfileId(
                              card.isSelf ? null : card.profileId,
                            );
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  card.isSelf
                                      ? 'Switched to your profile'
                                      : 'Switched to ${card.displayName}',
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  const SizedBox(height: 6),
                  OutlinedButton.icon(
                    onPressed: _openAddMember,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Family Member'),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _FamilyDashboardCardView extends StatelessWidget {
  final FamilyDashboardCard card;
  final VoidCallback onTap;

  const _FamilyDashboardCardView({
    required this.card,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          decoration: KinsuTheme.cardDecoration,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: _avatarColor(card.initials),
                      child: Text(
                        card.initials,
                        style: TextStyle(
                          color: _avatarTextColor(card.initials),
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  card.displayName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (card.isSelf || card.isActiveContext)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: KinsuTheme.primaryLight.withOpacity(0.35),
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    card.isSelf ? 'You' : 'Active',
                                    style: const TextStyle(
                                      color: KinsuTheme.primary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            [
                              card.relation,
                              if (card.age != null) '${card.age}y',
                              if (card.bloodGroup != null && card.bloodGroup!.isNotEmpty)
                                card.bloodGroup!,
                            ].join(' · '),
                            style: const TextStyle(
                              color: KinsuTheme.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                          if (card.healthConditions.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: card.healthConditions
                                  .map(
                                    (condition) => Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFF7ED),
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        _labelize(condition),
                                        style: const TextStyle(
                                          color: Color(0xFFB45309),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Icon(Icons.chevron_right_rounded),
                  ],
                ),
              ),
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: _MetaItem(
                        icon: Icons.description_outlined,
                        label: '${card.recordCount} records',
                      ),
                    ),
                    Expanded(
                      child: _MetaItem(
                        icon: Icons.medication_outlined,
                        label: '${card.medicationCount} medications',
                      ),
                    ),
                    Expanded(
                      child: Text(
                        card.lastActivity,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                          color: KinsuTheme.textSecondary,
                          fontSize: 13,
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
      ),
    );
  }

  static Color _avatarColor(String initials) {
    switch (initials.characters.firstOrNull ?? 'A') {
      case 'L':
        return const Color(0xFFF3E8FF);
      case 'R':
        return const Color(0xFFE0ECFF);
      case 'V':
        return const Color(0xFFFFF3E8);
      default:
        return KinsuTheme.primaryLight.withOpacity(0.35);
    }
  }

  static Color _avatarTextColor(String initials) {
    switch (initials.characters.firstOrNull ?? 'A') {
      case 'L':
        return const Color(0xFF8B5CF6);
      case 'R':
        return const Color(0xFF3B82F6);
      case 'V':
        return const Color(0xFFF59E0B);
      default:
        return KinsuTheme.primary;
    }
  }

  static String _labelize(String raw) {
    return raw
        .split('_')
        .map((part) => part.isEmpty
            ? part
            : '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
  }
}

class _MetaItem extends StatelessWidget {
  final IconData icon;
  final String label;

  const _MetaItem({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: KinsuTheme.textSecondary),
        const SizedBox(width: 6),
        Flexible(
          child: Text(
            label,
            style: const TextStyle(
              color: KinsuTheme.textSecondary,
              fontSize: 13,
            ),
          ),
        ),
      ],
    );
  }
}
