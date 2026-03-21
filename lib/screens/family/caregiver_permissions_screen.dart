import 'package:flutter/material.dart';

import '../../core/theme.dart';
import 'family_models.dart';

class CaregiverPermissionsScreen extends StatefulWidget {
  final FamilyMember member;

  const CaregiverPermissionsScreen({
    super.key,
    required this.member,
  });

  @override
  State<CaregiverPermissionsScreen> createState() =>
      _CaregiverPermissionsScreenState();
}

class _CaregiverPermissionsScreenState
    extends State<CaregiverPermissionsScreen> {
  late List<CaregiverPermission> _permissions;

  @override
  void initState() {
    super.initState();
    _permissions = caregiverPermissionsSeed;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Caregiver Controls'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: KinsuTheme.cardDecoration,
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: widget.member.color.withOpacity(0.15),
                  child: Text(
                    widget.member.avatar,
                    style: TextStyle(
                      color: widget.member.color,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.member.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      '${widget.member.relation} · ${widget.member.age} years · ${widget.member.blood}',
                      style: const TextStyle(
                        color: KinsuTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Container(
            decoration: KinsuTheme.cardDecoration,
            child: Column(
              children: _permissions.asMap().entries.map((entry) {
                final index = entry.key;
                final permission = entry.value;
                return Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    border: index == _permissions.length - 1
                        ? null
                        : Border(
                            bottom: BorderSide(
                              color: KinsuTheme.divider.withOpacity(0.6),
                            ),
                          ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              permission.action,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              permission.description,
                              style: const TextStyle(
                                color: KinsuTheme.textSecondary,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: permission.enabled,
                        onChanged: (value) {
                          setState(() {
                            _permissions[index] =
                                permission.copyWith(enabled: value);
                          });
                        },
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: const Text(
              'Consent Required: Permission updates require confirmation from the patient. OTP confirmation is recommended.',
              style: TextStyle(
                color: Color(0xFF92400E),
                fontSize: 12,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Permissions saved')),
              );
            },
            child: const Text('Save Permissions'),
          ),
        ],
      ),
    );
  }
}
