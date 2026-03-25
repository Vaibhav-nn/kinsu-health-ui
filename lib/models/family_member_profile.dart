class FamilyMemberProfile {
  final int id;
  final String displayName;
  final String phoneE164;
  final String? relation;
  final DateTime? dateOfBirth;
  final String? notes;
  final bool isActive;

  const FamilyMemberProfile({
    required this.id,
    required this.displayName,
    required this.phoneE164,
    this.relation,
    this.dateOfBirth,
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
