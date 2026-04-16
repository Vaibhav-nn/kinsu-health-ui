import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/vital.dart';
import '../../providers/vitals_provider.dart';
import '../../services/home_service.dart';
import 'medications/add_medication_screen.dart';
import 'symptoms/quick_symptom_log_screen.dart';
import 'vitals/log_vital_screen.dart';
import 'vitals/vitals_trends_screen.dart';

class TrackHome extends StatefulWidget {
  const TrackHome({super.key});

  @override
  State<TrackHome> createState() => _TrackHomeState();
}

class _TrackHomeState extends State<TrackHome> {
  String _displayName = 'there';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VitalsProvider>().loadVitals();
      _loadDisplayName();
    });
  }

  Future<void> _loadDisplayName() async {
    try {
      final overview = await context.read<HomeService>().fetchOverview();
      final raw = overview.profile.displayName.trim();
      if (!mounted || raw.isEmpty) {
        return;
      }
      setState(() {
        _displayName = raw;
      });
    } catch (_) {
      // Keep default fallback when profile endpoint is temporarily unavailable.
    }
  }

  List<VitalLog> _entriesForType(List<VitalLog> vitals, String type) {
    final expectedType = _normalizeVitalType(type);
    final list = vitals
        .where((item) => _normalizeVitalType(item.vitalType) == expectedType)
        .toList()
      ..sort((a, b) => a.recordedAt.compareTo(b.recordedAt));
    return list;
  }

  String _normalizeVitalType(String value) {
    return value.trim().toLowerCase().replaceAll(' ', '_');
  }

  String _formatNumber(double value) {
    if ((value - value.roundToDouble()).abs() < 0.05) {
      return value.round().toString();
    }
    return value.toStringAsFixed(1);
  }

  _TrendStat _buildTrendStat({
    required List<VitalLog> vitals,
    required String type,
    required String label,
    required String fallbackUnit,
    required Color color,
  }) {
    final entries = _entriesForType(vitals, type);
    if (entries.isEmpty) {
      return _TrendStat(
        label: label,
        value: '--',
        unit: fallbackUnit,
        delta: '→ 0%',
        color: color,
      );
    }

    final latest = entries.last;
    final displayValue = type == 'blood_pressure' &&
            latest.valueSecondary != null
        ? '${_formatNumber(latest.value)}/${_formatNumber(latest.valueSecondary!)}'
        : _formatNumber(latest.value);

    String delta = '→ 0%';
    if (entries.length >= 2) {
      final prev = entries[entries.length - 2].value;
      if (prev.abs() > 0.001) {
        final pct = ((latest.value - prev) / prev) * 100;
        if (pct.abs() >= 0.1) {
          delta = '${pct > 0 ? '↑' : '↓'} ${pct.abs().round()}%';
        }
      }
    }

    return _TrendStat(
      label: label,
      value: displayValue,
      unit: latest.unit.trim().isEmpty ? fallbackUnit : latest.unit,
      delta: delta,
      color: color,
    );
  }

  String _latestInsightBody(List<VitalLog> vitals) {
    if (vitals.isEmpty) {
      return 'Start logging vitals to unlock your latest trend insights.';
    }

    final sorted = [...vitals]
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));
    final latest = sorted.first;
    final label = latest.vitalType.trim().replaceAll('_', ' ');
    final titleCase = label
        .split(' ')
        .where((part) => part.isNotEmpty)
        .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
        .join(' ');
    final value = latest.valueSecondary != null
        ? '${_formatNumber(latest.value)}/${_formatNumber(latest.valueSecondary!)}'
        : _formatNumber(latest.value);
    return 'Latest saved: $titleCase $value ${latest.unit} at '
        '${latest.recordedAt.hour.toString().padLeft(2, '0')}:${latest.recordedAt.minute.toString().padLeft(2, '0')}.';
  }

  @override
  Widget build(BuildContext context) {
    final vitalsProvider = context.watch<VitalsProvider>();

    final bp = _buildTrendStat(
      vitals: vitalsProvider.vitals,
      type: 'blood_pressure',
      label: 'BP',
      fallbackUnit: 'mmHg',
      color: const Color(0xFFDC6C5C),
    );

    final hr = _buildTrendStat(
      vitals: vitalsProvider.vitals,
      type: 'heart_rate',
      label: 'HR',
      fallbackUnit: 'bpm',
      color: const Color(0xFF0F9A96),
    );

    final hrEntries = _entriesForType(vitalsProvider.vitals, 'heart_rate');
    final chartValues = hrEntries.isEmpty
        ? const [70.0, 74.0, 73.0, 82.0, 79.0, 76.0, 84.0]
        : hrEntries
            .skip(math.max(0, hrEntries.length - 7))
            .map((item) => item.value)
            .toList();

    return Scaffold(
      backgroundColor: KinsuTheme.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 30),
          children: [
            const Text(
              'DAILY OVERVIEW',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: KinsuTheme.primary,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Good morning, $_displayName.',
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                height: 1.0,
                color: KinsuTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Your wellness markers are stable today. Take a moment to log your morning vitals.',
              style: TextStyle(
                color: KinsuTheme.textSecondary,
                fontSize: 14,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 18),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF6F8F8),
                borderRadius: BorderRadius.circular(26),
                border: Border.all(color: KinsuTheme.divider),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: KinsuTheme.primaryLight,
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Text(
                          'VITALS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: KinsuTheme.primaryDark,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Vitality Metrics',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            height: 1.1,
                          ),
                        ),
                      ),
                      _TrendChip(stat: bp),
                      const SizedBox(width: 6),
                      _TrendChip(stat: hr),
                    ],
                  ),
                  const SizedBox(height: 16),
                  SizedBox(height: 128, child: _Sparkline(values: chartValues)),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children:
                        const ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN']
                            .map(
                              (label) => Text(
                                label,
                                style: TextStyle(
                                  color: KinsuTheme.textSecondary,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                            .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Icons.monitor_heart_outlined,
                    label: 'Log Vitals',
                    iconBg: const Color(0xFFE8F5F7),
                    iconColor: const Color(0xFF3D7281),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const LogVitalScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.medication_outlined,
                    label: 'Log Meds',
                    iconBg: const Color(0xFFF7EFC8),
                    iconColor: const Color(0xFF7D7418),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AddMedicationScreen()),
                      );
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.bolt_rounded,
                    label: 'Log Symptoms',
                    iconBg: const Color(0xFFE6F5E4),
                    iconColor: const Color(0xFF648932),
                    highlight: true,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const QuickSymptomLogScreen()),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            const _InsightRow(
              icon: Icons.lightbulb_outline_rounded,
              title: 'Weekly Wellness Tip',
              body:
                  'Increasing your hydration by just 500ml daily can significantly improve your morning vital readings.',
              accent: Color(0xFF5AA5AD),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const VitalsTrendsScreen()),
                );
              },
              child: _InsightRow(
                icon: Icons.history_rounded,
                title: 'Last Saved Vitals',
                body: _latestInsightBody(vitalsProvider.vitals),
                accent: Color(0xFF8B5CF6),
                trailing: const Icon(
                  Icons.chevron_right_rounded,
                  color: KinsuTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color iconBg;
  final Color iconColor;
  final bool highlight;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.iconBg,
    required this.iconColor,
    this.highlight = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        constraints: const BoxConstraints(minHeight: 158),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 16),
        decoration: BoxDecoration(
          color: highlight ? const Color(0xFFECF6D8) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: KinsuTheme.divider),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: iconColor, size: 25),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TrendChip extends StatelessWidget {
  final _TrendStat stat;

  const _TrendChip({required this.stat});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: stat.color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        stat.label,
        style: TextStyle(
          color: stat.color,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _InsightRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  final Color accent;
  final Widget? trailing;

  const _InsightRow({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: KinsuTheme.divider),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: KinsuTheme.primaryDark),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 14,
                    color: KinsuTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}

class _Sparkline extends StatelessWidget {
  final List<double> values;

  const _Sparkline({required this.values});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _SparklinePainter(values),
      child: const SizedBox.expand(),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> values;

  _SparklinePainter(this.values);

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) {
      return;
    }

    final minValue = values.reduce(math.min);
    final maxValue = values.reduce(math.max);
    final spread =
        (maxValue - minValue).abs() < 0.001 ? 1.0 : maxValue - minValue;

    final linePaint = Paint()
      ..color = KinsuTheme.primaryDark
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x33149C97), Color(0x00149C97)],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < values.length; i++) {
      final x = (size.width - 24) * (i / math.max(values.length - 1, 1)) + 12;
      final normalized = (values[i] - minValue) / spread;
      final y = (size.height - 12) - (normalized * (size.height - 46));

      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height - 2);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    final lastX = (size.width - 24) + 12;
    fillPath.lineTo(lastX, size.height - 2);
    fillPath.close();

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = KinsuTheme.primaryDark;
    for (var i = 0; i < values.length; i++) {
      final x = (size.width - 24) * (i / math.max(values.length - 1, 1)) + 12;
      final normalized = (values[i] - minValue) / spread;
      final y = (size.height - 12) - (normalized * (size.height - 46));
      canvas.drawCircle(Offset(x, y), 4.5, dotPaint);
      canvas.drawCircle(Offset(x, y), 2, Paint()..color = Colors.white);
    }
  }

  @override
  bool shouldRepaint(covariant _SparklinePainter oldDelegate) {
    return oldDelegate.values != values;
  }
}

class _TrendStat {
  final String label;
  final String value;
  final String unit;
  final String delta;
  final Color color;

  const _TrendStat({
    required this.label,
    required this.value,
    required this.unit,
    required this.delta,
    required this.color,
  });
}
