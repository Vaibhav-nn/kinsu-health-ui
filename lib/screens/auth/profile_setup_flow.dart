import 'package:flutter/material.dart';
import 'package:kinsu_health/widgets/ios_back_button.dart';

import '../../core/theme.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';

class ProfileSetupFlow extends StatefulWidget {
  final AuthService authService;
  final UserProfile initialProfile;
  final VoidCallback onCompleted;

  const ProfileSetupFlow({
    super.key,
    required this.authService,
    required this.initialProfile,
    required this.onCompleted,
  });

  @override
  State<ProfileSetupFlow> createState() => _ProfileSetupFlowState();
}

class _ProfileSetupFlowState extends State<ProfileSetupFlow> {
  final _nameController = TextEditingController();
  final _professionController = TextEditingController();
  final _heightController = TextEditingController();
  final _weightController = TextEditingController();

  int _stepIndex = 0;
  bool _isSaving = false;
  bool _consentAccepted = false;
  String? _gender;
  DateTime? _dob;
  String? _bloodGroup;
  final Set<String> _selectedGoals = <String>{};

  final List<_GoalOption> _goalOptions = const [
    _GoalOption(
        id: 'diabetes',
        label: 'Manage Diabetes',
        icon: Icons.water_drop_outlined),
    _GoalOption(
        id: 'bp',
        label: 'Control Blood Pressure',
        icon: Icons.favorite_outline),
    _GoalOption(
        id: 'weight',
        label: 'Lose Weight',
        icon: Icons.monitor_weight_outlined),
    _GoalOption(
        id: 'fitness',
        label: 'Get Fitter',
        icon: Icons.directions_run_outlined),
    _GoalOption(id: 'diet', label: 'Eat Healthier', icon: Icons.eco_outlined),
    _GoalOption(
        id: 'thyroid', label: 'Manage Thyroid', icon: Icons.healing_outlined),
    _GoalOption(
        id: 'stress',
        label: 'Reduce Stress',
        icon: Icons.self_improvement_outlined),
    _GoalOption(
        id: 'records',
        label: 'Organize Medical Records',
        icon: Icons.folder_copy_outlined),
    _GoalOption(
        id: 'family', label: 'Care for Family', icon: Icons.shield_outlined),
  ];

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _nameController.text = p.displayName ?? '';
    _professionController.text = p.profession ?? '';
    if (p.heightCm != null) {
      _heightController.text = p.heightCm!.toStringAsFixed(0);
    }
    if (p.weightKg != null) {
      _weightController.text = p.weightKg!.toStringAsFixed(0);
    }
    _gender = p.gender;
    _dob = p.dateOfBirth;
    _bloodGroup = p.bloodGroup;
    _consentAccepted = p.consentAcceptedAt != null;
    _selectedGoals.addAll(p.healthGoals);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _professionController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  Future<void> _next() async {
    if (_isSaving) return;
    if (_stepIndex == 0 && !_consentAccepted) {
      _showMessage('Please accept consent to continue.');
      return;
    }
    if (_stepIndex == 1 && _nameController.text.trim().isEmpty) {
      _showMessage('Full name is required.');
      return;
    }

    if (_stepIndex < 3) {
      setState(() => _stepIndex += 1);
      return;
    }

    await _saveProfile();
  }

