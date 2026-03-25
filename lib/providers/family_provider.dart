import 'package:flutter/foundation.dart';

import '../core/network/profile_context.dart';
import '../models/family_member_profile.dart';
import '../services/family_service.dart';

class FamilyProvider extends ChangeNotifier {
  final FamilyService _service;

  FamilyProvider(this._service);

  List<FamilyMemberProfile> _members = [];
  List<FamilyMemberProfile> get members => _members;

  List<AccountProfileOption> _profiles = [];
  List<AccountProfileOption> get profiles => _profiles;

  int? _activeFamilyProfileId;
  int? get activeFamilyProfileId => _activeFamilyProfileId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadFamilyData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _members = await _service.listMembers();
      _profiles = await _service.listProfiles();
      final hasCurrent =
          _profiles.any((p) => p.profileId == _activeFamilyProfileId);
      if (!hasCurrent) {
        _activeFamilyProfileId = null;
        ProfileContext.setActiveFamilyProfileId(null);
      }
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addMember({
    required String displayName,
    required String phoneE164,
    String? relation,
    DateTime? dateOfBirth,
    String? notes,
  }) async {
    try {
      await _service.addMember(
        displayName: displayName,
        phoneE164: phoneE164,
        relation: relation,
        dateOfBirth: dateOfBirth,
        notes: notes,
      );
      await loadFamilyData();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  void setActiveProfileId(int? profileId) {
    _activeFamilyProfileId = profileId;
    ProfileContext.setActiveFamilyProfileId(profileId);
    notifyListeners();
  }
}
