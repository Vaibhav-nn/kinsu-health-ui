import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fl_chart/fl_chart.dart';

import '../../core/theme.dart';
import '../../providers/family_provider.dart';
import '../../providers/health_sync_provider.dart';
import '../../providers/medications_provider.dart';
import '../../providers/vitals_provider.dart';
import '../../utils/display_utils.dart';
import '../settings/health_connect_settings_screen.dart';
import 'medications/medications_list_screen.dart';
import 'vitals/vitals_trends_screen.dart';
import 'symptoms/symptoms_list_screen.dart';

class TrackHome extends StatefulWidget {
  const TrackHome({super.key});

  @override
  State<TrackHome> createState() => _TrackHomeState();
}

class _TrackHomeState extends State<TrackHome> {
  String _selectedMetric = 'BP'; // 'BP' or 'HR'

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationsProvider>().loadMedications(isActive: true);
      context.read<VitalsProvider>().loadVitals();
    });
  }

  @override
  Widget build(BuildContext context) {
    final medsProvider = context.watch<MedicationsProvider>();
    final vitalsProvider = context.watch<VitalsProvider>();
    final familyProvider = context.watch<FamilyProvider>();
    final hsp = context.watch<HealthSyncProvider>();

    final activeMeds = medsProvider.activeMedications;
    const takenCount = 0; // no local taken state; requires backend session
    final displayName = familyProvider.profiles.isEmpty
        ? 'there'
        : (familyProvider.profiles
                .firstWhere((p) => p.isSelf,
                    orElse: () => familyProvider.profiles.first)
                .displayName);
    final firstName = displayName.split(' ').first;

    // Build weekly vitals data
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));
    final vitalType = _selectedMetric == 'BP' ? 'blood_pressure' : 'heart_rate';
    final weeklyVitals = vitalsProvider.vitals
        .where((v) => v.vitalType == vitalType && v.recordedAt.isAfter(weekAgo))
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));

    // Build 7-day sparkline spots
    final List<FlSpot> spots = [];
    for (int i = 0; i < 7; i++) {
      final day = weekAgo.add(Duration(days: i));
      final dayVitals = weeklyVitals.where((v) {
        return v.recordedAt.year == day.year &&
            v.recordedAt.month == day.month &&
            v.recordedAt.day == day.day;
      }).toList();
      if (dayVitals.isNotEmpty) {
        final avg = dayVitals.map((v) => v.value).reduce((a, b) => a + b) / dayVitals.length;
        spots.add(FlSpot(i.toDouble(), avg));
      }
    }
    final hasChartData = spots.isNotEmpty;

    // Adherence copy
    String adherenceCopy;
    if (activeMeds.isNotEmpty && takenCount > 0) {
      adherenceCopy = "You've taken $takenCount medicines today — nice work.";
    } else if (weeklyVitals.isNotEmpty) {
      adherenceCopy = "Your vitals are being tracked — stay consistent.";
    } else {
      adherenceCopy = "Start logging your vitals and meds to build insights.";
    }

    final hasError = vitalsProvider.error != null || medsProvider.error != null;
    final errorMessage = vitalsProvider.error ?? medsProvider.error;

    return Scaffold(
      backgroundColor: KinsuTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
          children: [
            if (hasError)
              _TrackErrorBanner(
                message: errorMessage!,
                onRetry: () {
                  context.read<MedicationsProvider>().loadMedications(isActive: true);
                  context.read<VitalsProvider>().loadVitals();
                },
              ),
            // ── Top bar ──────────────────────────────────────
            Row(
              children: [
                const Icon(Icons.chevron_left, color: KinsuTheme.textSecondary),
                const SizedBox(width: 4),
                const Text(
                  'Track',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: KinsuTheme.primary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: KinsuTheme.primaryLight,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Text(
                    'Today',
                    style: TextStyle(
                      fontSize: 12,
                      color: KinsuTheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Daily Overview label ───────────────────────────
            const Text(
              'DAILY OVERVIEW',
              style: TextStyle(
                fontSize: 11,
                color: KinsuTheme.primary,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),

            // ── Greeting ──────────────────────────────────────
            Text(
              '${greeting()}, $firstName.',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: KinsuTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              adherenceCopy,
              style: const TextStyle(
                fontSize: 14,
                color: KinsuTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 18),

            // ── Vitality Metrics card ──────────────────────────
            Container(
              decoration: KinsuTheme.cardDecoration,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: KinsuTheme.statusWarning.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          'INSIGHT',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: KinsuTheme.statusWarning,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Vitality Metrics',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      _MetricChip(
                        label: 'BP',
                        isSelected: _selectedMetric == 'BP',
                        onTap: () => setState(() => _selectedMetric = 'BP'),
                      ),
                      const SizedBox(width: 6),
                      _MetricChip(
                        label: 'HR',
                        isSelected: _selectedMetric == 'HR',
                        onTap: () => setState(() => _selectedMetric = 'HR'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    height: 120,
                    child: hasChartData
                        ? LineChart(
                            LineChartData(
                              minX: 0,
                              maxX: 6,
                              minY: spots.map((s) => s.y).reduce((a, b) => a < b ? a : b) - 10,
                              maxY: spots.map((s) => s.y).reduce((a, b) => a > b ? a : b) + 10,
                              gridData: const FlGridData(show: false),
                              borderData: FlBorderData(show: false),
                              titlesData: FlTitlesData(
                                leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      const labels = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
                                      final idx = value.round();
                                      if (idx < 0 || idx > 6) return const SizedBox.shrink();
                                      return Text(
                                        labels[idx],
                                        style: const TextStyle(
                                          fontSize: 8,
                                          color: KinsuTheme.textSecondary,
                                        ),
                                      );
                                    },
                                    reservedSize: 20,
                                  ),
                                ),
                              ),
                              lineBarsData: [
                                LineChartBarData(
                                  spots: spots,
                                  isCurved: true,
                                  color: KinsuTheme.primary,
                                  barWidth: 2.5,
                                  dotData: const FlDotData(show: false),
                                  belowBarData: BarAreaData(
                                    show: true,
                                    color: KinsuTheme.primary.withValues(alpha: 0.08),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _DashedLine(),
                              const SizedBox(height: 8),
                              const Text(
                                'No data this week. Start logging vitals.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: KinsuTheme.textSecondary,
                                ),
                              ),
                            ],
                          ),
                  ),
                  const SizedBox(height: 4),
                  if (!hasChartData)
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        Text('MON', style: TextStyle(fontSize: 8, color: KinsuTheme.textSecondary)),
                        Text('TUE', style: TextStyle(fontSize: 8, color: KinsuTheme.textSecondary)),
                        Text('WED', style: TextStyle(fontSize: 8, color: KinsuTheme.textSecondary)),
                        Text('THU', style: TextStyle(fontSize: 8, color: KinsuTheme.textSecondary)),
                        Text('FRI', style: TextStyle(fontSize: 8, color: KinsuTheme.textSecondary)),
                        Text('SAT', style: TextStyle(fontSize: 8, color: KinsuTheme.textSecondary)),
                        Text('SUN', style: TextStyle(fontSize: 8, color: KinsuTheme.textSecondary)),
                      ],
                    ),
                  if (!hasChartData && hsp.isAvailable) ...[
                    const SizedBox(height: 12),
                    const Divider(height: 1, color: KinsuTheme.divider),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.bolt,
                            size: 16, color: KinsuTheme.primary),
                        const SizedBox(width: 6),
                        const Expanded(
                          child: Text(
                            'Import vitals from Health Connect',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: KinsuTheme.textPrimary,
                            ),
                          ),
                        ),
                        hsp.status == HCSyncStatus.syncing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: KinsuTheme.primary,
                                ),
                              )
                            : TextButton(
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  backgroundColor: KinsuTheme.primaryLight,
                                  foregroundColor: KinsuTheme.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                                onPressed: () => hsp.importFromHC(days: 30),
                                child: const Text(
                                  'Import',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const HealthConnectSettingsScreen(),
                        ),
                      ),
                      child: const Text(
                        'Manage Health Connect settings →',
                        style: TextStyle(
                          fontSize: 11,
                          color: KinsuTheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Quick action tiles ─────────────────────────────
            Row(
              children: [
                Expanded(
                  child: _QuickActionTile(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Log Vitals',
                    bg: KinsuTheme.primaryLight,
                    color: KinsuTheme.primary,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const VitalsTrendsScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionTile(
                    icon: Icons.medication_outlined,
                    label: 'Log Meds',
                    bg: KinsuTheme.accent.withValues(alpha: 0.25),
                    color: const Color(0xFFB45309),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const MedicationsListScreen()),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _QuickActionTile(
                    icon: Icons.sick_outlined,
                    label: 'Symptoms',
                    bg: KinsuTheme.success.withValues(alpha: 0.12),
                    color: KinsuTheme.success,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SymptomsListScreen()),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Weekly Wellness Tip ────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: KinsuTheme.primary,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.water_drop, color: Colors.white, size: 28),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly Wellness Tip',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Stay hydrated — aim for 8 glasses of water daily to support heart health.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Community Insight card ──────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1C1E),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Row(
                children: [
                  Icon(Icons.nightlight_round, color: Colors.white60, size: 24),
                  SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Good sleep improves medication effectiveness by up to 20%.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _MetricChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? KinsuTheme.primary : KinsuTheme.panel,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: isSelected ? Colors.white : KinsuTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color color;
  final VoidCallback onTap;

  const _QuickActionTile({
    required this.icon,
    required this.label,
    required this.bg,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: KinsuTheme.cardDecoration,
        child: Column(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: KinsuTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: CustomPaint(
        painter: _DashedLinePainter(),
        size: const Size(double.infinity, 60),
      ),
    );
  }
}

class _TrackErrorBanner extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _TrackErrorBanner({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: KinsuTheme.destructive.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: KinsuTheme.destructive.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.wifi_off_rounded,
              size: 16, color: KinsuTheme.destructive),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                  fontSize: 12, color: KinsuTheme.destructive),
            ),
          ),
          TextButton(
            onPressed: onRetry,
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: KinsuTheme.destructive,
            ),
            child: const Text('Retry',
                style:
                    TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}

class _DashedLinePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = KinsuTheme.divider
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    const dashWidth = 6.0;
    const dashSpace = 4.0;
    double startX = 0;
    final y = size.height / 2;
    while (startX < size.width) {
      canvas.drawLine(Offset(startX, y), Offset(startX + dashWidth, y), paint);
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
