class UserProfile {
  final int id;
  final String firebaseUid;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final String? gender;
  final DateTime? dateOfBirth;
  final int? age;
  final String? bloodGroup;
  final double? heightCm;
  final double? weightKg;
  final String? profession;
  final List<String> healthGoals;
  final DateTime? consentAcceptedAt;
  final DateTime? onboardingCompletedAt;
  final String? authProvider;
  final DateTime? lastLoginAt;

  const UserProfile({
    required this.id,
    required this.firebaseUid,
    required this.email,
    required this.displayName,
    required this.photoUrl,
    required this.gender,
    required this.dateOfBirth,
    required this.age,
    required this.bloodGroup,
    required this.heightCm,
    required this.weightKg,
    required this.profession,
    required this.healthGoals,
    required this.consentAcceptedAt,
    required this.onboardingCompletedAt,
    required this.authProvider,
    required this.lastLoginAt,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      return DateTime.tryParse(value.toString());
    }

    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return UserProfile(
      id: json['id'] as int,
      firebaseUid: (json['firebase_uid'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      displayName: json['display_name'] as String?,
      photoUrl: json['photo_url'] as String?,
      gender: json['gender'] as String?,
      dateOfBirth: parseDate(json['date_of_birth']),
      age: json['age'] as int?,
      bloodGroup: json['blood_group'] as String?,
      heightCm: parseDouble(json['height_cm']),
      weightKg: parseDouble(json['weight_kg']),
      profession: json['profession'] as String?,
      healthGoals: (json['health_goals'] as List<dynamic>? ?? const [])
          .map((e) => e.toString())
          .toList(),
      consentAcceptedAt: parseDate(json['consent_accepted_at']),
      onboardingCompletedAt: parseDate(json['onboarding_completed_at']),
      authProvider: json['auth_provider'] as String?,
      lastLoginAt: parseDate(json['last_login_at']),
    );
  }

  static UserProfile fromProfileResponse(Map<String, dynamic> json) {
    final userJson = json['user'] as Map<String, dynamic>? ?? const {};
    return UserProfile.fromJson(userJson);
  }
}
