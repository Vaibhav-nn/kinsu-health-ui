import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../models/user_profile.dart';

class AuthService {
  final Dio _dio;

  AuthService(this._dio);

  Future<UserProfile> loginBootstrap() async {
    final response = await _dio.post(ApiConstants.authLogin);
    return UserProfile.fromProfileResponse(
        response.data as Map<String, dynamic>);
  }

  Future<UserProfile> getProfile() async {
    final response = await _dio.get(ApiConstants.authProfile);
    return UserProfile.fromProfileResponse(
        response.data as Map<String, dynamic>);
  }

  Future<UserProfile> acceptConsent() async {
    final response = await _dio.post(
      ApiConstants.authConsent,
      data: const {'accepted': true},
    );
    return UserProfile.fromProfileResponse(
        response.data as Map<String, dynamic>);
  }

  Future<UserProfile> updateProfile({
    String? displayName,
    String? gender,
    DateTime? dateOfBirth,
    String? bloodGroup,
    double? heightCm,
    double? weightKg,
    String? profession,
    List<String>? healthGoals,
    bool markOnboardingComplete = false,
  }) async {
    final payload = <String, dynamic>{
      if (displayName != null) 'display_name': displayName,
      if (gender != null) 'gender': gender,
      if (dateOfBirth != null)
        'date_of_birth': dateOfBirth.toIso8601String().split('T').first,
      if (bloodGroup != null) 'blood_group': bloodGroup,
      if (heightCm != null) 'height_cm': heightCm,
      if (weightKg != null) 'weight_kg': weightKg,
      if (profession != null) 'profession': profession,
      if (healthGoals != null) 'health_goals': healthGoals,
      'mark_onboarding_complete': markOnboardingComplete,
    };

    final response = await _dio.put(
      ApiConstants.authProfile,
      data: payload,
    );
    return UserProfile.fromProfileResponse(
        response.data as Map<String, dynamic>);
  }
}
