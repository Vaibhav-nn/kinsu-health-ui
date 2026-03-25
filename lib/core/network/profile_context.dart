class ProfileContext {
  ProfileContext._();

  static int? _activeFamilyProfileId;

  static int? get activeFamilyProfileId => _activeFamilyProfileId;

  static void setActiveFamilyProfileId(int? profileId) {
    _activeFamilyProfileId = profileId;
  }
}
