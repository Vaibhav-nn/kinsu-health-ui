import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/vital.dart';
import '../../../providers/vitals_provider.dart';

/// Form screen to log a new vital reading.
class LogVitalScreen extends StatefulWidget {
  const LogVitalScreen({super.key});

  @override
  State<LogVitalScreen> createState() => _LogVitalScreenState();
}

class _LogVitalScreenState extends State<LogVitalScreen> {
  final _formKey = GlobalKey<FormState>();
  String _selectedType = 'blood_pressure';
  final _valueController = TextEditingController();
  final _secondaryController = TextEditingController();
  final _notesController = TextEditingController();
  DateTime _recordedAt = DateTime.now();

  static const _vitalTypes = {
    'blood_pressure': {'label': 'Blood Pressure', 'unit': 'mmHg', 'hasSecondary': true},
    'blood_sugar': {'label': 'Blood Sugar', 'unit': 'mg/dL', 'hasSecondary': false},
    'heart_rate': {'label': 'Heart Rate', 'unit': 'bpm', 'hasSecondary': false},
    'spo2': {'label': 'SpO2', 'unit': '%', 'hasSecondary': false},
    'weight': {'label': 'Weight', 'unit': 'kg', 'hasSecondary': false},
    'temperature': {'label': 'Temperature', 'unit': '°F', 'hasSecondary': false},
  };

  Map<String, dynamic> get _currentConfig => _vitalTypes[_selectedType]!;

  @override
  void dispose() {
    _valueController.dispose();
    _secondaryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final vital = VitalLog(
      vitalType: _selectedType,
      value: double.parse(_valueController.text),
      valueSecondary: _secondaryController.text.isNotEmpty
          ? double.parse(_secondaryController.text)
          : null,
      unit: _currentConfig['unit'] as String,
      recordedAt: _recordedAt,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    final success = await context.read<VitalsProvider>().logVital(vital);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Vital logged successfully!'),
          backgroundColor: KinsuTheme.statusActive,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasSecondary = _currentConfig['hasSecondary'] as bool;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Vital'),
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
            // ── Vital Type Selector ─────────────────
            const Text(
              'Vital Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KinsuTheme.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _vitalTypes.entries.map((entry) {
                final isSelected = _selectedType == entry.key;
                return ChoiceChip(
                  label: Text(entry.value['label'] as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedType = entry.key;
                        _valueController.clear();
                        _secondaryController.clear();
                      });
                    }
                  },
                  selectedColor: KinsuTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : KinsuTheme.textPrimary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // ── Value Input ─────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _valueController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: hasSecondary
                          ? 'Systolic'
                          : _currentConfig['label'] as String,
                      suffixText: _currentConfig['unit'] as String,
                    ),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Required';
                      if (double.tryParse(v) == null) return 'Invalid number';
                      return null;
                    },
                  ),
                ),
                if (hasSecondary) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _secondaryController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Diastolic',
                        suffixText: _currentConfig['unit'] as String,
                      ),
                      validator: (v) {
                        if (hasSecondary && (v == null || v.isEmpty)) {
                          return 'Required';
                        }
                        if (v != null && v.isNotEmpty && double.tryParse(v) == null) {
                          return 'Invalid';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),

            // ── Date & Time ─────────────────────────
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _recordedAt,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: TimeOfDay.fromDateTime(_recordedAt),
                  );
                  if (time != null) {
                    setState(() {
                      _recordedAt = DateTime(
                        date.year, date.month, date.day,
                        time.hour, time.minute,
                      );
                    });
                  }
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: KinsuTheme.cardDecoration,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: KinsuTheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      '${_recordedAt.day}/${_recordedAt.month}/${_recordedAt.year}  '
                      '${_recordedAt.hour.toString().padLeft(2, '0')}:'
                      '${_recordedAt.minute.toString().padLeft(2, '0')}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ── Notes ───────────────────────────────
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit ──────────────────────────────
            Consumer<VitalsProvider>(
              builder: (context, provider, _) {
                return ElevatedButton(
                  onPressed: provider.isLoading ? null : _submit,
                  child: provider.isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text('Save Vital'),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
