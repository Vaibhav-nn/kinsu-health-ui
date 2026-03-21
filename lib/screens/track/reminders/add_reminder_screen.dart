import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/reminder.dart';
import '../../../providers/reminders_provider.dart';

/// Form to create a new reminder.
class AddReminderScreen extends StatefulWidget {
  const AddReminderScreen({super.key});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  String _reminderType = 'medication';
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 8, minute: 0);
  String _recurrence = 'daily';

  static const _types = [
    {'key': 'medication', 'label': 'Medication', 'icon': Icons.medication},
    {'key': 'appointment', 'label': 'Appointment', 'icon': Icons.event},
    {'key': 'checkup', 'label': 'Checkup', 'icon': Icons.health_and_safety},
    {'key': 'custom', 'label': 'Custom', 'icon': Icons.alarm},
  ];

  static const _recurrences = ['daily', 'weekly', 'monthly', 'once'];

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final timeStr =
        '${_scheduledTime.hour.toString().padLeft(2, '0')}:${_scheduledTime.minute.toString().padLeft(2, '0')}:00';

    final reminder = Reminder(
      title: _titleController.text,
      reminderType: _reminderType,
      scheduledTime: timeStr,
      recurrence: _recurrence,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
    );

    final success =
        await context.read<RemindersProvider>().createReminder(reminder);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder created!'),
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
        title: const Text('Add Reminder'),
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
            // ── Title ───────────────────────────────
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Reminder Title',
                hintText: 'e.g. Take Metformin',
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 20),

            // ── Type ────────────────────────────────
            const Text(
              'Type',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _types.map((t) {
                final isSelected = _reminderType == t['key'];
                return ChoiceChip(
                  avatar: Icon(
                    t['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : KinsuTheme.textSecondary,
                  ),
                  label: Text(t['label'] as String),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) {
                      setState(() => _reminderType = t['key'] as String);
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

            // ── Time ────────────────────────────────
            const Text(
              'Scheduled Time',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime: _scheduledTime,
                );
                if (picked != null) {
                  setState(() => _scheduledTime = picked);
                }
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: KinsuTheme.cardDecoration,
                child: Row(
                  children: [
                    const Icon(Icons.access_time,
                        size: 20, color: KinsuTheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      _scheduledTime.format(context),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Recurrence ──────────────────────────
            const Text(
              'Repeat',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: _recurrences.map((r) {
                final isSelected = _recurrence == r;
                return ChoiceChip(
                  label: Text(r[0].toUpperCase() + r.substring(1)),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _recurrence = r);
                  },
                  selectedColor: KinsuTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : KinsuTheme.textPrimary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

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

            ElevatedButton(
              onPressed: _submit,
              child: const Text('Create Reminder'),
            ),
          ],
        ),
      ),
    );
  }
}
