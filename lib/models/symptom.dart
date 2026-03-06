/// Data model for Chronic Symptoms — matches backend Pydantic schema.

class ChronicSymptom {
  final int? id;
  final String symptomName;
  final int severity;
  final String frequency;
  final String? bodyArea;
  final String? triggers;
  final DateTime firstNoticed;
  final bool isActive;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  ChronicSymptom({
    this.id,
    required this.symptomName,
    required this.severity,
    required this.frequency,
    this.bodyArea,
    this.triggers,
    required this.firstNoticed,
    this.isActive = true,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory ChronicSymptom.fromJson(Map<String, dynamic> json) =>
      ChronicSymptom(
        id: json['id'],
        symptomName: json['symptom_name'],
        severity: json['severity'],
        frequency: json['frequency'],
        bodyArea: json['body_area'],
        triggers: json['triggers'],
        firstNoticed: DateTime.parse(json['first_noticed']),
        isActive: json['is_active'] ?? true,
        notes: json['notes'],
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'symptom_name': symptomName,
        'severity': severity,
        'frequency': frequency,
        'body_area': bodyArea,
        'triggers': triggers,
        'first_noticed':
            '${firstNoticed.year}-${firstNoticed.month.toString().padLeft(2, '0')}-${firstNoticed.day.toString().padLeft(2, '0')}',
        'is_active': isActive,
        'notes': notes,
      };

  /// For partial update — only non-null fields.
  Map<String, dynamic> toUpdateJson() {
    final map = <String, dynamic>{};
    map['symptom_name'] = symptomName;
    map['severity'] = severity;
    map['frequency'] = frequency;
    if (bodyArea != null) map['body_area'] = bodyArea;
    if (triggers != null) map['triggers'] = triggers;
    map['is_active'] = isActive;
    if (notes != null) map['notes'] = notes;
    return map;
  }
}
