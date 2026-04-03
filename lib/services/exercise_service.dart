import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../models/activity_models.dart';

class ExerciseService {
  final Dio _dio;

  ExerciseService(this._dio);

  Future<List<ActivityCatalogSection>> fetchCatalog() async {
    final response = await _dio.get(ApiConstants.exerciseCatalog);
    return (response.data as List<dynamic>)
        .map((item) =>
            ActivityCatalogSection.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<ActivityLogItem>> fetchLogs() async {
    final response = await _dio.get(ApiConstants.exerciseLogs);
    return (response.data as List<dynamic>)
        .map((item) => ActivityLogItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<ActivitySummaryData> fetchSummary() async {
    final response = await _dio.get(ApiConstants.exerciseSummary);
    return ActivitySummaryData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ActivityHistoryData> fetchHistory() async {
    final response = await _dio.get(ApiConstants.exerciseHistory);
    return ActivityHistoryData.fromJson(response.data as Map<String, dynamic>);
  }

  Future<ActivityRecommendationsData> fetchRecommendations() async {
    final response = await _dio.get(ApiConstants.exerciseRecommendations);
    return ActivityRecommendationsData.fromJson(
      response.data as Map<String, dynamic>,
    );
  }

  Future<ActivityLogItem> logActivity({
    required String category,
    required String activityName,
    required int durationMinutes,
    double? distanceKm,
    int? caloriesBurned,
    Map<String, dynamic>? details,
  }) async {
    final response = await _dio.post(
      ApiConstants.exerciseLogs,
      data: {
        'category': category,
        'activity_name': activityName,
        'duration_minutes': durationMinutes,
        if (distanceKm != null) 'distance_km': distanceKm,
        if (caloriesBurned != null) 'calories_burned': caloriesBurned,
        if (details != null && details.isNotEmpty) 'details': details,
      },
    );
    return ActivityLogItem.fromJson(response.data as Map<String, dynamic>);
  }
}
