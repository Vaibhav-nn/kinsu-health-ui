import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/ai/ai_chat_screen.dart';
import '../screens/ai/ai_screen.dart';
import '../screens/auth/auth_gate.dart';
import '../screens/family/add_family_member_screen.dart';
import '../screens/family/family_screen.dart';
import '../screens/home/exercise_screen.dart';
import '../screens/home/home_screen.dart';
import '../screens/home/notifications_screen.dart';
import '../screens/home/profile_screen.dart';
import '../screens/shell/main_shell.dart';
import '../screens/track/illness/illness_detail_screen.dart';
import '../screens/track/illness/illness_list_screen.dart';
import '../screens/track/medications/add_medication_screen.dart';
import '../screens/track/medications/medications_list_screen.dart';
import '../screens/track/reminders/add_reminder_screen.dart';
import '../screens/track/reminders/reminders_timeline_screen.dart';
import '../screens/track/symptoms/add_symptom_screen.dart';
import '../screens/track/symptoms/quick_symptom_log_screen.dart';
import '../screens/track/symptoms/symptoms_list_screen.dart';
import '../screens/track/track_home.dart';
import '../screens/track/vitals/log_vital_screen.dart';
import '../screens/track/vitals/vitals_trends_screen.dart';
import '../screens/upload_record_screen.dart';
import '../screens/vault/lab_parameter_trends_screen.dart';
import '../screens/vault_screen.dart';
import 'constants.dart';

/// Named route paths — import these throughout the app instead of hard-coding strings.
class KinsuRoutes {
  KinsuRoutes._();

  static const auth = '/auth';

  // ── Tabs ──────────────────────────────────────────────────────────────────
  static const home = '/';
  static const track = '/track';
  static const vault = '/vault';
  static const family = '/family';
  static const ai = '/ai';

  // ── Home sub-routes ───────────────────────────────────────────────────────
  static const notifications = '/notifications';
  static const profile = '/profile';
  static const exercise = '/exercise';

  // ── Track sub-routes ──────────────────────────────────────────────────────
  static const vitals = '/track/vitals';
  static const vitalLog = '/track/vitals/log';
  static const symptoms = '/track/symptoms';
  static const symptomsAdd = '/track/symptoms/add';
  static const symptomsQuick = '/track/symptoms/quick';
  static const medications = '/track/medications';
  static const medicationsAdd = '/track/medications/add';
  static const reminders = '/track/reminders';
  static const remindersAdd = '/track/reminders/add';
  static const illness = '/track/illness';
  // illness/:id — build dynamically: '/track/illness/$episodeId'

  // ── Vault sub-routes ──────────────────────────────────────────────────────
  static const vaultUpload = '/vault/upload';
  // vault/lab/:key — build dynamically: '/vault/lab/$paramKey'

  // ── Family sub-routes ─────────────────────────────────────────────────────
  static const familyAdd = '/family/add';

  // ── AI sub-routes ─────────────────────────────────────────────────────────
  static const aiChat = '/ai/chat';
}

/// Branch indices inside the StatefulShellRoute — keep in sync with branches list.
class _Branch {
  static const home = 0;
  static const track = 1;
  static const vault = 2;
  static const family = 3;
  static const ai = 4;
}

/// All 5 tab paths, indexed by branch index.
const _branchPaths = [
  KinsuRoutes.home,
  KinsuRoutes.track,
  KinsuRoutes.vault,
  KinsuRoutes.family,
  KinsuRoutes.ai,
];

/// Mobile bottom-nav has 4 items: Home(0) Track(1) Vault(2) AI(3).
/// Maps a mobile tap index → branch index.
int mobileNavToBranch(int navIndex) {
  const map = [_Branch.home, _Branch.track, _Branch.vault, _Branch.ai];
  return map[navIndex];
}

/// Inverse: branch index → mobile nav indicator index.
/// Family (branch 3) is not in the mobile nav — returns −1.
int branchToMobileNav(int branchIndex) {
  const map = <int, int>{
    _Branch.home: 0,
    _Branch.track: 1,
    _Branch.vault: 2,
    _Branch.ai: 3,
  };
  return map[branchIndex] ?? -1;
}

