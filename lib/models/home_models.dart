class HomeTopBarProfileData {
  final String displayName;
  final String email;
  final String initials;

  const HomeTopBarProfileData({
    required this.displayName,
    required this.email,
    required this.initials,
  });

  factory HomeTopBarProfileData.fromJson(Map<String, dynamic> json) {
    return HomeTopBarProfileData(
      displayName: (json['display_name'] ?? '') as String,
      email: (json['email'] ?? '') as String,
      initials: (json['initials'] ?? 'U') as String,
    );
  }
}

class HomeOverviewData {
  final String searchPlaceholder;
  final int notificationUnreadCount;
  final String themeMode;
  final HomeTopBarProfileData profile;
  final String activeProfileType;
  final int? activeProfileId;
  final String? activeProfileLabel;

  const HomeOverviewData({
    required this.searchPlaceholder,
    required this.notificationUnreadCount,
    required this.themeMode,
    required this.profile,
    required this.activeProfileType,
    required this.activeProfileId,
    required this.activeProfileLabel,
  });

  factory HomeOverviewData.fromJson(Map<String, dynamic> json) {
    final topBar = json['top_bar'] as Map<String, dynamic>? ?? const {};
    return HomeOverviewData(
      searchPlaceholder: (topBar['search_placeholder'] ?? 'Search') as String,
      notificationUnreadCount:
          (topBar['notification_unread_count'] ?? 0) as int,
      themeMode: (topBar['theme_mode'] ?? 'system') as String,
      profile: HomeTopBarProfileData.fromJson(
        topBar['profile'] as Map<String, dynamic>? ?? const {},
      ),
      activeProfileType: (topBar['active_profile_type'] ?? 'self') as String,
      activeProfileId: topBar['active_profile_id'] as int?,
      activeProfileLabel: topBar['active_profile_label'] as String?,
    );
  }
}

class HomeNotificationItem {
  final int id;
  final String notificationType;
  final String category;
  final String priority;
  final String? sectionKey;
  final String? sectionLabel;
  final String title;
  final String body;
  final String? actionRoute;
  final String? primaryActionLabel;
  final String? secondaryActionLabel;
  final String? secondaryActionRoute;
  final Map<String, dynamic>? metadataJson;
  final bool isRead;
  final DateTime? readAt;
  final DateTime createdAt;

  const HomeNotificationItem({
    required this.id,
    required this.notificationType,
    required this.category,
    required this.priority,
    required this.sectionKey,
    required this.sectionLabel,
    required this.title,
    required this.body,
    required this.actionRoute,
    required this.primaryActionLabel,
    required this.secondaryActionLabel,
    required this.secondaryActionRoute,
    required this.metadataJson,
    required this.isRead,
    required this.readAt,
    required this.createdAt,
  });

