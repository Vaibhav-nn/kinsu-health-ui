import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/network/dio_client.dart';
import '../../models/user_profile.dart';
import '../../providers/health_sync_provider.dart';
import '../../screens/settings/health_connect_settings_screen.dart';
import '../../screens/shell/main_shell.dart';
import '../../services/auth_service.dart';
import 'auth_flow.dart';
import 'profile_setup_flow.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final Dio _dio;
  late final AuthService _authService;

  String? _sessionUid;
  Future<_SessionResolution>? _sessionFuture;
  bool _pendingHCSheet = false;

  @override
  void initState() {
    super.initState();
    _dio = DioClient.create(baseUrl: ApiConstants.baseUrl);
    _authService = AuthService(_dio);
  }

  Future<_SessionResolution> _resolveSession() async {
    final loginProfile = await _authService.loginBootstrap();
    final profile = await _authService.getProfile();
    final resolved = profile.id > 0 ? profile : loginProfile;
    return _SessionResolution(
      profile: resolved,
      needsOnboarding: resolved.onboardingCompletedAt == null,
    );
  }

  void _refreshSession({bool showHCSheet = false}) {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return;
    setState(() {
      _sessionUid = current.uid;
      _sessionFuture = _resolveSession();
      _pendingHCSheet = showHCSheet;
    });
  }

  void _maybeShowHCSheet() {
    if (!_pendingHCSheet) return;
    _pendingHCSheet = false;
    final hsp = context.read<HealthSyncProvider>();
    if (!hsp.isAvailable) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _HCOnboardingSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Authentication failed to initialize.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          );
        }

        final firebaseUser = snapshot.data;
        if (firebaseUser == null) {
          _sessionUid = null;
          _sessionFuture = null;
          return const AuthFlow();
        }

        if (_sessionFuture == null || _sessionUid != firebaseUser.uid) {
          _sessionUid = firebaseUser.uid;
          _sessionFuture = _resolveSession();
        }

        return FutureBuilder<_SessionResolution>(
          future: _sessionFuture,
          builder: (context, sessionSnapshot) {
            if (sessionSnapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }

            if (sessionSnapshot.hasError || sessionSnapshot.data == null) {
              return Scaffold(
                body: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.error_outline,
                            size: 44, color: Colors.redAccent),
                        const SizedBox(height: 10),
                        Text(
                          'Session setup failed: ${sessionSnapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _refreshSession,
                          child: const Text('Retry'),
                        ),
                        TextButton(
                          onPressed: () => FirebaseAuth.instance.signOut(),
                          child: const Text('Sign Out'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }

            final resolution = sessionSnapshot.data!;
            if (resolution.needsOnboarding) {
              return ProfileSetupFlow(
                authService: _authService,
                initialProfile: resolution.profile,
                onCompleted: () => _refreshSession(showHCSheet: true),
              );
            }

            // Profile is complete — go to the main shell.
            // If we're coming from onboarding, show the HC sheet on first frame.
            if (_pendingHCSheet) {
              WidgetsBinding.instance.addPostFrameCallback((_) => _maybeShowHCSheet());
            }
            return const MainShell();
          },
        );
      },
    );
  }
}

class _SessionResolution {
  final UserProfile profile;
  final bool needsOnboarding;

  const _SessionResolution({
    required this.profile,
    required this.needsOnboarding,
  });
}

// ── Health Connect onboarding sheet ──────────────────────────────────────────

class _HCOnboardingSheet extends StatelessWidget {
  const _HCOnboardingSheet();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(Icons.health_and_safety_outlined,
                color: Color(0xFF3B82F6), size: 30),
          ),
          const SizedBox(height: 16),
          const Text(
            'Connect Health Connect',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Auto-sync your steps, heart rate, and workouts '
            'directly into Kinsu — no manual logging needed.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF6B7280),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 6),
          const _HCBullet(icon: Icons.directions_walk, text: 'Steps & activity'),
          const _HCBullet(icon: Icons.favorite_outline, text: 'Heart rate & SpO₂'),
          const _HCBullet(icon: Icons.fitness_center_outlined, text: 'Workouts & sleep'),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const HealthConnectSettingsScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Set up Health Connect'),
            ),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Maybe later',
              style: TextStyle(color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }
}

class _HCBullet extends StatelessWidget {
  final IconData icon;
  final String text;

  const _HCBullet({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: const Color(0xFF3B82F6)),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF374151),
            ),
          ),
        ],
      ),
    );
  }
}
