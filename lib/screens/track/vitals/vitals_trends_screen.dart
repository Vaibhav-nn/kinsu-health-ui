import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../providers/vitals_provider.dart';
import 'log_vital_screen.dart';

/// Vitals Trends screen — matches the mockup with 2×3 grid cards + 7-day chart.
class VitalsTrendsScreen extends StatefulWidget {
  const VitalsTrendsScreen({super.key});

  @override
  State<VitalsTrendsScreen> createState() => _VitalsTrendsScreenState();
}

class _VitalsTrendsScreenState extends State<VitalsTrendsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VitalsProvider>().loadVitals();
    });
  }

  Future<void> _showVitalOverview(_VitalMetric metric) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: metric.iconColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(metric.icon, color: metric.iconColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        metric.label,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _VitalOverviewRow(
                    label: 'Current', value: '${metric.value} ${metric.unit}'),
                _VitalOverviewRow(label: 'Trend', value: metric.change),
                if (metric.contextNote != null)
                  _VitalOverviewRow(label: 'Note', value: metric.contextNote!),
                const SizedBox(height: 6),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final metrics = <_VitalMetric>[
      const _VitalMetric(
        icon: Icons.favorite,
        iconColor: Color(0xFFE53935),
        label: 'Blood Pressure',
        value: '128/84',
        unit: 'mmHg',
        change: '↓ 3%',
        changeColor: KinsuTheme.statusActive,
        contextNote: 'Stable in the last week.',
      ),
      const _VitalMetric(
        icon: Icons.local_fire_department,
        iconColor: Color(0xFFFF9800),
        label: 'Blood Sugar',
        value: '142',
        unit: 'mg/dL',
        change: '↑ 8%',
        changeColor: KinsuTheme.statusWarning,
        contextNote: 'Slightly above your weekly average.',
      ),
      const _VitalMetric(
        icon: Icons.show_chart,
        iconColor: KinsuTheme.primary,
        label: 'Heart Rate',
        value: '72',
        unit: 'bpm',
        change: '→ 0%',
        changeColor: KinsuTheme.statusActive,
        contextNote: 'No major fluctuation today.',
      ),
      const _VitalMetric(
        icon: Icons.air,
        iconColor: Color(0xFF2196F3),
        label: 'SpO2',
        value: '98',
        unit: '%',
        change: '→',
        changeColor: KinsuTheme.statusActive,
        contextNote: 'Within healthy range.',
      ),
      const _VitalMetric(
        icon: Icons.monitor_weight_outlined,
        iconColor: Color(0xFF9C27B0),
        label: 'Weight',
        value: '68.5',
        unit: 'kg',
        change: '↓ 0.5',
        changeColor: KinsuTheme.statusActive,
        contextNote: 'Gradual decline over the week.',
      ),
      const _VitalMetric(
        icon: Icons.thermostat,
        iconColor: Color(0xFFFF5722),
        label: 'Temperature',
        value: '98.4',
        unit: '°F',
        change: '→',
        changeColor: KinsuTheme.statusActive,
        contextNote: 'No fever trend detected.',
      ),
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitals Trends'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const LogVitalScreen()),
        ),
        backgroundColor: KinsuTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Log Vital'),
      ),
      body: Consumer<VitalsProvider>(
        builder: (context, provider, _) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.4,
                children: metrics
                    .map(
                      (metric) => _VitalCard(
                        metric: metric,
                        onTap: () => _showVitalOverview(metric),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: KinsuTheme.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Blood Pressure (7 days)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: KinsuTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      height: 200,
                      child: LineChart(
                        LineChartData(
                          gridData: FlGridData(
                            show: true,
                            drawVerticalLine: false,
                            horizontalInterval: 20,
                            getDrawingHorizontalLine: (value) => const FlLine(
                              color: KinsuTheme.divider,
                              strokeWidth: 1,
                            ),
                          ),
                          titlesData: FlTitlesData(
                            topTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            rightTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            leftTitles: const AxisTitles(
                              sideTitles: SideTitles(showTitles: false),
                            ),
                            bottomTitles: AxisTitles(
                              sideTitles: SideTitles(
                                showTitles: true,
                                getTitlesWidget: (value, meta) {
                                  final days = [
                                    '14 Feb',
                                    '15 Feb',
                                    '16 Feb',
                                    '17 Feb',
                                    '18 Feb',
                                    '19 Feb',
                                  ];
                                  final idx = value.toInt();
                                  if (idx >= 0 && idx < days.length) {
                                    return Text(
                                      days[idx],
                                      style: const TextStyle(
                                        fontSize: 10,
                                        color: KinsuTheme.textSecondary,
                                      ),
                                    );
                                  }
                                  return const Text('');
                                },
                              ),
                            ),
                          ),
                          borderData: FlBorderData(show: false),
                          lineBarsData: [
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 130),
                                FlSpot(1, 134),
                                FlSpot(2, 128),
                                FlSpot(3, 132),
                                FlSpot(4, 129),
                                FlSpot(5, 128),
                              ],
                              isCurved: true,
                              color: const Color(0xFFE53935),
                              barWidth: 2.5,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, bar, index) =>
                                    FlDotCirclePainter(
                                  radius: 4,
                                  color: const Color(0xFFE53935),
                                  strokeColor: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                              belowBarData: BarAreaData(
                                show: true,
                                color: const Color(0xFFE53935)
                                    .withValues(alpha: 0.1),
                              ),
                            ),
                            LineChartBarData(
                              spots: const [
                                FlSpot(0, 82),
                                FlSpot(1, 86),
                                FlSpot(2, 84),
                                FlSpot(3, 83),
                                FlSpot(4, 84),
                                FlSpot(5, 86),
                              ],
                              isCurved: true,
                              color: const Color(0xFFFF9800),
                              barWidth: 2.5,
                              dotData: FlDotData(
                                show: true,
                                getDotPainter: (spot, percent, bar, index) =>
                                    FlDotCirclePainter(
                                  radius: 4,
                                  color: const Color(0xFFFF9800),
                                  strokeColor: Colors.white,
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                          ],
                          minY: 60,
                          maxY: 160,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _VitalMetric {
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;
  final String change;
  final Color changeColor;
  final String? contextNote;

  const _VitalMetric({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    required this.unit,
    required this.change,
    required this.changeColor,
    this.contextNote,
  });
}

/// Single vital card widget matching the mockup grid.
class _VitalCard extends StatelessWidget {
  final _VitalMetric metric;
  final VoidCallback onTap;

  const _VitalCard({
    required this.metric,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: KinsuTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(metric.icon, size: 16, color: metric.iconColor),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      metric.label,
                      style: const TextStyle(
                        fontSize: 12,
                        color: KinsuTheme.textSecondary,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    metric.value,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w700,
                      color: KinsuTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      metric.unit,
                      style: const TextStyle(
                        fontSize: 13,
                        color: KinsuTheme.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                metric.change,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: metric.changeColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VitalOverviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _VitalOverviewRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: KinsuTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
