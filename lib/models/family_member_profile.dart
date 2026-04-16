class FamilyMemberProfile {
  final int id;
  final String displayName;
  final String phoneE164;
  final String? relation;
  final DateTime? dateOfBirth;
  final String? bloodGroup;
  final List<String> healthConditions;
  final String? notes;
  final bool isActive;

  const FamilyMemberProfile({
    required this.id,
    required this.displayName,
    required this.phoneE164,
    this.relation,
    this.dateOfBirth,
    this.bloodGroup,
    this.healthConditions = const [],
    this.notes,
    required this.isActive,
  });

  factory FamilyMemberProfile.fromJson(Map<String, dynamic> json) {
    return FamilyMemberProfile(
      id: json['id'] as int,
      displayName: json['display_name'] as String,
      phoneE164: json['phone_e164'] as String,
      relation: json['relation'] as String?,
      dateOfBirth: json['date_of_birth'] != null
          ? DateTime.parse(json['date_of_birth'] as String)
          : null,
      bloodGroup: json['blood_group'] as String?,
      healthConditions:
          (json['health_conditions'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      notes: json['notes'] as String?,
      isActive: json['is_active'] as bool? ?? true,
    );
  }
}

class AccountProfileOption {
  final String profileType;
  final int? profileId;
  final String displayName;
  final String? subtitle;

  const AccountProfileOption({
    required this.profileType,
    required this.profileId,
    required this.displayName,
    this.subtitle,
  });

  bool get isSelf => profileType == 'self';

  factory AccountProfileOption.fromJson(Map<String, dynamic> json) {
    return AccountProfileOption(
      profileType: json['profile_type'] as String,
      profileId: json['profile_id'] as int?,
      displayName: json['display_name'] as String,
      subtitle: json['subtitle'] as String?,
    );
  }
}

class FamilyDashboardCard {
  final String profileType;
  final int? profileId;
  final String displayName;
  final String relation;
  final int? age;
  final String? bloodGroup;
  final String initials;
  final List<String> healthConditions;
  final int recordCount;
  final int medicationCount;
  final String lastActivity;
  final bool isActiveContext;

  const FamilyDashboardCard({
    required this.profileType,
    required this.profileId,
    required this.displayName,
    required this.relation,
    required this.age,
    required this.bloodGroup,
    required this.initials,
    required this.healthConditions,
    required this.recordCount,
    required this.medicationCount,
    required this.lastActivity,
    required this.isActiveContext,
  });

  bool get isSelf => profileType == 'self';

  factory FamilyDashboardCard.fromJson(Map<String, dynamic> json) {
    return FamilyDashboardCard(
      profileType: json['profile_type'] as String? ?? 'family_member',
      profileId: json['profile_id'] as int?,
      displayName: json['display_name'] as String? ?? '',
      relation: json['relation'] as String? ?? 'Family',
      age: json['age'] as int?,
      bloodGroup: json['blood_group'] as String?,
      initials: json['initials'] as String? ?? 'U',
      healthConditions:
          (json['health_conditions'] as List<dynamic>? ?? const [])
              .map((item) => item.toString())
              .toList(),
      recordCount: json['record_count'] as int? ?? 0,
      medicationCount: json['medication_count'] as int? ?? 0,
      lastActivity: json['last_activity'] as String? ?? 'Profile created',
      isActiveContext: json['is_active_context'] as bool? ?? false,
    );
  }
}
