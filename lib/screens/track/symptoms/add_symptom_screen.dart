import 'package:flutter/material.dart';
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
    'Head', 'Neck', 'Chest', 'Back', 'Abdomen',
    'Arms', 'Legs', 'Joints', 'General'
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _triggersController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final symptom = ChronicSymptom(
      symptomName: _nameController.text,
      severity: _severity,
      frequency: _frequency,
      bodyArea: _bodyArea?.toLowerCase(),
      triggers: _triggersController.text.isNotEmpty ? _triggersController.text : null,
      firstNoticed: _firstNoticed,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    final success = await context.read<SymptomsProvider>().addSymptom(symptom);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Symptom added!'),
          backgroundColor: KinsuTheme.statusActive,
        ),
      );
      Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add Symptom'),
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
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Symptom Name',
                hintText: 'e.g. Migraine, Joint Pain',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            // ── Severity Slider ─────────────────────
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
                const Text('1', style: TextStyle(color: KinsuTheme.textSecondary)),
                Expanded(
                  child: Slider(
                    value: _severity.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    activeColor: KinsuTheme.primary,
                    label: '$_severity',
                    onChanged: (v) => setState(() => _severity = v.round()),
                  ),
                ),
                const Text('10', style: TextStyle(color: KinsuTheme.textSecondary)),
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

            // ── Frequency ───────────────────────────
            const Text(
              'Frequency',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _frequencies.map((f) {
                final isSelected = _frequency == f;
                return ChoiceChip(
                  label: Text(f[0].toUpperCase() + f.substring(1)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _frequency = f);
                  },
                  selectedColor: KinsuTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : KinsuTheme.textPrimary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Body Area ───────────────────────────
            DropdownButtonFormField<String>(
              value: _bodyArea,
              decoration: const InputDecoration(labelText: 'Body Area'),
              items: _bodyAreas.map((a) {
                return DropdownMenuItem(value: a, child: Text(a));
              }).toList(),
              onChanged: (v) => setState(() => _bodyArea = v),
            ),
            const SizedBox(height: 16),

            // ── First Noticed ───────────────────────
            InkWell(
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: _firstNoticed,
                  firstDate: DateTime(2015),
                  lastDate: DateTime.now(),
                );
                if (date != null) setState(() => _firstNoticed = date);
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: KinsuTheme.cardDecoration,
                child: Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 20, color: KinsuTheme.primary),
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
              onPressed: _submit,
              child: const Text('Save Symptom'),
            ),
          ],
        ),
      ),
    );
  }
}
