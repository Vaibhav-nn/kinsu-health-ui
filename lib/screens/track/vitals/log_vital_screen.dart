import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/vital.dart';
import '../../../providers/vitals_provider.dart';

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

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _recordedAt,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now(),
    );
    if (pickedDate == null || !mounted) {
      return;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_recordedAt),
    );
    if (pickedTime == null) {
      return;
    }

    setState(() {
      _recordedAt = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Vitals'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            const Text(
              'Daily Record',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            const Text(
              'How are you feeling today? Regular tracking helps your care team provide more personalized insights.',
              style: TextStyle(color: KinsuTheme.textSecondary, height: 1.4),
            ),
            const SizedBox(height: 20),
            const _SectionLabel('Blood Pressure'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _VitalField(
                    controller: _bpSystolicController,
                    label: 'Systolic',
                    suffix: 'mmHg',
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _VitalField(
                    controller: _bpDiastolicController,
                    label: 'Diastolic',
                    suffix: 'mmHg',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _VitalField(
              controller: _bloodSugarController,
              label: 'Blood Sugar (Fasting)',
              suffix: 'mg/dL',
            ),
            const SizedBox(height: 16),
            _VitalField(
              controller: _heartRateController,
              label: 'Heart Rate',
              suffix: 'bpm',
            ),
            const SizedBox(height: 16),
            _VitalField(
              controller: _weightController,
              label: 'Weight',
              suffix: 'kg',
            ),
            const SizedBox(height: 16),
            _VitalField(
              controller: _temperatureController,
              label: 'Temperature',
              suffix: '°F',
            ),
            const SizedBox(height: 16),
            _VitalField(
              controller: _spo2Controller,
              label: 'SpO2',
              suffix: '%',
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _pickDateTime,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: KinsuTheme.cardDecoration,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined,
                        color: KinsuTheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      '${_recordedAt.day}/${_recordedAt.month}/${_recordedAt.year}  ${TimeOfDay.fromDateTime(_recordedAt).format(context)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              minLines: 4,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Additional Notes',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isLoading ? null : _submit,
              child: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('Save Vitals'),
            ),
            const SizedBox(height: 12),
            Text(
              'Last updated: ${MaterialLocalizations.of(context).formatMediumDate(_recordedAt)}, ${TimeOfDay.fromDateTime(_recordedAt).format(context)}',
              style: const TextStyle(
                color: KinsuTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _VitalField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;

  const _VitalField({
    required this.controller,
    required this.label,
    required this.suffix,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      validator: (value) {
        if (value == null || value.trim().isEmpty) {
          return null;
        }
        return double.tryParse(value.trim()) == null ? 'Invalid number' : null;
      },
      decoration: InputDecoration(
        labelText: label,
        suffixText: suffix,
      ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String title;

  const _SectionLabel(this.title);

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
    );
  }
}
