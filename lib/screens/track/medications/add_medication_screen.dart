import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/medication.dart';
import '../../../providers/medications_provider.dart';

/// Add Medication form — matches the mockup design.
class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _doctorController = TextEditingController();
  final _notesController = TextEditingController();

  String _frequency = 'twice_daily';
  List<TimeOfDay> _reminderTimes = [
    const TimeOfDay(hour: 8, minute: 0),
    const TimeOfDay(hour: 14, minute: 0),
  ];

  static const _frequencies = [
    {'key': 'once_daily', 'label': 'Daily'},
    {'key': 'twice_daily', 'label': 'Twice/day'},
    {'key': 'weekly', 'label': 'Weekly'},
    {'key': 'as_needed', 'label': 'As needed'},
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _doctorController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final medication = Medication(
      name: _nameController.text,
      dosage: _dosageController.text,
      frequency: _frequency,
      startDate: DateTime.now(),
      prescribingDoctor:
          _doctorController.text.isNotEmpty ? _doctorController.text : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    final success =
        await context.read<MedicationsProvider>().addMedication(medication);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication saved!'),
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
        title: const Text('Add Medication'),
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
            // ── Medication Name ─────────────────────
            const Text(
              'Medication Name',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Metformin 500mg',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            // ── Dosage ──────────────────────────────
            const Text(
              'Dosage',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _dosageController,
              decoration: const InputDecoration(
                hintText: 'e.g. 1 tablet',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
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
                final isSelected = _frequency == f['key'];
                return ChoiceChip(
                  label: Text(f['label']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _frequency = f['key']!);
                  },
                  selectedColor: KinsuTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : KinsuTheme.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // ── Reminder Times ──────────────────────
            const Text(
              'Reminder Times',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._reminderTimes.asMap().entries.map((entry) {
              final idx = entry.key;
              final time = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: time,
                    );
                    if (picked != null) {
                      setState(() => _reminderTimes[idx] = picked);
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: KinsuTheme.cardDecoration,
                    child: Row(
                      children: [
                        const Icon(Icons.access_time,
                            size: 20, color: KinsuTheme.textSecondary),
                        const SizedBox(width: 12),
                        Text(
                          time.format(context),
                          style: const TextStyle(fontSize: 16),
                        ),
                        const Spacer(),
                        if (_reminderTimes.length > 1)
                          GestureDetector(
                            onTap: () {
                              setState(() => _reminderTimes.removeAt(idx));
                            },
                            child: const Icon(Icons.remove_circle_outline,
                                size: 20, color: KinsuTheme.statusError),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            GestureDetector(
              onTap: () {
                setState(() {
                  _reminderTimes.add(const TimeOfDay(hour: 20, minute: 0));
                });
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.add, size: 18, color: KinsuTheme.primary),
                    SizedBox(width: 6),
                    Text(
                      'Add another time',
                      style: TextStyle(
                        color: KinsuTheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Prescribing Doctor ───────────────────
            const Text(
              'Prescribing Doctor',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: _doctorController,
              decoration: const InputDecoration(
                hintText: 'e.g. Dr. Kapoor',
              ),
            ),
            const SizedBox(height: 32),

            // ── Submit ──────────────────────────────
            ElevatedButton(
              onPressed: _submit,
              child: const Text('Save Medication'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
