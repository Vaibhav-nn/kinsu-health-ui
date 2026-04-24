/// Routing constants and helpers for Kinsu Health.
/// Navigation is handled via Navigator.push (no go_router dependency).
class KinsuRoutes {
  KinsuRoutes._();

  static const String home = '/';
  static const String track = '/track';
  static const String vault = '/vault';
  static const String vaultUpload = '/vault/upload';
  static const String family = '/family';
  static const String ai = '/ai';
  static const String profile = '/profile';
  static const String healthConnect = '/health-connect';
  static const String trackVitals = '/track/vitals';
  static const String trackReminders = '/track/reminders';
}

/// Internal branch indices — keep in sync with MainShell._pages order.
// ignore: unused_element
class _Branch {
  _Branch._();

  static const int home = 0;
  static const int track = 1;
  static const int vault = 2;
  static const int family = 3;
  // AI (index 4) is not in the mobile nav but is accessible via the center FAB.
  static const int ai = 4; // ignore: unused_field
}

/// Maps mobile nav index (0-3) to a branch index.
/// AI (branch 4) is not in the mobile nav.
int mobileNavToBranch(int navIndex) {
  const map = [_Branch.home, _Branch.track, _Branch.vault, _Branch.family];
  return map[navIndex];
}

/// Maps branch index back to mobile nav index, or -1 if not in nav.
int branchToMobileNav(int branchIndex) {
  const map = <int, int>{
    _Branch.home: 0,
    _Branch.track: 1,
    _Branch.vault: 2,
    _Branch.family: 3,
  };
  return map[branchIndex] ?? -1;
}
