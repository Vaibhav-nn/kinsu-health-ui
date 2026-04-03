import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/user_profile.dart';
import '../../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  UserProfile? _profile;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProfile();
    });
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final profile = await context.read<AuthService>().getProfile();
      if (!mounted) {
        return;
      }
      setState(() {
        _profile = profile;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = error.toString();
        _isLoading = false;
      });
    }
  }

  String _initials() {
    final name = _profile?.displayName?.trim();
    if (name == null || name.isEmpty) {
      return 'KH';
    }
    final parts =
        name.split(RegExp(r'\s+')).where((part) => part.isNotEmpty).toList();
    if (parts.length == 1) {
      return parts.first
          .substring(0, parts.first.length >= 2 ? 2 : 1)
          .toUpperCase();
    }
    return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
  }

  String _displayName() {
    final name = _profile?.displayName?.trim();
    if (name != null && name.isNotEmpty) {
      return name;
    }
    return 'Kinsu User';
  }

  String _formatDate(DateTime? value) {
    if (value == null) {
      return 'Not available';
    }
    return '${value.day.toString().padLeft(2, '0')}/'
        '${value.month.toString().padLeft(2, '0')}/${value.year}';
  }

  List<_InfoChipData> _summaryChips() {
    final chips = <_InfoChipData>[];
    if (_profile?.age != null) {
      chips.add(_InfoChipData(label: '${_profile!.age}y'));
    }
    if ((_profile?.bloodGroup ?? '').isNotEmpty) {
      chips.add(_InfoChipData(label: _profile!.bloodGroup!));
    }
    if ((_profile?.gender ?? '').isNotEmpty) {
      chips.add(_InfoChipData(label: _profile!.gender!));
    }
    return chips;
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: RefreshIndicator(
        onRefresh: _loadProfile,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ProfileErrorCard(message: _error!, onRetry: _loadProfile)
            else ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                      color: KinsuTheme.divider.withValues(alpha: 0.5)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x12000000),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundColor:
                          KinsuTheme.primary.withValues(alpha: 0.12),
                      child: Text(
                        _initials(),
                        style: const TextStyle(
                          color: KinsuTheme.primary,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _displayName(),
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: KinsuTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            profile?.email ?? 'No email available',
                            style: const TextStyle(
                              fontSize: 14,
                              color: KinsuTheme.textSecondary,
                            ),
                          ),
                          if ((profile?.authProvider ?? '').isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Text(
                              'Signed in with ${profile!.authProvider}',
                              style: const TextStyle(
                                fontSize: 12,
                                color: KinsuTheme.textSecondary,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              if (_summaryChips().isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _summaryChips()
                      .map((chip) => _InfoChip(label: chip.label))
                      .toList(),
                ),
              if (_summaryChips().isNotEmpty) const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _ProfileMetricCard(
                      label: 'Height',
                      value: profile?.heightCm == null
                          ? '--'
                          : '${profile!.heightCm!.toStringAsFixed(0)} cm',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ProfileMetricCard(
                      label: 'Weight',
                      value: profile?.weightKg == null
                          ? '--'
                          : '${profile!.weightKg!.toStringAsFixed(0)} kg',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _SectionCard(
                title: 'Health Goals',
                child: (profile?.healthGoals ?? const []).isEmpty
                    ? const Text(
                        'No health goals selected yet.',
                        style: TextStyle(color: KinsuTheme.textSecondary),
                      )
                    : Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: profile!.healthGoals
                            .map((goal) => _InfoChip(label: goal))
                            .toList(),
                      ),
              ),
              const SizedBox(height: 14),
              _SectionCard(
                title: 'Account Details',
                child: Column(
                  children: [
                    _ProfileRow(
                      label: 'Date of Birth',
                      value: _formatDate(profile?.dateOfBirth),
                    ),
                    _ProfileRow(
                      label: 'Profession',
                      value: (profile?.profession ?? '').isEmpty
                          ? 'Not provided'
                          : profile!.profession!,
                    ),
                    _ProfileRow(
                      label: 'Consent',
                      value: profile?.consentAcceptedAt == null
                          ? 'Pending'
                          : 'Accepted on ${_formatDate(profile!.consentAcceptedAt)}',
                    ),
                    _ProfileRow(
                      label: 'Onboarding',
                      value: profile?.onboardingCompletedAt == null
                          ? 'Incomplete'
                          : 'Completed on ${_formatDate(profile!.onboardingCompletedAt)}',
                    ),
                    _ProfileRow(
                      label: 'Last Login',
                      value: _formatDate(profile?.lastLoginAt),
                      showDivider: false,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ProfileMetricCard extends StatelessWidget {
  final String label;
  final String value;

  const _ProfileMetricCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: KinsuTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style:
                const TextStyle(fontSize: 13, color: KinsuTheme.textSecondary),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KinsuTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ProfileRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const _ProfileRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(
                bottom: BorderSide(
                    color: KinsuTheme.divider.withValues(alpha: 0.5)),
              )
            : null,
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                  fontSize: 14, color: KinsuTheme.textSecondary),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final String label;

  const _InfoChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: KinsuTheme.primaryLight.withValues(alpha: 0.25),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: KinsuTheme.primary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _InfoChipData {
  final String label;

  const _InfoChipData({required this.label});
}

class _ProfileErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ProfileErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: KinsuTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Unable to load profile',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(color: KinsuTheme.textSecondary),
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
