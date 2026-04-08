import 'package:flutter/material.dart';
import 'package:kinsu_health/widgets/ios_back_button.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../providers/symptoms_provider.dart';
import '../widgets/track_flow_bottom_nav.dart';

class QuickSymptomLogScreen extends StatefulWidget {
  const QuickSymptomLogScreen({super.key});

  @override
  State<QuickSymptomLogScreen> createState() => _QuickSymptomLogScreenState();
}

class _QuickSymptomLogScreenState extends State<QuickSymptomLogScreen> {
  static const _feelOptions = [
    _EmojiChipData('Energetic', '⚡'),
    _EmojiChipData('Fatigue', '😴'),
    _EmojiChipData('Stable', '⚖️'),
  ];

  static const _moodOptions = [
    _EmojiChipData('Calm', '😌'),
    _EmojiChipData('Happy', '😊'),
    _EmojiChipData('Anxious', '😰'),
    _EmojiChipData('Irritable', '😠'),
    _EmojiChipData('Sad', '😢'),
    _EmojiChipData('Mood swings', '📈'),
    _EmojiChipData('Depressed', '☹️'),
    _EmojiChipData('Feeling guilty', '😔'),
    _EmojiChipData('Obsessive thoughts', '🧠'),
    _EmojiChipData('Low energy', '🔋'),
    _EmojiChipData('Apathetic', '😐'),
    _EmojiChipData('Confused', '🫨'),
    _EmojiChipData('Very self-critical', '🔎'),
  ];

  static const _digestionOptions = [
    _EmojiChipData('Nausea', '🤢'),
    _EmojiChipData('Bloating', '🫧'),
    _EmojiChipData('Diarrhea', '💧'),
    _EmojiChipData('Constipation', '🥴'),
  ];

  static const _painOptions = [
    _EmojiChipData('Headache', '💭'),
    _EmojiChipData('Backache', '🦴'),
    _EmojiChipData('Joint Pain', '🦵'),
    _EmojiChipData('Cramps', '🌀'),
  ];

  static const _activityOptions = [
    _ActivityCardData('GYM', Icons.fitness_center_rounded),
    _ActivityCardData('WALKING', Icons.directions_walk_rounded),
    _ActivityCardData('YOGA', Icons.self_improvement_rounded),
  ];

  static const _cycleOptions = [
    'On Period',
    'Spotting',
  ];

  static const _otherOptions = [
    _EmojiChipData('Travel', '✈️'),
    _EmojiChipData('Stress', '📍'),
    _EmojiChipData('Alcohol', '🍷'),
  ];

