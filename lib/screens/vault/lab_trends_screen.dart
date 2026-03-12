import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/theme.dart';

class LabTrendsScreen extends StatefulWidget {
  const LabTrendsScreen({super.key});

  @override
  State<LabTrendsScreen> createState() => _LabTrendsScreenState();
}

class _LabTrendsScreenState extends State<LabTrendsScreen> {
  String _selectedParam = 'Hemoglobin';

  final Map<String, List<double>> _trendData = {
    'Hemoglobin': [13.2, 12.8, 13.5, 12.1, 13.8, 14.1],
    'RBC': [4.5, 4.3, 4.6, 4.2, 4.7, 4.8],
    'WBC': [7200, 6900, 7400, 7100, 7600, 7200],
    'HbA1c': [7.2, 7.1, 7.0, 6.9, 6.8, 6.8],
  };

  @override
  Widget build(BuildContext context) {
    final values = _trendData[_selectedParam]!;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Lab Trends'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            value: _selectedParam,
            decoration: const InputDecoration(labelText: 'Parameter'),
            items: _trendData.keys
                .map((key) => DropdownMenuItem(value: key, child: Text(key)))
                .toList(),
            onChanged: (value) {
              if (value == null) return;
              setState(() => _selectedParam = value);
            },
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: KinsuTheme.cardDecoration,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$_selectedParam (6 months)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: KinsuTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  height: 220,
                  child: LineChart(
                    LineChartData(
                      minX: 0,
                      maxX: (values.length - 1).toDouble(),
                      minY: values.reduce((a, b) => a < b ? a : b) * 0.9,
                      maxY: values.reduce((a, b) => a > b ? a : b) * 1.1,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (value) => FlLine(
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
                              const labels = [
                                'Sep',
                                'Oct',
                                'Nov',
                                'Dec',
                                'Jan',
                                'Feb',
                              ];
                              final idx = value.toInt();
                              if (idx < 0 || idx >= labels.length) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                labels[idx],
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: KinsuTheme.textSecondary,
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      lineBarsData: [
                        LineChartBarData(
                          spots: values
                              .asMap()
                              .entries
                              .map((entry) => FlSpot(
                                    entry.key.toDouble(),
                                    entry.value,
                                  ))
                              .toList(),
                          color: KinsuTheme.primary,
                          isCurved: true,
                          barWidth: 3,
                          belowBarData: BarAreaData(
                            show: true,
                            color: KinsuTheme.primary.withOpacity(0.12),
                          ),
                          dotData: FlDotData(
                            show: true,
                            getDotPainter: (spot, percent, bar, index) =>
                                FlDotCirclePainter(
                              radius: 4,
                              color: KinsuTheme.primary,
                              strokeWidth: 2,
                              strokeColor: Colors.white,
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
        ],
      ),
    );
  }
}
