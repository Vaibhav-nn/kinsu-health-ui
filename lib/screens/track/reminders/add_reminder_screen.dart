import 'package:flutter/material.dart';
import 'package:kinsu_health/widgets/ios_back_button.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/reminder.dart';
import '../../../providers/reminders_provider.dart';
import '../widgets/track_flow_bottom_nav.dart';

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
  final List<TimeOfDay> _medicineTimes = [const TimeOfDay(hour: 8, minute: 0)];
  String _vesselSize = '500 ml';
  String _foodWindow = 'Lunch';
  String _reminderDepth = 'generic_alert';
  bool _gentleWakeup = true;
  bool _hapticFeedback = false;
  bool _notifyBeforeMeal = true;
  TimeOfDay _bedTime = const TimeOfDay(hour: 22, minute: 30);
  TimeOfDay _wakeTime = const TimeOfDay(hour: 6, minute: 30);
  final String _careProductType = 'comb_oil';

  static const _types = <_ReminderType>[
    _ReminderType('doctor_consultation', 'Doctor\nConsultation',
        Icons.medical_services_outlined, Color(0xFFE9F4F7), Color(0xFF226B84)),
    _ReminderType('medicine', 'Medicine', Icons.medication_outlined,
        Color(0xFFF4F7DD), Color(0xFF79820A)),
    _ReminderType('sleep', 'Sleep', Icons.dark_mode_outlined, Color(0xFFF4EEDC),
        Color(0xFF8B6B1F)),
    _ReminderType('water', 'Water', Icons.local_drink_outlined,
        Color(0xFFE7F3F7), Color(0xFF2E6E86)),
    _ReminderType('food', 'Food', Icons.restaurant_outlined, Color(0xFFF4F8DB),
        Color(0xFF7B810B)),
    _ReminderType('skin_care', 'Skin', Icons.face_retouching_natural_outlined,
        Color(0xFFE6F4F7), Color(0xFF2A7288)),
    _ReminderType('hair_care', 'Hair', Icons.content_cut_outlined,
        Color(0xFFF6F3F2), Color(0xFF6B7280)),
    _ReminderType('eye_care', 'Eye', Icons.visibility_outlined,
        Color(0xFFF4F8DB), Color(0xFF7B810B)),
  ];

  static const _mealSlots = <_MealSlot>[
    _MealSlot('Breakfast', '08:00 AM', Icons.breakfast_dining_outlined),
    _MealSlot('Lunch', '01:00 PM', Icons.wb_sunny_outlined),
    _MealSlot('Dinner', '07:30 PM', Icons.nightlight_outlined),
    _MealSlot('Snacks', '04:00 PM', Icons.cookie_outlined),
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

  String _displayTime(TimeOfDay value) {
    final hour = value.hourOfPeriod == 0 ? 12 : value.hourOfPeriod;
    final minute = value.minute.toString().padLeft(2, '0');
    final suffix = value.period == DayPeriod.am ? 'AM' : 'PM';
    return '$hour:$minute $suffix';
  }

  String _dateString(DateTime value) =>
      '${value.year.toString().padLeft(4, '0')}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';

  Future<void> _pickTime(
      {TimeOfDay? initial, required ValueChanged<TimeOfDay> onPicked}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: initial ?? _scheduledTime,
    );
    if (picked != null) {
      onPicked(picked);
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
          'timing_slots': _medicineTimes.map(_timeString).toList(),
        };
      case 'sleep':
        return {
          'goal': _goalController.text.trim(),
          'bedtime': _timeString(_bedTime),
          'wake_time': _timeString(_wakeTime),
          'gentle_wakeup_sound': _gentleWakeup,
          'haptic_feedback': _hapticFeedback,
        };
      case 'water':
        return {
          'daily_goal': _goalController.text.trim(),
          'interval': _intervalController.text.trim(),
          'vessel_size': _vesselSize,
          'schedule':
              '${_displayTime(const TimeOfDay(hour: 8, minute: 0))} - ${_displayTime(const TimeOfDay(hour: 22, minute: 0))}',
        };
      case 'food':
        return {
          'meal_window': _foodWindow,
          'reminder_depth': _reminderDepth,
          'notify_before_meal': _notifyBeforeMeal,
          'custom_message': _customMessageController.text.trim(),
        };
      case 'skin_care':
      case 'hair_care':
      case 'eye_care':
        return {
          'product': _productController.text.trim(),
          'frequency': _recurrence,
          'date': _dateString(_selectedDate),
          'care_product_type': _careProductType,
        };
      default:
        return {};
    }
  }

  Future<void> _submit() async {
    if (_selectedType == null || !_formKey.currentState!.validate()) {
      return;
    }

    final provider = context.read<RemindersProvider>();
    bool success = true;

    if (_selectedType == 'medicine') {
      for (final time in _medicineTimes) {
        final reminder = Reminder(
          title: _defaultTitle('medicine'),
          reminderType: 'medicine',
          scheduledTime: _timeString(time),
          recurrence: _recurrence,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          details: {
            ..._buildDetails('medicine'),
            'scheduled_label': _displayTime(time),
          },
        );
        success = await provider.createReminder(reminder) && success;
      }
    } else {
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
      success = await provider.createReminder(reminder);
    }

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
          provider.error ?? 'Unable to create reminder right now.',
        ),
        backgroundColor: KinsuTheme.statusError,
      ),
    );
  }

  void _handleBack() {
    if (_selectedType == null || widget.initialType != null) {
      Navigator.pop(context);
    } else {
      setState(() => _selectedType = null);
    }
  }

  double _bottomNavInset(BuildContext context, {bool forHub = false}) {
    final safeBottom = MediaQuery.of(context).padding.bottom;
    return (forHub ? 288 : 220) + safeBottom;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      bottomNavigationBar: const TrackFlowBottomNav(
        selectedTab: TrackFlowNavTab.track,
      ),
      body: SafeArea(
        child: _selectedType == null ? _buildHub() : _buildFormShell(),
      ),
    );
  }

  Widget _buildHub() {
    return ListView(
      padding: EdgeInsets.fromLTRB(
        22,
        20,
        22,
        _bottomNavInset(context, forHub: true),
      ),
      children: [
        Row(
          children: [
            IosBackButton(onTap: _handleBack),
          ],
        ),
        const SizedBox(height: 12),
        const Text(
          'What would you like\n'
          'to track today?',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            height: 1.02,
            color: KinsuTheme.primaryDark,
          ),
        ),
        const SizedBox(height: 14),
        const Text(
          'Select a category to set your wellness intentions.',
          style: TextStyle(
            color: KinsuTheme.textSecondary,
            fontSize: 17,
            fontWeight: FontWeight.w500,
            height: 1.55,
          ),
        ),
        const SizedBox(height: 22),
        Wrap(
          spacing: 16,
          runSpacing: 16,
          children: _types.map((type) {
            return SizedBox(
              width: 161,
              height: 192,
              child: InkWell(
                borderRadius: BorderRadius.circular(22),
                onTap: () => setState(() => _selectedType = type.key),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(color: KinsuTheme.divider),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          color: type.background,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Icon(type.icon, color: type.color, size: 30),
                      ),
                      const SizedBox(height: 14),
                      Text(
                        type.label,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: KinsuTheme.primaryDark,
                          height: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 30),
        Container(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8DDA0),
            borderRadius: BorderRadius.circular(16),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.auto_awesome, color: Color(0xFF6B4B00), size: 18),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Sanctuary Insight: Most users find setting a Water reminder first thing in the morning increases focus by 20%.',
                  style: TextStyle(
                    color: Color(0xFF6B4B00),
                    fontWeight: FontWeight.w700,
                    height: 1.45,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 38),
      ],
    );
  }

  Widget _buildFormShell() {
    final provider = context.watch<RemindersProvider>();
    final type = _types.firstWhere((item) => item.key == _selectedType);

    return Form(
      key: _formKey,
      child: ListView(
        padding: EdgeInsets.fromLTRB(20, 16, 20, _bottomNavInset(context)),
        children: [
          Row(
            children: [
              IosBackButton(onTap: _handleBack),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  _screenTitle(type.key),
                  style: const TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                    color: KinsuTheme.primaryDark,
                    height: 1.0,
                  ),
                ),
              ),
              const Icon(
                Icons.notifications_none_rounded,
                color: KinsuTheme.primary,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ..._buildBody(type),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: provider.isLoading ? null : _submit,
            style: ElevatedButton.styleFrom(
              backgroundColor: KinsuTheme.primaryDark,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
            child: provider.isLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : Text(_submitLabel(type.key)),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildBody(_ReminderType type) {
    switch (type.key) {
      case 'doctor_consultation':
        return _doctorBody();
      case 'medicine':
        return _medicineBody();
      case 'sleep':
        return _sleepBody();
      case 'water':
        return _waterBody();
      case 'food':
        return _foodBody();
      case 'skin_care':
        return _skinBody();
      case 'hair_care':
        return _hairBody();
      case 'eye_care':
        return _eyeBody();
      default:
        return const [SizedBox.shrink()];
    }
  }

  List<Widget> _doctorBody() {
    return [
      const Text(
        'CONSULTATION SCHEDULE',
        style: TextStyle(
          color: Color(0xFF98A66B),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Plan your visit.',
        style: TextStyle(
          fontSize: 38,
          fontWeight: FontWeight.w800,
          color: KinsuTheme.primary,
          height: 0.96,
        ),
      ),
      const SizedBox(height: 10),
      const Text(
        'Capture doctor, date, and consultation details so your follow-ups never slip.',
        style: TextStyle(
          color: KinsuTheme.textPrimary,
          fontSize: 15,
          height: 1.45,
        ),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: KinsuTheme.panel,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: [
            _LabeledField(
                controller: _doctorNameController,
                label: 'DOCTOR NAME',
                hintText: 'Dr. Sarah Jenkins'),
            const SizedBox(height: 14),
            _DropdownShell(
              label: 'TYPE',
              value: _doctorTypeController.text.isEmpty
                  ? 'Physician'
                  : _doctorTypeController.text,
              values: const [
                'Physician',
                'Cardiologist',
                'Dermatologist',
                'ENT'
              ],
              onChanged: (value) => setState(
                  () => _doctorTypeController.text = value ?? 'Physician'),
            ),
            const SizedBox(height: 14),
            _PickerField(
              label: 'DATE',
              value: MaterialLocalizations.of(context)
                  .formatShortDate(_selectedDate),
              icon: Icons.calendar_today_outlined,
              onTap: _pickDate,
            ),
            const SizedBox(height: 14),
            _PickerField(
              label: 'TIME',
              value: _displayTime(_scheduledTime),
              icon: Icons.schedule_outlined,
              onTap: () => _pickTime(
                  onPicked: (time) => setState(() => _scheduledTime = time)),
            ),
            const SizedBox(height: 14),
            _LabeledField(
                controller: _hospitalController,
                label: 'HOSPITAL / LOCATION',
                hintText: 'St. Mary\'s Medical Center, Wing B'),
            const SizedBox(height: 14),
            _LabeledField(
              controller: _problemController,
              label: 'PROBLEM / ILLNESS',
              hintText:
                  'Brief description of symptoms or consultation reason...',
              minLines: 3,
              maxLines: 4,
            ),
          ],
        ),
      ),
      const SizedBox(height: 22),
      const Row(
        children: [
          Expanded(
            child: Text(
              'Previously\nConsulted',
              style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w800, height: 1.0),
            ),
          ),
          Text(
            'RECENT\nACTIVITY',
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: KinsuTheme.textSecondary),
          ),
        ],
      ),
      const SizedBox(height: 14),
      const _HistoryCard(
        title: 'Dr. Michael Chen',
        subtitle: 'Neurologist · General Checkup',
        meta: 'LAST VISITED 3M AGO',
        actionLabel: 'Set\nReminder',
      ),
      const SizedBox(height: 12),
      const _HistoryCard(
        title: 'Dr. Elena Rodriguez',
        subtitle: 'ENT Specialist · Sinus Visit',
        meta: 'LAST VISITED 1Y AGO',
        actionLabel: 'Set\nReminder',
      ),
      const SizedBox(height: 16),
      const _InsightCard(
        text:
            'Regular ENT checkups are recommended every 12 months for seasonal allergy sufferers.',
      ),
    ];
  }

  List<Widget> _medicineBody() {
    return [
      Container(
        height: 164,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F9A96), Color(0xFF1B7F7B)],
          ),
        ),
        child: const Stack(
          children: [
            Positioned(
              left: 20,
              top: 20,
              child: Text(
                'STAY ON TRACK',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 20,
              child: Text(
                'New Medication',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Row(
        children: [
          Expanded(
              child: _TypeCard(
                  label: 'Tablet',
                  icon: Icons.circle_outlined,
                  selected: _medicineType == 'tablet',
                  onTap: () => setState(() => _medicineType = 'tablet'))),
          const SizedBox(width: 12),
          Expanded(
              child: _TypeCard(
                  label: 'Syrup',
                  icon: Icons.medication_liquid_outlined,
                  selected: _medicineType == 'syrup',
                  onTap: () => setState(() => _medicineType = 'syrup'))),
          const SizedBox(width: 12),
          Expanded(
              child: _TypeCard(
                  label: 'Injection',
                  icon: Icons.vaccines_outlined,
                  selected: _medicineType == 'injection',
                  onTap: () => setState(() => _medicineType = 'injection'))),
        ],
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: KinsuTheme.panel,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          children: [
            _LabeledField(
                controller: _titleController,
                label: 'MEDICINE NAME',
                hintText: 'e.g. Amoxicillin'),
            const SizedBox(height: 14),
            _LabeledField(
                controller: _productController,
                label: 'DOSAGE',
                hintText: '500 mg'),
            const SizedBox(height: 14),
            _DropdownShell(
              label: 'FREQUENCY',
              value: _recurrence == 'once'
                  ? 'Once'
                  : _recurrence[0].toUpperCase() + _recurrence.substring(1),
              values: const ['Daily', 'Weekly', 'Monthly', 'Once'],
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _recurrence = value.toLowerCase() == 'once'
                      ? 'once'
                      : value.toLowerCase();
                });
              },
            ),
            const SizedBox(height: 14),
            _PickerField(
              label: 'START DATE',
              value: MaterialLocalizations.of(context)
                  .formatShortDate(_selectedDate),
              icon: Icons.calendar_today_outlined,
              onTap: _pickDate,
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const _InsightCard(
        text:
            'This medication works best when taken 30 minutes before breakfast for maximum absorption.',
      ),
      const SizedBox(height: 18),
      const _SectionKicker('TIME SELECTION'),
      const SizedBox(height: 10),
      Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          ..._medicineTimes.asMap().entries.map((entry) {
            final index = entry.key;
            final time = entry.value;
            return _TimeChip(
              label: _displayTime(time),
              onRemove: _medicineTimes.length == 1
                  ? null
                  : () => setState(() => _medicineTimes.removeAt(index)),
            );
          }),
          ActionChip(
            onPressed: () => _pickTime(
              initial: _medicineTimes.last,
              onPicked: (time) => setState(() => _medicineTimes.add(time)),
            ),
            backgroundColor: const Color(0xFFD8EB7C),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            label: const Text(
              '+ ADD TIME',
              style: TextStyle(
                  fontWeight: FontWeight.w800, color: Color(0xFF647300)),
            ),
          ),
        ],
      ),
    ];
  }

  List<Widget> _sleepBody() {
    return [
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0B5F68), Color(0xFF257E83)],
          ),
        ),
        child: const Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'RESTORATION CYCLE',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Curation of Calm',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 0.98,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 12),
            Icon(Icons.dark_mode_rounded, color: Colors.white, size: 44),
          ],
        ),
      ),
      const SizedBox(height: 22),
      _TimeStatCard(
        title: 'BEDTIME',
        value: _displayTime(_bedTime),
        icon: Icons.dark_mode_rounded,
        iconColor: const Color(0xFF0F766E),
        iconBackground: const Color(0xFFC7F1FF),
        actionColor: const Color(0xFFEAF1F5),
        onTap: () => _pickTime(
            initial: _bedTime,
            onPicked: (time) => setState(() => _bedTime = time)),
      ),
      const SizedBox(height: 14),
      _TimeStatCard(
        title: 'WAKE UP',
        value: _displayTime(_wakeTime),
        icon: Icons.wb_sunny_rounded,
        iconColor: const Color(0xFF6A7C00),
        iconBackground: const Color(0xFFE2F089),
        actionColor: const Color(0xFFEAF1F5),
        onTap: () => _pickTime(
            initial: _wakeTime,
            onPicked: (time) => setState(() => _wakeTime = time)),
      ),
      const SizedBox(height: 16),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFD98C),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          '✨ Goal: ${_goalController.text.trim().isEmpty ? '8h of restorative sleep' : _goalController.text.trim()}',
          style: const TextStyle(
              color: Color(0xFF6B4B00), fontWeight: FontWeight.w700),
        ),
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: KinsuTheme.panel,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            _SwitchRow(
              icon: Icons.volume_up_outlined,
              label: 'Gentle Wake-up Sound',
              value: _gentleWakeup,
              onChanged: (value) => setState(() => _gentleWakeup = value),
            ),
            const SizedBox(height: 12),
            _SwitchRow(
              icon: Icons.vibration_outlined,
              label: 'Haptic Feedback',
              value: _hapticFeedback,
              onChanged: (value) => setState(() => _hapticFeedback = value),
            ),
          ],
        ),
      ),
      const SizedBox(height: 14),
      _LabeledField(
          controller: _goalController,
          label: 'SLEEP GOAL',
          hintText: '8h of restorative sleep',
          required: false),
    ];
  }

  List<Widget> _waterBody() {
    return [
      Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0D5961), Color(0xFF1C6972)],
          ),
          boxShadow: const [
            BoxShadow(
                color: Color(0x220F6B74), blurRadius: 24, offset: Offset(0, 16))
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('DAILY TARGET',
                style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0)),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _goalController.text.trim().isEmpty
                      ? '2.0'
                      : _goalController.text.trim(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 50,
                      fontWeight: FontWeight.w800,
                      height: 1),
                ),
                const SizedBox(width: 8),
                const Padding(
                  padding: EdgeInsets.only(top: 16),
                  child: Text('Liters',
                      style: TextStyle(color: Colors.white70, fontSize: 22)),
                ),
                const Spacer(),
                const Icon(Icons.opacity_rounded,
                    color: Colors.white24, size: 72),
              ],
            ),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(18),
              ),
              child: const Row(
                children: [
                  Icon(Icons.auto_awesome, size: 16, color: Colors.white70),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Optimal hydration based on your activity',
                      style: TextStyle(
                          color: Colors.white70, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: KinsuTheme.panel,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const Expanded(child: _SectionKicker('DAILY GOAL')),
                IconButton(
                  onPressed: () => setState(() => _goalController.text =
                      ((_parseGoal() - 0.5).clamp(0.5, 10)).toStringAsFixed(1)),
                  icon: const Icon(Icons.remove_circle_outline),
                  color: KinsuTheme.textSecondary,
                ),
                Text(
                  '${_parseGoal().toStringAsFixed(1)}L',
                  style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w800),
                ),
                IconButton(
                  onPressed: () => setState(() => _goalController.text =
                      ((_parseGoal() + 0.5).clamp(0.5, 10)).toStringAsFixed(1)),
                  icon: const Icon(Icons.add_circle_outline),
                  color: KinsuTheme.textSecondary,
                ),
                const SizedBox(width: 4),
                const Icon(Icons.edit_calendar_outlined,
                    color: KinsuTheme.textSecondary),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _InfoCard(
                    label: 'INTERVAL',
                    value: _intervalController.text.trim().isEmpty
                        ? 'Every 2h'
                        : _intervalController.text.trim(),
                    icon: Icons.timer_outlined,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: _InfoCard(
                    label: 'SCHEDULE',
                    value: '08:00 - 22:00',
                    icon: Icons.schedule_outlined,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            const _SectionKicker('VESSEL SIZE'),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                    child: _VesselCard(
                        label: '200ml',
                        icon: Icons.wine_bar_outlined,
                        selected: _vesselSize == '200 ml',
                        onTap: () => setState(() => _vesselSize = '200 ml'))),
                const SizedBox(width: 12),
                Expanded(
                    child: _VesselCard(
                        label: '500ml',
                        icon: Icons.sports_bar_outlined,
                        selected: _vesselSize == '500 ml',
                        onTap: () => setState(() => _vesselSize = '500 ml'))),
                const SizedBox(width: 12),
                Expanded(
                    child: _VesselCard(
                        label: '350ml',
                        icon: Icons.coffee_outlined,
                        selected: _vesselSize == '350 ml',
                        onTap: () => setState(() => _vesselSize = '350 ml'))),
              ],
            ),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const _InsightCard(
          text:
              'Regular intervals maintain steady energy levels and cognitive focus throughout your day.'),
    ];
  }

  List<Widget> _foodBody() {
    return [
      Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
        decoration: BoxDecoration(
          color: KinsuTheme.panel,
          borderRadius: BorderRadius.circular(26),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'NOURISHMENT SCHEDULE',
              style: TextStyle(
                  color: Color(0xFF98A66B),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.1),
            ),
            const SizedBox(height: 10),
            const Text(
              'Set your rhythm.',
              style: TextStyle(
                  fontSize: 42,
                  fontWeight: FontWeight.w800,
                  color: KinsuTheme.primary,
                  height: 0.92),
            ),
            const SizedBox(height: 10),
            const Text(
              'Consistent meal times support metabolic health and mental clarity. Let\'s curate your daily dining experience.',
              style: TextStyle(
                  color: KinsuTheme.textPrimary, fontSize: 16, height: 1.5),
            ),
            const SizedBox(height: 20),
            ..._mealSlots.map((slot) {
              final selected = _foodWindow == slot.label;
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => setState(() => _foodWindow = slot.label),
                  child: Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(
                          color: selected
                              ? KinsuTheme.primary
                              : KinsuTheme.divider),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0F5CA),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(slot.icon,
                              color: const Color(0xFF7A8405), size: 22),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(slot.label,
                                  style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800)),
                              const SizedBox(height: 4),
                              Text(slot.time,
                                  style: const TextStyle(
                                      color: KinsuTheme.textSecondary,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12)),
                            ],
                          ),
                        ),
                        Icon(
                          selected ? Icons.check_circle : Icons.circle_outlined,
                          color: selected
                              ? KinsuTheme.primary
                              : KinsuTheme.divider,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(height: 8),
            const _SectionKicker('REMINDER DEPTH'),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: const Color(0xFFE9EEEF),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Expanded(
                      child: _PillToggle(
                          label: 'Generic Alert',
                          selected: _reminderDepth == 'generic_alert',
                          onTap: () => setState(
                              () => _reminderDepth = 'generic_alert'))),
                  const SizedBox(width: 8),
                  Expanded(
                      child: _PillToggle(
                          label: 'Specific Meals',
                          selected: _reminderDepth == 'specific_meals',
                          onTap: () => setState(
                              () => _reminderDepth = 'specific_meals'))),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Row(
                children: [
                  const Icon(Icons.notifications_active_outlined,
                      color: Color(0xFF7B810B)),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notify 15 mins before',
                            style: TextStyle(fontWeight: FontWeight.w800)),
                        SizedBox(height: 2),
                        Text('Prepare your mind and ingredients',
                            style: TextStyle(
                                color: KinsuTheme.textSecondary, fontSize: 13)),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _notifyBeforeMeal,
                    onChanged: (value) =>
                        setState(() => _notifyBeforeMeal = value),
                    activeTrackColor: KinsuTheme.primary.withValues(alpha: 0.4),
                    activeThumbColor: KinsuTheme.primary,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            _LabeledField(
                controller: _customMessageController,
                label: 'CUSTOM MESSAGE (OPTIONAL)',
                hintText: 'e.g. Remember to hydrate before lunch...',
                required: false),
          ],
        ),
      ),
      const SizedBox(height: 16),
      const _InsightCard(
          text: 'AI Suggestion: Dinner at 7:30 PM optimizes your sleep cycle'),
    ];
  }

  List<Widget> _skinBody() {
    return [
      Container(
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(26),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1CA69E), Color(0xFF2F9A88)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'DAILY INSIGHT',
              style: TextStyle(
                color: Color(0xFFFFF2C9),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Maintain your glow.',
              style: TextStyle(
                color: Colors.white,
                fontSize: 36,
                fontWeight: FontWeight.w800,
                height: 1.0,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Consistency is the secret to cellular regeneration. Set your evening retinol cycle now.',
              style: TextStyle(color: Colors.white70, height: 1.45),
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
                color: Color(0x120F172A), blurRadius: 18, offset: Offset(0, 10))
          ],
        ),
        child: Column(
          children: [
            _LabeledField(
                controller: _titleController,
                label: 'TREATMENT NAME',
                hintText: 'e.g. Retinol',
                required: true),
            const SizedBox(height: 14),
            _DropdownShell(
              label: 'PRODUCT',
              value: _productController.text.isEmpty
                  ? 'Night Serum'
                  : _productController.text,
              values: const ['Night Serum', 'Hydrating Cream', 'SPF Gel'],
              onChanged: (value) =>
                  setState(() => _productController.text = value ?? ''),
            ),
            const SizedBox(height: 14),
            _PickerField(
              label: 'TIME',
              value: _displayTime(_scheduledTime),
              icon: Icons.schedule_outlined,
              onTap: () => _pickTime(
                  onPicked: (time) => setState(() => _scheduledTime = time)),
            ),
            const SizedBox(height: 14),
            _DropdownShell(
              label: 'FREQUENCY',
              value: _recurrence[0].toUpperCase() + _recurrence.substring(1),
              values: const ['Daily', 'Weekly', 'Monthly'],
              onChanged: (value) => setState(
                  () => _recurrence = (value ?? 'Daily').toLowerCase()),
            ),
          ],
        ),
      ),
      const SizedBox(height: 20),
      const Row(
        children: [
          Expanded(
            child: Text(
              'Skin Care History',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            'View All',
            style: TextStyle(
                color: KinsuTheme.primary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      const SizedBox(height: 12),
      const _CareHistoryCard(
          title: 'Hyaluronic Acid',
          subtitle: 'Applied · Oct 24, 08:30 AM',
          tag: 'COMPLETED'),
      const SizedBox(height: 12),
      const _CareHistoryCard(
          title: 'Chemical Peel',
          subtitle: 'Scheduled · Oct 22, 09:00 PM',
          tag: 'MISSED'),
      const SizedBox(height: 12),
      const _CareHistoryCard(
          title: 'Sunscreen 50+',
          subtitle: 'Applied · Oct 21, 07:15 AM',
          tag: 'COMPLETED'),
      const SizedBox(height: 18),
      Container(
        height: 140,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF7DD1D1), Color(0xFF0A6B6C)],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Text(
              'Hydrate within for outer glow.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 18),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _hairBody() {
    return [
      const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Text(
          'WELLNESS PROTOCOL',
          style: TextStyle(
            color: Color(0xFF98A66B),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ),
      const Text(
        'Curate your personalized routine to maintain optimal scalp health and strand vitality.',
        style: TextStyle(
          fontSize: 15,
          color: KinsuTheme.textSecondary,
          height: 1.45,
        ),
      ),
      const SizedBox(height: 18),
      _LabeledField(
        controller: _titleController,
        label: 'ROUTINE NAME',
        hintText: 'e.g., Deep Conditioning',
      ),
      const SizedBox(height: 14),
      _DropdownShell(
        label: 'TOOL/PRODUCT',
        value: _productController.text.isEmpty
            ? 'Comb/Oil'
            : _productController.text,
        values: const ['Comb/Oil', 'Scalp Serum', 'Hydration Mask'],
        onChanged: (value) =>
            setState(() => _productController.text = value ?? ''),
      ),
      const SizedBox(height: 14),
      _DropdownShell(
        label: 'FREQUENCY',
        value: _recurrence[0].toUpperCase() + _recurrence.substring(1),
        values: const ['Daily', 'Weekly', 'Monthly'],
        onChanged: (value) =>
            setState(() => _recurrence = (value ?? 'Weekly').toLowerCase()),
      ),
      const SizedBox(height: 14),
      _PickerField(
        label: 'SCHEDULE TIME',
        value: _displayTime(_scheduledTime),
        icon: Icons.access_time_outlined,
        onTap: () => _pickTime(
            onPicked: (time) => setState(() => _scheduledTime = time)),
      ),
      const SizedBox(height: 16),
      const _InsightCard(
        text:
            'AI Insight: Deep conditioning is most effective after using a scalp serum on Monday nights.',
      ),
      const SizedBox(height: 18),
      const Row(
        children: [
          Expanded(
            child: Text(
              'Hair Care History',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            'View All',
            style: TextStyle(
                color: KinsuTheme.primary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      const SizedBox(height: 12),
      const _CareHistoryCard(
          title: 'Trim & Treatment', subtitle: 'Oct 24, 10:00 AM', tag: 'VIEW'),
      const SizedBox(height: 12),
      const _CareHistoryCard(
          title: 'Scalp Oil Therapy',
          subtitle: 'Oct 18, 09:15 PM',
          tag: 'VIEW'),
      const SizedBox(height: 12),
      const _CareHistoryCard(
          title: 'Hydration Mask', subtitle: 'Oct 11, 08:30 PM', tag: 'VIEW'),
    ];
  }

  List<Widget> _eyeBody() {
    return [
      const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Text(
          'ROUTINE OPTIMIZATION',
          style: TextStyle(
            color: Color(0xFF98A66B),
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.1,
          ),
        ),
      ),
      const Text(
        'Maintain your visual health with precision. Configure your specialized eye care treatments to receive timely alerts.',
        style: TextStyle(
          fontSize: 15,
          color: KinsuTheme.textSecondary,
          height: 1.45,
        ),
      ),
      const SizedBox(height: 18),
      Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: KinsuTheme.divider),
        ),
        child: Column(
          children: [
            _LabeledField(
              controller: _titleController,
              label: 'TREATMENT NAME',
              hintText: 'e.g., Hydrating Drops',
            ),
            const SizedBox(height: 14),
            _DropdownShell(
              label: 'PRODUCT',
              value: _productController.text.isEmpty
                  ? 'Dropper'
                  : _productController.text,
              values: const ['Dropper', 'Night Ointment', 'Lid Wipes'],
              onChanged: (value) =>
                  setState(() => _productController.text = value ?? ''),
            ),
            const SizedBox(height: 14),
            _PickerField(
              label: 'START TIME',
              value: _displayTime(_scheduledTime),
              icon: Icons.access_time_outlined,
              onTap: () => _pickTime(
                onPicked: (time) => setState(() => _scheduledTime = time),
              ),
            ),
            const SizedBox(height: 14),
            _DropdownShell(
              label: 'FREQUENCY',
              value: _recurrence == 'daily'
                  ? '3x Daily'
                  : _recurrence[0].toUpperCase() + _recurrence.substring(1),
              values: const ['3x Daily', 'Daily', 'Weekly'],
              onChanged: (value) => setState(() {
                _recurrence =
                    (value ?? 'daily').toLowerCase().replaceAll('3x ', '');
              }),
            ),
            const SizedBox(height: 14),
            const _InsightCard(
              text:
                  'Tip: Using drops at consistent times each day improves absorption and effectiveness for chronic dryness.',
            ),
          ],
        ),
      ),
      const SizedBox(height: 18),
      const Row(
        children: [
          Expanded(
            child: Text(
              'Eye Care History',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
            ),
          ),
          Text(
            'View Full Log',
            style: TextStyle(
                color: KinsuTheme.primary, fontWeight: FontWeight.w700),
          ),
        ],
      ),
      const SizedBox(height: 12),
      const _CareHistoryCard(
          title: 'Hydrating Drops',
          subtitle: 'Applied on time',
          tag: 'COMPLETED'),
      const SizedBox(height: 12),
      const _CareHistoryCard(
          title: 'Night Ointment',
          subtitle: 'Routine care session',
          tag: 'YESTERDAY'),
      const SizedBox(height: 12),
      const _CareHistoryCard(
          title: 'Lid Wipes', subtitle: 'Deep cleanse', tag: 'COMPLETED'),
    ];
  }

  double _parseGoal() {
    return double.tryParse(_goalController.text.trim()) ?? 2.0;
  }

  String _screenTitle(String type) {
    switch (type) {
      case 'doctor_consultation':
        return 'Doctor reminder';
      case 'medicine':
        return 'Medicine reminder';
      case 'sleep':
        return 'Sleep reminder';
      case 'water':
        return 'Water reminder';
      case 'food':
        return 'Food reminder';
      case 'skin_care':
        return 'Set Skin\nReminder';
      case 'hair_care':
        return 'Set Hair\nReminder';
      case 'eye_care':
        return 'Set Eye\nReminder';
      default:
        return 'Add Reminder';
    }
  }

  String _submitLabel(String type) =>
      type == 'medicine' ? 'Set Reminder' : 'Set Reminder';
}

class _ReminderType {
  final String key;
  final String label;
  final IconData icon;
  final Color background;
  final Color color;

  const _ReminderType(
      this.key, this.label, this.icon, this.background, this.color);
}

class _MealSlot {
  final String label;
  final String time;
  final IconData icon;

  const _MealSlot(this.label, this.time, this.icon);
}

class _LabeledField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hintText;
  final int minLines;
  final int maxLines;
  final bool required;

  const _LabeledField({
    required this.controller,
    required this.label,
    required this.hintText,
    this.minLines = 1,
    this.maxLines = 1,
    this.required = true,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionKicker(label),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          minLines: minLines,
          maxLines: maxLines,
          validator: required
              ? (value) =>
                  value == null || value.trim().isEmpty ? 'Required' : null
              : null,
          decoration: InputDecoration(
              hintText: hintText, alignLabelWithHint: maxLines > 1),
        ),
      ],
    );
  }
}

class _PickerField extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  const _PickerField(
      {required this.label,
      required this.value,
      required this.icon,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionKicker(label),
        const SizedBox(height: 8),
        InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: KinsuTheme.divider),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    value,
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: KinsuTheme.primaryDark),
                  ),
                ),
                Icon(icon, color: KinsuTheme.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DropdownShell extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String?> onChanged;

  const _DropdownShell(
      {required this.label,
      required this.value,
      required this.values,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionKicker(label),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: KinsuTheme.divider),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: values.contains(value) ? value : values.first,
              isExpanded: true,
              icon: const Icon(Icons.keyboard_arrow_down_rounded),
              items: values
                  .map((item) =>
                      DropdownMenuItem(value: item, child: Text(item)))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionKicker extends StatelessWidget {
  final String text;

  const _SectionKicker(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        color: Color(0xFF79820A),
        fontSize: 12,
        fontWeight: FontWeight.w800,
        letterSpacing: 1.0,
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String text;

  const _InsightCard({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF2C9),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.auto_awesome, color: Color(0xFF6B4B00), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                  color: Color(0xFF6B4B00),
                  fontWeight: FontWeight.w700,
                  height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeCard(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(22),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: KinsuTheme.panel,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
              color: selected ? KinsuTheme.primary : Colors.transparent,
              width: 1.6),
        ),
        child: Column(
          children: [
            Icon(icon,
                color:
                    selected ? KinsuTheme.primary : KinsuTheme.textSecondary),
            const SizedBox(height: 10),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w800)),
          ],
        ),
      ),
    );
  }
}

