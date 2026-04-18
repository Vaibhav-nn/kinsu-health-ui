import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:kinsu_health/widgets/ios_back_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme.dart';

class _SosContact {
  final String name;
  final String phone;
  final String relation;

  const _SosContact({
    required this.name,
    required this.phone,
    required this.relation,
  });
}

class SosScreen extends StatefulWidget {
  const SosScreen({super.key});

  @override
  State<SosScreen> createState() => _SosScreenState();
}

class _SosScreenState extends State<SosScreen> {
  final List<_SosContact> _contacts = [
    const _SosContact(
      name: 'Primary Caregiver',
      phone: '+91 98XXXXXXXX',
      relation: 'Family',
    ),
    const _SosContact(
      name: 'Ambulance',
      phone: '102',
      relation: 'Emergency Service',
    ),
  ];

  Future<void> _showAddContactDialog() async {
    final nameController = TextEditingController();
    final phoneController = TextEditingController();
    final relationController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Add Emergency Contact'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: 'Name *'),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 8),
            TextField(
              controller: phoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(labelText: 'Phone number *'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: relationController,
              decoration: const InputDecoration(
                labelText: 'Relation',
                hintText: 'e.g. Family, Friend',
              ),
              textCapitalization: TextCapitalization.words,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final phone = phoneController.text.trim();
              if (name.isEmpty || phone.isEmpty) {
                return;
              }
              setState(() {
                _contacts.add(_SosContact(
                  name: name,
                  phone: phone,
                  relation: relationController.text.trim().isEmpty
                      ? 'Contact'
                      : relationController.text.trim(),
                ));
              });
              Navigator.pop(dialogContext);
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    nameController.dispose();
    phoneController.dispose();
    relationController.dispose();
  }

  void _removeContact(int index) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove Contact'),
        content: Text(
            'Remove "${_contacts[index].name}" from emergency contacts?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              setState(() => _contacts.removeAt(index));
              Navigator.pop(ctx);
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const IosBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('SOS'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_outlined),
            tooltip: 'Add Contact',
            onPressed: _showAddContactDialog,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFEF2F2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFECACA)),
            ),
            child: const Text(
              'Emergency mode shares your latest health summary with caregivers and calls the selected contact.',
              style: TextStyle(color: Color(0xFF991B1B)),
            ),
          ),
          const SizedBox(height: 12),
          if (_contacts.isEmpty)
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF9FAFB),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: const Text(
                'No emergency contacts yet. Tap the + button above to add one.',
                style: TextStyle(color: Color(0xFF6B7280)),
              ),
            )
          else
            ...List.generate(_contacts.length, (index) {
              final contact = _contacts[index];
              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: ListTile(
                    leading: const Icon(Icons.contact_phone_outlined),
                    title: Text(contact.name),
                    subtitle: Text('${contact.relation} · ${contact.phone}'),
                    trailing: IconButton(
                      icon: const Icon(
                        Icons.remove_circle_outline,
                        color: Color(0xFFDC2626),
                      ),
                      tooltip: 'Remove',
                      onPressed: () => _removeContact(index),
                    ),
                  ),
                ),
              );
            }),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _showAddContactDialog,
            icon: const Icon(Icons.add),
            label: const Text('Add Emergency Contact'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
              minimumSize: const Size.fromHeight(52),
            ),
            onPressed: () async {
              await showDialog<void>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('SOS Triggered'),
                  content: const Text(
                    'In production this will call emergency contacts and share your health summary.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Close'),
                    ),
                  ],
                ),
              );
            },
            icon: const Icon(Icons.sos),
            label: const Text('Trigger Emergency SOS'),
          ),
        ],
      ),
    );
  }
}

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  static const _types = ['Walk', 'Cardio', 'Yoga', 'Strength'];

  String _selected = _types.first;
  final TextEditingController _minutesController = TextEditingController();
  final List<_ExerciseEntry> _entries = [];

  @override
  void dispose() {
    _minutesController.dispose();
    super.dispose();
  }

  void _addEntry() {
    final minutes = int.tryParse(_minutesController.text.trim());
    if (minutes == null || minutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter valid minutes.')),
      );
      return;
    }
    setState(() {
      _entries.insert(
        0,
        _ExerciseEntry(type: _selected, minutes: minutes, at: DateTime.now()),
      );
      _minutesController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalMinutes =
        _entries.fold<int>(0, (sum, item) => sum + item.minutes);
    return Scaffold(
      appBar: AppBar(
        leading: const IosBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Exercise'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: KinsuTheme.cardDecoration,
            child: Row(
              children: [
                const Icon(Icons.local_fire_department,
                    color: KinsuTheme.primary),
                const SizedBox(width: 10),
                Text(
                  '$totalMinutes min logged this week',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _types
                .map(
                  (type) => ChoiceChip(
                    label: Text(type),
                    selected: _selected == type,
                    onSelected: (_) => setState(() => _selected = type),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _minutesController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Minutes',
              hintText: 'Example: 30',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _addEntry,
            child: const Text('Add Activity'),
          ),
          const SizedBox(height: 14),
          ..._entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Container(
                decoration: KinsuTheme.cardDecoration,
                child: ListTile(
                  leading: const Icon(Icons.fitness_center),
                  title: Text('${entry.type} · ${entry.minutes} min'),
                  subtitle: Text(
                    '${entry.at.day}/${entry.at.month} ${entry.at.hour.toString().padLeft(2, '0')}:${entry.at.minute.toString().padLeft(2, '0')}',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class DietScreen extends StatefulWidget {
  const DietScreen({super.key});

  @override
  State<DietScreen> createState() => _DietScreenState();
}

class _DietScreenState extends State<DietScreen> {
  static const _keyWater = 'diet_water_glasses';
  static const _keyMealsPrefix = 'diet_meal_';
  static const _keyDate = 'diet_last_date';

  int _waterGlasses = 0;
  final Map<String, bool> _meals = {
    'Breakfast': false,
    'Lunch': false,
    'Dinner': false,
    'Snacks': false,
  };
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_keyDate) ?? '';

    if (savedDate != today) {
      // New day — reset everything
      await prefs.setString(_keyDate, today);
      await prefs.setInt(_keyWater, 0);
      for (final key in _meals.keys) {
        await prefs.setBool('$_keyMealsPrefix$key', false);
      }
    }

    if (!mounted) return;
    setState(() {
      _waterGlasses = prefs.getInt(_keyWater) ?? 0;
      for (final key in _meals.keys) {
        _meals[key] = prefs.getBool('$_keyMealsPrefix$key') ?? false;
      }
      _loaded = true;
    });
  }

  Future<void> _addWater() async {
    final next = math.min(8, _waterGlasses + 1);
    setState(() => _waterGlasses = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyWater, next);
  }

  Future<void> _toggleMeal(String meal, bool value) async {
    setState(() => _meals[meal] = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('$_keyMealsPrefix$meal', value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final mealsTracked = _meals.values.where((v) => v).length;

    return Scaffold(
      appBar: AppBar(
        leading: const IosBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Diet'),
      ),
      body: _loaded
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Water tracker ─────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: KinsuTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.water_drop_outlined, color: KinsuTheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Water intake today',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            '$_waterGlasses / 8',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: KinsuTheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      // Water glass indicators
                      Row(
                        children: List.generate(8, (i) {
                          final filled = i < _waterGlasses;
                          return Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 2),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                height: 28,
                                decoration: BoxDecoration(
                                  color: filled
                                      ? KinsuTheme.primary.withOpacity(0.8)
                                      : KinsuTheme.primary.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: filled
                                    ? const Icon(Icons.water_drop, size: 14, color: Colors.white)
                                    : null,
                              ),
                            ),
                          );
                        }),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _waterGlasses < 8 ? _addWater : null,
                          icon: const Icon(Icons.add, size: 16),
                          label: Text(_waterGlasses >= 8 ? 'Goal reached! 🎉' : 'Log a glass'),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // ── Meal tracker ──────────────────────────────
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: KinsuTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.restaurant_outlined, color: KinsuTheme.primary),
                          const SizedBox(width: 8),
                          Text(
                            'Meals today',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const Spacer(),
                          Text(
                            '$mealsTracked / ${_meals.length}',
                            style: theme.textTheme.bodySmall?.copyWith(color: KinsuTheme.textSecondary),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ..._meals.entries.map(
                        (entry) => CheckboxListTile(
                          value: entry.value,
                          contentPadding: EdgeInsets.zero,
                          dense: true,
                          activeColor: colorScheme.primary,
                          title: Text(entry.key),
                          onChanged: (value) => _toggleMeal(entry.key, value ?? false),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // ── Daily summary chip ────────────────────────
                if (mealsTracked == _meals.length && _waterGlasses >= 8)
                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle_outline, color: Colors.green),
                        SizedBox(width: 10),
                        Text(
                          'Great job! All nutrition goals met today.',
                          style: TextStyle(color: Colors.green, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  static const _keySleepH = 'sleep_sleep_hour';
  static const _keySleepM = 'sleep_sleep_minute';
  static const _keyWakeH = 'sleep_wake_hour';
  static const _keyWakeM = 'sleep_wake_minute';
  static const _keyLogged = 'sleep_logged_today';
  static const _keyDate = 'sleep_last_date';

  TimeOfDay _sleep = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wake = const TimeOfDay(hour: 7, minute: 0);
  bool _loggedToday = false;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final savedDate = prefs.getString(_keyDate) ?? '';

    if (savedDate != today) {
      await prefs.setString(_keyDate, today);
      await prefs.setBool(_keyLogged, false);
    }

    if (!mounted) return;
    setState(() {
      _sleep = TimeOfDay(
        hour: prefs.getInt(_keySleepH) ?? 23,
        minute: prefs.getInt(_keySleepM) ?? 0,
      );
      _wake = TimeOfDay(
        hour: prefs.getInt(_keyWakeH) ?? 7,
        minute: prefs.getInt(_keyWakeM) ?? 0,
      );
      _loggedToday = prefs.getBool(_keyLogged) ?? false;
      _loaded = true;
    });
  }

  Future<void> _pickSleep() async {
    final value = await showTimePicker(context: context, initialTime: _sleep);
    if (value != null && mounted) {
      setState(() => _sleep = value);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keySleepH, value.hour);
      await prefs.setInt(_keySleepM, value.minute);
    }
  }

  Future<void> _pickWake() async {
    final value = await showTimePicker(context: context, initialTime: _wake);
    if (value != null && mounted) {
      setState(() => _wake = value);
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyWakeH, value.hour);
      await prefs.setInt(_keyWakeM, value.minute);
    }
  }

  Future<void> _logSleep() async {
    setState(() => _loggedToday = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyLogged, true);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Sleep logged for today!')),
    );
  }

  String _sleepQualityLabel(int hours) {
    if (hours >= 8) return 'Excellent 🌟';
    if (hours >= 7) return 'Good 👍';
    if (hours >= 6) return 'Fair ⚠️';
    return 'Low 😴 — aim for 7–9 hours';
  }

  Color _sleepQualityColor(int hours) {
    if (hours >= 8) return Colors.green;
    if (hours >= 7) return KinsuTheme.primary;
    if (hours >= 6) return Colors.orange;
    return Colors.red;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final sleepMinutes = _sleep.hour * 60 + _sleep.minute;
    var wakeMinutes = _wake.hour * 60 + _wake.minute;
    if (wakeMinutes <= sleepMinutes) wakeMinutes += 24 * 60;
    final duration = Duration(minutes: wakeMinutes - sleepMinutes);
    final hours = duration.inHours;
    final mins = duration.inMinutes.remainder(60);

    return Scaffold(
      appBar: AppBar(
        leading: const IosBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Sleep'),
      ),
      body: _loaded
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ── Duration card ────────────────────────────
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: KinsuTheme.cardDecoration,
                  child: Column(
                    children: [
                      Text(
                        '${hours}h ${mins}m',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: _sleepQualityColor(hours),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _sleepQualityLabel(hours),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: _sleepQualityColor(hours),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // ── Time pickers ─────────────────────────────
                Container(
                  decoration: KinsuTheme.cardDecoration,
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.bedtime_outlined, color: KinsuTheme.primary),
                        title: const Text('Bedtime'),
                        subtitle: Text(_sleep.format(context)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _pickSleep,
                      ),
                      const Divider(height: 1),
                      ListTile(
                        leading: const Icon(Icons.wb_sunny_outlined, color: KinsuTheme.primary),
                        title: const Text('Wake time'),
                        subtitle: Text(_wake.format(context)),
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: _pickWake,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                // ── Log button ────────────────────────────────
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: _loggedToday ? null : _logSleep,
                    icon: Icon(_loggedToday ? Icons.check : Icons.save_outlined),
                    label: Text(_loggedToday ? 'Logged for today' : 'Log tonight\'s sleep'),
                  ),
                ),
                if (!_loggedToday) ...[
                  const SizedBox(height: 8),
                  const Text(
                    'Tap to record your sleep for today. Logged times persist across sessions.',
                    style: TextStyle(fontSize: 12, color: KinsuTheme.textSecondary),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class MoodScreen extends StatefulWidget {
  const MoodScreen({super.key});

  @override
  State<MoodScreen> createState() => _MoodScreenState();
}

class _MoodScreenState extends State<MoodScreen> {
  int _selectedMood = 3;
  final TextEditingController _notesController = TextEditingController();
  final List<_MoodEntry> _entries = [];

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _saveMood() {
    setState(() {
      _entries.insert(
        0,
        _MoodEntry(
          score: _selectedMood,
          notes: _notesController.text.trim(),
          at: DateTime.now(),
        ),
      );
      _notesController.clear();
    });
  }

  String _moodLabel(int score) {
    switch (score) {
      case 1:
        return 'Low';
      case 2:
        return 'Down';
      case 3:
        return 'Neutral';
      case 4:
        return 'Good';
      default:
        return 'Great';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const IosBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Mood'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text('How are you feeling today? (${_moodLabel(_selectedMood)})'),
          Slider(
            value: _selectedMood.toDouble(),
            min: 1,
            max: 5,
            divisions: 4,
            label: _moodLabel(_selectedMood),
            onChanged: (value) => setState(() => _selectedMood = value.round()),
          ),
          TextField(
            controller: _notesController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Notes',
              hintText: 'Anything affecting your mood?',
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton(
            onPressed: _saveMood,
            child: const Text('Save Mood'),
          ),
          const SizedBox(height: 10),
          ..._entries.map(
            (entry) => ListTile(
              contentPadding: EdgeInsets.zero,
              title: Text('Mood: ${_moodLabel(entry.score)}'),
              subtitle: Text(
                '${entry.notes.isEmpty ? 'No notes' : entry.notes}\n${entry.at.day}/${entry.at.month} ${entry.at.hour.toString().padLeft(2, '0')}:${entry.at.minute.toString().padLeft(2, '0')}',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: const IosBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Community'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: BoxDecoration(
                color: colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.people_outline_rounded, size: 48, color: colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Community is coming soon',
              style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Connect with others on the same health journey — share milestones, tips, and encouragement.',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey[600], height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            _UpcomingFeatureTile(
              icon: Icons.forum_outlined,
              title: 'Health forums',
              description: 'Discuss topics like nutrition, exercise, and chronic conditions.',
            ),
            const SizedBox(height: 12),
            _UpcomingFeatureTile(
              icon: Icons.emoji_events_outlined,
              title: 'Challenges & streaks',
              description: 'Join group challenges and celebrate milestones together.',
            ),
            const SizedBox(height: 12),
            _UpcomingFeatureTile(
              icon: Icons.volunteer_activism_outlined,
              title: 'Expert Q&A',
              description: 'Get answers from verified health professionals.',
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.notifications_outlined),
                label: const Text('Notify me when it launches'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingFeatureTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;

  const _UpcomingFeatureTile({
    required this.icon,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: KinsuTheme.cardDecoration,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: colorScheme.primary.withOpacity(0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, size: 22, color: colorScheme.primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                const SizedBox(height: 4),
                Text(description, style: TextStyle(fontSize: 13, color: Colors.grey[600], height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _keyReminders = 'settings_reminders_enabled';
  static const _keyWeeklyDigest = 'settings_weekly_digest';

  bool _remindersEnabled = true;
  bool _weeklyDigest = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _remindersEnabled = prefs.getBool(_keyReminders) ?? true;
      _weeklyDigest = prefs.getBool(_keyWeeklyDigest) ?? true;
      _loaded = true;
    });
  }

  Future<void> _setReminders(bool value) async {
    setState(() => _remindersEnabled = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyReminders, value);
  }

  Future<void> _setWeeklyDigest(bool value) async {
    setState(() => _weeklyDigest = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyWeeklyDigest, value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const IosBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Settings'),
      ),
      body: _loaded
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SwitchListTile(
                  value: _remindersEnabled,
                  onChanged: _setReminders,
                  title: const Text('Medication reminders'),
                  subtitle: const Text('Get notified when it\'s time to take your medication'),
                ),
                SwitchListTile(
                  value: _weeklyDigest,
                  onChanged: _setWeeklyDigest,
                  title: const Text('Weekly health digest'),
                  subtitle: const Text('Receive a weekly summary of your health trends'),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}

class _ExerciseEntry {
  final String type;
  final int minutes;
  final DateTime at;

  const _ExerciseEntry({
    required this.type,
    required this.minutes,
    required this.at,
  });
}

class _MoodEntry {
  final int score;
  final String notes;
  final DateTime at;

  const _MoodEntry({
    required this.score,
    required this.notes,
    required this.at,
  });
}
