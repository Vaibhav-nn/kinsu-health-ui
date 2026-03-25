import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Consumer<FamilyProvider>(
          builder: (context, provider, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Family',
                        style: TextStyle(
                            fontSize: 24, fontWeight: FontWeight.w700),
                      ),
                    ),
                    IconButton(
                      onPressed: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AddFamilyMemberScreen(),
                          ),
                        );
                        if (mounted) {
                          context.read<FamilyProvider>().loadFamilyData();
                        }
                      },
                      icon: const Icon(Icons.person_add_alt_1),
                    ),
                  ],
                ),
                const Text(
                  'Link family members by phone and manage caregiver tracking profiles.',
                  style:
                      TextStyle(color: KinsuTheme.textSecondary, fontSize: 13),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: KinsuTheme.primaryLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: KinsuTheme.primaryLight),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: KinsuTheme.primary),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Caregiver mode enabled: you can log records on behalf of linked family members.',
                          style: TextStyle(
                            color: KinsuTheme.textPrimary,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (provider.isLoading)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.members.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: KinsuTheme.cardDecoration,
                    child: const Text(
                      'No linked family members yet. Tap + to add one.',
                      style: TextStyle(color: KinsuTheme.textSecondary),
                    ),
                  )
                else
                  ...provider.members.map((member) {
                    final isActiveContext =
                        provider.activeFamilyProfileId == member.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Container(
                        decoration: KinsuTheme.cardDecoration,
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                KinsuTheme.primary.withValues(alpha: 0.12),
                            child: Text(
                              member.displayName.trim().isEmpty
                                  ? 'F'
                                  : member.displayName.trim()[0].toUpperCase(),
                              style: const TextStyle(
                                color: KinsuTheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          title: Text(
                            member.displayName,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          subtitle: Text(
                            [
                              if (member.relation != null &&
                                  member.relation!.trim().isNotEmpty)
                                member.relation!,
                              member.phoneE164,
                            ].join(' · '),
                            style: const TextStyle(
                                color: KinsuTheme.textSecondary),
                          ),
                          trailing: TextButton(
                            onPressed: () {
                              provider.setActiveProfileId(
                                  isActiveContext ? null : member.id);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isActiveContext
                                        ? 'Switched to self profile'
                                        : 'Switched to ${member.displayName}',
                                  ),
                                ),
                              );
                            },
                            child: Text(isActiveContext ? 'Active' : 'Switch'),
                          ),
                        ),
                      ),
                    );
                  }),
                const SizedBox(height: 10),
                OutlinedButton.icon(
                  onPressed: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddFamilyMemberScreen(),
                      ),
                    );
                    if (mounted) {
                      context.read<FamilyProvider>().loadFamilyData();
                    }
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add Family Member'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
