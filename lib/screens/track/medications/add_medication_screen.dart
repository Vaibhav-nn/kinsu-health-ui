import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/medication.dart';
import '../../../models/reminder.dart';
import '../../../providers/medications_provider.dart';
import '../../../providers/reminders_provider.dart';

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
  bool _isSubmitting = false;

  List<DateTime> _scheduleSlots = [
    DateTime.now().copyWith(hour: 8, minute: 0, second: 0, millisecond: 0),
    DateTime.now().copyWith(hour: 20, minute: 0, second: 0, millisecond: 0),
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

  String _timeString(DateTime dt) {
    final hh = dt.hour.toString().padLeft(2, '0');
    final mm = dt.minute.toString().padLeft(2, '0');
    return '$hh:$mm:00';
  }

  String _dateString(DateTime dt) {
    final yyyy = dt.year.toString();
    final mm = dt.month.toString().padLeft(2, '0');
    final dd = dt.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }

  String _formatSlot(DateTime slot) {
    final dateLabel = MaterialLocalizations.of(context).formatMediumDate(slot);
    final timeLabel = MaterialLocalizations.of(context)
        .formatTimeOfDay(TimeOfDay.fromDateTime(slot));
    return '$dateLabel, $timeLabel';
  }

  String _mapFrequencyToRecurrence(String frequency) {
    switch (frequency) {
      case 'weekly':
        return 'weekly';
      case 'as_needed':
        return 'once';
      default:
        return 'daily';
    }
  }

  Future<DateTime?> _pickDateTime(DateTime initialValue) async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: initialValue,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (pickedDate == null || !mounted) {
      return null;
    }

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initialValue),
    );
    if (pickedTime == null) {
      return null;
    }

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Future<void> _addScheduleSlot() async {
    final base = _scheduleSlots.isEmpty
        ? DateTime.now()
        : _scheduleSlots.last.add(const Duration(hours: 4));
    final picked = await _pickDateTime(base);
    if (picked == null) {
      return;
    }

    setState(() {
      _scheduleSlots = [..._scheduleSlots, picked]..sort();
    });
  }

  Future<void> _editScheduleSlot(int index) async {
    final picked = await _pickDateTime(_scheduleSlots[index]);
    if (picked == null) {
      return;
    }

    setState(() {
      _scheduleSlots[index] = picked;
      _scheduleSlots.sort();
    });
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    if (_scheduleSlots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one schedule slot.'),
          backgroundColor: KinsuTheme.statusWarning,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final sortedSlots = [..._scheduleSlots]..sort();
      final firstSlot = sortedSlots.first;

      final medication = Medication(
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim(),
        frequency: _frequency,
        startDate: DateTime(firstSlot.year, firstSlot.month, firstSlot.day),
        prescribingDoctor: _doctorController.text.trim().isNotEmpty
            ? _doctorController.text.trim()
            : null,
        notes: _notesController.text.trim().isNotEmpty
            ? _notesController.text.trim()
            : null,
      );

      final medsProvider = context.read<MedicationsProvider>();
      final createdMedication = await medsProvider.addMedication(medication);

      if (!mounted) {
        return;
      }

      if (createdMedication == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              medsProvider.error ??
                  'Unable to save medication. Please try again.',
            ),
            backgroundColor: KinsuTheme.statusError,
          ),
        );
        return;
      }

      final remindersProvider = context.read<RemindersProvider>();
      final recurrence = _mapFrequencyToRecurrence(_frequency);

      int successCount = 0;
      for (final slot in sortedSlots) {
        final reminder = Reminder(
          title: 'Take ${createdMedication.name}',
          reminderType: 'medication',
          linkedMedicationId: createdMedication.id,
          scheduledTime: _timeString(slot),
          recurrence: recurrence,
          notes: 'Scheduled from ${_dateString(slot)}',
        );

        final created = await remindersProvider.createReminder(reminder);
        if (created) {
          successCount += 1;
        }
      }

      if (!mounted) {
        return;
      }

      final total = sortedSlots.length;
      if (successCount == total) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Medication and schedule saved!'),
            backgroundColor: KinsuTheme.statusActive,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Medication saved. Created $successCount of $total reminders.',
            ),
            backgroundColor: KinsuTheme.statusWarning,
          ),
        );
      }

      Navigator.pop(context, true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              },
            ),
            const SizedBox(height: 20),
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
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Required';
                }
                return null;
              },
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
                final isSelected = _frequency == frequency['key'];
                return ChoiceChip(
                  label: Text(frequency['label']!),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _frequency = frequency['key']!);
                    }
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
            const Text(
              'Schedule (Date & Time)',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            ..._scheduleSlots.asMap().entries.map((entry) {
              final index = entry.key;
              final slot = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: InkWell(
                  onTap: () => _editScheduleSlot(index),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: KinsuTheme.cardDecoration,
                    child: Row(
                      children: [
                        const Icon(
                          Icons.schedule,
                          size: 20,
                          color: KinsuTheme.textSecondary,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _formatSlot(slot),
                            style: const TextStyle(fontSize: 15),
                          ),
                        ),
                        if (_scheduleSlots.length > 1)
                          GestureDetector(
                            onTap: () {
                              setState(() => _scheduleSlots.removeAt(index));
                            },
                            child: const Icon(
                              Icons.remove_circle_outline,
                              size: 20,
                              color: KinsuTheme.statusError,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            GestureDetector(
              onTap: _addScheduleSlot,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Icon(Icons.add, size: 18, color: KinsuTheme.primary),
                    SizedBox(width: 6),
                    Text(
                      'Add another date & time',
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
              onPressed: _isSubmitting ? null : _submit,
              child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text('Save Medication'),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
