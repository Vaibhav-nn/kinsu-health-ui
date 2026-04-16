import 'package:flutter/material.dart';
import 'package:kinsu_health/widgets/ios_back_button.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/symptom.dart';
import '../../../providers/symptoms_provider.dart';

/// Form to add a new chronic symptom.
class AddSymptomScreen extends StatefulWidget {
  const AddSymptomScreen({super.key});

  @override
  State<AddSymptomScreen> createState() => _AddSymptomScreenState();
}

class _AddSymptomScreenState extends State<AddSymptomScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _triggersController = TextEditingController();
  final _notesController = TextEditingController();

  int _severity = 5;
  String _frequency = 'daily';
  String? _bodyArea;
  DateTime _firstNoticed = DateTime.now();

  static const _frequencies = ['daily', 'weekly', 'monthly', 'intermittent'];
  static const _bodyAreas = [
    'Head',
    'Neck',
    'Chest',
    'Back',
    'Abdomen',
    'Arms',
    'Legs',
    'Joints',
    'General',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _triggersController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<SymptomsProvider>();
    if (provider.isLoading) {
      return;
    }

    FocusScope.of(context).unfocus();

    final symptom = ChronicSymptom(
      symptomName: _nameController.text.trim(),
      severity: _severity,
      frequency: _frequency,
      bodyArea: _bodyArea?.toLowerCase(),
      triggers: _triggersController.text.trim().isNotEmpty
          ? _triggersController.text.trim()
          : null,
      firstNoticed: _firstNoticed,
      notes: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    final success = await provider.addSymptom(symptom);

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Symptom added!'),
          backgroundColor: KinsuTheme.statusActive,
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    final errorMessage =
        provider.error ?? 'Unable to save symptom. Please try again.';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(errorMessage),
        backgroundColor: KinsuTheme.statusError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context
        .select<SymptomsProvider, bool>((provider) => provider.isLoading);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Symptom'),
        leading: const IosBackButton(),
        automaticallyImplyLeading: false,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Symptom Name',
                hintText: 'e.g. Migraine, Joint Pain',
              ),
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
            const Text(
              'Severity',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text('1',
                    style: TextStyle(color: KinsuTheme.textSecondary)),
                Expanded(
                  child: Slider(
                    value: _severity.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: KinsuTheme.primary,
                    label: '$_severity',
                    onChanged: (value) =>
                        setState(() => _severity = value.round()),
                  ),
                ),
                const Text('10',
                    style: TextStyle(color: KinsuTheme.textSecondary)),
              ],
            ),
            Center(
              child: Text(
                '$_severity / 10',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: KinsuTheme.primary,
                ),
              ),
            ),
            const SizedBox(height: 20),
            const Text(
              'Frequency',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _frequencies.map((frequency) {
                final isSelected = _frequency == frequency;
                return ChoiceChip(
                  label: Text(
                    frequency[0].toUpperCase() + frequency.substring(1),
                  ),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _frequency = frequency);
                    }
                  },
                  selectedColor: KinsuTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : KinsuTheme.textPrimary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),
            DropdownButtonFormField<String>(
              initialValue: _bodyArea,
              decoration: const InputDecoration(labelText: 'Body Area'),
              items: _bodyAreas
                  .map((area) =>
                      DropdownMenuItem(value: area, child: Text(area)))
                  .toList(),
              onChanged: (value) => setState(() => _bodyArea = value),
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _firstNoticed,
                  firstDate: DateTime(2015),
                  lastDate: DateTime.now(),
                );
                if (date != null) {
                  setState(() => _firstNoticed = date);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: KinsuTheme.cardDecoration,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        size: 20, color: KinsuTheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      'First noticed: ${_firstNoticed.day}/${_firstNoticed.month}/${_firstNoticed.year}',
                      style: const TextStyle(fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _triggersController,
              decoration: const InputDecoration(
                labelText: 'Triggers (optional)',
                hintText: 'e.g. Stress, Weather changes',
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 32),
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
                  : const Text('Save Symptom'),
            ),
          ],
        ),
      ),
    );
  }
}
