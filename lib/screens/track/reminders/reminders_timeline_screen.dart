import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/reminder.dart';
import '../../../providers/reminders_provider.dart';
import 'add_reminder_screen.dart';

/// Today's reminders sorted by scheduled time — timeline view.
class RemindersTimelineScreen extends StatefulWidget {
  const RemindersTimelineScreen({super.key});

  @override
  State<RemindersTimelineScreen> createState() =>
      _RemindersTimelineScreenState();
}

class _RemindersTimelineScreenState extends State<RemindersTimelineScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RemindersProvider>().loadTimeline();
    });
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'medication':
        return Icons.medication;
      case 'appointment':
        return Icons.event;
      case 'checkup':
        return Icons.health_and_safety;
      case 'custom':
        return Icons.alarm;
      default:
        return Icons.notifications;
    }
  }

  Color _typeColor(String type) {
    switch (type) {
      case 'medication':
        return const Color(0xFF2196F3);
      case 'appointment':
        return const Color(0xFF9C27B0);
      case 'checkup':
        return KinsuTheme.primary;
      case 'custom':
        return const Color(0xFFFF9800);
      default:
        return KinsuTheme.textSecondary;
    }
  }

  String _formatRecurrence(String recurrence) {
    if (recurrence.isEmpty) {
      return 'Daily';
    }
    return recurrence[0].toUpperCase() + recurrence.substring(1);
  }

  Future<void> _showReminderOverview(Reminder reminder) async {
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
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: _typeColor(reminder.reminderType)
                              .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          _typeIcon(reminder.reminderType),
                          color: _typeColor(reminder.reminderType),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          reminder.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _ReminderDetailRow(
                    label: 'Type',
                    value: reminder.reminderType[0].toUpperCase() +
                        reminder.reminderType.substring(1),
                  ),
                  _ReminderDetailRow(
                    label: 'Scheduled Time',
                    value: reminder.displayTime,
                  ),
                  _ReminderDetailRow(
                    label: 'Repeat',
                    value: _formatRecurrence(reminder.recurrence),
                  ),
                  _ReminderDetailRow(
                    label: 'Status',
                    value: reminder.isEnabled ? 'Enabled' : 'Disabled',
                  ),
                  if (reminder.linkedMedicationId != null)
                    _ReminderDetailRow(
                      label: 'Linked Medication ID',
                      value: reminder.linkedMedicationId.toString(),
                    ),
                  if (reminder.notes != null &&
                      reminder.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      reminder.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: KinsuTheme.textSecondary,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton.icon(
            onPressed: () {
              context.read<RemindersProvider>().loadReminders();
            },
            icon: const Icon(Icons.list, size: 18),
            label: const Text('All'),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddReminderScreen()),
          );
          if (result == true && context.mounted) {
            context.read<RemindersProvider>().loadTimeline();
          }
        },
        backgroundColor: KinsuTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Reminder'),
      ),
      body: Consumer<RemindersProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = provider.timeline.isNotEmpty
              ? provider.timeline
              : provider.reminders;

          if (items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.alarm_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No reminders set',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add reminders for medications & checkups',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade400),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: KinsuTheme.primaryLight.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.today,
                        size: 16, color: KinsuTheme.primary),
                    const SizedBox(width: 6),
                    const Text(
                      "Today's Schedule",
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: KinsuTheme.primaryDark,
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${items.length} reminders',
                      style: const TextStyle(
                        fontSize: 12,
                        color: KinsuTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ...items.asMap().entries.map((entry) {
                final idx = entry.key;
                final reminder = entry.value;
                final isLast = idx == items.length - 1;

                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 60,
                      child: Text(
                        reminder.displayTime,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: KinsuTheme.textSecondary,
                        ),
                      ),
                    ),
                    Column(
                      children: [
                        Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: _typeColor(reminder.reminderType),
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 60,
                            color: KinsuTheme.divider,
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () => _showReminderOverview(reminder),
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: KinsuTheme.cardDecoration,
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: BoxDecoration(
                                    color: _typeColor(reminder.reminderType)
                                        .withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _typeIcon(reminder.reminderType),
                                    size: 20,
                                    color: _typeColor(reminder.reminderType),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        reminder.title,
                                        style: const TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      Text(
                                        reminder.reminderType[0].toUpperCase() +
                                            reminder.reminderType.substring(1),
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color: KinsuTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Switch(
                                  value: reminder.isEnabled,
                                  activeThumbColor: KinsuTheme.primary,
                                  activeTrackColor:
                                      KinsuTheme.primary.withValues(alpha: 0.3),
                                  onChanged: (value) {
                                    context
                                        .read<RemindersProvider>()
                                        .updateReminder(
                                      reminder.id!,
                                      {'is_enabled': value},
                                    );
                                  },
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              }),
            ],
          );
        },
      ),
    );
  }
}

class _ReminderDetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _ReminderDetailRow({
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
            width: 140,
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
