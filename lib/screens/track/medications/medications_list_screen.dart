import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../providers/medications_provider.dart';
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
    });
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
          if (result == true) {
            context.read<MedicationsProvider>().loadMedications();
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
                  Icon(Icons.medication_outlined,
                      size: 64, color: Colors.grey.shade400),
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
              final med = provider.medications[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                padding: const EdgeInsets.all(16),
                decoration: KinsuTheme.cardDecoration,
                child: Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF2196F3).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.medication,
                          color: Color(0xFF2196F3), size: 24),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            med.name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${med.dosage} · ${_formatFrequency(med.frequency)}',
                            style: const TextStyle(
                              fontSize: 13,
                              color: KinsuTheme.textSecondary,
                            ),
                          ),
                          if (med.prescribingDoctor != null) ...[
                            const SizedBox(height: 2),
                            Text(
                              'Dr. ${med.prescribingDoctor}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: med.isActive
                            ? KinsuTheme.statusActive.withOpacity(0.1)
                            : Colors.grey.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        med.isActive ? 'Active' : 'Stopped',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: med.isActive
                              ? KinsuTheme.statusActive
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }

  String _formatFrequency(String freq) {
    switch (freq) {
      case 'once_daily':
        return 'Once daily';
      case 'twice_daily':
        return 'Twice/day';
      case 'as_needed':
        return 'As needed';
      default:
        return freq;
    }
  }
}
