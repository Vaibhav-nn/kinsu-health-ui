class Prescription {
  final String id;
  final String name;
  final String doctor;
  final DateTime openedAt;
  final String status;

  Prescription({
    required this.id,
    required this.name,
    required this.doctor,
    required this.openedAt,
    required this.status,
  });

  String get timeAgo {
    final diff = DateTime.now().difference(openedAt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays == 1) return 'Yesterday';
    return '${diff.inDays}d ago';
  }
}
