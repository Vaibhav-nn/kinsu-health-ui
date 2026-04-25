import 'dart:math' show min;

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Automatically retries idempotent requests on transient network failures.
///
/// Retries up to [maxRetries] times with exponential back-off:
///   attempt 1 → 500 ms delay
///   attempt 2 → 1 000 ms delay
///   (capped at [maxDelay])
///
/// Only retries on:
///   • Connection / timeout errors (no response received)
///   • 429 Too Many Requests (honours Retry-After header if present)
///   • 502, 503, 504 gateway errors
///
/// Never retries:
///   • POST / PATCH / PUT with a body (non-idempotent) — unless the caller
///     sets the extra option `retryOnPost: true`.
///   • 4xx client errors (except 429).
///   • Cancelled requests.
class RetryInterceptor extends Interceptor {
  final Dio dio;
  final int maxRetries;
  final Duration maxDelay;

  RetryInterceptor({
    required this.dio,
    this.maxRetries = 2,
    this.maxDelay = const Duration(seconds: 4),
  });

  static const _retryCountKey = '_retryCount';

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final options = err.requestOptions;

    // Never retry cancelled requests.
    if (err.type == DioExceptionType.cancel) {
      return handler.next(err);
    }

    // Don't retry non-idempotent methods unless explicitly opted in.
    final method = options.method.toUpperCase();
    final isIdempotent = method == 'GET' || method == 'HEAD' || method == 'DELETE';
    final forceRetry = options.extra['retryOnPost'] == true;
    if (!isIdempotent && !forceRetry) {
      return handler.next(err);
    }

    // Check if this is a retryable error.
    final statusCode = err.response?.statusCode;
    final isTransient = err.type == DioExceptionType.connectionError ||
        err.type == DioExceptionType.connectionTimeout ||
        err.type == DioExceptionType.receiveTimeout ||
        err.type == DioExceptionType.sendTimeout ||
        statusCode == 429 ||
        statusCode == 502 ||
        statusCode == 503 ||
        statusCode == 504;

    if (!isTransient) return handler.next(err);

    // Track retry count in the request extras.
    final retryCount = (options.extra[_retryCountKey] as int? ?? 0) + 1;
    if (retryCount > maxRetries) return handler.next(err);

    // Exponential back-off: 500ms * 2^(attempt-1), capped at maxDelay.
    final delay = min(
      Duration(milliseconds: 500 * (1 << (retryCount - 1))).inMilliseconds,
      maxDelay.inMilliseconds,
    );

    // Honour Retry-After header for 429 responses.
    int waitMs = delay;
    final retryAfter = err.response?.headers.value('retry-after');
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null) waitMs = seconds * 1000;
    }

    debugPrint(
      '⟳ RetryInterceptor: attempt $retryCount/$maxRetries '
      'for ${options.method} ${options.path} '
      '(status: $statusCode) — waiting ${waitMs}ms',
    );

    await Future<void>.delayed(Duration(milliseconds: waitMs));

    options.extra[_retryCountKey] = retryCount;

    try {
      final response = await dio.fetch<dynamic>(options);
      return handler.resolve(response);
    } on DioException catch (e) {
      return handler.next(e);
    }
  }
}
