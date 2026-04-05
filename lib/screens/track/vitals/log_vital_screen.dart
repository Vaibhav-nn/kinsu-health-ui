import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/vital.dart';
import '../../../providers/vitals_provider.dart';
import '../widgets/track_flow_bottom_nav.dart';

class LogVitalScreen extends StatefulWidget {
  const LogVitalScreen({super.key});

  @override
  State<LogVitalScreen> createState() => _LogVitalScreenState();
}

class _LogVitalScreenState extends State<LogVitalScreen> {
  final _formKey = GlobalKey<FormState>();

  final _bpSystolicController = TextEditingController();
  final _bpDiastolicController = TextEditingController();
  final _bloodSugarController = TextEditingController();
  final _heartRateController = TextEditingController();
  final _weightController = TextEditingController();
  final _temperatureController = TextEditingController();
  final _spo2Controller = TextEditingController();
  final _notesController = TextEditingController();

  DateTime _recordedAt = DateTime.now();

  @override
  void dispose() {
    _bpSystolicController.dispose();
    _bpDiastolicController.dispose();
    _bloodSugarController.dispose();
    _heartRateController.dispose();
    _weightController.dispose();
    _temperatureController.dispose();
    _spo2Controller.dispose();
    _notesController.dispose();
    super.dispose();
  }

  double? _parseNumber(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return double.tryParse(trimmed);
  }

  Future<void> _submit() async {
    final hasAnyValue = [
      _bpSystolicController,
      _bpDiastolicController,
      _bloodSugarController,
      _heartRateController,
      _weightController,
      _temperatureController,
      _spo2Controller,
    ].any((controller) => controller.text.trim().isNotEmpty);

    if (!hasAnyValue) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter at least one vital before saving.'),
          backgroundColor: KinsuTheme.statusWarning,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final snapshot = VitalSnapshot(
      recordedAt: _recordedAt,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      bloodPressureSystolic: _parseNumber(_bpSystolicController.text),
      bloodPressureDiastolic: _parseNumber(_bpDiastolicController.text),
      bloodSugar: _parseNumber(_bloodSugarController.text),
      heartRate: _parseNumber(_heartRateController.text),
      weight: _parseNumber(_weightController.text),
      temperature: _parseNumber(_temperatureController.text),
      spo2: _parseNumber(_spo2Controller.text),
    );

    final success = await context.read<VitalsProvider>().logSnapshot(snapshot);
    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily vitals saved successfully.'),
          backgroundColor: KinsuTheme.statusActive,
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.read<VitalsProvider>().error ??
              'Unable to save vitals right now.',
        ),
        backgroundColor: KinsuTheme.statusError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<VitalsProvider>().isLoading;
    final updatedLabel = MaterialLocalizations.of(context).formatTimeOfDay(
      TimeOfDay.fromDateTime(_recordedAt),
      alwaysUse24HourFormat: false,
    );

    return Scaffold(
      backgroundColor: KinsuTheme.background,
      bottomNavigationBar: const TrackFlowBottomNav(
        selectedTab: TrackFlowNavTab.vitals,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: KinsuTheme.primaryDark,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 10),
                    const Expanded(
                      child: Text(
                        'Log Vitals',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: KinsuTheme.primaryDark,
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => Navigator.of(context).pop(),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE9EFF2),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_outline_rounded,
                            size: 16, color: KinsuTheme.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  children: [
                    const Text(
                      'DAILY RECORD',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF9AA888),
                        letterSpacing: 1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'How are you feeling\ntoday?',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                        color: KinsuTheme.primaryDark,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Regular tracking helps your care team provide more personalized insights. Your data is encrypted and secure.',
                      style: TextStyle(
                        fontSize: 14,
                        color: KinsuTheme.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _VitalInputCard(
                      icon: Icons.monitor_heart_outlined,
                      label: 'Blood Pressure',
                      valueBuilder: Row(
                        children: [
                          Expanded(
                            child: _PlainInput(
                              controller: _bpSystolicController,
                              hint: '120',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _PlainInput(
                              controller: _bpDiastolicController,
                              hint: '80',
                            ),
                          ),
                        ],
                      ),
                      unit: 'MMHG',
                    ),
                    const SizedBox(height: 10),
                    _VitalInputCard(
                      icon: Icons.monitor_weight_outlined,
                      label: 'Weight',
                      valueBuilder: _PlainInput(
                          controller: _weightController, hint: '0.0'),
                      unit: 'KG',
                    ),
                    const SizedBox(height: 10),
                    _VitalInputCard(
                      icon: Icons.thermostat_outlined,
                      label: 'Temperature',
                      valueBuilder: _PlainInput(
                          controller: _temperatureController, hint: '98.4'),
                      unit: '°F',
                    ),
                    const SizedBox(height: 10),
                    _VitalInputCard(
                      icon: Icons.favorite_outline_rounded,
                      label: 'Heart Rate',
                      valueBuilder: _PlainInput(
                          controller: _heartRateController, hint: '72'),
                      unit: 'BPM',
                    ),
                    const SizedBox(height: 10),
                    _VitalInputCard(
                      icon: Icons.bloodtype_outlined,
                      label: 'Blood Sugar',
                      valueBuilder: _PlainInput(
                          controller: _bloodSugarController, hint: '100'),
                      unit: 'MG/DL',
                    ),
                    const SizedBox(height: 10),
                    _VitalInputCard(
                      icon: Icons.air_rounded,
                      label: 'SpO2',
                      highlighted: true,
                      valueBuilder:
                          _PlainInput(controller: _spo2Controller, hint: '98'),
                      unit: '%',
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: KinsuTheme.divider),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Row(
                            children: [
                              Icon(Icons.notes_rounded,
                                  size: 16, color: KinsuTheme.textSecondary),
                              SizedBox(width: 8),
                              Text(
                                'Additional Notes',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 15,
                                  color: KinsuTheme.textPrimary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextFormField(
                            controller: _notesController,
                            minLines: 3,
                            maxLines: 4,
                            decoration: const InputDecoration(
                              hintText:
                                  'Symptoms, context, or notes for your physician...',
                              isDense: true,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _submit,
                      icon: const Icon(Icons.check_circle_outline_rounded,
                          size: 18),
                      label: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Vitals'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'LAST UPDATED TODAY, $updatedLabel',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFFC3CBD6),
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VitalInputCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget valueBuilder;
  final String unit;
  final bool highlighted;

  const _VitalInputCard({
    required this.icon,
    required this.label,
    required this.valueBuilder,
    required this.unit,
    this.highlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: highlighted ? const Color(0xFFF4F8D8) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KinsuTheme.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: KinsuTheme.primaryDark),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: KinsuTheme.primaryDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          valueBuilder,
          const SizedBox(height: 4),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: KinsuTheme.textSecondary,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}

class _PlainInput extends StatelessWidget {
  final TextEditingController controller;
  final String hint;

  const _PlainInput({required this.controller, required this.hint});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        hintText: hint,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
    );
  }
}
