import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

import '../constants.dart';

/// Dio [Interceptor] that automatically attaches the current Firebase
/// user's ID token to every outgoing request.
class FirebaseAuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      if (AppFlags.disableAuth) {
        options.headers.remove('Authorization');
        handler.next(options);
        return;
      }

      if (Firebase.apps.isEmpty) {
        handler.next(options);
        return;
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        options.headers.remove('Authorization');
        handler.next(options);
        return;
      }

      final idToken = await user.getIdToken();
      if (idToken != null && idToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $idToken';
      } else {
        options.headers.remove('Authorization');
      }
    } catch (e) {
      options.headers.remove('Authorization');
      debugPrint('⚠️ FirebaseAuthInterceptor: failed to get ID token — $e');
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      debugPrint('🔒 Received 401 — user should re-authenticate.');
    }

    handler.next(err);
  }
}
