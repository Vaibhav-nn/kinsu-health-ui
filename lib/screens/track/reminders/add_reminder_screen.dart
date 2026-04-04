import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/reminder.dart';
import '../../../providers/reminders_provider.dart';

class AddReminderScreen extends StatefulWidget {
  final String? initialType;

  const AddReminderScreen({super.key, this.initialType});

  @override
  State<AddReminderScreen> createState() => _AddReminderScreenState();
}

class _AddReminderScreenState extends State<AddReminderScreen> {
  final _formKey = GlobalKey<FormState>();

  final _titleController = TextEditingController();
  final _notesController = TextEditingController();
  final _doctorNameController = TextEditingController();
  final _doctorTypeController = TextEditingController();
  final _hospitalController = TextEditingController();
  final _problemController = TextEditingController();
  final _productController = TextEditingController();
  final _goalController = TextEditingController();
  final _intervalController = TextEditingController();
  final _customMessageController = TextEditingController();

  String? _selectedType;
  String _recurrence = 'daily';
  TimeOfDay _scheduledTime = const TimeOfDay(hour: 8, minute: 0);
  DateTime _selectedDate = DateTime.now();

  String _medicineType = 'tablet';
  final Set<String> _medicineTimingSlots = {'After Breakfast'};
  String _vesselSize = '250 ml';
  String _foodWindow = 'Breakfast';
  bool _gentleWakeup = true;
  bool _hapticFeedback = true;

  static const _types = <_ReminderType>[
    _ReminderType('doctor_consultation', 'Doctor Consultation',
        Icons.medical_services_outlined),
    _ReminderType('medicine', 'Medicine', Icons.medication_outlined),
    _ReminderType('sleep', 'Sleep', Icons.bedtime_outlined),
    _ReminderType('water', 'Water', Icons.water_drop_outlined),
    _ReminderType('food', 'Food', Icons.restaurant_outlined),
    _ReminderType('skin_care', 'Skin Care', Icons.spa_outlined),
    _ReminderType('hair_care', 'Hair Care', Icons.content_cut_outlined),
    _ReminderType('eye_care', 'Eye Care', Icons.visibility_outlined),
  ];

  static const _medicineTimings = <String>[
    'Empty Stomach',
    'Before Breakfast',
    'After Breakfast',
    'Before Lunch',
    'After Lunch',
    'Before Dinner',
    'After Dinner',
    'Before Sleep',
  ];

  @override
  void initState() {
    super.initState();
    _selectedType = widget.initialType;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    _doctorNameController.dispose();
    _doctorTypeController.dispose();
    _hospitalController.dispose();
    _problemController.dispose();
    _productController.dispose();
    _goalController.dispose();
    _intervalController.dispose();
    _customMessageController.dispose();
    super.dispose();
  }

  String _timeString(TimeOfDay value) =>
      '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}:00';