  Future<void> _saveProfile() async {
    final height = double.tryParse(_heightController.text.trim());
    final weight = double.tryParse(_weightController.text.trim());

    if (height != null && (height < 0 || height > 250)) {
      _showMessage('Height must be between 0 and 250 cm.');
      return;
    }
    if (weight != null && (weight < 0 || weight > 200)) {
      _showMessage('Weight must be between 0 and 200 kg.');
      return;
    }

    setState(() => _isSaving = true);
    try {
      if (_consentAccepted && widget.initialProfile.consentAcceptedAt == null) {
        await widget.authService.acceptConsent();
      }

      await widget.authService.updateProfile(
        displayName: _nameController.text.trim().isEmpty
            ? null
            : _nameController.text.trim(),
        gender: _gender,
        dateOfBirth: _dob,
        bloodGroup: _bloodGroup,
        heightCm: height,
        weightKg: weight,
        profession: _professionController.text.trim().isEmpty
            ? null
            : _professionController.text.trim(),
        healthGoals: _selectedGoals.toList(),
        markOnboardingComplete: true,
      );

      if (!mounted) return;
      widget.onCompleted();
    } catch (e) {
      _showMessage('Unable to save profile: $e');
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  int? _calculateAge(DateTime? dob) {
    if (dob == null) return null;
    final today = DateTime.now();
    var years = today.year - dob.year;
    final hadBirthday = (today.month > dob.month) ||
        (today.month == dob.month && today.day >= dob.day);
    if (!hadBirthday) {
      years -= 1;
    }
    return years < 0 ? null : years;
  }

  Future<void> _pickDate() async {
    final initial = _dob ?? DateTime(1992, 1, 1);
    final selected = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (selected != null) {
      setState(() => _dob = selected);
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: const IosBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Set Up Your Profile'),
      ),
      body: SafeArea(
        child: Column(
          children: [
            LinearProgressIndicator(
              value: (_stepIndex + 1) / 4,
              minHeight: 4,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: switch (_stepIndex) {
                  0 => _buildConsentStep(),
                  1 => _buildBasicStep(),
                  2 => _buildOptionalStep(),
                  _ => _buildGoalsStep(),
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Row(
                children: [
                  if (_stepIndex > 0)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () => setState(() => _stepIndex -= 1),
                        child: const Text('Back'),
                      ),
                    ),
                  if (_stepIndex > 0) const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _isSaving ? null : _next,
                      child: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : Text(_stepIndex == 3 ? 'Finish Setup' : 'Continue'),
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

  Widget _buildConsentStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Consent & Privacy',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'We use your data to power health tracking, reminders, and insights. You can manage permissions anytime.',
          style: TextStyle(color: KinsuTheme.textSecondary, height: 1.4),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: KinsuTheme.cardDecoration,
          child: Row(
            children: [
              Checkbox(
                value: _consentAccepted,
                onChanged: (value) {
                  setState(() => _consentAccepted = value ?? false);
                },
              ),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'I agree to Kinsu Terms of Service and Privacy Policy.',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildBasicStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Basic Details',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _nameController,
          decoration: const InputDecoration(labelText: 'Full Name *'),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          key: ValueKey(_gender ?? 'gender_none'),
          initialValue: _gender,
          decoration: const InputDecoration(labelText: 'Gender'),
          items: const [
            DropdownMenuItem(value: 'male', child: Text('Male')),
            DropdownMenuItem(value: 'female', child: Text('Female')),
            DropdownMenuItem(value: 'other', child: Text('Other')),
            DropdownMenuItem(
                value: 'prefer_not_to_say', child: Text('Prefer not to say')),
          ],
          onChanged: (value) => setState(() => _gender = value),
        ),
        const SizedBox(height: 12),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(12),
          child: InputDecorator(
            decoration: const InputDecoration(labelText: 'Date of Birth'),
            child: Text(
              _dob == null
                  ? 'Select date'
                  : '${_dob!.year}-${_dob!.month.toString().padLeft(2, '0')}-${_dob!.day.toString().padLeft(2, '0')}',
            ),
          ),
        ),
        if (_dob != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: KinsuTheme.cardDecoration,
            child: Text(
              'Age recognized: ${_calculateAge(_dob) ?? '--'} years',
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                color: KinsuTheme.textPrimary,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: ['A+', 'A-', 'B+', 'B-', 'O+', 'O-', 'AB+', 'AB-']
              .map(
                (group) => ChoiceChip(
                  label: Text(group),
                  selected: _bloodGroup == group,
                  onSelected: (_) => setState(() => _bloodGroup = group),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildOptionalStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Optional Details',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _heightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Height (cm)',
                  helperText: 'Max 250 cm',
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _weightController,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weight (kg)',
                  helperText: 'Max 200 kg',
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _professionController,
          decoration: const InputDecoration(labelText: 'Profession'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: _isSaving ? null : () => setState(() => _stepIndex = 3),
          child: const Text('Skip this step'),
        ),
      ],
    );
  }

  Widget _buildGoalsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Health Goals',
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        const Text(
          'Select all that apply. This helps personalize reminders and insights.',
          style: TextStyle(color: KinsuTheme.textSecondary),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _goalOptions
              .map(
                (goal) => FilterChip(
                  avatar: Icon(goal.icon, size: 16),
                  label: Text(goal.label),
                  selected: _selectedGoals.contains(goal.id),
                  onSelected: (selected) {
                    setState(() {
                      if (selected) {
                        _selectedGoals.add(goal.id);
                      } else {
                        _selectedGoals.remove(goal.id);
                      }
                    });
                  },
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class _GoalOption {
  final String id;
  final String label;
  final IconData icon;

  const _GoalOption({
    required this.id,
    required this.label,
    required this.icon,
  });
}
