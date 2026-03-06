import 'package:dio/dio.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Dio [Interceptor] that automatically attaches the current Firebase
/// user's ID token to every outgoing request.
class FirebaseAuthInterceptor extends Interceptor {
  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user != null) {
        final idToken = await user.getIdToken(true);
        options.headers['Authorization'] = 'Bearer $idToken';
      }
    } catch (e) {
      print('⚠️ FirebaseAuthInterceptor: failed to get ID token — $e');
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      print('🔒 Received 401 — user should re-authenticate.');
    }

    handler.next(err);
  }
}
