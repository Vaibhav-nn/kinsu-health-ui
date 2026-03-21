import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'add_family_member_screen.dart';
import 'caregiver_permissions_screen.dart';
import 'family_models.dart';

class FamilyScreen extends StatelessWidget {
  const FamilyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Family',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddFamilyMemberScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.person_add_alt_1),
                ),
              ],
            ),
            const Text(
              'Manage family members and caregiver access',
              style: TextStyle(color: KinsuTheme.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: KinsuTheme.primaryLight.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: KinsuTheme.primaryLight),
              ),
              child: const Row(
                children: [
                  Icon(Icons.shield_outlined, color: KinsuTheme.primary),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Caregiver mode available for logging data on behalf of family members',
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
            ...familyMembers.map((member) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: KinsuTheme.cardDecoration,
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: member.color.withOpacity(0.16),
                              child: Text(
                                member.avatar,
                                style: TextStyle(
                                  color: member.color,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        member.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      if (member.id == 'self') ...[
                                        const SizedBox(width: 6),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: KinsuTheme.primary
                                                .withOpacity(0.1),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: const Text(
                                            'You',
                                            style: TextStyle(
                                              color: KinsuTheme.primary,
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  Text(
                                    '${member.relation} · ${member.age}y · ${member.blood}',
                                    style: const TextStyle(
                                      color: KinsuTheme.textSecondary,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => CaregiverPermissionsScreen(
                                      member: member,
                                    ),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                      ),
                      if (member.conditions.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
                          child: Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: member.conditions
                                .map(
                                  (condition) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFFBEB),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Text(
                                      condition,
                                      style: const TextStyle(
                                        color: Color(0xFF92400E),
                                        fontSize: 11,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                        decoration: BoxDecoration(
                          border: Border(
                            top: BorderSide(
                              color: KinsuTheme.divider.withOpacity(0.7),
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Text(
                              '${member.records} records',
                              style: const TextStyle(
                                color: KinsuTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Text(
                              '${member.meds} medications',
                              style: const TextStyle(
                                color: KinsuTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              member.lastActivity,
                              style: const TextStyle(
                                color: KinsuTheme.textSecondary,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const AddFamilyMemberScreen(),
                  ),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Family Member'),
            ),
          ],
        ),
      ),
    );
  }
}
