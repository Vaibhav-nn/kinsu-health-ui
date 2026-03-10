import 'package:flutter/material.dart';
import '../data/mock_data.dart';
import '../widgets/bp_pulse_widget.dart';
import '../widgets/recent_prescriptions.dart';
import '../widgets/next_doses.dart';

class HomeContent extends StatelessWidget {
  const HomeContent({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Home',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 24),
                // 1. BP & Pulse widget
                BpPulseWidget(
                  systolic: 122,
                  diastolic: 78,
                  pulse: 68,
                  lastUpdated: DateTime.now().subtract(const Duration(minutes: 30)),
                ),
                const SizedBox(height: 28),
                // 2. Recent opened prescriptions
                RecentPrescriptions(
                  prescriptions: MockData.recentPrescriptions,
                  onSeeAll: () {},
                ),
                const SizedBox(height: 28),
                // 3. Next doses
                NextDoses(
                  doses: MockData.nextDoses,
                  onSeeAll: () {},
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
