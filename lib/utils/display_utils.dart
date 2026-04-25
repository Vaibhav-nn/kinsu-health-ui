/// Display utilities shared across screens.
library;

/// Returns a time-appropriate greeting string.
String greeting({bool withEmoji = false}) {
  final hour = DateTime.now().hour;
  if (withEmoji) {
    if (hour < 12) return 'Good Morning ☀️';
    if (hour < 17) return 'Good Afternoon 🌤';
    return 'Good Evening 🌙';
  }
  if (hour < 12) return 'Good morning';
  if (hour < 17) return 'Good afternoon';
  return 'Good evening';
}

/// Returns up-to-2-character initials from a display name.
/// "Deovrat Singh" → "DS",  "Alice" → "A"
String initialsFromName(String name) {
  final parts = name.trim().split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}

/// Returns up-to-2-character initials from an email address.
/// "deovrat.singh@gmail.com" → "DS"
String initialsFromEmail(String email) {
  final local = email.split('@').first;
  final parts = local.split(RegExp(r'[\._\-]')).where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty) return 'U';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
}
