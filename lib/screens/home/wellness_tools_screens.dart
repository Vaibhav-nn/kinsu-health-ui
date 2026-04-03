import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../core/theme.dart';

class SosScreen extends StatelessWidget {
  const SosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SOS')),
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
          const _EmergencyContactCard(
            name: 'Primary Caregiver',
            phone: '+91 98XXXXXXXX',
            relation: 'Family',
          ),
          const SizedBox(height: 10),
          const _EmergencyContactCard(
            name: 'Ambulance',
            phone: '102',
            relation: 'Emergency Service',
          ),
          const SizedBox(height: 24),
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
      appBar: AppBar(title: const Text('Exercise')),
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
  int _waterGlasses = 0;
  final Map<String, bool> _meals = {
    'Breakfast tracked': false,
    'Lunch tracked': false,
    'Dinner tracked': false,
    'Snacks tracked': false,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Diet')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: KinsuTheme.cardDecoration,
            child: Row(
              children: [
                const Icon(Icons.water_drop_outlined,
                    color: KinsuTheme.primary),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Water intake: $_waterGlasses / 8 glasses',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _waterGlasses = math.min(8, _waterGlasses + 1);
                    });
                  },
                  child: const Text('+1'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          ..._meals.entries.map(
            (item) => CheckboxListTile(
              value: item.value,
              contentPadding: EdgeInsets.zero,
              title: Text(item.key),
              onChanged: (value) {
                setState(() => _meals[item.key] = value ?? false);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class SleepScreen extends StatefulWidget {
  const SleepScreen({super.key});

  @override
  State<SleepScreen> createState() => _SleepScreenState();
}

class _SleepScreenState extends State<SleepScreen> {
  TimeOfDay _sleep = const TimeOfDay(hour: 23, minute: 0);
  TimeOfDay _wake = const TimeOfDay(hour: 7, minute: 0);

  Future<void> _pickSleep() async {
    final value = await showTimePicker(context: context, initialTime: _sleep);
    if (value != null) {
      setState(() => _sleep = value);
    }
  }

  Future<void> _pickWake() async {
    final value = await showTimePicker(context: context, initialTime: _wake);
    if (value != null) {
      setState(() => _wake = value);
    }
  }

  @override
  Widget build(BuildContext context) {
    final sleepMinutes = _sleep.hour * 60 + _sleep.minute;
    var wakeMinutes = _wake.hour * 60 + _wake.minute;
    if (wakeMinutes <= sleepMinutes) {
      wakeMinutes += 24 * 60;
    }
    final duration = Duration(minutes: wakeMinutes - sleepMinutes);
    final hours = duration.inHours;
    final mins = duration.inMinutes.remainder(60);

    return Scaffold(
      appBar: AppBar(title: const Text('Sleep')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration: KinsuTheme.cardDecoration,
            child: Text(
              'Estimated sleep: ${hours}h ${mins}m',
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(height: 10),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.bedtime_outlined),
            title: const Text('Sleep time'),
            subtitle: Text(_sleep.format(context)),
            onTap: _pickSleep,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.wb_sunny_outlined),
            title: const Text('Wake time'),
            subtitle: Text(_wake.format(context)),
            onTap: _pickWake,
          ),
        ],
      ),
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
      appBar: AppBar(title: const Text('Mood')),
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
    const posts = [
      'Completed a 30-minute walk streak for 7 days.',
      'Shared healthy breakfast ideas for sugar control.',
      'Tips for keeping medication reminders consistent.',
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Community')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: posts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: KinsuTheme.cardDecoration,
            child: Text(posts[index]),
          );
        },
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
  bool _remindersEnabled = true;
  bool _weeklyDigest = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            value: _remindersEnabled,
            onChanged: (value) => setState(() => _remindersEnabled = value),
            title: const Text('Medication reminders'),
          ),
          SwitchListTile(
            value: _weeklyDigest,
            onChanged: (value) => setState(() => _weeklyDigest = value),
            title: const Text('Weekly health digest'),
          ),
        ],
      ),
    );
  }
}

class _EmergencyContactCard extends StatelessWidget {
  final String name;
  final String phone;
  final String relation;

  const _EmergencyContactCard({
    required this.name,
    required this.phone,
    required this.relation,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: KinsuTheme.cardDecoration,
      child: ListTile(
        leading: const Icon(Icons.contact_phone_outlined),
        title: Text(name),
        subtitle: Text('$relation · $phone'),
      ),
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