  String _dateString(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _scheduledTime,
    );
    if (picked != null) {
      setState(() => _scheduledTime = picked);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 3650)),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  String _defaultTitle(String type) {
    switch (type) {
      case 'doctor_consultation':
        return _doctorNameController.text.trim().isNotEmpty
            ? 'Doctor visit: ${_doctorNameController.text.trim()}'
            : 'Doctor consultation';
      case 'medicine':
        return _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : 'Medicine reminder';
      case 'sleep':
        return 'Sleep reminder';
      case 'water':
        return 'Drink water';
      case 'food':
        return '$_foodWindow reminder';
      case 'skin_care':
        return 'Skin care routine';
      case 'hair_care':
        return 'Hair care routine';
      case 'eye_care':
        return 'Eye care routine';
      default:
        return 'Reminder';
    }
  }

  Map<String, dynamic> _buildDetails(String type) {
    switch (type) {
      case 'doctor_consultation':
        return {
          'doctor_name': _doctorNameController.text.trim(),
          'doctor_type': _doctorTypeController.text.trim(),
          'date': _dateString(_selectedDate),
          'hospital_location': _hospitalController.text.trim(),
          'problem_illness': _problemController.text.trim(),
        };
      case 'medicine':
        return {
          'medicine_type': _medicineType,
          'product': _productController.text.trim(),
          'date': _dateString(_selectedDate),
          'timing_slots': _medicineTimingSlots
              .map((value) => value.toLowerCase().replaceAll(' ', '_'))
              .toList(),
        };
      case 'sleep':
        return {
          'goal': _goalController.text.trim(),
          'date': _dateString(_selectedDate),
          'gentle_wakeup_sound': _gentleWakeup,
          'haptic_feedback': _hapticFeedback,
        };
      case 'water':
        return {
          'daily_goal': _goalController.text.trim(),
          'interval': _intervalController.text.trim(),
          'vessel_size': _vesselSize,
        };
      case 'food':
        return {
          'meal_window': _foodWindow,
          'custom_message': _customMessageController.text.trim(),
        };
      case 'skin_care':
      case 'hair_care':
      case 'eye_care':
        return {
          'product': _productController.text.trim(),
          'frequency': _recurrence,
          'date': _dateString(_selectedDate),
        };
      default:
        return {};
    }
  }

  Future<void> _submit() async {
    if (_selectedType == null || !_formKey.currentState!.validate()) {
      return;
    }

    final reminder = Reminder(
      title: _defaultTitle(_selectedType!),
      reminderType: _selectedType!,
      scheduledTime: _timeString(_scheduledTime),
      recurrence: _recurrence,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
      details: _buildDetails(_selectedType!),
    );

    final success =
        await context.read<RemindersProvider>().createReminder(reminder);
    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reminder created successfully.'),
          backgroundColor: KinsuTheme.statusActive,
        ),
      );
      Navigator.pop(context, true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.read<RemindersProvider>().error ??
              'Unable to create reminder right now.',
        ),
        backgroundColor: KinsuTheme.statusError,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_selectedType == null ? 'Add Reminder' : 'Create Reminder'),
        leading: IconButton(
          icon: Icon(_selectedType == null ? Icons.close : Icons.arrow_back),
          onPressed: () {
            if (_selectedType == null || widget.initialType != null) {
              Navigator.pop(context);
            } else {
              setState(() => _selectedType = null);
            }
          },
        ),
      ),
      body: _selectedType == null ? _buildHub() : _buildForm(),
    );
  }

  Widget _buildHub() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FDFB),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: KinsuTheme.primary.withValues(alpha: 0.15)),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Reminder Hub',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              SizedBox(height: 8),
              Text(
                'Pick the type of reminder you want to set up and we’ll tailor the form to it.',
                style: TextStyle(color: KinsuTheme.textSecondary, height: 1.4),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _types.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.25,
          ),
          itemBuilder: (context, index) {
            final type = _types[index];
            return InkWell(
              borderRadius: BorderRadius.circular(24),
              onTap: () => setState(() => _selectedType = type.key),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: KinsuTheme.divider),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: KinsuTheme.primary.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(type.icon, color: KinsuTheme.primary),
                    ),
                    const Spacer(),
                    Text(
                      type.label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildForm() {
    final isSubmitting = context.watch<RemindersProvider>().isLoading;

    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            _types.firstWhere((item) => item.key == _selectedType).label,
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          _buildDynamicFields(),
          const SizedBox(height: 16),
          const _SectionLabel('Reminder time'),
          const SizedBox(height: 8),
          _PickerTile(
            icon: Icons.schedule,
            label: _scheduledTime.format(context),
            onTap: _pickTime,
          ),
          const SizedBox(height: 16),
          const _SectionLabel('Repeat'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const ['daily', 'weekly', 'monthly', 'once'].map((value) {
              return value;
            }).map((value) {
              final isSelected = _recurrence == value;
              return ChoiceChip(
                label: Text(value[0].toUpperCase() + value.substring(1)),
                selected: isSelected,
                onSelected: (_) => setState(() => _recurrence = value),
                selectedColor: KinsuTheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : KinsuTheme.textPrimary,
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _notesController,
            minLines: 3,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Notes (optional)',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isSubmitting ? null : _submit,
            child: isSubmitting
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Reminder'),
          ),
        ],
      ),
    );
  }

  Widget _buildDynamicFields() {
    switch (_selectedType) {
      case 'doctor_consultation':
        return Column(
          children: [
            _textField(_doctorNameController, 'Doctor name'),
            const SizedBox(height: 12),
            _textField(_doctorTypeController, 'Type / specialty'),
            const SizedBox(height: 12),
            _PickerTile(
              icon: Icons.calendar_today_outlined,
              label: MaterialLocalizations.of(context)
                  .formatMediumDate(_selectedDate),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            _textField(_hospitalController, 'Hospital / location'),
            const SizedBox(height: 12),
            _textField(_problemController, 'Problem / illness'),
          ],
        );
      case 'medicine':
        return Column(
          children: [
            _textField(_titleController, 'Medicine name'),
            const SizedBox(height: 12),
            _textField(_productController, 'Dosage / product'),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'When to take',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _medicineTimings.map((value) {
                final isSelected = _medicineTimingSlots.contains(value);
                return FilterChip(
                  label: Text(value),
                  selected: isSelected,
                  onSelected: (_) {
                    setState(() {
                      if (!_medicineTimingSlots.add(value)) {
                        _medicineTimingSlots.remove(value);
                      }
                    });
                  },
                  selectedColor: KinsuTheme.primary.withValues(alpha: 0.16),
                  checkmarkColor: KinsuTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected
                        ? KinsuTheme.primaryDark
                        : KinsuTheme.textPrimary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  side: const BorderSide(color: KinsuTheme.divider),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                ['tablet', 'Tablet'],
                ['syrup', 'Syrup'],
                ['injection', 'Injection'],
              ].map((item) {
                final isSelected = _medicineType == item[0];
                return ChoiceChip(
                  label: Text(item[1]),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _medicineType = item[0]),
                  selectedColor: KinsuTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : KinsuTheme.textPrimary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            _PickerTile(
              icon: Icons.event_outlined,
              label: MaterialLocalizations.of(context)
                  .formatMediumDate(_selectedDate),
              onTap: _pickDate,
            ),
            const SizedBox(height: 12),
            Text(
              'You can select multiple timings if this medicine needs more than one reminder in a day.',
              style: TextStyle(
                fontSize: 13,
                color: KinsuTheme.textSecondary.withValues(alpha: 0.9),
                height: 1.35,
              ),
            ),
          ],
        );
      case 'sleep':
        return Column(
          children: [
            _textField(_goalController, 'Sleep goal (e.g. 8 hours)'),
            const SizedBox(height: 12),
            SwitchListTile(
              value: _gentleWakeup,
              onChanged: (value) => setState(() => _gentleWakeup = value),
              title: const Text('Gentle wake-up sound'),
            ),
            SwitchListTile(
              value: _hapticFeedback,
              onChanged: (value) => setState(() => _hapticFeedback = value),
              title: const Text('Haptic feedback'),
            ),
          ],
        );
      case 'water':
        return Column(
          children: [
            _textField(_goalController, 'Daily goal (e.g. 2000 ml)'),
            const SizedBox(height: 12),
            _textField(_intervalController, 'Interval (e.g. every 2 hours)'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const ['250 ml', '500 ml', '750 ml'].map((value) {
                final isSelected = _vesselSize == value;
                return ChoiceChip(
                  label: Text(value),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _vesselSize = value),
                  selectedColor: KinsuTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : KinsuTheme.textPrimary,
                  ),
                );
              }).toList(),
            ),
          ],
        );
      case 'food':
        return Column(
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children:
                  const ['Breakfast', 'Lunch', 'Dinner', 'Snack'].map((value) {
                final isSelected = _foodWindow == value;
                return ChoiceChip(
                  label: Text(value),
                  selected: isSelected,
                  onSelected: (_) => setState(() => _foodWindow = value),
                  selectedColor: KinsuTheme.primary,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : KinsuTheme.textPrimary,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            _textField(_customMessageController, 'Custom message'),
          ],
        );
      case 'skin_care':
      case 'hair_care':
      case 'eye_care':
        return Column(
          children: [
            _textField(_titleController, 'Treatment name'),
            const SizedBox(height: 12),
            _textField(_productController, 'Product / tool'),
            const SizedBox(height: 12),
            _PickerTile(
              icon: Icons.event_outlined,
              label: MaterialLocalizations.of(context)
                  .formatMediumDate(_selectedDate),
              onTap: _pickDate,
            ),
          ],
        );
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _textField(
    TextEditingController controller,
    String label, {
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      validator: required
          ? (value) => value == null || value.trim().isEmpty ? 'Required' : null
          : null,
      decoration: InputDecoration(labelText: label),
    );
  }
}

class _ReminderType {
  final String key;
  final String label;
  final IconData icon;

  const _ReminderType(this.key, this.label, this.icon);
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

class _PickerTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _PickerTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: KinsuTheme.cardDecoration,
        child: Row(
          children: [
            Icon(icon, color: KinsuTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
