import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../providers/symptoms_provider.dart';

class QuickSymptomLogScreen extends StatefulWidget {
  const QuickSymptomLogScreen({super.key});

  @override
  State<QuickSymptomLogScreen> createState() => _QuickSymptomLogScreenState();
}

class _QuickSymptomLogScreenState extends State<QuickSymptomLogScreen> {
  static const List<String> _symptoms = [
    'Headache',
    'Fatigue',
    'Nausea',
    'Dizziness',
    'Body ache',
    'Fever',
    'Cough',
    'Breathlessness',
  ];

  final TextEditingController _notesController = TextEditingController();
  String? _selectedSymptom = _symptoms.first;
  int _severity = 5;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final symptom = _selectedSymptom;
    if (symptom == null) {
      return;
    }

    final provider = context.read<SymptomsProvider>();
    final success = await provider.quickLogSymptom(
      symptomName: symptom,
      severity: _severity,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Symptoms logged successfully.'),
          backgroundColor: KinsuTheme.statusActive,
        ),
      );
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          provider.error ?? 'Unable to log symptoms. Please try again.',
        ),
        backgroundColor: KinsuTheme.statusError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaving =
        context.select<SymptomsProvider, bool>((provider) => provider.isLoading);

    return Scaffold(
      backgroundColor: KinsuTheme.background,
      appBar: AppBar(
        title: const Text('Quick Symptom Log'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'What are you experiencing?',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _symptoms
                .map(
                  (symptom) => ChoiceChip(
                    label: Text(symptom),
                    selected: _selectedSymptom == symptom,
                    onSelected: (_) {
                      setState(() => _selectedSymptom = symptom);
                    },
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 28),
          const Text(
            'Severity (1-10)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: KinsuTheme.primary,
              inactiveTrackColor: KinsuTheme.textSecondary.withValues(alpha: 0.25),
              thumbColor: KinsuTheme.primary,
              overlayColor: KinsuTheme.primary.withValues(alpha: 0.12),
            ),
            child: Slider(
              value: _severity.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) => setState(() => _severity = value.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mild',
                style: TextStyle(color: KinsuTheme.textSecondary),
              ),
              Text(
                '$_severity/10',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Text(
                'Severe',
                style: TextStyle(color: KinsuTheme.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const Text(
            'Notes (optional)',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _notesController,
            minLines: 4,
            maxLines: 4,
            decoration: const InputDecoration(
              hintText: 'Add any additional details...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 28),
          ElevatedButton(
            onPressed: isSaving ? null : _submit,
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text('Log Symptoms'),
          ),
        ],
      ),
    );
  }
}
