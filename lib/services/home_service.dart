import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../models/home_models.dart';

class HomeService {
  final Dio _dio;

  HomeService(this._dio);

  Future<HomeOverviewData> fetchOverview() async {
    final response = await _dio.get(ApiConstants.homescreenOverview);
    return HomeOverviewData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<HomeDashboardData> fetchDashboard() async {
    final response = await _dio.get(ApiConstants.homescreenDashboard);
    return HomeDashboardData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<List<HomeNotificationItem>> fetchNotifications() async {
    final response = await _dio.get(ApiConstants.homescreenNotifications);
    return (response.data as List<dynamic>)
        .map((item) =>
            HomeNotificationItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<HomeSearchResultItemData>> search(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const [];
    }
    final response = await _dio.get(
      ApiConstants.homescreenSearch,
      queryParameters: {'q': trimmed},
    );
    final results = response.data['results'] as List<dynamic>? ?? const [];
    return results
        .map((item) =>
            HomeSearchResultItemData.fromJson(item as Map<String, dynamic>))
        .toList();
  }
}
