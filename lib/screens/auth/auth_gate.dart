import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../shell/main_shell.dart';
import 'sign_in_page.dart';

/// Shows sign-in until FirebaseAuth reports a user session.
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
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

        if (snapshot.data == null) {
          return const SignInPage();
        }

        return const MainShell();
      },
    );
  }
}