class _TimeChip extends StatelessWidget {
  final String label;
  final VoidCallback? onRemove;

  const _TimeChip({required this.label, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: KinsuTheme.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.watch_later_outlined,
              size: 16, color: KinsuTheme.textSecondary),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (onRemove != null) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onRemove,
              child:
                  const Icon(Icons.close, size: 16, color: Color(0xFFF87171)),
            ),
          ],
        ],
      ),
    );
  }
}

class _TimeStatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBackground;
  final Color actionColor;
  final VoidCallback onTap;

  const _TimeStatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.actionColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
                color: iconBackground, borderRadius: BorderRadius.circular(16)),
            child: Icon(icon, color: iconColor),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        color: KinsuTheme.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 28, fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: actionColor, borderRadius: BorderRadius.circular(14)),
              child: const Icon(Icons.edit_outlined, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow(
      {required this.icon,
      required this.label,
      required this.value,
      required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: KinsuTheme.primary),
        const SizedBox(width: 12),
        Expanded(
            child: Text(label,
                style: const TextStyle(fontWeight: FontWeight.w700))),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeTrackColor: KinsuTheme.primary.withValues(alpha: 0.4),
          activeThumbColor: KinsuTheme.primary,
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _InfoCard(
      {required this.label, required this.value, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(20)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: KinsuTheme.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          Row(
            children: [
              Icon(icon, color: const Color(0xFF9BAA47)),
              const SizedBox(width: 8),
              Expanded(
                  child: Text(value,
                      style: const TextStyle(fontWeight: FontWeight.w800))),
            ],
          ),
        ],
      ),
    );
  }
}

