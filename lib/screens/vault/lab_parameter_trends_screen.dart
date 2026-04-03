import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/vault_models.dart';
import '../../providers/vault_provider.dart';

class LabParameterTrendsScreen extends StatefulWidget {
  final String initialParameterKey;

  const LabParameterTrendsScreen({
    super.key,
    this.initialParameterKey = 'hemoglobin',
  });

  @override
  State<LabParameterTrendsScreen> createState() =>
      _LabParameterTrendsScreenState();
}

class _LabParameterTrendsScreenState extends State<LabParameterTrendsScreen> {
  static const List<_LabParameterOption> _options = [
    _LabParameterOption('hemoglobin', 'Hemoglobin'),
    _LabParameterOption('rbc', 'RBC'),
    _LabParameterOption('wbc', 'WBC'),
    _LabParameterOption('hba1c', 'HbA1c'),
    _LabParameterOption('tsh', 'TSH'),
  ];

  late String _selectedParameterKey;
  VaultLabTrend? _trend;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _selectedParameterKey = widget.initialParameterKey;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadTrend();
    });
  }

  Future<void> _loadTrend() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final trend = await context
          .read<VaultProvider>()
          .fetchLabTrend(_selectedParameterKey);
      if (!mounted) {
        return;
      }
      setState(() {
        _trend = trend;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  Color _statusColor(String? status) {
    switch ((status ?? '').toLowerCase()) {
      case 'normal':
      case 'normal_range':
        return KinsuTheme.statusActive;
      case 'high':
      case 'elevated':
        return const Color(0xFFF59E0B);
      case 'low':
        return const Color(0xFF3B82F6);
      default:
        return KinsuTheme.textSecondary;
    }
  }

  String _statusLabel(String? status) {
    final value = (status ?? '').trim();
    if (value.isEmpty) {
      return 'Awaiting data';
    }
    return value.replaceAll('_', ' ');
  }

  String _formatValue(double value) {
    if ((value - value.roundToDouble()).abs() < 0.05) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  List<FlSpot> _spots(List<VaultLabTrendPoint> points) {
    return points
        .asMap()
        .entries
        .map((entry) => FlSpot(entry.key.toDouble(), entry.value.value))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final trend = _trend;
    final labelStyle = Theme.of(context)
        .textTheme
        .bodySmall
        ?.copyWith(color: KinsuTheme.textSecondary);

    return Scaffold(
      backgroundColor: KinsuTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Lab Parameter Trends',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 50,
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: _options.length,
                separatorBuilder: (_, __) => const SizedBox(width: 8),
                itemBuilder: (context, index) {
                  final option = _options[index];
                  final selected = option.key == _selectedParameterKey;
                  return ChoiceChip(
                    label: Text(option.label),
                    selected: selected,
                    onSelected: (_) {
                      if (_selectedParameterKey == option.key) {
                        return;
                      }
                      setState(() {
                        _selectedParameterKey = option.key;
                      });
                      _loadTrend();
                    },
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _error != null
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.error_outline,
                                  size: 52,
                                  color: KinsuTheme.textSecondary,
                                ),
                                const SizedBox(height: 12),
                                Text(
                                  _error!,
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(
                                    color: KinsuTheme.textSecondary,
                                  ),
                                ),
                                const SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _loadTrend,
                                  child: const Text('Retry'),
                                ),
                              ],
                            ),
                          ),
                        )
                      : trend == null
                          ? const SizedBox.shrink()
                          : ListView(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: KinsuTheme.cardDecoration,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  trend.parameterLabel,
                                                  style: const TextStyle(
                                                    fontSize: 18,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                const SizedBox(height: 4),
                                                const Text(
                                                  '6-month trend',
                                                  style: TextStyle(
                                                    color: KinsuTheme
                                                        .textSecondary,
                                                    fontSize: 14,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.end,
                                            children: [
                                              Text(
                                                trend.latestValue == null
                                                    ? '--'
                                                    : _formatValue(
                                                        trend.latestValue!,
                                                      ),
                                                style: const TextStyle(
                                                  fontSize: 28,
                                                  fontWeight: FontWeight.w800,
                                                  color: KinsuTheme.textPrimary,
                                                ),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                _statusLabel(trend.status),
                                                style: TextStyle(
                                                  color: _statusColor(
                                                      trend.status),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 20),
                                      SizedBox(
                                        height: 240,
                                        child: trend.dataPoints.isEmpty
                                            ? const Center(
                                                child: Text(
                                                  'No trend data available yet.',
                                                  style: TextStyle(
                                                    color: KinsuTheme
                                                        .textSecondary,
                                                  ),
                                                ),
                                              )
                                            : LineChart(
                                                LineChartData(
                                                  minX: 0,
                                                  maxX:
                                                      (trend.dataPoints.length -
                                                              1)
                                                          .toDouble(),
                                                  gridData: FlGridData(
                                                    show: true,
                                                    drawVerticalLine: false,
                                                    horizontalInterval: 1,
                                                    getDrawingHorizontalLine:
                                                        (_) => const FlLine(
                                                      color: Color(0xFFE6EEF2),
                                                      strokeWidth: 1,
                                                    ),
                                                  ),
                                                  borderData:
                                                      FlBorderData(show: false),
                                                  titlesData: FlTitlesData(
                                                    topTitles: const AxisTitles(
                                                      sideTitles: SideTitles(
                                                        showTitles: false,
                                                      ),
                                                    ),
                                                    rightTitles:
                                                        const AxisTitles(
                                                      sideTitles: SideTitles(
                                                        showTitles: false,
                                                      ),
                                                    ),
                                                    leftTitles: AxisTitles(
                                                      sideTitles: SideTitles(
                                                        showTitles: true,
                                                        reservedSize: 38,
                                                        getTitlesWidget:
                                                            (value, _) => Text(
                                                          value.toStringAsFixed(
                                                              1),
                                                          style: labelStyle,
                                                        ),
                                                      ),
                                                    ),
                                                    bottomTitles: AxisTitles(
                                                      sideTitles: SideTitles(
                                                        showTitles: true,
                                                        reservedSize: 30,
                                                        getTitlesWidget:
                                                            (value, _) {
                                                          final index = value
                                                              .round()
                                                              .clamp(
                                                                0,
                                                                trend.dataPoints
                                                                        .length -
                                                                    1,
                                                              );
                                                          final date = trend
                                                              .dataPoints[index]
                                                              .observedOn;
                                                          const labels = [
                                                            'Jan',
                                                            'Feb',
                                                            'Mar',
                                                            'Apr',
                                                            'May',
                                                            'Jun',
                                                            'Jul',
                                                            'Aug',
                                                            'Sep',
                                                            'Oct',
                                                            'Nov',
                                                            'Dec',
                                                          ];
                                                          return Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .only(
                                                              top: 8,
                                                            ),
                                                            child: Text(
                                                              labels[
                                                                  date.month -
                                                                      1],
                                                              style: labelStyle,
                                                            ),
                                                          );
                                                        },
                                                      ),
                                                    ),
                                                  ),
                                                  lineBarsData: [
                                                    LineChartBarData(
                                                      spots: _spots(
                                                          trend.dataPoints),
                                                      isCurved: true,
                                                      color: KinsuTheme.primary,
                                                      barWidth: 4,
                                                      dotData: FlDotData(
                                                        show: true,
                                                        getDotPainter: (_, __,
                                                                ___, ____) =>
                                                            FlDotCirclePainter(
                                                          radius: 5,
                                                          color: Colors.white,
                                                          strokeWidth: 3,
                                                          strokeColor:
                                                              KinsuTheme
                                                                  .primary,
                                                        ),
                                                      ),
                                                      belowBarData: BarAreaData(
                                                        show: true,
                                                        gradient:
                                                            LinearGradient(
                                                          begin: Alignment
                                                              .topCenter,
                                                          end: Alignment
                                                              .bottomCenter,
                                                          colors: [
                                                            KinsuTheme.primary
                                                                .withValues(
                                                                    alpha:
                                                                        0.18),
                                                            KinsuTheme.primary
                                                                .withValues(
                                                                    alpha:
                                                                        0.02),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: KinsuTheme.cardDecoration,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      const Text(
                                        'History',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 12),
                                      if (trend.history.isEmpty)
                                        const Text(
                                          'No historical results available.',
                                          style: TextStyle(
                                            color: KinsuTheme.textSecondary,
                                          ),
                                        )
                                      else
                                        ...trend.history.map(
                                          (item) => Container(
                                            padding: const EdgeInsets.symmetric(
                                              vertical: 14,
                                            ),
                                            decoration: const BoxDecoration(
                                              border: Border(
                                                bottom: BorderSide(
                                                  color: KinsuTheme.divider,
                                                ),
                                              ),
                                            ),
                                            child: Row(
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    MaterialLocalizations.of(
                                                            context)
                                                        .formatMediumDate(
                                                      item.observedOn,
                                                    ),
                                                    style: const TextStyle(
                                                      color: KinsuTheme
                                                          .textSecondary,
                                                      fontSize: 14,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  '${_formatValue(item.value)} ${item.unit}',
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w700,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                    ],
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

class _LabParameterOption {
  final String key;
  final String label;

  const _LabParameterOption(this.key, this.label);
}
