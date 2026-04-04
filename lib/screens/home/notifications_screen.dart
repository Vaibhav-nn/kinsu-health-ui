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

  IconData _iconForItem(HomeNotificationItem item) {
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
      case 'hydration':
        return Icons.water_drop_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _accentForItem(HomeNotificationItem item) {
    switch (item.priority) {
      case 'critical':
        return const Color(0xFFDC2626);
      case 'high':
        return const Color(0xFFF59E0B);
      default:
        switch (item.notificationType) {
          case 'medication':
            return const Color(0xFF0EA5A4);
          case 'lab':
            return const Color(0xFF22C55E);
          case 'appointment':
            return const Color(0xFF8B5CF6);
          case 'family':
            return const Color(0xFF3B82F6);
          case 'hydration':
            return const Color(0xFF06B6D4);
          default:
            return KinsuTheme.primary;
        }
    }
  }

  String _relativeLabel(DateTime value) {
    final diff = DateTime.now().difference(value);
    if (diff.inMinutes < 1) {
      return 'Just now';
    }
    if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    }
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    }
    if (diff.inDays == 1) {
      return 'Yesterday';
    }
    return '${diff.inDays} days ago';
  }

  String _sectionLabel(HomeNotificationItem item) {
    if (item.sectionLabel != null && item.sectionLabel!.trim().isNotEmpty) {
      return item.sectionLabel!;
    }
    final createdAt = item.createdAt;
    final now = DateTime.now();
    final createdDate =
        DateTime(createdAt.year, createdAt.month, createdAt.day);
    final today = DateTime(now.year, now.month, now.day);
    final diff = today.difference(createdDate).inDays;
    if (diff <= 0) {
      return 'Today';
    }
    if (diff == 1) {
      return 'Yesterday';
    }
    return 'Earlier';
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
      appBar: AppBar(
        title: const Text('Notifications'),
      ),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          children: [
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: _tabs
                  .map(
                    (tab) => _NotificationTabChip(
                      label: switch (tab) {
                        'reminder' => 'Reminders',
                        'alert' => 'Alerts',
                        _ => 'All',
                      },
                      selected: _selectedTab == tab,
                      onTap: () => _changeTab(tab),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
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
                padding: const EdgeInsets.all(18),
                decoration: KinsuTheme.cardDecoration,
                child: const Text(
                  'No notifications in this tab yet.',
                  style: TextStyle(color: KinsuTheme.textSecondary),
                ),
              )
            else
              ...grouped.entries.map(
                (entry) => Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 12),
                    ...entry.value.map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: _NotificationCard(
                          item: item,
                          icon: _iconForItem(item),
                          accent: _accentForItem(item),
                          timeLabel: _relativeLabel(item.createdAt),
                          onPrimaryAction: () => _handlePrimaryAction(item),
                          onSecondaryAction: item.secondaryActionLabel == null
                              ? null
                              : () => _handleSecondaryAction(item),
                        ),
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
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? KinsuTheme.primary : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? KinsuTheme.primary : KinsuTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : KinsuTheme.textSecondary,
          ),
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
      padding: const EdgeInsets.all(16),
      decoration: KinsuTheme.cardDecoration,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style:
                const TextStyle(color: KinsuTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 12),
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
  final IconData icon;
  final Color accent;
  final String timeLabel;
  final VoidCallback onPrimaryAction;
  final VoidCallback? onSecondaryAction;

  const _NotificationCard({
    required this.item,
    required this.icon,
    required this.accent,
    required this.timeLabel,
    required this.onPrimaryAction,
    required this.onSecondaryAction,
  });

  bool get _highlight => item.priority == 'high' || item.priority == 'critical';

  @override
  Widget build(BuildContext context) {
    final pillLabel = item.priority == 'critical'
        ? 'Critical'
        : item.priority == 'high'
            ? 'High Priority'
            : null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _highlight ? const Color(0xFFFFFBEB) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color:
              _highlight ? accent.withValues(alpha: 0.35) : KinsuTheme.divider,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: accent, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.title,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.body,
                      style: const TextStyle(
                        color: KinsuTheme.textSecondary,
                        fontSize: 16,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              if (pillLabel != null)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: accent.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    pillLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: accent,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            timeLabel,
            style: const TextStyle(
              fontSize: 13,
              color: KinsuTheme.textSecondary,
            ),
          ),
          if (item.primaryActionLabel != null ||
              item.secondaryActionLabel != null) ...[
            const SizedBox(height: 16),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                if (item.primaryActionLabel != null)
                  ElevatedButton(
                    onPressed: onPrimaryAction,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    child: Text(item.primaryActionLabel!),
                  ),
                if (item.secondaryActionLabel != null)
                  OutlinedButton(
                    onPressed: onSecondaryAction,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: KinsuTheme.textSecondary,
                      side: const BorderSide(color: KinsuTheme.divider),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 12),
                    ),
                    child: Text(item.secondaryActionLabel!),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
