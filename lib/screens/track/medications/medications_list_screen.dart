import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme.dart';
import '../../../models/medication.dart';
import '../../../providers/medications_provider.dart';
import '../../../providers/reminders_provider.dart';
import 'add_medication_screen.dart';

/// List of medications with active/inactive indicators.
class MedicationsListScreen extends StatefulWidget {
  const MedicationsListScreen({super.key});

  @override
  State<MedicationsListScreen> createState() => _MedicationsListScreenState();
}

class _MedicationsListScreenState extends State<MedicationsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MedicationsProvider>().loadMedications();
      context
          .read<RemindersProvider>()
          .loadReminders(reminderType: 'medication');
    });
  }

  String _formatDate(DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date);
  }

  String _formatDoctor(String doctor) {
    final cleaned = doctor.trim();
    if (cleaned.toLowerCase().startsWith('dr')) {
      return cleaned;
    }
    return 'Dr. $cleaned';
  }

  Future<void> _openMedicationPreview(Medication medication) async {
    final remindersProvider = context.read<RemindersProvider>();
    final linkedReminders = remindersProvider.reminders
        .where((reminder) => reminder.linkedMedicationId == medication.id)
        .toList()
      ..sort((a, b) => a.scheduledTime.compareTo(b.scheduledTime));

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
                      Expanded(
                        child: Text(
                          medication.name,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: medication.isActive
                              ? KinsuTheme.statusActive.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          medication.isActive ? 'Active' : 'Stopped',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: medication.isActive
                                ? KinsuTheme.statusActive
                                : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'Dosage', value: medication.dosage),
                  _DetailRow(
                    label: 'Frequency',
                    value: _formatFrequency(medication.frequency),
                  ),
                  _DetailRow(label: 'Route', value: medication.route),
                  _DetailRow(
                    label: 'Start Date',
                    value: _formatDate(medication.startDate),
                  ),
                  if (medication.endDate != null)
                    _DetailRow(
                      label: 'End Date',
                      value: _formatDate(medication.endDate!),
                    ),
                  if (medication.prescribingDoctor != null &&
                      medication.prescribingDoctor!.trim().isNotEmpty)
                    _DetailRow(
                      label: 'Prescribing Doctor',
                      value: _formatDoctor(medication.prescribingDoctor!),
                    ),
                  if (linkedReminders.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    const Text(
                      'Scheduled Times',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: linkedReminders
                          .map(
                            (reminder) => Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    KinsuTheme.primary.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                reminder.displayTime,
                                style: const TextStyle(
                                  color: KinsuTheme.primary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                  if (medication.notes != null &&
                      medication.notes!.trim().isNotEmpty) ...[
                    const SizedBox(height: 14),
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      medication.notes!,
                      style: const TextStyle(
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
        title: const Text('Medications'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddMedicationScreen()),
          );
          if (result == true && context.mounted) {
            context.read<MedicationsProvider>().loadMedications();
            context
                .read<RemindersProvider>()
                .loadReminders(reminderType: 'medication');
          }
        },
        backgroundColor: KinsuTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Medication'),
      ),
      body: Consumer<MedicationsProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.medications.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.medication_outlined,
                    size: 64,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No medications added yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.medications.length,
            itemBuilder: (context, index) {
              final medication = provider.medications[index];

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => _openMedicationPreview(medication),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: KinsuTheme.cardDecoration,
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2196F3)
                                  .withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.medication,
                              color: Color(0xFF2196F3),
                              size: 24,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  medication.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${medication.dosage} · ${_formatFrequency(medication.frequency)}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: KinsuTheme.textSecondary,
                                  ),
                                ),
                                if (medication.prescribingDoctor != null &&
                                    medication.prescribingDoctor!
                                        .trim()
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    _formatDoctor(
                                        medication.prescribingDoctor!),
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: medication.isActive
                                      ? KinsuTheme.statusActive
                                          .withValues(alpha: 0.1)
                                      : Colors.grey.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  medication.isActive ? 'Active' : 'Stopped',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: medication.isActive
                                        ? KinsuTheme.statusActive
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Icon(
                                Icons.chevron_right,
                                color: KinsuTheme.textSecondary,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatFrequency(String frequency) {
    switch (frequency) {
      case 'once_daily':
        return 'Once daily';
      case 'twice_daily':
        return 'Twice/day';
      case 'weekly':
        return 'Weekly';
      case 'as_needed':
        return 'As needed';
      default:
        return frequency;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
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
            width: 132,
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
