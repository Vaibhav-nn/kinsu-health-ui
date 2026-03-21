import 'package:flutter/material.dart';

import '../../core/theme.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _NotificationCard(
            icon: Icons.favorite_outline,
            iconColor: Color(0xFFE53935),
            title: 'Vitals Reminder',
            message: 'Log your blood pressure for today.',
            time: '2h ago',
          ),
          SizedBox(height: 12),
          _NotificationCard(
            icon: Icons.medication_outlined,
            iconColor: Color(0xFF2196F3),
            title: 'Medication Reminder',
            message: 'Your evening medicine is scheduled at 8:00 PM.',
            time: '5h ago',
          ),
          SizedBox(height: 12),
          _NotificationCard(
            icon: Icons.healing_outlined,
            iconColor: Color(0xFFFF9800),
            title: 'Symptoms Check-in',
            message: 'Track how you are feeling today in Symptoms.',
            time: 'Yesterday',
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String message;
  final String time;

  const _NotificationCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.message,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: KinsuTheme.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: KinsuTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  message,
                  style: const TextStyle(
                    color: KinsuTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            time,
            style: const TextStyle(
              color: KinsuTheme.textSecondary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
