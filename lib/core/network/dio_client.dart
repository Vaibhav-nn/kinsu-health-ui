import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'firebase_auth_interceptor.dart';
import 'profile_context_interceptor.dart';
import 'retry_interceptor.dart';

/// Factory class that creates and configures the [Dio] HTTP client
/// for communicating with the Kinsu Health backend.
class DioClient {
  DioClient._();

  /// Create a fully configured [Dio] instance.
  static Dio create({
    required String baseUrl,
    Duration connectTimeout = const Duration(seconds: 15),
    Duration receiveTimeout = const Duration(seconds: 15),
  }) {
    final dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: connectTimeout,
        receiveTimeout: receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // 1. Firebase Auth — attaches Bearer token when a user is signed in
    dio.interceptors.add(FirebaseAuthInterceptor());

    // 2. Profile context — attaches X-Profile-Id for family profile scope
    dio.interceptors.add(ProfileContextInterceptor());

    // 3. Retry — up to 2 retries with exponential backoff for transient errors
    dio.interceptors.add(RetryInterceptor(dio: dio));

    // 4. Logging — debug builds only (avoids leaking PHI/tokens in production logs)
    if (kDebugMode) {
      dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          logPrint: (obj) => debugPrint('🌐 DIO: $obj'),
        ),
      );
    }

    return dio;
  }
}
