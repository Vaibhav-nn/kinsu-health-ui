import 'package:flutter/material.dart';
import 'package:kinsu_health/widgets/ios_back_button.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/illness.dart';
import '../../../providers/illness_provider.dart';

/// Detailed view of a single illness episode with detail entries timeline.
class IllnessDetailScreen extends StatefulWidget {
  final int episodeId;
  const IllnessDetailScreen({super.key, required this.episodeId});

  @override
  State<IllnessDetailScreen> createState() => _IllnessDetailScreenState();
}

class _IllnessDetailScreenState extends State<IllnessDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IllnessProvider>().loadEpisodeDetails(widget.episodeId);
    });
  }

  IconData _detailIcon(String type) {
    switch (type) {
      case 'symptom':
        return Icons.healing;
      case 'diagnosis':
        return Icons.assignment;
      case 'treatment':
        return Icons.medication;
      case 'note':
        return Icons.note;
      default:
        return Icons.info;
    }
  }

  Color _detailColor(String type) {
    switch (type) {
      case 'symptom':
        return const Color(0xFFFF9800);
      case 'diagnosis':
        return const Color(0xFF2196F3);
      case 'treatment':
        return KinsuTheme.primary;
      case 'note':
        return const Color(0xFF9C27B0);
      default:
        return KinsuTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Episode Details'),
        leading: const IosBackButton(),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDetailDialog(context),
        backgroundColor: KinsuTheme.primary,
        foregroundColor: Colors.white,
        child: const Icon(Icons.add),
      ),
      body: Consumer<IllnessProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final episode = provider.selectedEpisode;
          if (episode == null) {
            return const Center(child: Text('Episode not found'));
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Episode Header ────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: KinsuTheme.cardDecoration,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            episode.title,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        _StatusChip(status: episode.status),
                      ],
                    ),
                    if (episode.description != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        episode.description!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: KinsuTheme.textSecondary,
                        ),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        const Icon(Icons.calendar_today,
                            size: 14, color: KinsuTheme.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          'Started: ${episode.startDate.day}/${episode.startDate.month}/${episode.startDate.year}',
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
              const SizedBox(height: 24),

              // ── Details Timeline ──────────────────
              const Text(
                'Timeline',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),

              if (episode.details.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: KinsuTheme.cardDecoration,
                  child: const Center(
                    child: Text(
                      'No entries yet. Tap + to add symptoms, diagnosis, or treatments.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: KinsuTheme.textSecondary),
                    ),
                  ),
                )
              else
                ...episode.details.map((detail) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: _detailColor(detail.detailType)
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Icon(
                                  _detailIcon(detail.detailType),
                                  size: 18,
                                  color: _detailColor(detail.detailType),
                                ),
                              ),
                              Container(
                                width: 2,
                                height: 30,
                                color: KinsuTheme.divider,
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: KinsuTheme.cardDecoration,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _detailColor(detail.detailType)
                                              .withOpacity(0.1),
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Text(
                                          detail.detailType[0].toUpperCase() +
                                              detail.detailType.substring(1),
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color:
                                                _detailColor(detail.detailType),
                                          ),
                                        ),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${detail.recordedAt.day}/${detail.recordedAt.month}',
                                        style: const TextStyle(
                                          fontSize: 11,
                                          color: KinsuTheme.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    detail.content,
                                    style: const TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )),
            ],
          );
        },
      ),
    );
  }

  void _showAddDetailDialog(BuildContext context) {
    final contentController = TextEditingController();
    String selectedType = 'symptom';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Detail',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children:
                        ['symptom', 'diagnosis', 'treatment', 'note'].map((t) {
                      final isSelected = selectedType == t;
                      return ChoiceChip(
                        label: Text(t[0].toUpperCase() + t.substring(1)),
                        selected: isSelected,
                        onSelected: (s) {
                          if (s) setModalState(() => selectedType = t);
                        },
                        selectedColor: KinsuTheme.primary,
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : KinsuTheme.textPrimary,
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: contentController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Details',
                      hintText: 'Describe the symptom, diagnosis, or treatment',
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () async {
                      if (contentController.text.isEmpty) return;
                      final detail = IllnessDetail(
                        detailType: selectedType,
                        content: contentController.text,
                        recordedAt: DateTime.now(),
                      );
                      final illnessProvider = context.read<IllnessProvider>();
                      await illnessProvider.addDetail(widget.episodeId, detail);
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                    },
                    child: const Text('Add'),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  Color get _color {
    switch (status) {
      case 'active':
        return KinsuTheme.statusError;
      case 'recovered':
        return KinsuTheme.statusActive;
      case 'chronic':
        return KinsuTheme.statusWarning;
      default:
        return KinsuTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status[0].toUpperCase() + status.substring(1),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: _color,
        ),
      ),
    );
  }
}
