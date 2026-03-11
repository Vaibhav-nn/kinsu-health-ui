import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../providers/theme_provider.dart';
import 'notifications_screen.dart';
import 'profile_screen.dart';
import '../track/medications/medications_list_screen.dart';
import '../track/symptoms/symptoms_list_screen.dart';
import '../track/vitals/vitals_trends_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _heroController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  final List<_HomeFeature> _features = const [
    _HomeFeature(
      title: 'Vitals',
      subtitle: 'Log and track key health signals',
      icon: Icons.favorite_outline,
      color: Color(0xFFE53935),
      page: VitalsTrendsScreen(),
    ),
    _HomeFeature(
      title: 'Symptoms',
      subtitle: 'Track symptoms over time',
      icon: Icons.healing_outlined,
      color: Color(0xFFFF9800),
      page: SymptomsListScreen(),
    ),
    _HomeFeature(
      title: 'Medications',
      subtitle: 'Manage medicine schedules',
      icon: Icons.medication_outlined,
      color: Color(0xFF2196F3),
      page: MedicationsListScreen(),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _heroController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = context.watch<AppThemeProvider>().themeMode;
    final colorScheme = Theme.of(context).colorScheme;
    final filteredFeatures = _features.where((feature) {
      if (_query.trim().isEmpty) return true;
      final q = _query.toLowerCase();
      return feature.title.toLowerCase().contains(q) ||
          feature.subtitle.toLowerCase().contains(q);
    }).toList();

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'Home',
                    style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.notifications_outlined),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationsScreen(),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                InkWell(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const ProfileScreen(),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(20),
                  child: CircleAvatar(
                    radius: 18,
                    backgroundColor: colorScheme.primary.withOpacity(0.1),
                    child: Icon(
                      Icons.person_outline,
                      size: 20,
                      color: colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _searchController,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: 'Search Vitals, Symptoms, Medications',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _query = '');
                        },
                      ),
              ),
            ),
            const SizedBox(height: 14),
            _ThemeModeSelector(currentMode: themeMode),
            const SizedBox(height: 16),
            _AnimatedHeroCard(controller: _heroController),
            const SizedBox(height: 20),
            Text(
              'Your Health Tools',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
            const SizedBox(height: 10),
            if (filteredFeatures.isEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: KinsuTheme.cardDecoration,
                child: const Text(
                  'No matches found. Try another keyword.',
                  style: TextStyle(color: KinsuTheme.textSecondary),
                ),
              ),
            for (final feature in filteredFeatures)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _FeatureCard(feature: feature),
              ),
          ],
        ),
      ),
    );
  }
}

class _ThemeModeSelector extends StatelessWidget {
  final ThemeMode currentMode;

  const _ThemeModeSelector({required this.currentMode});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: KinsuTheme.cardDecoration,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          const Padding(
            padding: EdgeInsets.only(right: 4),
            child: Icon(Icons.brightness_6_outlined, size: 18),
          ),
          _modeChip(context, ThemeMode.system, 'System'),
          _modeChip(context, ThemeMode.light, 'Light'),
          _modeChip(context, ThemeMode.dark, 'Dark'),
        ],
      ),
    );
  }

  Widget _modeChip(BuildContext context, ThemeMode mode, String label) {
    return ChoiceChip(
      label: Text(label),
      selected: currentMode == mode,
      onSelected: (_) => context.read<AppThemeProvider>().setThemeMode(mode),
    );
  }
}

class _AnimatedHeroCard extends StatelessWidget {
  final AnimationController controller;

  const _AnimatedHeroCard({required this.controller});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value * 2 * math.pi;
        return Container(
          height: 205,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: [
                colorScheme.primary,
                KinsuTheme.primaryDark,
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 16 + (math.sin(t) * 10),
                top: 18 + (math.cos(t) * 8),
                child: _bubble(68, Colors.white.withOpacity(0.14)),
              ),
              Positioned(
                left: 30 + (math.cos(t * 1.1) * 12),
                bottom: 30 + (math.sin(t * 1.2) * 7),
                child: _bubble(44, Colors.white.withOpacity(0.12)),
              ),
              Positioned(
                right: 90 + (math.sin(t * 0.8) * 9),
                bottom: 22 + (math.cos(t * 1.3) * 8),
                child: _bubble(26, Colors.white.withOpacity(0.22)),
              ),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Daily Health Snapshot',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Tap a section below to view details and trends.',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const Spacer(),
                    Row(
                      children: const [
                        Expanded(
                          child: _MiniStat(label: 'Vitals', value: '6'),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _MiniStat(label: 'Symptoms', value: '4'),
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: _MiniStat(label: 'Meds', value: '3'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _bubble(double size, Color color) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;

  const _MiniStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureCard extends StatelessWidget {
  final _HomeFeature feature;

  const _FeatureCard({required this.feature});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => feature.page),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: KinsuTheme.cardDecoration,
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: feature.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(feature.icon, color: feature.color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feature.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: KinsuTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      feature.subtitle,
                      style: const TextStyle(
                        color: KinsuTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: KinsuTheme.textSecondary),
            ],
          ),
        ),
      ),
    );
  }
}

class _HomeFeature {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Widget page;

  const _HomeFeature({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.page,
  });
}
