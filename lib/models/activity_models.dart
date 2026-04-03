class ActivityCatalogItem {
  final String category;
  final String activityName;
  final int estimatedCalories;
  final int durationMinutes;
  final List<String> fields;

  const ActivityCatalogItem({
    required this.category,
    required this.activityName,
    required this.estimatedCalories,
    required this.durationMinutes,
    required this.fields,
  });

  factory ActivityCatalogItem.fromJson(Map<String, dynamic> json) {
    return ActivityCatalogItem(
      category: (json['category'] ?? '') as String,
      activityName: (json['activity_name'] ?? '') as String,
      estimatedCalories: (json['estimated_calories'] ?? 0) as int,
      durationMinutes: (json['duration_minutes'] ?? 0) as int,
      fields: (json['fields'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class ActivityCatalogSection {
  final String category;
  final String title;
  final List<ActivityCatalogItem> items;

  const ActivityCatalogSection({
    required this.category,
    required this.title,
    required this.items,
  });

  factory ActivityCatalogSection.fromJson(Map<String, dynamic> json) {
    return ActivityCatalogSection(
      category: (json['category'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) =>
              ActivityCatalogItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ActivityLogItem {
  final int id;
  final String category;
  final String activityName;
  final int durationMinutes;
  final int caloriesBurned;
  final double? distanceKm;
  final Map<String, dynamic>? details;
  final DateTime loggedAt;

  const ActivityLogItem({
    required this.id,
    required this.category,
    required this.activityName,
    required this.durationMinutes,
    required this.caloriesBurned,
    required this.distanceKm,
    required this.details,
    required this.loggedAt,
  });

  factory ActivityLogItem.fromJson(Map<String, dynamic> json) {
    double? parseDouble(dynamic value) {
      if (value == null) return null;
      if (value is num) return value.toDouble();
      return double.tryParse(value.toString());
    }

    return ActivityLogItem(
      id: (json['id'] ?? 0) as int,
      category: (json['category'] ?? '') as String,
      activityName: (json['activity_name'] ?? '') as String,
      durationMinutes: (json['duration_minutes'] ?? 0) as int,
      caloriesBurned: (json['calories_burned'] ?? 0) as int,
      distanceKm: parseDouble(json['distance_km']),
      details: json['details'] as Map<String, dynamic>?,
      loggedAt: DateTime.tryParse(json['logged_at'].toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class ActivitySummaryData {
  final int calories;
  final int durationMinutes;
  final int activitiesDone;
  final List<ActivityLogItem> today;

  const ActivitySummaryData({
    required this.calories,
    required this.durationMinutes,
    required this.activitiesDone,
    required this.today,
  });

  factory ActivitySummaryData.fromJson(Map<String, dynamic> json) {
    return ActivitySummaryData(
      calories: (json['calories'] ?? 0) as int,
      durationMinutes: (json['duration_minutes'] ?? 0) as int,
      activitiesDone: (json['activities_done'] ?? 0) as int,
      today: (json['today'] as List<dynamic>? ?? const [])
          .map((item) => ActivityLogItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ActivityHistoryBarData {
  final String weekday;
  final int calories;

  const ActivityHistoryBarData({
    required this.weekday,
    required this.calories,
  });

  factory ActivityHistoryBarData.fromJson(Map<String, dynamic> json) {
    return ActivityHistoryBarData(
      weekday: (json['weekday'] ?? '') as String,
      calories: (json['calories'] ?? 0) as int,
    );
  }
}

class ActivityHistoryData {
  final List<ActivityHistoryBarData> weeklyCalories;
  final int activeDays;
  final int totalWeeklyCalories;

  const ActivityHistoryData({
    required this.weeklyCalories,
    required this.activeDays,
    required this.totalWeeklyCalories,
  });

  factory ActivityHistoryData.fromJson(Map<String, dynamic> json) {
    return ActivityHistoryData(
      weeklyCalories: (json['weekly_calories'] as List<dynamic>? ?? const [])
          .map((item) =>
              ActivityHistoryBarData.fromJson(item as Map<String, dynamic>))
          .toList(),
      activeDays: (json['active_days'] ?? 0) as int,
      totalWeeklyCalories: (json['total_weekly_calories'] ?? 0) as int,
    );
  }
}

class ActivityRecommendationItemData {
  final String title;
  final String subtitle;
  final int durationMinutes;
  final String recommendationReason;
  final String riskLevel;

  const ActivityRecommendationItemData({
    required this.title,
    required this.subtitle,
    required this.durationMinutes,
    required this.recommendationReason,
    required this.riskLevel,
  });

  factory ActivityRecommendationItemData.fromJson(Map<String, dynamic> json) {
    return ActivityRecommendationItemData(
      title: (json['title'] ?? '') as String,
      subtitle: (json['subtitle'] ?? '') as String,
      durationMinutes: (json['duration_minutes'] ?? 0) as int,
      recommendationReason: (json['recommendation_reason'] ?? '') as String,
      riskLevel: (json['risk_level'] ?? '') as String,
    );
  }
}

class ActivityRecommendationsData {
  final String summary;
  final List<ActivityRecommendationItemData> items;

  const ActivityRecommendationsData({
    required this.summary,
    required this.items,
  });

  factory ActivityRecommendationsData.fromJson(Map<String, dynamic> json) {
    return ActivityRecommendationsData(
      summary: (json['summary'] ?? '') as String,
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) => ActivityRecommendationItemData.fromJson(
              item as Map<String, dynamic>))
          .toList(),
    );
  }
}
