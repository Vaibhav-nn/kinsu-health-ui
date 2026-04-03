import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../models/home_models.dart';

class HomeService {
  final Dio _dio;

  HomeService(this._dio);

  bool _isUserBootstrapError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final detail =
        data is Map<String, dynamic> ? data['detail']?.toString() ?? '' : '';
    return statusCode == 404 && detail.contains('User not found');
  }

  Future<void> _bootstrapUser() async {
    await _dio.post(ApiConstants.authLogin);
  }

  Future<T> _withBootstrapRetry<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on DioException catch (error) {
      if (_isUserBootstrapError(error)) {
        await _bootstrapUser();
        return await operation();
      }
      rethrow;
    }
  }

  Future<HomeOverviewData> fetchOverview() async {
    return _withBootstrapRetry(() async {
      final response = await _dio.get(ApiConstants.homescreenOverview);
      return HomeOverviewData.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<HomeDashboardData> fetchDashboard() async {
    return _withBootstrapRetry(() async {
      final response = await _dio.get(ApiConstants.homescreenDashboard);
      return HomeDashboardData.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<List<HomeNotificationItem>> fetchNotifications() async {
    return _withBootstrapRetry(() async {
      final response = await _dio.get(ApiConstants.homescreenNotifications);
      return (response.data as List<dynamic>)
          .map((item) =>
              HomeNotificationItem.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<HomeSearchResultItemData>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    return _withBootstrapRetry(() async {
      final response = await _dio.get(
        ApiConstants.homescreenSearch,
        queryParameters: {'q': trimmed},
      );
      final results = response.data['results'] as List<dynamic>? ?? const [];
      return results
          .map((item) =>
              HomeSearchResultItemData.fromJson(item as Map<String, dynamic>))
          .toList();
    });
  }
}
