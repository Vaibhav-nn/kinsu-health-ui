import 'package:flutter/material.dart';
import 'package:kinsu_health/widgets/ios_back_button.dart';

import '../../core/theme.dart';

class ContextAdviceScreen extends StatelessWidget {
  const ContextAdviceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const IosBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Context Advice'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: const [
          _AdviceCard(
            trigger: 'Weather Alert',
            title: 'Cold Wave Advisory — Delhi NCR',
            description:
                'Temperature dropping to 4°C tonight. Cold weather may temporarily increase BP.',
            tips: [
              'Monitor blood pressure more frequently',
              'Keep warm and avoid sudden cold exposure',
              'Take medications on time',
            ],
            chip: 'Hypertension',
            icon: Icons.ac_unit,
            color: Color(0xFF3B82F6),
          ),
          SizedBox(height: 12),
          _AdviceCard(
            trigger: 'Travel Context',
            title: 'Upcoming Travel — Mumbai',
            description:
                'During high humidity travel, monitor blood sugar and hydration more actively.',
            tips: [
              'Carry extra medications',
              'Check blood sugar more frequently',
              'Keep prescriptions accessible',
            ],
            chip: 'Pre-diabetes',
            icon: Icons.flight_takeoff,
            color: Color(0xFF8B5CF6),
          ),
        ],
      ),
    );
  }
}

class _AdviceCard extends StatelessWidget {
  final String trigger;
  final String title;
  final String description;
  final List<String> tips;
  final String chip;
  final IconData icon;
  final Color color;

  const _AdviceCard({
    required this.trigger,
    required this.title,
    required this.description,
    required this.tips,
    required this.chip,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KinsuTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: color),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        trigger,
                        style: const TextStyle(
                          color: KinsuTheme.textSecondary,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 10),
            child: Text(
              description,
              style: const TextStyle(color: KinsuTheme.textSecondary),
            ),
          ),
          ...tips.map(
            (tip) => Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
              child: Row(
                children: [
                  const Icon(
                    Icons.check,
                    size: 16,
                    color: KinsuTheme.statusActive,
                  ),
                  const SizedBox(width: 8),
                  Expanded(child: Text(tip)),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
            child: Row(
              children: [
                const Text(
                  'Relevant condition:',
                  style:
                      TextStyle(fontSize: 12, color: KinsuTheme.textSecondary),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: KinsuTheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    chip,
                    style: const TextStyle(
                      color: KinsuTheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