/// Application-level GoRouter.
///
/// Auth behaviour:
///   DISABLE_AUTH=true  — skips all auth checks; no Firebase calls.
///   Normal mode        — redirect to /auth when no Firebase user; refresh on
///                        auth-state changes via [_AuthChangeNotifier].
///
/// Onboarding: handled inside AuthGate (async profile check). The router only
/// guards unauthenticated access; onboarding redirect is driven by AuthGate
/// calling context.go(KinsuRoutes.home) after the check completes.
final GoRouter appRouter = GoRouter(
  // Start at home for authenticated/no-auth builds; /auth for fresh installs.
  initialLocation: (!AppFlags.disableAuth &&
          FirebaseAuth.instance.currentUser == null)
      ? KinsuRoutes.auth
      : KinsuRoutes.home,
  refreshListenable: AppFlags.disableAuth
      ? null
      : _AuthChangeNotifier(FirebaseAuth.instance.authStateChanges()),
  redirect: (context, state) {
    if (AppFlags.disableAuth) return null;

    final user = FirebaseAuth.instance.currentUser;
    final onAuth = state.matchedLocation.startsWith(KinsuRoutes.auth);

    // Unauthenticated user trying to access a protected route → send to auth.
    if (user == null && !onAuth) return KinsuRoutes.auth;

    // Authenticated users on /auth: let AuthGate drive the navigation after
    // its async onboarding check — do NOT redirect here to avoid skipping
    // the ProfileSetupFlow for first-time users.
    return null;
  },
  routes: [
    // ── Auth (login + onboarding) ────────────────────────────────────────────
    GoRoute(
      path: KinsuRoutes.auth,
      builder: (context, state) => const AuthGate(),
    ),

    // ── Main shell (5 tabs) ──────────────────────────────────────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        // ── Branch 0: Home ───────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: _branchPaths[_Branch.home],
              builder: (_, __) => const HomeScreen(),
              routes: [
                GoRoute(
                  path: 'notifications',
                  builder: (_, __) => const NotificationsScreen(),
                ),
                GoRoute(
                  path: 'profile',
                  builder: (_, __) => const ProfileScreen(),
                ),
                GoRoute(
                  path: 'exercise',
                  builder: (_, __) => const ExerciseScreen(),
                ),
              ],
            ),
          ],
        ),

        // ── Branch 1: Track ──────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: _branchPaths[_Branch.track],
              builder: (_, __) => const TrackHome(),
              routes: [
                GoRoute(
                  path: 'vitals',
                  builder: (_, __) => const VitalsTrendsScreen(),
                ),
                GoRoute(
                  path: 'vitals/log',
                  builder: (_, __) => const LogVitalScreen(),
                ),
                GoRoute(
                  path: 'symptoms',
                  builder: (_, __) => const SymptomsListScreen(),
                ),
                GoRoute(
                  path: 'symptoms/add',
                  builder: (_, __) => const AddSymptomScreen(),
                ),
                GoRoute(
                  path: 'symptoms/quick',
                  builder: (_, __) => const QuickSymptomLogScreen(),
                ),
                GoRoute(
                  path: 'medications',
                  builder: (_, __) => const MedicationsListScreen(),
                ),
                GoRoute(
                  path: 'medications/add',
                  builder: (_, __) => const AddMedicationScreen(),
                ),
                GoRoute(
                  path: 'reminders',
                  builder: (_, __) => const RemindersTimelineScreen(),
                ),
                GoRoute(
                  path: 'reminders/add',
                  builder: (_, __) => const AddReminderScreen(),
                ),
                GoRoute(
                  path: 'illness',
                  builder: (_, __) => const IllnessListScreen(),
                ),
                GoRoute(
                  path: 'illness/:id',
                  builder: (_, state) => IllnessDetailScreen(
                    episodeId: int.tryParse(
                            state.pathParameters['id'] ?? '') ??
                        0,
                  ),
                ),
              ],
            ),
          ],
        ),

        // ── Branch 2: Vault ──────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: _branchPaths[_Branch.vault],
              builder: (_, __) => const VaultScreen(),
              routes: [
                GoRoute(
                  path: 'upload',
                  builder: (_, __) => const UploadRecordScreen(),
                ),
                GoRoute(
                  path: 'lab/:key',
                  builder: (_, state) => LabParameterTrendsScreen(
                    initialParameterKey:
                        state.pathParameters['key'] ?? 'hemoglobin',
                  ),
                ),
              ],
            ),
          ],
        ),

        // ── Branch 3: Family ─────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: _branchPaths[_Branch.family],
              builder: (_, __) => const FamilyScreen(),
              routes: [
                GoRoute(
                  path: 'add',
                  builder: (_, __) => const AddFamilyMemberScreen(),
                ),
              ],
            ),
          ],
        ),

        // ── Branch 4: AI ─────────────────────────────────────────────────────
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: _branchPaths[_Branch.ai],
              builder: (_, __) => const AiScreen(),
              routes: [
                GoRoute(
                  path: 'chat',
                  builder: (_, __) => const AiChatScreen(),
                ),
              ],
            ),
          ],
        ),
      ],
    ),
  ],
);

/// ChangeNotifier that fires whenever the Firebase auth state changes.
/// go_router uses this to re-evaluate the redirect guard.
class _AuthChangeNotifier extends ChangeNotifier {
  _AuthChangeNotifier(Stream<User?> authStream) {
    _subscription = authStream.listen((_) => notifyListeners());
  }

  late final StreamSubscription<User?> _subscription;

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}
