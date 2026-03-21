/// Data model for Reminders — matches backend Pydantic schema.

class Reminder {
  final int? id;
  final String title;
  final String reminderType;
  final int? linkedMedicationId;
  final String scheduledTime; // "HH:MM:SS" from backend
  final String recurrence;
  final bool isEnabled;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  Reminder({
    this.id,
    required this.title,
    required this.reminderType,
    this.linkedMedicationId,
    required this.scheduledTime,
    this.recurrence = 'daily',
    this.isEnabled = true,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory Reminder.fromJson(Map<String, dynamic> json) => Reminder(
        id: json['id'],
        title: json['title'],
        reminderType: json['reminder_type'],
        linkedMedicationId: json['linked_medication_id'],
        scheduledTime: json['scheduled_time'],
        recurrence: json['recurrence'] ?? 'daily',
        isEnabled: json['is_enabled'] ?? true,
        notes: json['notes'],
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'])
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'])
            : null,
      );

  Map<String, dynamic> toJson() => {
        'title': title,
        'reminder_type': reminderType,
        'linked_medication_id': linkedMedicationId,
        'scheduled_time': scheduledTime,
        'recurrence': recurrence,
        'is_enabled': isEnabled,
        'notes': notes,
      };

  /// Parse "HH:MM:SS" string to a display-friendly format.
  String get displayTime {
    final parts = scheduledTime.split(':');
    if (parts.length < 2) return scheduledTime;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = parts[1];
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
    return '$displayHour:$minute $period';
  }
}
