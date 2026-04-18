/// Shared error formatting utility for all providers.
///
/// Converts DioException, network errors, and generic exceptions into
/// user-friendly messages with consistent language across the app.
library;

import 'package:dio/dio.dart';

import 'constants.dart';

/// Returns a human-readable error message from any caught exception.
String formatProviderError(Object error) {
  if (error is DioException) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;

    String? detail;
    if (data is Map<String, dynamic>) {
      final rawDetail = data['detail'];
      if (rawDetail is String) {
        detail = rawDetail;
      } else if (rawDetail is List) {
        detail = rawDetail
            .map((item) => item is Map<String, dynamic>
                ? item['msg']?.toString() ?? item.toString()
                : item.toString())
            .join(', ');
      }
    } else if (data is String && data.trim().isNotEmpty) {
      detail = data.trim();
    }

    if (statusCode == 401) {
      return 'You are signed out. Please sign in again.';
    }
    if (statusCode == 403) {
      return 'You do not have permission to perform this action.';
    }
    if (statusCode == 404) {
      if (detail?.contains('User not found') ?? false) {
        return 'Your account is being set up. Please try again.';
      }
      return detail?.isNotEmpty == true ? detail! : 'The requested item was not found.';
    }
    if (statusCode == 422) {
      return detail == null || detail.isEmpty
          ? 'Please check your input and try again.'
          : 'Validation error: $detail';
    }
    if (statusCode == 429) {
      return 'Too many requests. Please wait a moment and try again.';
    }
    if (statusCode != null) {
      return detail == null || detail.isEmpty
          ? 'Request failed with status $statusCode.'
          : 'Request failed ($statusCode): $detail';
    }

    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.sendTimeout) {
      return 'Cannot reach server. Check your connection or ensure the app server is running.';
    }

    if (error.message?.contains('XMLHttpRequest') ?? false) {
      return 'Cannot reach server at ${ApiConstants.baseUrl}.';
    }
  }

  final msg = error.toString();
  if (msg.contains('connection error') ||
      msg.contains('Connection refused') ||
      msg.contains('Failed host lookup') ||
      msg.contains('XMLHttpRequest onError')) {
    return 'Cannot reach server at ${ApiConstants.baseUrl}. '
        'Please ensure the API server is running and reachable.';
  }

  return 'Something went wrong. Please try again.';
}
