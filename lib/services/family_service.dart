import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../models/family_member_profile.dart';

class FamilyService {
  final Dio _dio;

  FamilyService(this._dio);

  Future<List<FamilyMemberProfile>> listMembers({
    bool includeInactive = false,
  }) async {
    final response = await _dio.get(
      ApiConstants.familyMembers,
      queryParameters: {
        'include_inactive': includeInactive,
      },
    );

    return (response.data as List)
        .map((item) => FamilyMemberProfile.fromJson(item))
        .toList();
  }

  Future<FamilyMemberProfile> addMember({
    required String displayName,
    required String phoneE164,
    String? relation,
    DateTime? dateOfBirth,
    String? bloodGroup,
    List<String>? healthConditions,
    String? notes,
  }) async {
    final response = await _dio.post(
      ApiConstants.familyMembers,
      data: {
        'display_name': displayName,
        'phone_e164': phoneE164,
        if (relation != null && relation.isNotEmpty) 'relation': relation,
        if (dateOfBirth != null)
          'date_of_birth':
              '${dateOfBirth.year.toString().padLeft(4, '0')}-${dateOfBirth.month.toString().padLeft(2, '0')}-${dateOfBirth.day.toString().padLeft(2, '0')}',
        if (bloodGroup != null && bloodGroup.isNotEmpty)
          'blood_group': bloodGroup,
        if (healthConditions != null && healthConditions.isNotEmpty)
          'health_conditions': healthConditions,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );

    return FamilyMemberProfile.fromJson(response.data);
  }

  Future<List<AccountProfileOption>> listProfiles() async {
    final response = await _dio.get(ApiConstants.familyProfiles);
    return (response.data as List)
        .map((item) => AccountProfileOption.fromJson(item))
        .toList();
  }

  Future<List<FamilyDashboardCard>> fetchDashboard() async {
    final response = await _dio.get(ApiConstants.familyDashboard);
    return (response.data as List<dynamic>)
        .map((item) =>
            FamilyDashboardCard.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
