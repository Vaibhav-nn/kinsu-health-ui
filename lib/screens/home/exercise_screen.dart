import 'package:flutter/material.dart';
import 'package:kinsu_health/widgets/ios_back_button.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../models/activity_models.dart';
import '../../services/exercise_service.dart';

class ExerciseScreen extends StatefulWidget {
  const ExerciseScreen({super.key});

  @override
  State<ExerciseScreen> createState() => _ExerciseScreenState();
}

class _ExerciseScreenState extends State<ExerciseScreen> {
  int _tabIndex = 0;
  bool _isLoading = true;
  String? _error;
  List<ActivityCatalogSection> _catalog = const [];
  ActivitySummaryData? _summary;
  ActivityHistoryData? _history;
  ActivityRecommendationsData? _recommendations;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final service = context.read<ExerciseService>();
      final results = await Future.wait<dynamic>([
        service.fetchCatalog(),
        service.fetchSummary(),
        service.fetchHistory(),
        service.fetchRecommendations(),
      ]);
      if (!mounted) {
        return;
      }
      setState(() {
        _catalog = results[0] as List<ActivityCatalogSection>;
        _summary = results[1] as ActivitySummaryData;
        _history = results[2] as ActivityHistoryData;
        _recommendations = results[3] as ActivityRecommendationsData;
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

  Future<void> _openCategoryChooser() async {
    if (_catalog.isEmpty) {
      await _loadData();
      if (!mounted || _catalog.isEmpty) {
        return;
      }
    }

    final section = await showModalBottomSheet<ActivityCatalogSection>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _CategoryChooserSheet(sections: _catalog),
    );

    if (!mounted || section == null) {
      return;
    }

    final item = await showModalBottomSheet<ActivityCatalogItem>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActivityChooserSheet(section: section),
    );

    if (!mounted || item == null) {
      return;
    }

    await _openLogForm(item);
  }

  Future<void> _openLogForm(ActivityCatalogItem item) async {
    final messenger = ScaffoldMessenger.of(context);
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActivityLogSheet(item: item),
    );

