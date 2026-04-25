import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/family_member_profile.dart';
import '../../providers/family_provider.dart';
import '../../utils/display_utils.dart';
import '../../widgets/kinsu_widgets.dart';

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

  void _showAddMemberSheet() {
    final nameCtrl = TextEditingController();
    final phoneCtrl = TextEditingController();
    final ageCtrl = TextEditingController();
    String? relation = 'Other';
    String gender = 'Male';
    String role = 'Dependent';

    const relations = [
      'Self',
      'Spouse',
      'Father',
      'Mother',
      'Son',
      'Daughter',
      'Brother',
      'Sister',
      'Grandparent',
      'Friend',
      'Other',
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setLocal) => Padding(
          padding: EdgeInsets.fromLTRB(
            20,
            16,
            20,
            MediaQuery.of(ctx2).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const KinsuDragHandle(),
                const SizedBox(height: 16),
                const Text(
                  'Add Family Member',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 16),
                // Name
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'Full name',
                  ),
                ),
                const SizedBox(height: 12),
                // Relation dropdown
                DropdownButtonFormField<String>(
                  initialValue: relation,
                  decoration: const InputDecoration(labelText: 'Relation'),
                  items: relations
                      .map((r) => DropdownMenuItem(value: r, child: Text(r)))
                      .toList(),
                  onChanged: (v) => setLocal(() => relation = v),
                ),
                const SizedBox(height: 12),
                // Phone
                TextField(
                  controller: phoneCtrl,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(
                    labelText: 'Phone',
                    hintText: '+91XXXXXXXXXX',
                  ),
                ),
                const SizedBox(height: 12),
                // Age
                TextField(
                  controller: ageCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Age'),
                ),
                const SizedBox(height: 14),
                // Gender chips
                const Text(
                  'Gender',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: KinsuTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['Male', 'Female', 'Other'].map((g) {
                    final sel = gender == g;
                    return FilterChip(
                      label: Text(g),
                      selected: sel,
                      onSelected: (_) => setLocal(() => gender = g),
                      selectedColor: KinsuTheme.primaryLight,
                      checkmarkColor: KinsuTheme.primary,
                      labelStyle: TextStyle(
                        color: sel ? KinsuTheme.primary : KinsuTheme.textPrimary,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),
                // Role chips
                const Text(
                  'Role',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: KinsuTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: ['You', 'Dependent', 'Caregiver'].map((r) {
                    final sel = role == r;
                    return FilterChip(
                      label: Text(r),
                      selected: sel,
                      onSelected: (_) => setLocal(() => role = r),
                      selectedColor: KinsuTheme.primaryLight,
                      checkmarkColor: KinsuTheme.primary,
                      labelStyle: TextStyle(
                        color: sel ? KinsuTheme.primary : KinsuTheme.textPrimary,
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx2),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () async {
                          final name = nameCtrl.text.trim();
                          if (name.isEmpty) {
                            ScaffoldMessenger.of(ctx2).showSnackBar(
                              const SnackBar(content: Text('Name is required')),
                            );
                            return;
                          }
                          final phone =
                              phoneCtrl.text.trim().isEmpty ? '+910000000000' : phoneCtrl.text.trim();
                          final ageInt = int.tryParse(ageCtrl.text.trim()) ?? 0;
                          final dob = ageInt > 0
                              ? DateTime(
                                  DateTime.now().year - ageInt,
                                  DateTime.now().month,
                                  DateTime.now().day,
                                )
                              : null;

                          Navigator.pop(ctx2);
                          final success =
                              await context.read<FamilyProvider>().addMember(
                                    displayName: name,
                                    phoneE164: phone,
                                    relation: relation,
                                    dateOfBirth: dob,
                                    notes: 'Gender: $gender, Role: $role',
                                  );
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  success
                                      ? '$name added successfully'
                                      : 'Failed to add member',
                                ),
                              ),
                            );
                          }
                        },
                        child: const Text('Save'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDetailSheet(FamilyMemberProfile member) {
    final initials = initialsFromName(member.displayName.isEmpty ? 'F' : member.displayName);

    final age = member.dateOfBirth != null
        ? '${DateTime.now().year - member.dateOfBirth!.year} yrs'
        : null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: KinsuTheme.divider,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 36,
              backgroundColor: KinsuTheme.primaryLight,
              child: Text(
                initials,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: KinsuTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              member.displayName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: KinsuTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            _RoleBadge(
              isActive: member.isActive,
              relation: member.relation,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: KinsuTheme.cardDecoration,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (member.relation != null && member.relation!.isNotEmpty)
                    _DetailRow(label: 'Relation', value: member.relation!),
                  if (age != null) _DetailRow(label: 'Age', value: age),
                  _DetailRow(label: 'Phone', value: member.phoneE164),
                  if (member.notes != null && member.notes!.isNotEmpty)
                    _DetailRow(label: 'Notes', value: member.notes!),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KinsuTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              decoration: const BoxDecoration(
                color: KinsuTheme.surface,
                border: Border(
                  bottom: BorderSide(color: KinsuTheme.divider, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Family Care',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w700,
                            color: KinsuTheme.textPrimary,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Manage care for the people you love',
                          style: TextStyle(
                            fontSize: 12,
                            color: KinsuTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  FilledButton.icon(
                    onPressed: _showAddMemberSheet,
                    icon: const Icon(Icons.person_add_rounded, size: 18),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      backgroundColor: KinsuTheme.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 10),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────
            Expanded(
              child: Consumer<FamilyProvider>(
                builder: (context, provider, _) {
                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Info banner
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: KinsuTheme.primaryLight.withValues(alpha: 0.5),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: KinsuTheme.primaryLight,
                          ),
                        ),
                        child: const Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(Icons.shield_outlined,
                                size: 16, color: KinsuTheme.primary),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Consent is required from each adult dependent before syncing their records.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: KinsuTheme.textPrimary,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Member list or empty state
                      if (provider.isLoading)
                        const Center(child: CircularProgressIndicator())
                      else if (provider.members.isEmpty)
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: Column(
                              children: [
                                const Icon(Icons.people_outline,
                                    size: 64,
                                    color: KinsuTheme.textSecondary),
                                const SizedBox(height: 16),
                                const Text(
                                  'No family members yet',
                                  style: TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.w600,
                                    color: KinsuTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Add a family member to start managing their care.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                      color: KinsuTheme.textSecondary,
                                      fontSize: 13),
                                ),
                                const SizedBox(height: 20),
                                FilledButton.icon(
                                  onPressed: _showAddMemberSheet,
                                  icon: const Icon(Icons.person_add_rounded,
                                      size: 18),
                                  label: const Text('Add Member'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: KinsuTheme.primary,
                                    foregroundColor: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...provider.members.map(
                          (member) {
                            final initials = initialsFromName(member.displayName.isEmpty ? 'F' : member.displayName);
                            final age = member.dateOfBirth != null
                                ? '${DateTime.now().year - member.dateOfBirth!.year} yrs'
                                : null;
                            final subtitle = [
                              if (member.relation != null &&
                                  member.relation!.isNotEmpty)
                                member.relation!,
                              if (age != null) age,
                            ].join(' · ');

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: Container(
                                decoration: KinsuTheme.cardDecoration,
                                child: ListTile(
                                  onTap: () => _showDetailSheet(member),
                                  leading: CircleAvatar(
                                    radius: 22,
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
                                  title: Text(
                                    member.displayName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 2),
                                      _RoleBadge(
                                        isActive: member.isActive,
                                        relation: member.relation,
                                      ),
                                      if (subtitle.isNotEmpty)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(top: 2),
                                          child: Text(
                                            subtitle,
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: KinsuTheme.textSecondary,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                  trailing: const Icon(Icons.chevron_right,
                                      color: KinsuTheme.textSecondary),
                                ),
                              ),
                            );
                          },
                        ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final bool isActive;
  final String? relation;

  const _RoleBadge({required this.isActive, this.relation});

  @override
  Widget build(BuildContext context) {
    final isSelf =
        relation?.toLowerCase() == 'self' || relation == null;
    final Color bgColor;
    final Color textColor;
    final String label;

    if (isSelf) {
      bgColor = KinsuTheme.primaryLight;
      textColor = KinsuTheme.primary;
      label = 'You';
    } else if (isActive) {
      bgColor = const Color(0xFFFFF3CD);
      textColor = const Color(0xFFB45309);
      label = 'Dependent';
    } else {
      bgColor = const Color(0xFFD1FAE5);
      textColor = const Color(0xFF047857);
      label = 'Caregiver';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
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
                color: KinsuTheme.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