  factory HomeNotificationItem.fromJson(Map<String, dynamic> json) {
    return HomeNotificationItem(
      id: (json['id'] ?? 0) as int,
      notificationType: (json['notification_type'] ?? 'general') as String,
      category: (json['category'] ?? 'general') as String,
      priority: (json['priority'] ?? 'normal') as String,
      sectionKey: json['section_key'] as String?,
      sectionLabel: json['section_label'] as String?,
      title: (json['title'] ?? '') as String,
      body: (json['body'] ?? '') as String,
      actionRoute: json['action_route'] as String?,
      primaryActionLabel: json['primary_action_label'] as String?,
      secondaryActionLabel: json['secondary_action_label'] as String?,
      secondaryActionRoute: json['secondary_action_route'] as String?,
      metadataJson: json['metadata_json'] is Map<String, dynamic>
          ? Map<String, dynamic>.from(json['metadata_json'] as Map)
          : null,
      isRead: json['is_read'] as bool? ?? false,
      readAt: json['read_at'] != null
          ? DateTime.tryParse(json['read_at'].toString())
          : null,
      createdAt: DateTime.tryParse(json['created_at'].toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class HomeAppointmentCardData {
  final int id;
  final String doctorName;
  final String? specialty;
  final DateTime appointmentAt;
  final String? location;
  final String status;
  final String? notes;

  const HomeAppointmentCardData({
    required this.id,
    required this.doctorName,
    required this.specialty,
    required this.appointmentAt,
    required this.location,
    required this.status,
    required this.notes,
  });

  factory HomeAppointmentCardData.fromJson(Map<String, dynamic> json) {
    return HomeAppointmentCardData(
      id: (json['id'] ?? 0) as int,
      doctorName: (json['doctor_name'] ?? '') as String,
      specialty: json['specialty'] as String?,
      appointmentAt: DateTime.tryParse(json['appointment_at'].toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
      location: json['location'] as String?,
      status: (json['status'] ?? 'scheduled') as String,
      notes: json['notes'] as String?,
    );
  }
}

class HomeMedicationStatusItem {
  final int id;
  final String name;
  final String dosage;
  final String subtitle;
  final String status;
  final String? scheduledLabel;

  const HomeMedicationStatusItem({
    required this.id,
    required this.name,
    required this.dosage,
    required this.subtitle,
    required this.status,
    required this.scheduledLabel,
  });

  factory HomeMedicationStatusItem.fromJson(Map<String, dynamic> json) {
    return HomeMedicationStatusItem(
      id: (json['id'] ?? 0) as int,
      name: (json['name'] ?? '') as String,
      dosage: (json['dosage'] ?? '') as String,
      subtitle: (json['subtitle'] ?? '') as String,
      status: (json['status'] ?? 'pending') as String,
      scheduledLabel: json['scheduled_label'] as String?,
    );
  }
}

class HomeInsightCardData {
  final String key;
  final String title;
  final String metric;
  final String deltaLabel;
  final String summary;
  final String trend;

  const HomeInsightCardData({
    required this.key,
    required this.title,
    required this.metric,
    required this.deltaLabel,
    required this.summary,
    required this.trend,
  });

  factory HomeInsightCardData.fromJson(Map<String, dynamic> json) {
    return HomeInsightCardData(
      key: (json['key'] ?? '') as String,
      title: (json['title'] ?? '') as String,
      metric: (json['metric'] ?? '--') as String,
      deltaLabel: (json['delta_label'] ?? '→ 0%') as String,
      summary: (json['summary'] ?? '') as String,
      trend: (json['trend'] ?? 'flat') as String,
    );
  }
}

class HomeRecentRecordData {
  final String id;
  final String title;
  final String subtitle;
  final String recordType;
  final DateTime recordDate;

  const HomeRecentRecordData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.recordType,
    required this.recordDate,
  });

  factory HomeRecentRecordData.fromJson(Map<String, dynamic> json) {
    return HomeRecentRecordData(
      id: json['id'].toString(),
      title: (json['title'] ?? '') as String,
      subtitle: (json['subtitle'] ?? '') as String,
      recordType: (json['record_type'] ?? '') as String,
      recordDate: DateTime.tryParse(json['record_date'].toString()) ??
          DateTime.fromMillisecondsSinceEpoch(0),
    );
  }
}

class HomeSearchResultItemData {
  final String section;
  final String itemId;
  final String title;
  final String subtitle;
  final String route;

  const HomeSearchResultItemData({
    required this.section,
    required this.itemId,
    required this.title,
    required this.subtitle,
    required this.route,
  });

  factory HomeSearchResultItemData.fromJson(Map<String, dynamic> json) {
    return HomeSearchResultItemData(
      section: (json['section'] ?? '') as String,
      itemId: json['item_id'].toString(),
      title: (json['title'] ?? '') as String,
      subtitle: (json['subtitle'] ?? '') as String,
      route: (json['route'] ?? '') as String,
    );
  }
}

class HomeDashboardData {
  final int streakDay;
  final HomeNotificationItem? aiAlert;
  final List<HomeAppointmentCardData> appointments;
  final int medicationsTaken;
  final int medicationsMissed;
  final int medicationsLeft;
  final List<HomeMedicationStatusItem> medicationItems;
  final List<HomeInsightCardData> insights;
  final List<HomeRecentRecordData> recentRecords;
  final List<HomeNotificationItem> notifications;

  const HomeDashboardData({
    required this.streakDay,
    required this.aiAlert,
    required this.appointments,
    required this.medicationsTaken,
    required this.medicationsMissed,
    required this.medicationsLeft,
    required this.medicationItems,
    required this.insights,
    required this.recentRecords,
    required this.notifications,
  });

  factory HomeDashboardData.fromJson(Map<String, dynamic> json) {
    return HomeDashboardData(
      streakDay: (json['streak_day'] ?? 1) as int,
      aiAlert: json['ai_alert'] is Map<String, dynamic>
          ? HomeNotificationItem.fromJson(
              json['ai_alert'] as Map<String, dynamic>)
          : null,
      appointments: (json['appointments'] as List<dynamic>? ?? const [])
          .map((item) =>
              HomeAppointmentCardData.fromJson(item as Map<String, dynamic>))
          .toList(),
      medicationsTaken: (json['medications_taken'] ?? 0) as int,
      medicationsMissed: (json['medications_missed'] ?? 0) as int,
      medicationsLeft: (json['medications_left'] ?? 0) as int,
      medicationItems: (json['medication_items'] as List<dynamic>? ?? const [])
          .map((item) =>
              HomeMedicationStatusItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      insights: (json['insights'] as List<dynamic>? ?? const [])
          .map((item) =>
              HomeInsightCardData.fromJson(item as Map<String, dynamic>))
          .toList(),
      recentRecords: (json['recent_records'] as List<dynamic>? ?? const [])
          .map((item) =>
              HomeRecentRecordData.fromJson(item as Map<String, dynamic>))
          .toList(),
      notifications: (json['notifications'] as List<dynamic>? ?? const [])
          .map((item) =>
              HomeNotificationItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
