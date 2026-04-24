import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/constants.dart';
import '../../core/network/dio_client.dart';
import '../../models/user_profile.dart';
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

  void _refreshSession() {
    final current = FirebaseAuth.instance.currentUser;
    if (current == null) return;
    setState(() {
      _sessionUid = current.uid;
      _sessionFuture = _resolveSession();
    });
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
                onCompleted: _refreshSession,
              );
            }

            // Profile is complete — go to the main shell.
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
