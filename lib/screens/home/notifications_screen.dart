import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/constants.dart';
import '../../core/theme.dart';
import '../../models/home_models.dart';
import '../../screens/track/medications/medications_list_screen.dart';
import '../../screens/vault_screen.dart';
import '../../services/home_service.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  static const _tabs = ['all', 'reminder', 'alert'];

  List<HomeNotificationItem> _items = const [];
  bool _isLoading = true;
  String? _error;
  String _selectedTab = 'all';

  String _friendlyError(Object error) {
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

      if (statusCode != null && detail.isNotEmpty) {
        return detail;
      }
    }

    return 'Unable to load notifications right now.';
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadNotifications());
  }

  Future<void> _loadNotifications() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final items = await context.read<HomeService>().fetchNotifications(
            category: _selectedTab == 'all' ? null : _selectedTab,
          );
      if (!mounted) {
        return;
      }
      setState(() {
        _items = items;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }
      setState(() {
        _error = _friendlyError(error);
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _changeTab(String tab) async {
    if (_selectedTab == tab) {
      return;
    }
    setState(() {
      _selectedTab = tab;
    });
    await _loadNotifications();
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

  String _sectionLabel(HomeNotificationItem item) {
    if (item.sectionLabel != null && item.sectionLabel!.trim().isNotEmpty) {
      return item.sectionLabel!.toUpperCase();
    }

    final createdAt = item.createdAt;
    final now = DateTime.now();
    final createdDate =
        DateTime(createdAt.year, createdAt.month, createdAt.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(createdDate).inDays;
    if (diff <= 0) {
      return 'TODAY';
    }
    if (diff == 1) {
      return 'YESTERDAY';
    }
    return 'WEEKLY INSIGHT';
  }

  Map<String, List<HomeNotificationItem>> _groupedItems() {
    final groups = <String, List<HomeNotificationItem>>{};
    for (final item in _items) {
      final key = _sectionLabel(item);
      groups.putIfAbsent(key, () => []).add(item);
    }
    return groups;
  }

  Future<void> _handlePrimaryAction(HomeNotificationItem item) async {
    final route = item.actionRoute ?? item.secondaryActionRoute ?? '';
    if (!mounted) {
      return;
    }

    if (route.contains('vault') || item.notificationType == 'lab') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const VaultScreen()),
      );
      return;
    }

    if (route.contains('medication') || item.notificationType == 'medication') {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const MedicationsListScreen()),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item.primaryActionLabel ?? 'Action noted.'),
        backgroundColor: KinsuTheme.primary,
      ),
    );
  }

  Future<void> _handleSecondaryAction(HomeNotificationItem item) async {
    if (!mounted) {
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(item.secondaryActionLabel ?? 'Reminder snoozed for now.'),
        backgroundColor: KinsuTheme.statusWarning,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final grouped = _groupedItems();
    return Scaffold(
      backgroundColor: KinsuTheme.background,
      bottomNavigationBar: const _NotificationsBottomNav(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadNotifications,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 24),
            children: [
              Row(
                children: [
                  _RoundIconButton(
                    icon: Icons.arrow_back_ios_new_rounded,
                    onTap: () => Navigator.of(context).pop(),
                  ),
                  const SizedBox(width: 14),
                  const Expanded(
                    child: Text(
                      'Notifications',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: KinsuTheme.textPrimary,
                      ),
                    ),
                  ),
                  _RoundIconButton(icon: Icons.more_vert, onTap: () {}),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: const Color(0xFFE9EEEF),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: _tabs
                      .map(
                        (tab) => Expanded(
                          child: _NotificationTabChip(
                            label: switch (tab) {
                              'reminder' => 'Reminders',
                              'alert' => 'Alerts',
                              _ => 'All',
                            },
                            selected: _selectedTab == tab,
                            onTap: () => _changeTab(tab),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
              const SizedBox(height: 16),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 52),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _NotificationsErrorCard(
                  title: _selectedTab == 'all'
                      ? 'Unable to load notifications'
                      : 'Unable to load this notification tab',
                  message: _error!,
                  onRetry: _loadNotifications,
                )
              else if (_items.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: KinsuTheme.cardDecoration,
                  child: const Text(
                    'No notifications in this tab yet.',
                    style: TextStyle(
                      color: KinsuTheme.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                )
              else
                ...grouped.entries.map(
                  (entry) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _SectionPill(label: entry.key),
                        const SizedBox(height: 10),
                        ...entry.value.map(
                          (item) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _NotificationCard(
                              item: item,
                              timeLabel: _relativeLabel(item.createdAt),
                              onPrimaryAction: () => _handlePrimaryAction(item),
                              onSecondaryAction:
                                  item.secondaryActionLabel == null
                                      ? null
                                      : () => _handleSecondaryAction(item),
                            ),
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
    );
  }
}

class _NotificationTabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _NotificationTabChip({
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
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? KinsuTheme.primaryDark : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            color: selected ? Colors.white : KinsuTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}

class _SectionPill extends StatelessWidget {
  final String label;

  const _SectionPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFFF8E5A6),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w800,
          color: Color(0xFF7A6200),
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _NotificationsErrorCard extends StatelessWidget {
  final String title;
  final String message;
  final VoidCallback onRetry;

  const _NotificationsErrorCard({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: KinsuTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline,
              color: KinsuTheme.statusWarning, size: 22),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: const TextStyle(
              color: KinsuTheme.textSecondary,
              height: 1.4,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 14),
          OutlinedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final HomeNotificationItem item;
  final String timeLabel;
  final VoidCallback onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  const _NotificationCard({
    required this.item,
    required this.timeLabel,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
  });

  bool get _highlight => item.priority == 'high' || item.priority == 'critical';

  Color get _accent {
    switch (item.priority) {
      case 'critical':
        return const Color(0xFFF59E0B);
      case 'high':
        return const Color(0xFF0EA5A4);
      default:
        switch (item.notificationType) {
          case 'medication':
            return const Color(0xFF149C97);
          case 'lab':
            return const Color(0xFF22C55E);
          case 'appointment':
            return const Color(0xFF8B5CF6);
          case 'family':
            return const Color(0xFF3B82F6);
          default:
            return KinsuTheme.textSecondary;
        }
    }
  }

  bool get _isWeeklyInsight => _sectionLabelHint == 'WEEKLY INSIGHT';

  String get _sectionLabelHint => item.sectionLabel?.trim().toUpperCase() ?? '';

  IconData get _icon {
    switch (item.notificationType) {
      case 'ai':
      case 'insight':
        return Icons.warning_amber_rounded;
      case 'medication':
        return Icons.medication_rounded;
      case 'lab':
        return Icons.science_outlined;
      case 'appointment':
        return Icons.event_outlined;
      case 'family':
        return Icons.family_restroom_outlined;
      default:
        return Icons.notifications_none_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.zero,
      decoration: BoxDecoration(
        color: _isWeeklyInsight
            ? KinsuTheme.primaryDark
            : _highlight
                ? const Color(0xFFFEFBF0)
                : switch (item.notificationType) {
                    'medication' => const Color(0xFFF4FAEE),
                    'lab' => const Color(0xFFF9FBFF),
                    _ => Colors.white,
                  },
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: _isWeeklyInsight
              ? Colors.transparent
              : _highlight
                  ? const Color(0xFFF2D36C)
                  : KinsuTheme.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (!_isWeeklyInsight)
                Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: _accent,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(28),
                      bottomLeft: Radius.circular(28),
                    ),
                  ),
                ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!_isWeeklyInsight) ...[
                            Icon(_icon, color: _accent, size: 18),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        item.title,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w800,
                                          color: _isWeeklyInsight
                                              ? Colors.white
                                              : KinsuTheme.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (!_isWeeklyInsight) ...[
                                      const SizedBox(width: 10),
                                      Text(
                                        timeLabel,
                                        style: const TextStyle(
                                          color: KinsuTheme.textSecondary,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  item.body,
                                  style: TextStyle(
                                    color: _isWeeklyInsight
                                        ? Colors.white.withValues(alpha: 0.86)
                                        : KinsuTheme.textSecondary,
                                    fontSize: 12,
                                    height: 1.35,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                if (_isWeeklyInsight)
                                  Text(
                                    timeLabel,
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.72),
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      if (item.primaryActionLabel != null ||
                          item.secondaryActionLabel != null) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          alignment: WrapAlignment.start,
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (item.primaryActionLabel != null)
                              SizedBox(
                                height: 34,
                                child: ElevatedButton(
                                  onPressed: onPrimaryAction,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        _accent == KinsuTheme.textSecondary
                                            ? KinsuTheme.primary
                                            : _accent,
                                    minimumSize: const Size(0, 34),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  child: Text(item.primaryActionLabel!),
                                ),
                              ),
                            if (item.secondaryActionLabel != null)
                              SizedBox(
                                height: 34,
                                child: OutlinedButton(
                                  onPressed: onSecondaryAction,
                                  style: OutlinedButton.styleFrom(
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(999),
                                    ),
                                    side: const BorderSide(
                                      color: KinsuTheme.divider,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 12),
                                    textStyle: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  child: Text(item.secondaryActionLabel!),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoundIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _RoundIconButton({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F4F5),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: KinsuTheme.primaryDark, size: 18),
      ),
    );
  }
}

class _NotificationsBottomNav extends StatelessWidget {
  const _NotificationsBottomNav();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE8ECEE))),
        boxShadow: [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 12,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: const SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _NotificationFooterItem(
              icon: Icons.home_outlined,
              label: 'HOME',
            ),
            _NotificationFooterItem(
              icon: Icons.medical_information_outlined,
              label: 'HEALTH',
            ),
            _NotificationFooterItem(
              icon: Icons.notifications_none_rounded,
              label: 'INBOX',
              selected: true,
            ),
            _NotificationFooterItem(
              icon: Icons.person_outline_rounded,
              label: 'PROFILE',
            ),
          ],
        ),
      ),
    );
  }
}

class _NotificationFooterItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;

  const _NotificationFooterItem({
    required this.icon,
    required this.label,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final color = selected ? KinsuTheme.primaryDark : const Color(0xFF9AA4B2);
    return SizedBox(
      width: 62,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: selected ? const Color(0xFFDFF1EC) : Colors.transparent,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, size: 20, color: color),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: 0.6,
            ),
          ),
        ],
      ),
    );
  }
}
