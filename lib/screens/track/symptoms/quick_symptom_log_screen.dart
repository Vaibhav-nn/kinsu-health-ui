import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../providers/symptoms_provider.dart';

class QuickSymptomLogScreen extends StatefulWidget {
  const QuickSymptomLogScreen({super.key});

  @override
  State<QuickSymptomLogScreen> createState() => _QuickSymptomLogScreenState();
}

class _QuickSymptomLogScreenState extends State<QuickSymptomLogScreen> {
  static const _moodOptions = [
    'Energetic',
    'Fatigue',
    'Stable Mood',
    'Happy',
    'Anxious',
    'Sad',
    'Low Energy',
    'Mood Swings',
  ];

  static const _digestionOptions = [
    'Bloating',
    'Constipation',
    'Loose Stool',
    'Acidity',
  ];

  static const _painOptions = [
    'Headache',
    'Body Ache',
    'Joint Pain',
    'Swelling',
  ];

  static const _activityOptions = [
    'Walked',
    'Worked Out',
    'Sedentary',
    'Light Activity',
  ];

  static const _cycleOptions = [
    'Period',
    'PMS',
    'Cramps',
    'Irregular',
  ];

  static const _otherOptions = [
    'Cough',
    'Fever',
    'Dizziness',
    'Breathlessness',
  ];

  final _notesController = TextEditingController();
  String? _primaryFeeling;
  int _severity = 5;
  final Set<String> _moodTags = {};
  final Set<String> _digestionTags = {};
  final Set<String> _painTags = {};
  final Set<String> _activityTags = {};
  final Set<String> _cycleTags = {};
  final Set<String> _otherTags = {};

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final success = await context.read<SymptomsProvider>().submitDailyCheckIn(
          primaryFeeling: _primaryFeeling,
          moodTags: _moodTags.toList(),
          digestionTags: _digestionTags.toList(),
          painTags: _painTags.toList(),
          activityTags: _activityTags.toList(),
          cycleTags: _cycleTags.toList(),
          otherTags: _otherTags.toList(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          severity: _severity,
        );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily check-in saved successfully.'),
          backgroundColor: KinsuTheme.statusActive,
        ),
      );
      Navigator.of(context).pop(true);
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.read<SymptomsProvider>().error ??
              'Unable to save your symptom check-in.',
        ),
        backgroundColor: KinsuTheme.statusError,
      ),
    );
  }

  void _toggle(Set<String> target, String value) {
    setState(() {
      if (!target.add(value)) {
        target.remove(value);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = context
        .select<SymptomsProvider, bool>((provider) => provider.isLoading);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Log Symptoms'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Daily Check-in',
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your patterns speak. Let\'s listen. Capture how you feel across mood, digestion, pain, movement, and other body signals.',
            style: TextStyle(color: KinsuTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 20),
          _TagSection(
            title: 'How do you feel today?',
            options: _moodOptions,
            selected: _moodTags,
            onToggle: (value) {
              _toggle(_moodTags, value);
              _primaryFeeling ??= value;
            },
          ),
          const SizedBox(height: 18),
          _TagSection(
            title: 'Digestion & Stool',
            options: _digestionOptions,
            selected: _digestionTags,
            onToggle: (value) => _toggle(_digestionTags, value),
          ),
          const SizedBox(height: 18),
          _TagSection(
            title: 'Pain',
            options: _painOptions,
            selected: _painTags,
            onToggle: (value) => _toggle(_painTags, value),
          ),
          const SizedBox(height: 18),
          _TagSection(
            title: 'Physical Activity',
            options: _activityOptions,
            selected: _activityTags,
            onToggle: (value) => _toggle(_activityTags, value),
          ),
          const SizedBox(height: 18),
          _TagSection(
            title: 'Menstrual Cycle',
            options: _cycleOptions,
            selected: _cycleTags,
            onToggle: (value) => _toggle(_cycleTags, value),
          ),
          const SizedBox(height: 18),
          _TagSection(
            title: 'Other',
            options: _otherOptions,
            selected: _otherTags,
            onToggle: (value) => _toggle(_otherTags, value),
          ),
          const SizedBox(height: 20),
          const Text(
            'How intense did it feel?',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 12),
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: KinsuTheme.primary,
              inactiveTrackColor:
                  KinsuTheme.textSecondary.withValues(alpha: 0.2),
              thumbColor: KinsuTheme.primary,
            ),
            child: Slider(
              value: _severity.toDouble(),
              min: 1,
              max: 10,
              divisions: 9,
              onChanged: (value) => setState(() => _severity = value.round()),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Mild',
                  style: TextStyle(color: KinsuTheme.textSecondary)),
              Text(
                '$_severity/10',
                style:
                    const TextStyle(fontWeight: FontWeight.w700, fontSize: 18),
              ),
              const Text('Severe',
                  style: TextStyle(color: KinsuTheme.textSecondary)),
            ],
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _notesController,
            minLines: 4,
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'Extra Notes (optional)',
              hintText:
                  'Anything else you\'d like to mention? Personal observations or specific details...',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: isSaving ? null : _submit,
            child: isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Text('Save Daily Logs'),
          ),
        ],
      ),
    );
  }
}

class _TagSection extends StatelessWidget {
  final String title;
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;

  const _TagSection({
    required this.title,
    required this.options,
    required this.selected,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: options.map((option) {
            final isSelected = selected.contains(option);
            return ChoiceChip(
              label: Text(option),
              selected: isSelected,
              onSelected: (_) => onToggle(option),
              selectedColor: KinsuTheme.primary.withValues(alpha: 0.12),
              labelStyle: TextStyle(
                color: isSelected ? KinsuTheme.primary : KinsuTheme.textPrimary,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
