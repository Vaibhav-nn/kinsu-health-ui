import 'dart:async';
import 'dart:math' as math;

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/family_member_profile.dart';
import '../../models/home_models.dart';
import '../../providers/family_provider.dart';
import '../../providers/medications_provider.dart';
import '../../providers/vitals_provider.dart';
import '../../services/home_service.dart';
import '../ai/ai_screen.dart';
import '../track/medications/medications_list_screen.dart';
import '../track/symptoms/symptoms_list_screen.dart';
import '../track/vitals/log_vital_screen.dart';
import '../track/vitals/vitals_trends_screen.dart';
import '../upload_record_screen.dart';
import 'profile_screen.dart';
import 'wellness_tools_screens.dart' hide ExerciseScreen;
import 'exercise_screen.dart';
import '../vault_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  late final AnimationController _heroController;
  late final AnimationController _introController;
  Timer? _heroSlideTimer;
  final TextEditingController _searchController = TextEditingController();

  HomeOverviewData? _overview;
  HomeDashboardData? _dashboard;
  bool _isHomeLoading = true;
  String? _homeError;
  bool _showAiAlert = true;
  int _heroSlideIndex = 0;

  static const List<_HeroSlideData> _heroSlides = [
    _HeroSlideData(
      emoji: '🌅',
      headline: 'Great morning!',
      subline: 'Your health journey continues today.',
      tip: 'Tip: Keep your medication streak active today.',
      colors: [KinsuTheme.primary, KinsuTheme.primaryDark],
    ),
    _HeroSlideData(
      emoji: '💪',
      headline: 'Consistency is working',
      subline: 'Your daily tracking habits are improving trends.',
      tip: 'Tip: Log vitals after breakfast for stable comparisons.',
      colors: [Color(0xFF3B82F6), Color(0xFF1D4ED8)],
    ),
    _HeroSlideData(
      emoji: '🎯',
      headline: 'Stay on target',
      subline: 'You are building better long-term health signals.',
      tip: 'Tip: Review your trends weekly with AI summary.',
      colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)],
    ),
  ];

  static const List<String> _recentSearches = [
    'Blood sugar reports',
    'Dr. Kapoor prescription',
    'Vitamin D levels',
  ];

  @override
  void initState() {
    super.initState();
    _heroController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _heroSlideTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) {
        return;
      }
      setState(() {
        _heroSlideIndex = (_heroSlideIndex + 1) % _heroSlides.length;
      });
    });

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final familyProvider = context.read<FamilyProvider>();
      final medicationsProvider = context.read<MedicationsProvider>();
      final vitalsProvider = context.read<VitalsProvider>();
      await familyProvider.loadFamilyData();
      await medicationsProvider.loadMedications(isActive: true);
      await vitalsProvider.loadVitals();
      if (!mounted) {
        return;
      }
      await _loadHomeData();
    });
  }

  @override
  void dispose() {
    _heroSlideTimer?.cancel();
    _heroController.dispose();
    _introController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  String _friendlyError(Object error, {required String fallback}) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;
      final detail =
          data is Map<String, dynamic> ? data['detail']?.toString() ?? '' : '';

      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Cannot reach backend at ${ApiConstants.baseUrl}. Please ensure API server is running and reachable.';
      }

      if (statusCode == 404 && detail.contains('User not found')) {
        return 'Your account is still being prepared. Please try again in a moment.';
      }

      if (statusCode != null) {
        return detail.isEmpty ? '$fallback (status $statusCode).' : detail;
      }
    }
    return fallback;
  }

  Future<void> _loadHomeData({bool showSpinner = true}) async {
    if (showSpinner) {
      setState(() {
        _isHomeLoading = true;
        _homeError = null;
      });
    }

    try {
      final homeService = context.read<HomeService>();
      final overview = await homeService.fetchOverview();
      final dashboard = await homeService.fetchDashboard();
      if (!mounted) {
        return;
      }
      setState(() {
        _overview = overview;
        _dashboard = dashboard;
        _homeError = null;
        _isHomeLoading = false;
        _showAiAlert = dashboard.aiAlert != null;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _homeError =
            _friendlyError(error, fallback: 'Unable to load home dashboard.');
        _isHomeLoading = false;
      });
    }
  }

  Future<void> _refreshAll() async {
    final familyProvider = context.read<FamilyProvider>();
    final medicationsProvider = context.read<MedicationsProvider>();
    final vitalsProvider = context.read<VitalsProvider>();
    await familyProvider.loadFamilyData();
    await medicationsProvider.loadMedications(isActive: true);
    await vitalsProvider.loadVitals();
    if (!mounted) {
      return;
    }
    await _loadHomeData(showSpinner: false);
  }

  int _notificationUnreadCount() {
    if (_overview != null) {
      return _overview!.notificationUnreadCount;
    }
    return _dashboard?.notifications.where((item) => !item.isRead).length ?? 0;
  }

  List<_AppointmentData> _appointmentCards() {
    return (_dashboard?.appointments ?? const <HomeAppointmentCardData>[])
        .map(
          (item) => _AppointmentData(
            doctor: item.doctorName,
            specialty: item.specialty ?? 'Appointment',
            at: item.appointmentAt,
            place: item.location ?? 'Location pending',
            notes: item.notes,
          ),
        )
        .toList();
  }

  Color _recordColor(String type) {
    switch (type) {
      case 'lab_report':
        return KinsuTheme.primary;
      case 'prescription':
        return const Color(0xFF3B82F6);
      case 'imaging':
        return const Color(0xFF8B5CF6);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  IconData _recordIcon(String type) {
    switch (type) {
      case 'lab_report':
        return Icons.science_outlined;
      case 'prescription':
        return Icons.medical_services_outlined;
      case 'imaging':
        return Icons.image_outlined;
      default:
        return Icons.description_outlined;
    }
  }

  String _recordTypeLabel(String type) {
    switch (type) {
      case 'lab_report':
        return 'Lab Report';
      case 'prescription':
        return 'Prescription';
      case 'imaging':
        return 'Imaging';
      case 'discharge_summary':
        return 'Discharge Summary';
      default:
        return type.replaceAll('_', ' ').trim().isEmpty
            ? 'Record'
            : type
                .replaceAll('_', ' ')
                .split(' ')
                .map((part) => part.isEmpty
                    ? part
                    : '${part[0].toUpperCase()}${part.substring(1)}')
                .join(' ');
    }
  }

  List<_RecentRecordData> _recentRecordCards() {
    return (_dashboard?.recentRecords ?? const <HomeRecentRecordData>[])
        .map(
          (item) => _RecentRecordData(
            type: _recordTypeLabel(item.recordType),
            title: item.title,
            provider: item.subtitle,
            dateLabel: MaterialLocalizations.of(context)
                .formatMediumDate(item.recordDate),
            icon: _recordIcon(item.recordType),
            color: _recordColor(item.recordType),
          ),
        )
        .toList();
  }

  List<_NotificationItemData> _notificationItems() {
    return (_dashboard?.notifications ?? const <HomeNotificationItem>[])
        .map(
          (item) => _NotificationItemData(
            title: item.title,
            description: item.body,
            time: _relativeLabel(item.createdAt),
            unread: !item.isRead,
            alert: item.notificationType == 'ai' ||
                item.notificationType == 'insight',
          ),
        )
        .toList();
  }

  String _relativeLabel(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours} hr ago';
    }
    if (diff.inDays == 1) {
      return 'Yesterday';
    }
    return '${diff.inDays} days ago';
  }

  Future<void> _markMedicationTaken(HomeMedicationStatusItem item) async {
    final success = await context.read<MedicationsProvider>().logDose(
          item.id,
          status: 'taken',
          takenAt: DateTime.now(),
        );
    if (!mounted) {
      return;
    }
    if (success) {
      await _loadHomeData(showSpinner: false);
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name} marked as taken.')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          context.read<MedicationsProvider>().error ??
              'Unable to update medication.',
        ),
      ),
    );
  }

  Future<void> _showAppointmentOverview(_AppointmentData appointment) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  appointment.doctor,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  appointment.specialty,
                  style: const TextStyle(
                    fontSize: 14,
                    color: KinsuTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 14),
                _AppointmentDetailRow(
                  label: 'When',
                  value: _formatAppointmentDateTime(appointment.at),
                ),
                _AppointmentDetailRow(label: 'Where', value: appointment.place),
                if (appointment.notes != null &&
                    appointment.notes!.trim().isNotEmpty)
                  _AppointmentDetailRow(
                      label: 'Notes', value: appointment.notes!),
              ],
            ),
          ),
        );
      },
    );
  }

  String _formatAppointmentDateTime(DateTime dateTime) {
    final localizations = MaterialLocalizations.of(context);
    final dateLabel = localizations.formatMediumDate(dateTime);
    final timeLabel = localizations.formatTimeOfDay(
      TimeOfDay.fromDateTime(dateTime),
    );
    return '$dateLabel · $timeLabel';
  }

  Future<void> _showHomeVitalOverview({
    required String title,
    required String vitalType,
  }) async {
    final items = context
        .read<VitalsProvider>()
        .vitals
        .where((v) => v.vitalType == vitalType)
        .toList()
      ..sort((a, b) => b.recordedAt.compareTo(a.recordedAt));

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                if (items.isEmpty)
                  const Text(
                    'No readings available yet for this trend.',
                    style: TextStyle(color: KinsuTheme.textSecondary),
                  )
                else
                  ...items.take(6).map(
                        (entry) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  '${entry.value}${entry.valueSecondary != null ? '/${entry.valueSecondary!.toStringAsFixed(0)}' : ''} ${entry.unit}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              Text(
                                '${entry.recordedAt.day}/${entry.recordedAt.month} ${entry.recordedAt.hour.toString().padLeft(2, '0')}:${entry.recordedAt.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  color: KinsuTheme.textSecondary,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
        );
      },
    );
  }

  AccountProfileOption? _activeProfileOption(FamilyProvider familyProvider) {
    final profiles = familyProvider.profiles;
    if (profiles.isEmpty) {
      return null;
    }

    final activeId = familyProvider.activeFamilyProfileId;
    for (final option in profiles) {
      if (option.profileId == activeId) {
        return option;
      }
    }

    for (final option in profiles) {
      if (option.isSelf) {
        return option;
      }
    }
    return profiles.first;
  }

  String _initialsFromName(String name) {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((segment) => segment.isNotEmpty)
        .toList();
    if (parts.isEmpty) {
      return 'U';
    }
    if (parts.length == 1) {
      return parts.first[0].toUpperCase();
    }
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  Future<void> _switchProfile(int? profileId) async {
    final familyProvider = context.read<FamilyProvider>();
    final medicationsProvider = context.read<MedicationsProvider>();
    final vitalsProvider = context.read<VitalsProvider>();
    familyProvider.setActiveProfileId(profileId);

    await medicationsProvider.loadMedications(isActive: true);
    await vitalsProvider.loadVitals();
    await _loadHomeData(showSpinner: false);

    if (!mounted) {
      return;
    }

    final label =
        profileId == null ? 'Self profile active' : 'Family profile switched';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(label)),
    );
  }

  void _openHomeUtilityScreen(String item) {
    Widget? screen;
    switch (item) {
      case 'Exercise':
        screen = const ExerciseScreen();
        break;
      case 'Diet':
        screen = const DietScreen();
        break;
      case 'Sleep':
        screen = const SleepScreen();
        break;
      case 'Mood':
        screen = const MoodScreen();
        break;
      case 'Community':
        screen = const CommunityScreen();
        break;
      case 'Settings':
        screen = const SettingsScreen();
        break;
    }

    if (screen == null) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => screen!),
    );
  }

  IconData _searchIcon(String section) {
    switch (section) {
      case 'vitals':
        return Icons.monitor_heart_outlined;
      case 'symptoms':
        return Icons.sick_outlined;
      case 'medications':
        return Icons.medication_outlined;
      case 'records':
        return Icons.description_outlined;
      case 'appointments':
        return Icons.event_note_outlined;
      default:
        return Icons.search;
    }
  }

  Future<void> _openSearchResult(HomeSearchResultItemData item) async {
    if (item.section == 'records') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VaultScreen()),
      );
      return;
    }
    if (item.section == 'medications') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MedicationsListScreen()),
      );
      return;
    }
    if (item.section == 'vitals') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VitalsTrendsScreen()),
      );
      return;
    }
    if (item.section == 'symptoms') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SymptomsListScreen()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(item.title)),
    );
  }

  Future<void> _showSearchOverlay() async {
    var localQuery = _searchController.text.trim();
    var localResults = <HomeSearchResultItemData>[];
    var localError = '';
    var localLoading = false;
    final modalController = TextEditingController(text: localQuery);
    var searchTicket = 0;

    Future<void> runSearch(
      String value,
      void Function(void Function()) setModalState,
    ) async {
      final trimmed = value.trim();
      searchTicket += 1;
      final currentTicket = searchTicket;
      if (trimmed.isEmpty) {
        setModalState(() {
          localQuery = '';
          localResults = <HomeSearchResultItemData>[];
          localLoading = false;
          localError = '';
          _searchController.clear();
        });
        return;
      }

      setModalState(() {
        localQuery = trimmed;
        localLoading = true;
        localError = '';
        _searchController.text = trimmed;
      });

      try {
        final results = await context.read<HomeService>().search(trimmed);
        if (!mounted || currentTicket != searchTicket) {
          return;
        }
        setModalState(() {
          localResults = results;
          localLoading = false;
        });
      } catch (error) {
        if (!mounted || currentTicket != searchTicket) {
          return;
        }
        setModalState(() {
          localResults = <HomeSearchResultItemData>[];
          localLoading = false;
          localError = error.toString();
        });
      }
    }

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      builder: (modalContext) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return FractionallySizedBox(
              heightFactor: 0.96,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            autofocus: true,
                            controller: modalController,
                            onChanged: (value) =>
                                runSearch(value, setModalState),
                            decoration: const InputDecoration(
                              hintText: 'Search everything...',
                              prefixIcon: Icon(Icons.search),
                            ),
                          ),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: localQuery.isEmpty
                          ? ListView(
                              children: _recentSearches
                                  .map(
                                    (item) => ListTile(
                                      leading: const Icon(Icons.history),
                                      title: Text(item),
                                      onTap: () async {
                                        modalController.text = item;
                                        modalController.selection =
                                            TextSelection.collapsed(
                                                offset: item.length);
                                        await runSearch(item, setModalState);
                                      },
                                    ),
                                  )
                                  .toList(),
                            )
                          : localLoading
                              ? const Center(child: CircularProgressIndicator())
                              : localError.isNotEmpty
                                  ? Center(
                                      child: Text(
                                        localError,
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: KinsuTheme.textSecondary),
                                      ),
                                    )
                                  : localResults.isEmpty
                                      ? const Center(
                                          child: Text(
                                            'No matches found yet.',
                                            style: TextStyle(
                                                color:
                                                    KinsuTheme.textSecondary),
                                          ),
                                        )
                                      : ListView(
                                          children: localResults
                                              .map(
                                                (item) => ListTile(
                                                  leading: Icon(_searchIcon(
                                                      item.section)),
                                                  title: Text(item.title),
                                                  subtitle: Text(
                                                    '${item.section[0].toUpperCase()}${item.section.substring(1)} · ${item.subtitle}',
                                                  ),
                                                  onTap: () async {
                                                    _searchController.text =
                                                        item.title;
                                                    Navigator.pop(context);
                                                    await _openSearchResult(
                                                        item);
                                                  },
                                                ),
                                              )
                                              .toList(),
                                        ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
    modalController.dispose();
  }

  Future<void> _showNotificationsSheet() async {
    final items = _notificationItems();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Notifications',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 10),
              if (items.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    'No notifications yet.',
                    style: TextStyle(color: KinsuTheme.textSecondary),
                  ),
                )
              else
                ...items.map(
                  (item) => Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: item.alert
                          ? const Color(0xFFFFFBEB)
                          : KinsuTheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: item.alert
                            ? const Color(0xFFFDE68A)
                            : KinsuTheme.divider,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          margin: const EdgeInsets.only(top: 6),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: item.unread
                                ? KinsuTheme.primary
                                : Colors.transparent,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.title,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.description,
                                style: const TextStyle(
                                  color: KinsuTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                item.time,
                                style: const TextStyle(
                                  color: KinsuTheme.textSecondary,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _reveal({
    required int index,
    required Widget child,
  }) {
    final start = (index * 0.08).clamp(0.0, 0.75).toDouble();
    final end = (start + 0.22).clamp(start + 0.05, 1.0).toDouble();
    final animation = CurvedAnimation(
      parent: _introController,
      curve: Interval(start, end, curve: Curves.easeOutCubic),
    );
    return FadeTransition(
      opacity: animation,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
        ).animate(animation),
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final familyProvider = context.watch<FamilyProvider>();
    final activeProfile = familyProvider.activeDashboardCard;
    final activeProfileOption = _activeProfileOption(familyProvider);
    final profileDisplayName = activeProfile?.displayName ??
        _overview?.profile.displayName ??
        activeProfileOption?.displayName ??
        'Kinsu User';
    final avatarInitials = activeProfile?.initials.isNotEmpty == true
        ? activeProfile!.initials
        : _initialsFromName(profileDisplayName);
    final appointments = _appointmentCards();
    final recentRecords = _recentRecordCards();
    final medicationItems =
        _dashboard?.medicationItems ?? const <HomeMedicationStatusItem>[];
    final insights = _dashboard?.insights ?? const <HomeInsightCardData>[];
    final unreadCount = _notificationUnreadCount();
    final medicationsTaken = _dashboard?.medicationsTaken ?? 0;
    final medicationsMissed = _dashboard?.medicationsMissed ?? 0;
    final medicationsLeft = _dashboard?.medicationsLeft ?? 0;
    final medicationTotal =
        medicationsTaken + medicationsMissed + medicationsLeft;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _refreshAll,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 18),
            children: [
              _reveal(
                index: 0,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(18),
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [KinsuTheme.primary, KinsuTheme.primaryDark],
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          PopupMenuButton<int?>(
                            tooltip: 'Switch account',
                            padding: EdgeInsets.zero,
                            onSelected: _switchProfile,
                            itemBuilder: (context) {
                              final profiles = familyProvider.profiles;
                              if (profiles.isEmpty) {
                                return const [
                                  PopupMenuItem<int>(
                                    value: -1,
                                    enabled: false,
                                    child: Text('No linked accounts'),
                                  ),
                                ];
                              }
                              return profiles.map((profile) {
                                final isActive = profile.profileId ==
                                    familyProvider.activeFamilyProfileId;
                                final label = profile.subtitle == null ||
                                        profile.subtitle!.trim().isEmpty
                                    ? profile.displayName
                                    : '${profile.displayName} (${profile.subtitle})';
                                return PopupMenuItem<int?>(
                                  value: profile.profileId,
                                  child: Row(
                                    children: [
                                      Icon(
                                        isActive
                                            ? Icons.check_circle
                                            : Icons.radio_button_unchecked,
                                        size: 16,
                                        color: isActive
                                            ? KinsuTheme.primary
                                            : KinsuTheme.textSecondary,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          label,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList();
                            },
                            child: CircleAvatar(
                              radius: 20,
                              backgroundColor:
                                  Colors.white.withValues(alpha: 0.2),
                              child: Text(
                                avatarInitials,
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Good Morning',
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.75),
                                    fontSize: 12,
                                  ),
                                ),
                                Text(
                                  profileDisplayName,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 17,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Row(
                            children: [
                              Stack(
                                clipBehavior: Clip.none,
                                children: [
                                  _HeaderCircleIconButton(
                                    icon: Icons.notifications_none_rounded,
                                    onTap: _showNotificationsSheet,
                                  ),
                                  if (unreadCount > 0)
                                    Positioned(
                                      right: -2,
                                      top: -2,
                                      child: Container(
                                        width: 22,
                                        height: 22,
                                        alignment: Alignment.center,
                                        decoration: const BoxDecoration(
                                          color: Color(0xFFFF7A45),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Text(
                                          unreadCount > 9
                                              ? '9+'
                                              : '$unreadCount',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.w700,
                                          ),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 8),
                              _HeaderCircleIconButton(
                                icon: Icons.person_outline,
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const ProfileScreen(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _showSearchOverlay,
                        child: Container(
                          height: 48,
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.search,
                                color: Colors.white.withValues(alpha: 0.75),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  _searchController.text.trim().isEmpty
                                      ? (_overview?.searchPlaceholder ??
                                          'Search records, meds, doctors...')
                                      : _searchController.text.trim(),
                                  style: TextStyle(
                                    color: Colors.white.withValues(alpha: 0.86),
                                    fontSize: 15,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (_homeError != null && _dashboard == null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: KinsuTheme.cardDecoration,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Unable to load home dashboard',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _homeError!,
                        style: const TextStyle(color: KinsuTheme.textSecondary),
                      ),
                      const SizedBox(height: 10),
                      OutlinedButton(
                        onPressed: _loadHomeData,
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
              _reveal(
                index: 2,
                child: _AnimatedHeroCard(
                  controller: _heroController,
                  dayNumber: _dashboard?.streakDay ?? 1,
                  slide: _heroSlides[_heroSlideIndex],
                  currentSlide: _heroSlideIndex,
                  totalSlides: _heroSlides.length,
                  onDotTap: (index) {
                    setState(() {
                      _heroSlideIndex = index;
                    });
                  },
                ),
              ),
              if (_showAiAlert && _dashboard?.aiAlert != null) ...[
                const SizedBox(height: 10),
                _reveal(
                  index: 3,
                  child: _ContextAlertCard(
                    title: _dashboard!.aiAlert!.title,
                    message: _dashboard!.aiAlert!.body,
                    onClose: () => setState(() => _showAiAlert = false),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const AiScreen()),
                      );
                    },
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _reveal(
                  index: 4, child: const _SectionTitle(title: 'Quick Actions')),
              const SizedBox(height: 8),
              _reveal(
                index: 5,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: KinsuTheme.cardDecoration,
                  child: Column(
                    children: [
                      GridView.count(
                        crossAxisCount: 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        children: [
                          _ActionTile(
                            icon: Icons.upload_file_outlined,
                            label: 'Upload Record',
                            bg: const Color(0xFFE6F7F6),
                            color: KinsuTheme.primary,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const UploadRecordScreen()),
                              );
                            },
                          ),
                          _ActionTile(
                            icon: Icons.medication_outlined,
                            label: 'Medications',
                            bg: const Color(0xFFEFF6FF),
                            color: const Color(0xFF3B82F6),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) =>
                                        const MedicationsListScreen()),
                              );
                            },
                          ),
                          _ActionTile(
                            icon: Icons.monitor_heart_outlined,
                            label: 'Log Vitals',
                            bg: const Color(0xFFF5F3FF),
                            color: const Color(0xFF8B5CF6),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const LogVitalScreen()),
                              );
                            },
                          ),
                          _ActionTile(
                            icon: Icons.sos_outlined,
                            label: 'SOS',
                            bg: const Color(0xFFFEF2F2),
                            color: const Color(0xFFDC2626),
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                    builder: (_) => const SosScreen()),
                              );
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      GridView.count(
                        crossAxisCount: 6,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        mainAxisSpacing: 8,
                        crossAxisSpacing: 6,
                        childAspectRatio: 0.78,
                        children: [
                          _MiniActionTile(
                            icon: Icons.fitness_center,
                            label: 'Exercise',
                            bg: const Color(0xFFFEF2F2),
                            color: const Color(0xFFDC2626),
                            onTap: () => _openHomeUtilityScreen('Exercise'),
                          ),
                          _MiniActionTile(
                            icon: Icons.restaurant_menu,
                            label: 'Diet',
                            bg: const Color(0xFFFFFBEB),
                            color: const Color(0xFFF59E0B),
                            onTap: () => _openHomeUtilityScreen('Diet'),
                          ),
                          _MiniActionTile(
                            icon: Icons.bedtime_outlined,
                            label: 'Sleep',
                            bg: const Color(0xFFEEF2FF),
                            color: const Color(0xFF4F46E5),
                            onTap: () => _openHomeUtilityScreen('Sleep'),
                          ),
                          _MiniActionTile(
                            icon: Icons.mood_outlined,
                            label: 'Mood',
                            bg: const Color(0xFFFDF2F8),
                            color: const Color(0xFFEC4899),
                            onTap: () => _openHomeUtilityScreen('Mood'),
                          ),
                          _MiniActionTile(
                            icon: Icons.groups_outlined,
                            label: 'Community',
                            bg: const Color(0xFFF0FDF4),
                            color: const Color(0xFF10B981),
                            onTap: () => _openHomeUtilityScreen('Community'),
                          ),
                          _MiniActionTile(
                            icon: Icons.settings_outlined,
                            label: 'Settings',
                            bg: const Color(0xFFF9FAFB),
                            color: const Color(0xFF6B7280),
                            onTap: () => _openHomeUtilityScreen('Settings'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _reveal(
                index: 6,
                child: Row(
                  children: [
                    const Expanded(
                      child: _SectionTitle(title: 'Upcoming Appointments'),
                    ),
                    TextButton(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Appointment creation will be added next.'),
                          ),
                        );
                      },
                      child: const Text('Add +'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _reveal(
                index: 7,
                child: appointments.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(14),
                        decoration: KinsuTheme.cardDecoration,
                        child: const Text(
                          'No upcoming appointments yet.',
                          style: TextStyle(color: KinsuTheme.textSecondary),
                        ),
                      )
                    : SizedBox(
                        height: 130,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: appointments.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final appointment = appointments[index];
                            return _AppointmentCard(
                              appointment: appointment,
                              dateTimeLabel:
                                  _formatAppointmentDateTime(appointment.at),
                              onTap: () =>
                                  _showAppointmentOverview(appointment),
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 14),
              _reveal(
                index: 8,
                child: Row(
                  children: [
                    const Expanded(
                      child: _SectionTitle(title: 'Today\'s Medicines'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const MedicationsListScreen(),
                          ),
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _reveal(
                index: 9,
                child: _MedicationProgressCard(
                  taken: medicationsTaken,
                  missed: medicationsMissed,
                  left: medicationsLeft,
                  total: medicationTotal,
                ),
              ),
              const SizedBox(height: 8),
              if (_isHomeLoading && _dashboard == null)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (medicationItems.isEmpty)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: KinsuTheme.cardDecoration,
                  child: const Text(
                    'No active medications yet. Add medications in Track to show them here.',
                    style: TextStyle(color: KinsuTheme.textSecondary),
                  ),
                )
              else
                ...medicationItems.map((item) {
                  final isTaken = item.status == 'taken';
                  final isMissed = item.status == 'missed';
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: KinsuTheme.cardDecoration,
                      child: Row(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isTaken
                                  ? const Color(0xFFE8F5E9)
                                  : isMissed
                                      ? const Color(0xFFFEF2F2)
                                      : const Color(0xFFEFF6FF),
                            ),
                            child: Icon(
                              isTaken
                                  ? Icons.check
                                  : isMissed
                                      ? Icons.close
                                      : Icons.medication_outlined,
                              size: 18,
                              color: isTaken
                                  ? KinsuTheme.statusActive
                                  : isMissed
                                      ? const Color(0xFFDC2626)
                                      : const Color(0xFF3B82F6),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  item.scheduledLabel == null ||
                                          item.scheduledLabel!.trim().isEmpty
                                      ? item.subtitle
                                      : '${item.scheduledLabel} · ${item.subtitle}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: KinsuTheme.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isTaken)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFE8F5E9),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Taken',
                                style: TextStyle(
                                  color: KinsuTheme.statusActive,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          else if (isMissed)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'Missed',
                                style: TextStyle(
                                  color: Color(0xFFDC2626),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            )
                          else
                            FilledButton(
                              onPressed: () => _markMedicationTaken(item),
                              style: FilledButton.styleFrom(
                                backgroundColor: KinsuTheme.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14, vertical: 8),
                              ),
                              child: const Text('Take'),
                            ),
                        ],
                      ),
                    ),
                  );
                }),
              const SizedBox(height: 8),
              _reveal(
                index: 10,
                child: Row(
                  children: [
                    const Expanded(
                        child: _SectionTitle(title: 'Health Insights')),
                    TextButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AiScreen()),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome, size: 16),
                      label: const Text('AI Summary'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _reveal(
                index: 11,
                child: insights.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(14),
                        decoration: KinsuTheme.cardDecoration,
                        child: const Text(
                          'No health insights yet. Start tracking vitals to see changes here.',
                          style: TextStyle(color: KinsuTheme.textSecondary),
                        ),
                      )
                    : SizedBox(
                        height: 160,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: insights.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            final insight = insights[index];
                            return _InsightCard(
                              title: insight.title,
                              value: insight.metric,
                              trend: insight.deltaLabel,
                              warning: insight.trend == 'up',
                              note: insight.summary,
                              onTap: () => _showHomeVitalOverview(
                                title: '${insight.title} Trend',
                                vitalType: insight.key,
                              ),
                            );
                          },
                        ),
                      ),
              ),
              const SizedBox(height: 16),
              _reveal(
                index: 12,
                child: Row(
                  children: [
                    const Expanded(
                        child: _SectionTitle(title: 'Recent Records')),
                    TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const VaultScreen()),
                        );
                      },
                      child: const Text('View All'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              _reveal(
                index: 13,
                child: recentRecords.isEmpty
                    ? Container(
                        padding: const EdgeInsets.all(12),
                        decoration: KinsuTheme.cardDecoration,
                        child: const Text(
                          'No records uploaded yet.',
                          style: TextStyle(color: KinsuTheme.textSecondary),
                        ),
                      )
                    : Column(
                        children: recentRecords
                            .map(
                              (record) => Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: _RecentRecordCard(
                                  record: record,
                                  onTap: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (_) => const VaultScreen()),
                                    );
                                  },
                                ),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedHeroCard extends StatelessWidget {
  final AnimationController controller;
  final int dayNumber;
  final _HeroSlideData slide;
  final int currentSlide;
  final int totalSlides;
  final ValueChanged<int> onDotTap;

  const _AnimatedHeroCard({
    required this.controller,
    required this.dayNumber,
    required this.slide,
    required this.currentSlide,
    required this.totalSlides,
    required this.onDotTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final t = controller.value * 2 * math.pi;
        return Container(
          height: 156,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: slide.colors,
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                right: 16 + (math.sin(t) * 8),
                top: 16 + (math.cos(t) * 6),
                child: _bubble(40, Colors.white.withValues(alpha: 0.16)),
              ),
              Positioned(
                left: 30 + (math.cos(t * 1.1) * 9),
                bottom: 12 + (math.sin(t * 1.2) * 6),
                child: _bubble(28, Colors.white.withValues(alpha: 0.15)),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            '${slide.emoji} ${slide.headline}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 9,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.17),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            '$dayNumber days',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      slide.subline,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const Spacer(),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Text(
                        slide.tip,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        totalSlides,
                        (index) => GestureDetector(
                          onTap: () => onDotTap(index),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            width: currentSlide == index ? 16 : 6,
                            height: 6,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: currentSlide == index
                                  ? Colors.white
                                  : Colors.white54,
                            ),
                          ),
                        ),
                      ),
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
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    );
  }
}

class _HeaderCircleIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _HeaderCircleIconButton({
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.18),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: Colors.white),
        ),
      ),
    );
  }
}

class _ContextAlertCard extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onTap;
  final VoidCallback onClose;

  const _ContextAlertCard({
    required this.title,
    required this.message,
    required this.onTap,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, color: Color(0xFFB45309)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  message,
                  style: const TextStyle(
                    color: Color(0xFF92400E),
                    fontSize: 12,
                  ),
                ),
                TextButton(
                  onPressed: onTap,
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(0, 28),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: const Text('View AI Summary'),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onClose,
            icon: const Icon(Icons.close, size: 17),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;

  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color color;
  final VoidCallback onTap;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.bg,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}

class _MiniActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color bg;
  final Color color;
  final VoidCallback onTap;

  const _MiniActionTile({
    required this.icon,
    required this.label,
    required this.bg,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

class _MedicationProgressCard extends StatelessWidget {
  final int taken;
  final int missed;
  final int left;
  final int total;

  const _MedicationProgressCard({
    required this.taken,
    required this.missed,
    required this.left,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : ((taken / total) * 100).round();
    final barCount = total == 0
        ? 5
        : total > 5
            ? total
            : 5;
    final filledBars = taken.clamp(0, barCount);
    final missedBars = missed.clamp(0, barCount - filledBars);

    Widget statPill(String label, int value, Color tint) {
      return Container(
        width: 84,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: tint,
          borderRadius: BorderRadius.circular(22),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$value',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [KinsuTheme.primary, KinsuTheme.primaryDark],
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x22000000),
            blurRadius: 22,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Today's Progress",
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '$percent%',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              statPill('Taken', taken, Colors.white.withValues(alpha: 0.20)),
              const SizedBox(width: 8),
              statPill('Missed', missed, Colors.black.withValues(alpha: 0.16)),
              const SizedBox(width: 8),
              statPill('Left', left, Colors.white.withValues(alpha: 0.12)),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(barCount, (index) {
              final color = index < filledBars
                  ? Colors.white
                  : index < filledBars + missedBars
                      ? const Color(0xFFFF9EA0)
                      : Colors.white.withValues(alpha: 0.28);
              return Expanded(
                child: Container(
                  height: 9,
                  margin: EdgeInsets.only(right: index == barCount - 1 ? 0 : 8),
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _medStateDot(Icons.check, Colors.white, const Color(0xFF12B76A)),
              const SizedBox(width: 10),
              _medStateDot(Icons.close, const Color(0xFFFF5F67), Colors.white),
              const SizedBox(width: 10),
              for (var i = 0; i < 3; i++) ...[
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.18),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.22),
                    ),
                  ),
                ),
                if (i < 2) const SizedBox(width: 10),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _medStateDot(IconData icon, Color fill, Color iconColor) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: fill,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 20, color: iconColor),
    );
  }
}

class _AppointmentCard extends StatelessWidget {
  final _AppointmentData appointment;
  final String dateTimeLabel;
  final VoidCallback onTap;

  const _AppointmentCard({
    required this.appointment,
    required this.dateTimeLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          width: 260,
          padding: const EdgeInsets.all(16),
          decoration: KinsuTheme.cardDecoration,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.health_and_safety_outlined,
                      color: Color(0xFF3B82F6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          appointment.doctor,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          appointment.specialty,
                          style: const TextStyle(
                            color: KinsuTheme.textSecondary,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                dateTimeLabel,
                style: const TextStyle(
                  color: KinsuTheme.primary,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                appointment.place,
                style: const TextStyle(
                  color: KinsuTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InsightCard extends StatelessWidget {
  final String title;
  final String value;
  final String trend;
  final bool warning;
  final String note;
  final VoidCallback? onTap;

  const _InsightCard({
    required this.title,
    required this.value,
    required this.trend,
    required this.warning,
    required this.note,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 170,
        padding: const EdgeInsets.all(12),
        decoration: KinsuTheme.cardDecoration,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 12,
                color: KinsuTheme.textSecondary,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color:
                    warning ? const Color(0xFFFFFBEB) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                trend,
                style: TextStyle(
                  color: warning
                      ? const Color(0xFF92400E)
                      : const Color(0xFF047857),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              note,
              style: const TextStyle(
                fontSize: 10,
                color: KinsuTheme.textSecondary,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _RecentRecordCard extends StatelessWidget {
  final _RecentRecordData record;
  final VoidCallback onTap;

  const _RecentRecordCard({
    required this.record,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: KinsuTheme.cardDecoration,
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: record.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(record.icon, color: record.color),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '${record.provider} · ${record.dateLabel}',
                      style: const TextStyle(
                        color: KinsuTheme.textSecondary,
                        fontSize: 12,
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

class _AppointmentData {
  final String doctor;
  final String specialty;
  final DateTime at;
  final String place;
  final String? notes;

  const _AppointmentData({
    required this.doctor,
    required this.specialty,
    required this.at,
    required this.place,
    this.notes,
  });
}

class _AppointmentDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _AppointmentDetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 84,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: KinsuTheme.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSlideData {
  final String emoji;
  final String headline;
  final String subline;
  final String tip;
  final List<Color> colors;

  const _HeroSlideData({
    required this.emoji,
    required this.headline,
    required this.subline,
    required this.tip,
    required this.colors,
  });
}

class _NotificationItemData {
  final String title;
  final String description;
  final String time;
  final bool unread;
  final bool alert;

  const _NotificationItemData({
    required this.title,
    required this.description,
    required this.time,
    required this.unread,
    required this.alert,
  });
}

class _RecentRecordData {
  final String type;
  final String title;
  final String provider;
  final String dateLabel;
  final IconData icon;
  final Color color;

  const _RecentRecordData({
    required this.type,
    required this.title,
    required this.provider,
    required this.dateLabel,
    required this.icon,
    required this.color,
  });
}
