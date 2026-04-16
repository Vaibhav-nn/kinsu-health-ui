import 'package:flutter/material.dart';
import 'package:kinsu_health/widgets/ios_back_button.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/medication.dart';
import '../../../models/reminder.dart';
import '../../../providers/medications_provider.dart';
import '../../../providers/reminders_provider.dart';
import '../widgets/track_flow_bottom_nav.dart';

class AddMedicationScreen extends StatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  State<AddMedicationScreen> createState() => _AddMedicationScreenState();
}

class _AddMedicationScreenState extends State<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _dosageController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  final String _frequency = 'once_daily';
  final Set<String> _selectedTimingKeys = {'after_breakfast'};

  static const _timings = [
    _TimingOption('before_breakfast', 'Before Breakfast', '07:30 AM',
        '07:30:00', Icons.free_breakfast_outlined),
    _TimingOption('after_breakfast', 'After Breakfast', '09:00 AM', '09:00:00',
        Icons.free_breakfast_rounded),
    _TimingOption('before_lunch', 'Before Lunch', '01:00 PM', '13:00:00',
        Icons.lunch_dining_outlined),
    _TimingOption('before_dinner', 'Before Dinner', '07:30 PM', '19:30:00',
        Icons.nightlight_outlined),
    _TimingOption('after_lunch', 'After Lunch', '02:00 PM', '14:00:00',
        Icons.restaurant_outlined),
    _TimingOption('after_dinner', 'After Dinner', '09:00 PM', '21:00:00',
        Icons.dark_mode_outlined),
    _TimingOption('before_sleep', 'Before Sleep', '10:30 PM', '22:30:00',
        Icons.bedtime_outlined),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _dosageController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _mapFrequencyToRecurrence(String frequency) {
    switch (frequency) {
      case 'weekly':
        return 'weekly';
      case 'monthly':
        return 'monthly';
      case 'as_needed':
        return 'once';
      default:
        return 'daily';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedTimingKeys.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select at least one reminder time.'),
          backgroundColor: KinsuTheme.statusError,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final medication = Medication(
        name: _nameController.text.trim(),
        dosage: _dosageController.text.trim().isEmpty
            ? '1 dose'
            : _dosageController.text.trim(),
        frequency: _frequency,
        startDate: DateTime.now(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      final medsProvider = context.read<MedicationsProvider>();
      final remindersProvider = context.read<RemindersProvider>();
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

      for (final timing
          in _timings.where((item) => _selectedTimingKeys.contains(item.key))) {
        final reminder = Reminder(
          title: 'Take ${createdMedication.name}',
          reminderType: 'medicine',
          linkedMedicationId: createdMedication.id,
          scheduledTime: timing.time24,
          recurrence: _mapFrequencyToRecurrence(_frequency),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          details: {
            'timing_slot': timing.key,
            'timing_label': timing.title,
            'schedule_hint': timing.subtitle,
          },
        );
        await remindersProvider.createReminder(reminder);
      }

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Medication and reminders saved.'),
          backgroundColor: KinsuTheme.statusActive,
        ),
      );
      Navigator.pop(context, true);
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _toggleTiming(String key) {
    setState(() {
      if (!_selectedTimingKeys.add(key)) {
        _selectedTimingKeys.remove(key);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KinsuTheme.background,
      bottomNavigationBar:
          const TrackFlowBottomNav(selectedTab: TrackFlowNavTab.meds),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 18),
            children: [
              Row(
                children: [
                  IosBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Log Medicine',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: KinsuTheme.primaryDark,
                      ),
                    ),
                  ),
                  SizedBox(
                    height: 34,
                    child: ElevatedButton(
                      onPressed: _isSubmitting ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(0, 34),
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        textStyle: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w800),
                      ),
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 15,
                              height: 15,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Text('SAVE'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              const Text(
                'DAILY ROUTINE',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1,
                  color: Color(0xFF9AA888),
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Keep your health\non schedule.',
                style: TextStyle(
                  fontSize: 44,
                  fontWeight: FontWeight.w800,
                  height: 0.95,
                  color: KinsuTheme.primaryDark,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Logging your medication helps maintain consistency and improves long-term wellness outcomes.',
                style: TextStyle(
                  color: KinsuTheme.textSecondary,
                  fontSize: 14,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 18),
              const _SectionLabel('MEDICINE NAME'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _nameController,
                decoration:
                    const InputDecoration(hintText: 'e.g. Magnesium Citrate'),
                validator: (value) =>
                    value == null || value.trim().isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  const _SectionLabel('WHEN TO TAKE'),
                  const Spacer(),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFE6F1A6),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Text(
                      'Multiple Select',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF6E7D12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _timings.map((timing) {
                  final selected = _selectedTimingKeys.contains(timing.key);
                  return GestureDetector(
                    onTap: () => _toggleTiming(timing.key),
                    child: Container(
                      width: (MediaQuery.of(context).size.width - 52) / 2,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color:
                            selected ? const Color(0xFFEAF7F2) : Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: selected
                              ? KinsuTheme.primary
                              : KinsuTheme.divider,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(timing.icon,
                              size: 16,
                              color: selected
                                  ? KinsuTheme.primary
                                  : KinsuTheme.textSecondary),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              timing.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: selected
                                    ? KinsuTheme.primaryDark
                                    : KinsuTheme.textPrimary,
                              ),
                            ),
                          ),
                          Icon(
                            selected
                                ? Icons.check_circle
                                : Icons.radio_button_unchecked,
                            size: 16,
                            color: selected
                                ? KinsuTheme.primary
                                : const Color(0xFFB7C0CC),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const _SectionLabel('ADDITIONAL NOTES'),
              const SizedBox(height: 6),
              TextFormField(
                controller: _notesController,
                minLines: 4,
                maxLines: 4,
                decoration: const InputDecoration(
                  hintText: 'Add specific instructions or reminders...',
                ),
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8E7B1),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.lightbulb_outline_rounded,
                        color: Color(0xFF7B6420), size: 16),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Health Insight\nTaking vitamins with food improves absorption. We\'ve suggested “After Breakfast” based on your history.',
                        style: TextStyle(
                          color: Color(0xFF7B6420),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          height: 1.35,
                        ),
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

class _SectionLabel extends StatelessWidget {
  final String text;

  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w800,
        color: KinsuTheme.textSecondary,
        letterSpacing: 0.9,
      ),
    );
  }
}

class _TimingOption {
  final String key;
  final String title;
  final String subtitle;
  final String time24;
  final IconData icon;

  const _TimingOption(
      this.key, this.title, this.subtitle, this.time24, this.icon);
}