class _VesselCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _VesselCard(
      {required this.label,
      required this.icon,
      required this.selected,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: selected ? KinsuTheme.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Icon(icon,
                color: selected ? Colors.white : KinsuTheme.textSecondary),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : KinsuTheme.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PillToggle extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _PillToggle(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? KinsuTheme.divider : Colors.transparent,
          ),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 14,
              color:
                  selected ? KinsuTheme.primaryDark : KinsuTheme.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String meta;
  final String actionLabel;

  const _HistoryCard(
      {required this.title,
      required this.subtitle,
      required this.meta,
      required this.actionLabel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: KinsuTheme.divider)),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
                color: Color(0xFFE9F3F8), shape: BoxShape.circle),
            child: const Icon(Icons.person_outline, color: KinsuTheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(
                        color: KinsuTheme.textSecondary, height: 1.35)),
                const SizedBox(height: 4),
                Text(meta,
                    style: const TextStyle(
                        color: Color(0xFF90A03A),
                        fontSize: 11,
                        fontWeight: FontWeight.w800)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
                color: const Color(0xFFDDEB7D),
                borderRadius: BorderRadius.circular(18)),
            child: Text(actionLabel,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.w800, color: Color(0xFF627100))),
          ),
        ],
      ),
    );
  }
}

class _CareHistoryCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final String tag;

  const _CareHistoryCard(
      {required this.title, required this.subtitle, required this.tag});

  @override
  Widget build(BuildContext context) {
    final normalizedTag = tag.toUpperCase();
    final (tagColor, textColor) = switch (normalizedTag) {
      'MISSED' => (const Color(0xFFFDE2E5), const Color(0xFFB91C1C)),
      'YESTERDAY' => (const Color(0xFFEAEFF5), const Color(0xFF64748B)),
      'VIEW' => (const Color(0xFFEAF2F3), const Color(0xFF0F766E)),
      _ => (const Color(0xFFE3F2D0), const Color(0xFF5C7C12)),
    };

    final leadingIcon = switch (normalizedTag) {
      'MISSED' => Icons.watch_later_outlined,
      'YESTERDAY' => Icons.calendar_today_outlined,
      _ => Icons.spa_outlined,
    };

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: KinsuTheme.divider)),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
                color: Color(0xFFF2F7DB), shape: BoxShape.circle),
            child: Icon(leadingIcon, color: const Color(0xFF86A01D), size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(color: KinsuTheme.textSecondary)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
                color: tagColor, borderRadius: BorderRadius.circular(999)),
            child: Text(tag,
                style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 11)),
          ),
        ],
      ),
    );
  }
}
