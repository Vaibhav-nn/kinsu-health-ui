/// Data model for Medications — matches backend Pydantic schema.

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

  Map<String, dynamic> toJson() => {
        'name': name,
        'dosage': dosage,
        'frequency': frequency,
        'route': route,
        'start_date':
            '${startDate.year}-${startDate.month.toString().padLeft(2, '0')}-${startDate.day.toString().padLeft(2, '0')}',
        'end_date': endDate != null
            ? '${endDate!.year}-${endDate!.month.toString().padLeft(2, '0')}-${endDate!.day.toString().padLeft(2, '0')}'
            : null,
        'prescribing_doctor': prescribingDoctor,
        'is_active': isActive,
        'notes': notes,
      };
}
