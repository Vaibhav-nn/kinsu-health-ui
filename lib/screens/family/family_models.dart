import 'package:flutter/material.dart';

class FamilyMember {
  final String id;
  final String name;
  final String relation;
  final int age;
  final String blood;
  final String avatar;
  final Color color;
  final List<String> conditions;
  final String lastActivity;
  final int records;
  final int meds;

  const FamilyMember({
    required this.id,
    required this.name,
    required this.relation,
    required this.age,
    required this.blood,
    required this.avatar,
    required this.color,
    required this.conditions,
    required this.lastActivity,
    required this.records,
    required this.meds,
  });
}

const familyMembers = <FamilyMember>[
  FamilyMember(
    id: 'self',
    name: 'Priya Sharma',
    relation: 'Self',
    age: 34,
    blood: 'B+',
    avatar: 'PS',
    color: Color(0xFF009688),
    conditions: ['Pre-diabetes', 'Hypertension'],
    lastActivity: 'BP logged today',
    records: 24,
    meds: 4,
  ),
  FamilyMember(
    id: 'amma',
    name: 'Lakshmi Sharma',
    relation: 'Mother',
    age: 62,
    blood: 'A+',
    avatar: 'LS',
    color: Color(0xFF8B5CF6),
    conditions: ['Type 2 Diabetes', 'Thyroid'],
    lastActivity: 'Sugar logged yesterday',
    records: 18,
    meds: 6,
  ),
  FamilyMember(
    id: 'papa',
    name: 'Rajesh Sharma',
    relation: 'Father',
    age: 65,
    blood: 'O+',
    avatar: 'RS',
    color: Color(0xFF3B82F6),
    conditions: ['Hypertension', 'Cholesterol'],
    lastActivity: 'Medication taken today',
    records: 15,
    meds: 5,
  ),
];

class CaregiverPermission {
  final String action;
  final String description;
  final bool enabled;

  const CaregiverPermission({
    required this.action,
    required this.description,
    required this.enabled,
  });

  CaregiverPermission copyWith({bool? enabled}) {
    return CaregiverPermission(
      action: action,
      description: description,
      enabled: enabled ?? this.enabled,
    );
  }
}

const caregiverPermissionsSeed = <CaregiverPermission>[
  CaregiverPermission(
    action: 'View health records',
    description: 'Access uploaded documents and reports',
    enabled: true,
  ),
  CaregiverPermission(
    action: 'Log vitals',
    description: 'Record blood pressure, sugar, and other vitals',
    enabled: true,
  ),
  CaregiverPermission(
    action: 'Manage medications',
    description: 'Add or update medication schedules',
    enabled: true,
  ),
  CaregiverPermission(
    action: 'Log symptoms',
    description: 'Record symptoms on behalf of patient',
    enabled: true,
  ),
  CaregiverPermission(
    action: 'Receive SOS alerts',
    description: 'Get notified during emergency triggers',
    enabled: true,
  ),
  CaregiverPermission(
    action: 'View AI summaries',
    description: 'Access AI-generated health insights',
    enabled: false,
  ),
];
