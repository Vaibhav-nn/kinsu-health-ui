import 'package:dio/dio.dart';

import 'profile_context.dart';

class ProfileContextInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final profileId = ProfileContext.activeFamilyProfileId;
    if (profileId == null) {
      options.headers.remove('X-Profile-Id');
    } else {
      options.headers['X-Profile-Id'] = '$profileId';
    }
    handler.next(options);
  }
}
