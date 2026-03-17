class NextDose {
  final String id;
  final String medicationName;
  final DateTime scheduledAt;
  final String dosage;
  final bool isOverdue;

  NextDose({
    required this.id,
    required this.medicationName,
    required this.scheduledAt,
    required this.dosage,
    required this.isOverdue,
  });

  String get timeLabel {
    if (isOverdue) {
      final diff = DateTime.now().difference(scheduledAt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m overdue';
      return '${diff.inHours}h overdue';
    }
    final diff = scheduledAt.difference(DateTime.now());
    if (diff.inMinutes < 60) return 'In ${diff.inMinutes}m';
    if (diff.inHours < 24) return 'In ${diff.inHours}h';
    return 'In ${diff.inDays}d';
  }

  String get timeOfDay {
    final h = scheduledAt.hour;
    final m = scheduledAt.minute;
    if (h < 12) return '${h == 0 ? 12 : h}:${m.toString().padLeft(2, '0')} AM';
    return '${h == 12 ? 12 : h - 12}:${m.toString().padLeft(2, '0')} PM';
  }
}
