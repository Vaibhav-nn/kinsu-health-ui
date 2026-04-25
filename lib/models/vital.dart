// Data models for vitals returned by the backend API.

class VitalLog {
  final int? id;
  final String vitalType;
  final double value;
  final double? valueSecondary;
  final String unit;
  final DateTime recordedAt;
  final String? notes;
  final DateTime? createdAt;

  VitalLog({
    this.id,
    required this.vitalType,
    required this.value,
    this.valueSecondary,
    required this.unit,
    required this.recordedAt,
    this.notes,
    this.createdAt,
  });

  factory VitalLog.fromJson(Map<String, dynamic> json) => VitalLog(
        id: json['id'],
        vitalType: json['vital_type'],
        value: (json['value'] as num).toDouble(),
        valueSecondary: json['value_secondary'] != null
            ? (json['value_secondary'] as num).toDouble()
            : null,
        unit: json['unit'],
        recordedAt: DateTime.parse(json['recorded_at']),
        notes: json['notes'],
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
      );

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'vital_type': vitalType,
      'value': value,
      'unit': unit,
      'recorded_at': recordedAt.toIso8601String(),
    };
    if (valueSecondary != null) json['value_secondary'] = valueSecondary;
    if (notes != null) json['notes'] = notes;
    return json;
  }
}

class VitalTrendPoint {
  final DateTime recordedAt;
  final double value;
  final double? valueSecondary;

  VitalTrendPoint({
    required this.recordedAt,
    required this.value,
    this.valueSecondary,
  });

  factory VitalTrendPoint.fromJson(Map<String, dynamic> json) =>
      VitalTrendPoint(
        recordedAt: DateTime.parse(json['recorded_at']),
        value: (json['value'] as num).toDouble(),
        valueSecondary: json['value_secondary'] != null
            ? (json['value_secondary'] as num).toDouble()
            : null,
      );
}

class VitalTrendResponse {
  final String vitalType;
  final String unit;
  final List<VitalTrendPoint> dataPoints;
  final int count;
  final double? avgValue;
  final double? minValue;
  final double? maxValue;

  VitalTrendResponse({
    required this.vitalType,
    required this.unit,
    required this.dataPoints,
    required this.count,
    this.avgValue,
    this.minValue,
    this.maxValue,
  });

  factory VitalTrendResponse.fromJson(Map<String, dynamic> json) =>
      VitalTrendResponse(
        vitalType: json['vital_type'],
        unit: json['unit'],
        dataPoints: (json['data_points'] as List)
            .map((e) => VitalTrendPoint.fromJson(e))
            .toList(),
        count: json['count'],
        avgValue: json['avg_value'] != null
            ? (json['avg_value'] as num).toDouble()
            : null,
        minValue: json['min_value'] != null
            ? (json['min_value'] as num).toDouble()
            : null,
        maxValue: json['max_value'] != null
            ? (json['max_value'] as num).toDouble()
            : null,
      );
}

class VitalSnapshot {
  final DateTime recordedAt;
  final String? notes;
  final double? bloodPressureSystolic;
  final double? bloodPressureDiastolic;
  final double? bloodSugar;
  final double? heartRate;
  final double? weight;
  final double? temperature;
  final double? spo2;

  VitalSnapshot({
    required this.recordedAt,
    this.notes,
    this.bloodPressureSystolic,
    this.bloodPressureDiastolic,
    this.bloodSugar,
    this.heartRate,
    this.weight,
    this.temperature,
    this.spo2,
  });

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{
      'recorded_at': recordedAt.toIso8601String(),
    };
    if (notes != null) json['notes'] = notes;
    if (bloodPressureSystolic != null) json['blood_pressure_systolic'] = bloodPressureSystolic;
    if (bloodPressureDiastolic != null) json['blood_pressure_diastolic'] = bloodPressureDiastolic;
    if (bloodSugar != null) json['blood_sugar'] = bloodSugar;
    if (heartRate != null) json['heart_rate'] = heartRate;
    if (weight != null) json['weight'] = weight;
    if (temperature != null) json['temperature'] = temperature;
    if (spo2 != null) json['spo2'] = spo2;
    return json;
  }
}
