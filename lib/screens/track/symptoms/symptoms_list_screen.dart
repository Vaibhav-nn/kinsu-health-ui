import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../providers/symptoms_provider.dart';
import 'add_symptom_screen.dart';

/// List of chronic symptoms with severity badges and active/inactive filter.
class SymptomsListScreen extends StatefulWidget {
  const SymptomsListScreen({super.key});

  @override
  State<SymptomsListScreen> createState() => _SymptomsListScreenState();
}

class _SymptomsListScreenState extends State<SymptomsListScreen> {
  bool? _filterActive;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SymptomsProvider>().loadSymptoms();
    });
  }

  Color _severityColor(int severity) {
    if (severity <= 3) return KinsuTheme.statusActive;
    if (severity <= 6) return KinsuTheme.statusWarning;
    return KinsuTheme.statusError;
  }

  String _severityLabel(int severity) {
    if (severity <= 3) return 'Mild';
    if (severity <= 6) return 'Moderate';
    return 'Severe';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Chronic Symptoms'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddSymptomScreen()),
          );
          if (result == true) {
            context.read<SymptomsProvider>().loadSymptoms(isActive: _filterActive);
          }
        },
        backgroundColor: KinsuTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('Add Symptom'),
      ),
      body: Column(
        children: [
          // ── Filter Chips ──────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _FilterChip(
                  label: 'All',
                  isSelected: _filterActive == null,
                  onTap: () {
                    setState(() => _filterActive = null);
                    context.read<SymptomsProvider>().loadSymptoms();
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Active',
                  isSelected: _filterActive == true,
                  onTap: () {
                    setState(() => _filterActive = true);
                    context.read<SymptomsProvider>().loadSymptoms(isActive: true);
                  },
                ),
                const SizedBox(width: 8),
                _FilterChip(
                  label: 'Resolved',
                  isSelected: _filterActive == false,
                  onTap: () {
                    setState(() => _filterActive = false);
                    context.read<SymptomsProvider>().loadSymptoms(isActive: false);
                  },
                ),
              ],
            ),
          ),

          // ── Symptoms List ─────────────────────────
          Expanded(
            child: Consumer<SymptomsProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (provider.symptoms.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.healing_outlined,
                            size: 64, color: Colors.grey.shade400),
                        const SizedBox(height: 16),
                        Text(
                          'No symptoms tracked yet',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: provider.symptoms.length,
                  itemBuilder: (context, index) {
                    final symptom = provider.symptoms[index];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: KinsuTheme.cardDecoration,
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _severityColor(symptom.severity),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  symptom.symptomName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Text(
                                      '${symptom.frequency} · ${symptom.bodyArea ?? "General"}',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        color: KinsuTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: _severityColor(symptom.severity)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_severityLabel(symptom.severity)} (${symptom.severity}/10)',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: _severityColor(symptom.severity),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: symptom.isActive
                                      ? KinsuTheme.statusActive.withOpacity(0.1)
                                      : Colors.grey.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  symptom.isActive ? 'Active' : 'Resolved',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: symptom.isActive
                                        ? KinsuTheme.statusActive
                                        : Colors.grey,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? KinsuTheme.primary : KinsuTheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? KinsuTheme.primary : KinsuTheme.divider,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : KinsuTheme.textSecondary,
          ),
        ),
      ),
    );
  }
}
