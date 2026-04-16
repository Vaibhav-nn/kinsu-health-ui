import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:kinsu_health/widgets/ios_back_button.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/vital.dart';
import '../../../providers/vitals_provider.dart';
import 'log_vital_screen.dart';

/// Vitals Trends screen — cards and chart are derived from live logged data.
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
    final currentValue =
        metric.value == '--' ? '--' : '${metric.value} ${metric.unit}';

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
                _VitalOverviewRow(label: 'Current', value: currentValue),
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

  List<VitalLog> _entriesForType(List<VitalLog> vitals, String vitalType) {
    final entries = vitals.where((item) => item.vitalType == vitalType).toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    return entries;
  }

  String _formatNumber(double value) {
    if ((value - value.roundToDouble()).abs() < 0.05) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  String _formatDateTime(DateTime value) {
    final hh = value.hour.toString().padLeft(2, '0');
    final mm = value.minute.toString().padLeft(2, '0');
    return '${value.day}/${value.month} $hh:$mm';
  }

  _TrendSnapshot _buildTrend(List<VitalLog> entries) {
    if (entries.length < 2) {
      return const _TrendSnapshot(
        label: 'No trend yet',
        color: KinsuTheme.textSecondary,
      );
    }

    final current = entries[0].value;
    final previous = entries[1].value;

    if (previous.abs() < 0.0001) {
      return const _TrendSnapshot(
        label: '→ 0%',
        color: KinsuTheme.textSecondary,
      );
    }

    final deltaPct = ((current - previous) / previous) * 100;
    if (deltaPct.abs() < 0.1) {
      return const _TrendSnapshot(
        label: '→ 0%',
        color: KinsuTheme.textSecondary,
      );
    }

    final arrow = deltaPct > 0 ? '↑' : '↓';
    final pctValue = deltaPct.abs();
    final pctLabel = (pctValue - pctValue.roundToDouble()).abs() < 0.05
        ? pctValue.round().toString()
        : pctValue.toStringAsFixed(1);

    return _TrendSnapshot(
      label: '$arrow $pctLabel%',
      color: deltaPct > 0 ? KinsuTheme.statusWarning : KinsuTheme.statusActive,
    );
  }

  _VitalMetric _buildMetric({
    required List<VitalLog> vitals,
    required String vitalType,
    required IconData icon,
    required Color iconColor,
    required String label,
    required String defaultUnit,
  }) {
    final entries = _entriesForType(vitals, vitalType);

    if (entries.isEmpty) {
      return _VitalMetric(
        vitalType: vitalType,
        icon: icon,
        iconColor: iconColor,
        label: label,
        value: '--',
        unit: defaultUnit,
        change: 'No data',
        changeColor: KinsuTheme.textSecondary,
        contextNote: 'No readings logged yet.',
      );
    }

    final latest = entries.first;
    final trend = _buildTrend(entries);

    final valueLabel = vitalType == 'blood_pressure' &&
            latest.valueSecondary != null
        ? '${_formatNumber(latest.value)}/${_formatNumber(latest.valueSecondary!)}'
        : _formatNumber(latest.value);

    final unitLabel = latest.unit.trim().isEmpty ? defaultUnit : latest.unit;

    return _VitalMetric(
      vitalType: vitalType,
      icon: icon,
      iconColor: iconColor,
      label: label,
      value: valueLabel,
      unit: unitLabel,
      change: trend.label,
      changeColor: trend.color,
      contextNote: 'Last logged ${_formatDateTime(latest.recordedAt)}',
    );
  }

  _BloodPressureChartData _buildBloodPressureChartData(List<VitalLog> vitals) {
    final entries = _entriesForType(vitals, 'blood_pressure')
        .where((item) => item.valueSecondary != null)
        .toList()
        .reversed
        .toList();

    final recent =
        entries.length > 7 ? entries.sublist(entries.length - 7) : entries;

    if (recent.isEmpty) {
      return const _BloodPressureChartData.empty();
    }

    final systolicSpots = <FlSpot>[];
    final diastolicSpots = <FlSpot>[];
    final labels = <String>[];

    for (var i = 0; i < recent.length; i++) {
      final item = recent[i];
      systolicSpots.add(FlSpot(i.toDouble(), item.value));
      diastolicSpots.add(FlSpot(i.toDouble(), item.valueSecondary!));
      labels.add('${item.recordedAt.day}/${item.recordedAt.month}');
    }

    final allValues = <double>[
      ...systolicSpots.map((e) => e.y),
      ...diastolicSpots.map((e) => e.y),
    ];
    final rawMin = allValues.reduce(math.min);
    final rawMax = allValues.reduce(math.max);

    var minY = (rawMin - 10).floorToDouble();
    var maxY = (rawMax + 10).ceilToDouble();
    if (minY < 0) {
      minY = 0;
    }
    if ((maxY - minY) < 20) {
      maxY = minY + 20;
    }

    return _BloodPressureChartData(
      labels: labels,
      systolicSpots: systolicSpots,
      diastolicSpots: diastolicSpots,
      minY: minY,
      maxY: maxY,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitals Trends'),
        leading: const IosBackButton(),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const LogVitalScreen()),
          );
          if (!context.mounted) {
            return;
          }
          await context.read<VitalsProvider>().loadVitals();
        },
        backgroundColor: KinsuTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Log Vital'),
      ),
      body: Consumer<VitalsProvider>(
        builder: (context, provider, _) {
          final metrics = <_VitalMetric>[
            _buildMetric(
              vitals: provider.vitals,
              vitalType: 'blood_pressure',
              icon: Icons.favorite,
              iconColor: const Color(0xFFE53935),
              label: 'Blood Pressure',
              defaultUnit: 'mmHg',
            ),
            _buildMetric(
              vitals: provider.vitals,
              vitalType: 'blood_sugar',
              icon: Icons.local_fire_department,
              iconColor: const Color(0xFFFF9800),
              label: 'Blood Sugar',
              defaultUnit: 'mg/dL',
            ),
            _buildMetric(
              vitals: provider.vitals,
              vitalType: 'heart_rate',
              icon: Icons.show_chart,
              iconColor: KinsuTheme.primary,
              label: 'Heart Rate',
              defaultUnit: 'bpm',
            ),
            _buildMetric(
              vitals: provider.vitals,
              vitalType: 'spo2',
              icon: Icons.air,
              iconColor: const Color(0xFF2196F3),
              label: 'SpO2',
              defaultUnit: '%',
            ),
            _buildMetric(
              vitals: provider.vitals,
              vitalType: 'weight',
              icon: Icons.monitor_weight_outlined,
              iconColor: const Color(0xFF9C27B0),
              label: 'Weight',
              defaultUnit: 'kg',
            ),
            _buildMetric(
              vitals: provider.vitals,
              vitalType: 'temperature',
              icon: Icons.thermostat,
              iconColor: const Color(0xFFFF5722),
              label: 'Temperature',
              defaultUnit: '°F',
            ),
          ];

          final bpChart = _buildBloodPressureChartData(provider.vitals);
          final interval =
              ((bpChart.maxY - bpChart.minY) / 4).clamp(5, 40).toDouble();

          if (provider.isLoading && provider.vitals.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }

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
                      'Blood Pressure (recent)',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: KinsuTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 20),
                    if (bpChart.isEmpty)
                      const SizedBox(
                        height: 200,
                        child: Center(
                          child: Text(
                            'No blood pressure readings logged yet.',
                            style: TextStyle(color: KinsuTheme.textSecondary),
                          ),
                        ),
                      )
                    else
                      SizedBox(
                        height: 200,
                        child: LineChart(
                          LineChartData(
                            gridData: FlGridData(
                              show: true,
                              drawVerticalLine: false,
                              horizontalInterval: interval,
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
                                    final idx = value.toInt();
                                    if (idx >= 0 &&
                                        idx < bpChart.labels.length) {
                                      return Text(
                                        bpChart.labels[idx],
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
                                spots: bpChart.systolicSpots,
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
                                spots: bpChart.diastolicSpots,
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
                            minX: 0,
                            maxX: (bpChart.labels.length - 1).toDouble(),
                            minY: bpChart.minY,
                            maxY: bpChart.maxY,
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

class _TrendSnapshot {
  final String label;
  final Color color;

  const _TrendSnapshot({
    required this.label,
    required this.color,
  });
}

class _BloodPressureChartData {
  final List<String> labels;
  final List<FlSpot> systolicSpots;
  final List<FlSpot> diastolicSpots;
  final double minY;
  final double maxY;

  const _BloodPressureChartData({
    required this.labels,
    required this.systolicSpots,
    required this.diastolicSpots,
    required this.minY,
    required this.maxY,
  });

  const _BloodPressureChartData.empty()
      : labels = const <String>[],
        systolicSpots = const <FlSpot>[],
        diastolicSpots = const <FlSpot>[],
        minY = 0,
        maxY = 100;

  bool get isEmpty => labels.isEmpty;
}

class _VitalMetric {
  final String vitalType;
  final IconData icon;
  final Color iconColor;
  final String label;
  final String value;
  final String unit;
  final String change;
  final Color changeColor;
  final String? contextNote;

  const _VitalMetric({
    required this.vitalType,
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
