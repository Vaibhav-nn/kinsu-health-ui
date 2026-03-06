import 'package:flutter/material.dart';
import '../../core/theme.dart';
import 'vitals/vitals_trends_screen.dart';
import 'symptoms/symptoms_list_screen.dart';
import 'illness/illness_list_screen.dart';
import 'medications/medications_list_screen.dart';
import 'reminders/reminders_timeline_screen.dart';

/// Track tab home — hub screen with navigation tiles to each health feature.
class TrackHome extends StatelessWidget {
  const TrackHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Track'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Quick summary banner
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [KinsuTheme.primary, KinsuTheme.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Health Tracking',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Monitor vitals, symptoms, and medications',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Feature tiles
          _buildFeatureTile(
            context,
            icon: Icons.favorite_outline,
            iconColor: const Color(0xFFE53935),
            title: 'Vitals',
            subtitle: 'Log & track vital signs',
            page: const VitalsTrendsScreen(),
          ),
          _buildFeatureTile(
            context,
            icon: Icons.healing_outlined,
            iconColor: const Color(0xFFFF9800),
            title: 'Symptoms',
            subtitle: 'Track chronic symptoms',
            page: const SymptomsListScreen(),
          ),
          _buildFeatureTile(
            context,
            icon: Icons.medical_information_outlined,
            iconColor: const Color(0xFF9C27B0),
            title: 'Illness Episodes',
            subtitle: 'Log illness & recovery timeline',
            page: const IllnessListScreen(),
          ),
          _buildFeatureTile(
            context,
            icon: Icons.medication_outlined,
            iconColor: const Color(0xFF2196F3),
            title: 'Medications',
            subtitle: 'Manage your prescriptions',
            page: const MedicationsListScreen(),
          ),
          _buildFeatureTile(
            context,
            icon: Icons.alarm_outlined,
            iconColor: KinsuTheme.primary,
            title: 'Reminders',
            subtitle: 'Daily medication & checkup reminders',
            page: const RemindersTimelineScreen(),
          ),
        ],
      ),
    );
  }

  Widget _buildFeatureTile(
    BuildContext context, {
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required Widget page,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => page),
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: KinsuTheme.cardDecoration,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: KinsuTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: KinsuTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: KinsuTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