  final _notesController = TextEditingController();
  String? _selectedFeeling;
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
          primaryFeeling: _selectedFeeling,
          moodTags: _moodTags.toList(),
          digestionTags: _digestionTags.toList(),
          painTags: _painTags.toList(),
          activityTags: _activityTags.toList(),
          cycleTags: _cycleTags.toList(),
          otherTags: _otherTags.toList(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          severity: 5,
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
      backgroundColor: Colors.white,
      bottomNavigationBar: const TrackFlowBottomNav(
        selectedTab: TrackFlowNavTab.symptoms,
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 12),
              child: Row(
                children: [
                  IosBackButton(onTap: () => Navigator.of(context).pop()),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Log Symptoms',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        color: KinsuTheme.primaryDark,
                      ),
                    ),
                  ),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFFFDE68A),
                    ),
                    alignment: Alignment.center,
                    child: const Text(
                      '🧑',
                      style: TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 26),
                children: [
                  Container(
                    padding: const EdgeInsets.fromLTRB(18, 18, 18, 20),
                    decoration: BoxDecoration(
                      color: KinsuTheme.primaryDark,
                      borderRadius: BorderRadius.circular(26),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _TinyPill(label: 'DAILY CHECK-IN'),
                        SizedBox(height: 12),
                        Text(
                          'Your patterns\nspeak. Let’s listen.',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            height: 1.05,
                          ),
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Logging today’s symptoms helps you care for your body and understand your wellness journey.',
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                            height: 1.45,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FlatSection(
                    icon: Icons.sentiment_satisfied_alt_rounded,
                    title: 'How do you feel today?',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _feelOptions.map((option) {
                        final isSelected = _selectedFeeling == option.label;
                        return _EmojiChip(
                          data: option,
                          selected: isSelected,
                          onTap: () => setState(() {
                            _selectedFeeling = isSelected ? null : option.label;
                          }),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FlatSection(
                    icon: Icons.mood_outlined,
                    title: 'Mood',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _moodOptions.map((option) {
                        final isSelected = _moodTags.contains(option.label);
                        return _EmojiChip(
                          data: option,
                          selected: isSelected,
                          onTap: () => _toggle(_moodTags, option.label),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FlatSection(
                    icon: Icons.restaurant_menu_outlined,
                    title: 'Digestion & Stool',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _digestionOptions.map((option) {
                        final isSelected =
                            _digestionTags.contains(option.label);
                        return _EmojiChip(
                          data: option,
                          selected: isSelected,
                          onTap: () => _toggle(_digestionTags, option.label),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FlatSection(
                    icon: Icons.personal_injury_outlined,
                    title: 'Pain',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _painOptions.map((option) {
                        final isSelected = _painTags.contains(option.label);
                        return _EmojiChip(
                          data: option,
                          selected: isSelected,
                          onTap: () => _toggle(_painTags, option.label),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FlatSection(
                    icon: Icons.directions_run_rounded,
                    title: 'Physical Activity',
                    child: Row(
                      children: _activityOptions.map((option) {
                        final isSelected = _activityTags.contains(option.label);
                        return Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              right: option == _activityOptions.last ? 0 : 10,
                            ),
                            child: _ActivityCard(
                              data: option,
                              selected: isSelected,
                              onTap: () => _toggle(_activityTags, option.label),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FlatSection(
                    icon: Icons.calendar_month_outlined,
                    title: 'Menstrual Cycle',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _cycleOptions.map((option) {
                        final isSelected = _cycleTags.contains(option);
                        return _MiniChoiceChip(
                          label: option,
                          selected: isSelected,
                          onTap: () => _toggle(_cycleTags, option),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FlatSection(
                    icon: Icons.more_horiz_rounded,
                    title: 'Other',
                    child: Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      children: _otherOptions.map((option) {
                        final isSelected = _otherTags.contains(option.label);
                        return _EmojiChip(
                          data: option,
                          selected: isSelected,
                          highlightSelected: true,
                          onTap: () => _toggle(_otherTags, option.label),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _FlatSection(
                    icon: Icons.edit_note_rounded,
                    title: 'Extra Notes',
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFF5F8FA),
                            borderRadius: BorderRadius.circular(22),
                            border: Border.all(color: KinsuTheme.divider),
                          ),
                          child: TextField(
                            controller: _notesController,
                            minLines: 4,
                            maxLines: 5,
                            decoration: const InputDecoration(
                              hintText:
                                  'Anything else you’d like to mention?\nPersonal observations or specific details…',
                              border: InputBorder.none,
                              enabledBorder: InputBorder.none,
                              focusedBorder: InputBorder.none,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 18,
                                vertical: 18,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Align(
                          alignment: Alignment.centerRight,
                          child: Text(
                            'OPTIONAL',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              color: KinsuTheme.textSecondary,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isSaving ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: KinsuTheme.primaryDark,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      child: isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('Save Daily Logs'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FlatSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget child;

  const _FlatSection({
    required this.icon,
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: const Color(0xFF7A8405)),
            const SizedBox(width: 8),
            Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: KinsuTheme.primaryDark,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}

class _EmojiChip extends StatelessWidget {
  final _EmojiChipData data;
  final bool selected;
  final VoidCallback onTap;
  final bool highlightSelected;

  const _EmojiChip({
    required this.data,
    required this.selected,
    required this.onTap,
    this.highlightSelected = false,
  });

  @override
  Widget build(BuildContext context) {
    final background = selected
        ? (highlightSelected
            ? const Color(0xFFE6EF87)
            : const Color(0xFFF1F5F8))
        : const Color(0xFFF1F5F8);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected
                ? (highlightSelected
                    ? const Color(0xFFD7DF65)
                    : KinsuTheme.divider)
                : Colors.transparent,
          ),
        ),
        child: Text(
          '${data.emoji} ${data.label}',
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: KinsuTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _MiniChoiceChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _MiniChoiceChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFF1F5F8) : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? KinsuTheme.primary : KinsuTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? KinsuTheme.primaryDark : KinsuTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

class _ActivityCard extends StatelessWidget {
  final _ActivityCardData data;
  final bool selected;
  final VoidCallback onTap;

  const _ActivityCard({
    required this.data,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7F9),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? KinsuTheme.primary : Colors.transparent,
            width: 1.4,
          ),
        ),
        child: Column(
          children: [
            Icon(
              data.icon,
              color: KinsuTheme.textPrimary,
              size: 28,
            ),
            const SizedBox(height: 12),
            Text(
              data.label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.6,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TinyPill extends StatelessWidget {
  final String label;

  const _TinyPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFEADFA2),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF6A5700),
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

class _EmojiChipData {
  final String label;
  final String emoji;

  const _EmojiChipData(this.label, this.emoji);
}

class _ActivityCardData {
  final String label;
  final IconData icon;

  const _ActivityCardData(this.label, this.icon);
}