    if (saved == true && mounted) {
      await _loadData();
      messenger.showSnackBar(
        SnackBar(content: Text('${item.activityName} logged successfully.')),
      );
    }
  }

  Future<void> _startRecommendation(ActivityRecommendationItemData item) async {
    ActivityCatalogItem? matched;
    for (final section in _catalog) {
      for (final catalogItem in section.items) {
        if (catalogItem.activityName.toLowerCase() ==
            item.title.toLowerCase()) {
          matched = catalogItem;
          break;
        }
      }
      if (matched != null) {
        break;
      }
    }

    if (matched == null) {
      final category = _guessCategoryFromTitle(item.title);
      matched = ActivityCatalogItem(
        category: category,
        activityName: item.title,
        estimatedCalories: item.durationMinutes * 5,
        durationMinutes: item.durationMinutes,
        fields: const ['duration_minutes'],
      );
    }

    await _openLogForm(matched);
  }

  String _guessCategoryFromTitle(String title) {
    final normalized = title.toLowerCase();
    if (normalized.contains('walk') || normalized.contains('run')) {
      return 'walk_run';
    }
    if (normalized.contains('yoga') || normalized.contains('vilom')) {
      return 'yoga';
    }
    if (normalized.contains('cycle')) {
      return 'cycling';
    }
    return 'other';
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final history = _history;
    final recommendations = _recommendations;

    return Scaffold(
      appBar: AppBar(
        leading: const IosBackButton(),
        automaticallyImplyLeading: false,
        title: const Text('Exercise & Activity'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 48),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error != null)
              _ErrorCard(message: _error!, onRetry: _loadData)
            else ...[
              Row(
                children: [
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.local_fire_department_outlined,
                      value: '${summary?.calories ?? 0}',
                      unit: 'kcal',
                      label: 'Calories',
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.timer_outlined,
                      value: '${summary?.durationMinutes ?? 0}',
                      unit: 'min',
                      label: 'Duration',
                      color: KinsuTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _MetricCard(
                      icon: Icons.sports_score_outlined,
                      value: '${summary?.activitiesDone ?? 0}',
                      unit: 'done',
                      label: 'Activities',
                      color: const Color(0xFF2563EB),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              _SegmentedTabs(
                labels: const ['Log', 'History', 'Recommendations'],
                selectedIndex: _tabIndex,
                onChanged: (index) {
                  setState(() {
                    _tabIndex = index;
                  });
                },
              ),
              const SizedBox(height: 18),
              if (_tabIndex == 0) ...[
                ElevatedButton.icon(
                  onPressed: _openCategoryChooser,
                  icon: const Icon(Icons.add, size: 28),
                  label: const Text('Log an Activity'),
                ),
                const SizedBox(height: 18),
                const Text(
                  "Today's Activity",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                if ((summary?.today ?? const []).isEmpty)
                  const _EmptyStateCard(
                    title: 'No activity logged yet',
                    message:
                        'Start by logging a workout, walk, or yoga session.',
                  )
                else
                  ...(summary?.today ?? const []).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _TodayActivityCard(item: item),
                    ),
                  ),
              ] else if (_tabIndex == 1) ...[
                _HistoryCard(history: history),
                const SizedBox(height: 16),
                _ConsistencyCard(history: history),
              ] else ...[
                if ((recommendations?.summary ?? '').isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFFBEB),
                      borderRadius: BorderRadius.circular(22),
                      border: Border.all(color: const Color(0xFFFDE68A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Personalized for You',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFB45309),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          recommendations!.summary,
                          style: const TextStyle(
                            fontSize: 14,
                            height: 1.45,
                            color: Color(0xFFB45309),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 16),
                if ((recommendations?.items ?? const []).isEmpty)
                  const _EmptyStateCard(
                    title: 'No recommendations yet',
                    message:
                        'Recommendations will appear after we have enough activity and health context.',
                  )
                else
                  ...(recommendations?.items ?? const []).map(
                    (item) => Padding(
                      padding: const EdgeInsets.only(bottom: 14),
                      child: _RecommendationCard(
                        item: item,
                        onStart: () => _startRecommendation(item),
                      ),
                    ),
                  ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String unit;
  final String label;
  final Color color;

  const _MetricCard({
    required this.icon,
    required this.value,
    required this.unit,
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KinsuTheme.divider.withValues(alpha: 0.6)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: KinsuTheme.textPrimary,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 12,
              color: KinsuTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: KinsuTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onChanged;

  const _SegmentedTabs({
    required this.labels,
    required this.selectedIndex,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KinsuTheme.divider.withValues(alpha: 0.5)),
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
          for (var index = 0; index < labels.length; index++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: selectedIndex == index
                        ? KinsuTheme.primary
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    labels[index],
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: selectedIndex == index
                          ? Colors.white
                          : const Color(0xFF94A3B8),
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

class _TodayActivityCard extends StatelessWidget {
  final ActivityLogItem item;

  const _TodayActivityCard({required this.item});

  String _subtitle() {
    final parts = <String>['${item.durationMinutes} min'];
    if (item.distanceKm != null) {
      parts.add('${item.distanceKm!.toStringAsFixed(1)} km');
    }
    return parts.join(' • ');
  }

  @override
  Widget build(BuildContext context) {
    final meta = _categoryMeta(item.category);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KinsuTheme.divider.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: meta.tint,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(meta.icon, color: meta.color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.activityName,
                  style: const TextStyle(
                      fontSize: 17, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 6),
                Text(
                  _subtitle(),
                  style: const TextStyle(
                    fontSize: 13,
                    color: KinsuTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${item.caloriesBurned}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFDC2626),
                ),
              ),
              const Text(
                'kcal',
                style: TextStyle(
                  fontSize: 12,
                  color: KinsuTheme.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final ActivityHistoryData? history;

  const _HistoryCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final bars = history?.weeklyCalories ?? const <ActivityHistoryBarData>[];
    final maxCalories = bars.fold<int>(0,
        (current, item) => item.calories > current ? item.calories : current);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: KinsuTheme.divider.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Weekly Calories Burned',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 220,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: bars
                  .map(
                    (item) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 240),
                              height: maxCalories == 0
                                  ? 8
                                  : ((item.calories / maxCalories) * 150)
                                      .clamp(8, 150)
                                      .toDouble(),
                              decoration: BoxDecoration(
                                color: const Color(0xFFDC2626),
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              item.weekday,
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  )
                  .toList(),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Total this week: ${history?.totalWeeklyCalories ?? 0} kcal',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: KinsuTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConsistencyCard extends StatelessWidget {
  final ActivityHistoryData? history;

  const _ConsistencyCard({required this.history});

  @override
  Widget build(BuildContext context) {
    final activeDays = history?.activeDays ?? 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: KinsuTheme.divider.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Streak & Consistency',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(7, (index) {
              final isActive = index < activeDays;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    height: 52,
                    decoration: BoxDecoration(
                      color: isActive
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFEFF2F7),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      isActive ? Icons.check : null,
                      color: Colors.white,
                    ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Text(
            '$activeDays of 7 days active this week',
            style: const TextStyle(
              fontSize: 16,
              color: KinsuTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

class _RecommendationCard extends StatelessWidget {
  final ActivityRecommendationItemData item;
  final VoidCallback onStart;

  const _RecommendationCard({
    required this.item,
    required this.onStart,
  });

  Color _riskColor() {
    switch (item.riskLevel.toLowerCase()) {
      case 'very low':
        return const Color(0xFF0EA5A4);
      case 'low':
        return KinsuTheme.primary;
      case 'medium':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFE11D48);
    }
  }

  @override
  Widget build(BuildContext context) {
    final riskColor = _riskColor();
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: KinsuTheme.divider.withValues(alpha: 0.5)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x10000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.w800),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: riskColor.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  item.riskLevel,
                  style: TextStyle(
                    color: riskColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.subtitle,
            style:
                const TextStyle(fontSize: 14, color: KinsuTheme.textSecondary),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.schedule_outlined,
                  size: 18, color: Color(0xFF94A3B8)),
              const SizedBox(width: 6),
              Text(
                '${item.durationMinutes} min',
                style: const TextStyle(
                    fontSize: 14, color: KinsuTheme.textSecondary),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    item.recommendationReason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 14, color: KinsuTheme.textSecondary),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: onStart,
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(92, 46),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: const Text('Start'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final Future<void> Function() onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: KinsuTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Unable to load exercise data',
            style: TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(color: KinsuTheme.textSecondary)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}

class _EmptyStateCard extends StatelessWidget {
  final String title;
  final String message;

  const _EmptyStateCard({required this.title, required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: KinsuTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(message,
              style: const TextStyle(color: KinsuTheme.textSecondary)),
        ],
      ),
    );
  }
}

class _CategoryChooserSheet extends StatelessWidget {
  final List<ActivityCatalogSection> sections;

  const _CategoryChooserSheet({required this.sections});

  @override
  Widget build(BuildContext context) {
    return _BottomSheetShell(
      title: 'Choose Exercise',
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: sections.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.15,
        ),
        itemBuilder: (context, index) {
          final section = sections[index];
          final meta = _categoryMeta(section.category);
          return InkWell(
            onTap: () => Navigator.of(context).pop(section),
            borderRadius: BorderRadius.circular(24),
            child: Container(
              decoration: BoxDecoration(
                color: meta.tint,
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(meta.icon, color: meta.color, size: 34),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      section.title,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: KinsuTheme.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActivityChooserSheet extends StatelessWidget {
  final ActivityCatalogSection section;

  const _ActivityChooserSheet({required this.section});

  @override
  Widget build(BuildContext context) {
    return _BottomSheetShell(
      title: section.title,
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: section.items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = section.items[index];
          return InkWell(
            onTap: () => Navigator.of(context).pop(item),
            borderRadius: BorderRadius.circular(22),
            child: Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: KinsuTheme.divider.withValues(alpha: 0.4)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.activityName,
                          style: const TextStyle(
                              fontSize: 16, fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '~${item.estimatedCalories} kcal / ${item.durationMinutes} min',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right, color: Color(0xFFCBD5E1)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ActivityLogSheet extends StatefulWidget {
  final ActivityCatalogItem item;

  const _ActivityLogSheet({required this.item});

  @override
  State<_ActivityLogSheet> createState() => _ActivityLogSheetState();
}

class _ActivityLogSheetState extends State<_ActivityLogSheet> {
  late final TextEditingController _durationController;
  final Map<String, TextEditingController> _controllers = {};
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _durationController =
        TextEditingController(text: widget.item.durationMinutes.toString());
    for (final field in widget.item.fields) {
      if (field == 'duration_minutes') {
        continue;
      }
      _controllers[field] = TextEditingController();
    }
  }

  @override
  void dispose() {
    _durationController.dispose();
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final duration = int.tryParse(_durationController.text.trim());
    if (duration == null || duration <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid duration in minutes.')),
      );
      return;
    }

    final details = <String, dynamic>{};
    double? distanceKm;

    for (final entry in _controllers.entries) {
      final text = entry.value.text.trim();
      if (text.isEmpty) {
        continue;
      }
      if (entry.key == 'distance_km') {
        distanceKm = double.tryParse(text);
        if (distanceKm == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Enter a valid distance value.')),
          );
          return;
        }
      } else {
        final numeric = num.tryParse(text);
        details[entry.key] = numeric ?? text;
      }
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await context.read<ExerciseService>().logActivity(
            category: widget.item.category,
            activityName: widget.item.activityName,
            durationMinutes: duration,
            distanceKm: distanceKm,
            details: details.isEmpty ? null : details,
          );
      if (!mounted) {
        return;
      }
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save activity: $error')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return _BottomSheetShell(
      title: widget.item.activityName,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _FieldLabel(label: 'Duration (minutes)'),
          TextField(
            controller: _durationController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(hintText: 'e.g. 30'),
          ),
          const SizedBox(height: 18),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _controllers.entries
                .map(
                  (entry) => SizedBox(
                    width: _fieldWidth(context, _controllers.length),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FieldLabel(label: _fieldTitle(entry.key)),
                        TextField(
                          controller: entry.value,
                          keyboardType: TextInputType.number,
                          decoration:
                              InputDecoration(hintText: _fieldHint(entry.key)),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            child: Text(_isSaving ? 'Saving...' : 'Save Activity'),
          ),
        ],
      ),
    );
  }

  double _fieldWidth(BuildContext context, int count) {
    if (count <= 1) {
      return MediaQuery.of(context).size.width - 80;
    }
    return (MediaQuery.of(context).size.width - 92) / 2;
  }

  String _fieldTitle(String key) {
    switch (key) {
      case 'distance_km':
        return 'Distance (km)';
      case 'incline':
        return 'Incline (%)';
      case 'speed':
        return 'Speed (km/h)';
      case 'reps':
        return 'Reps';
      case 'weight_kg':
        return 'Weight (kg)';
      default:
        return key.replaceAll('_', ' ');
    }
  }

  String _fieldHint(String key) {
    switch (key) {
      case 'distance_km':
        return 'e.g. 2.5';
      case 'incline':
        return 'e.g. 5';
      case 'speed':
        return 'e.g. 6';
      case 'reps':
        return 'e.g. 20';
      case 'weight_kg':
        return 'e.g. 40';
      default:
        return 'Enter value';
    }
  }
}

class _BottomSheetShell extends StatelessWidget {
  final String title;
  final Widget child;

  const _BottomSheetShell({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              18, 18, 18, 18 + MediaQuery.of(context).viewInsets.bottom),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w800),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              child,
            ],
          ),
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  final String label;

  const _FieldLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: Color(0xFF64748B),
        ),
      ),
    );
  }
}

_CategoryMeta _categoryMeta(String category) {
  switch (category) {
    case 'cardio':
      return const _CategoryMeta(
          Icons.favorite_outline, Color(0xFFE11D48), Color(0xFFFFF1F2));
    case 'strength':
      return const _CategoryMeta(
          Icons.fitness_center_outlined, Color(0xFF3B82F6), Color(0xFFEFF6FF));
    case 'yoga':
      return const _CategoryMeta(
          Icons.air_outlined, Color(0xFF8B5CF6), Color(0xFFF5F3FF));
    case 'walk_run':
      return const _CategoryMeta(
          Icons.directions_walk_outlined, Color(0xFF10B981), Color(0xFFECFDF5));
    case 'cycling':
      return const _CategoryMeta(
          Icons.pedal_bike_outlined, Color(0xFFF59E0B), Color(0xFFFFFBEB));
    default:
      return const _CategoryMeta(
          Icons.monitor_heart_outlined, Color(0xFF64748B), Color(0xFFF8FAFC));
  }
}

class _CategoryMeta {
  final IconData icon;
  final Color color;
  final Color tint;

  const _CategoryMeta(this.icon, this.color, this.tint);
}
