// Data model for medications matching backend schemas.

class Medication {
  final int? id;
  final String name;
  final String dosage;
  final String frequency;
  final String route;
  final DateTime startDate;
  final DateTime? endDate;
  final String? prescribingDoctor;
  final bool isActive;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Medication({
    this.id,
    required this.name,
    required this.dosage,
    required this.frequency,
    this.route = 'oral',
    required this.startDate,
    this.endDate,
    this.prescribingDoctor,
    this.isActive = true,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Medication.fromJson(Map<String, dynamic> json) => Medication(
        id: json['id'],
        name: json['name'],
        dosage: json['dosage'],
        frequency: json['frequency'],
        route: json['route'] ?? 'oral',
        startDate: DateTime.parse(json['start_date']),
        endDate:
            json['end_date'] != null ? DateTime.parse(json['end_date']) : null,
        prescribingDoctor: json['prescribing_doctor'],
        isActive: json['is_active'] ?? true,
        notes: json['notes'],
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );

  /// Formats a DateTime to a `yyyy-MM-dd` date string for the backend.
  static String _dateOnly(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'name': name,
      'dosage': dosage,
      'frequency': frequency,
      'route': route,
      'start_date': _dateOnly(startDate),
      'is_active': isActive,
    };
    if (endDate != null) json['end_date'] = _dateOnly(endDate!);
    if (prescribingDoctor != null) json['prescribing_doctor'] = prescribingDoctor;
    if (notes != null) json['notes'] = notes;
    return json;
  }
}

class MedicationDashboardItem {
  final Medication medication;
  final int adherencePct;
  final String latestStatus;
  final String? scheduleLabel;

  const MedicationDashboardItem({
    required this.medication,
    required this.adherencePct,
    required this.latestStatus,
    required this.scheduleLabel,
  });

  factory MedicationDashboardItem.fromJson(Map<String, dynamic> json) {
    return MedicationDashboardItem(
      medication:
          Medication.fromJson(json['medication'] as Map<String, dynamic>),
      adherencePct: json['adherence_pct'] as int? ?? 0,
      latestStatus: (json['latest_status'] ?? 'pending') as String,
      scheduleLabel: json['schedule_label'] as String?,
    );
  }
}

class MedicationDashboard {
  final int taken;
  final int missed;
  final int left;
  final int adherencePct;
  final List<MedicationDashboardItem> items;

  const MedicationDashboard({
    required this.taken,
    required this.missed,
    required this.left,
    required this.adherencePct,
    required this.items,
  });

  factory MedicationDashboard.fromJson(Map<String, dynamic> json) {
    return MedicationDashboard(
      taken: json['taken'] as int? ?? 0,
      missed: json['missed'] as int? ?? 0,
      left: json['left'] as int? ?? 0,
      adherencePct: json['adherence_pct'] as int? ?? 0,
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) =>
              MedicationDashboardItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class MedicationWeeklyMatrixEntry {
  final int medicationId;
  final String medicationName;
  final String dosage;
  final List<String> dayStatuses;

  const MedicationWeeklyMatrixEntry({
    required this.medicationId,
    required this.medicationName,
    required this.dosage,
    required this.dayStatuses,
  });

  factory MedicationWeeklyMatrixEntry.fromJson(Map<String, dynamic> json) {
    return MedicationWeeklyMatrixEntry(
      medicationId: json['medication_id'] as int,
      medicationName: json['medication_name'] as String? ?? '',
      dosage: json['dosage'] as String? ?? '',
      dayStatuses: (json['day_statuses'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
    );
  }
}

class MedicationMonthlyCalendarDay {
  final int day;
  final String adherenceBucket;

  const MedicationMonthlyCalendarDay({
    required this.day,
    required this.adherenceBucket,
  });

  factory MedicationMonthlyCalendarDay.fromJson(Map<String, dynamic> json) {
    return MedicationMonthlyCalendarDay(
      day: json['day'] as int? ?? 0,
      adherenceBucket: (json['adherence_bucket'] ?? 'none') as String,
    );
  }
}

class MedicationAdherence {
  final String view;
  final List<MedicationWeeklyMatrixEntry> weeklyRows;
  final List<MedicationMonthlyCalendarDay> monthlyDays;

  const MedicationAdherence({
    required this.view,
    required this.weeklyRows,
    required this.monthlyDays,
  });

  factory MedicationAdherence.fromJson(Map<String, dynamic> json) {
    return MedicationAdherence(
      view: (json['view'] ?? 'daily') as String,
      weeklyRows: (json['weekly_rows'] as List<dynamic>? ?? const [])
          .map((item) => MedicationWeeklyMatrixEntry.fromJson(
              item as Map<String, dynamic>))
          .toList(),
      monthlyDays: (json['monthly_days'] as List<dynamic>? ?? const [])
          .map((item) => MedicationMonthlyCalendarDay.fromJson(
              item as Map<String, dynamic>))
          .toList(),
    );
  }
}
