import 'package:flutter/foundation.dart';

import '../core/error_formatter.dart';
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

  List<FamilyDashboardCard> _dashboardCards = [];
  List<FamilyDashboardCard> get dashboardCards => _dashboardCards;

  int? _activeFamilyProfileId;
  int? get activeFamilyProfileId => _activeFamilyProfileId;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  FamilyDashboardCard? get activeDashboardCard {
    for (final card in _dashboardCards) {
      if (_activeFamilyProfileId == null && card.isSelf) {
        return card;
      }
      if (_activeFamilyProfileId != null &&
          card.profileId == _activeFamilyProfileId) {
        return card;
      }
    }
    return _dashboardCards.isNotEmpty ? _dashboardCards.first : null;
  }

  Future<void> loadFamilyData() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _members = await _service.listMembers();
      _profiles = await _service.listProfiles();
      _dashboardCards = await _service.fetchDashboard();
      final hasCurrent =
          _profiles.any((p) => p.profileId == _activeFamilyProfileId);
      if (!hasCurrent) {
        _activeFamilyProfileId = null;
        ProfileContext.setActiveFamilyProfileId(null);
      }
    } catch (e) {
      _error = formatProviderError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addMember({
    required String displayName,
    required String phoneE164,
    String? relation,
    DateTime? dateOfBirth,
    String? bloodGroup,
    List<String>? healthConditions,
    String? notes,
  }) async {
    try {
      await _service.addMember(
        displayName: displayName,
        phoneE164: phoneE164,
        relation: relation,
        dateOfBirth: dateOfBirth,
        bloodGroup: bloodGroup,
        healthConditions: healthConditions,
        notes: notes,
      );
      await loadFamilyData();
      return true;
    } catch (e) {
      _error = formatProviderError(e);
      notifyListeners();
      return false;
    }
  }

  void setActiveProfileId(int? profileId) {
    _activeFamilyProfileId = profileId;
    ProfileContext.setActiveFamilyProfileId(profileId);
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
}
