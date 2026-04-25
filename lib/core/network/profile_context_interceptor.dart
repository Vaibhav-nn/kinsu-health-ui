import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;

import 'profile_context.dart';

class ProfileContextInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final profileId = ProfileContext.activeFamilyProfileId;
    if (profileId == null) {
      options.headers.remove('X-Profile-Id');
      debugPrint(
        'ℹ️  ProfileContextInterceptor: no active family profile — '
        'X-Profile-Id omitted for ${options.method} ${options.path}',
      );
    } else {
      options.headers['X-Profile-Id'] = '$profileId';
    }
    handler.next(options);
  }
}
