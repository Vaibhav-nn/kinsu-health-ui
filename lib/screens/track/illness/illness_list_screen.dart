import 'package:flutter/material.dart';
import 'package:kinsu_health/widgets/ios_back_button.dart';
import 'package:provider/provider.dart';
import '../../../core/theme.dart';
import '../../../models/illness.dart';
import '../../../providers/illness_provider.dart';
import 'illness_detail_screen.dart';

/// List of illness episodes with status chips.
class IllnessListScreen extends StatefulWidget {
  const IllnessListScreen({super.key});

  @override
  State<IllnessListScreen> createState() => _IllnessListScreenState();
}

class _IllnessListScreenState extends State<IllnessListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<IllnessProvider>().loadEpisodes();
    });
  }

  Color _statusColor(String status) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Illness Episodes'),
        leading: const IosBackButton(),
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddDialog(context),
        backgroundColor: KinsuTheme.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text('New Episode'),
      ),
      body: Consumer<IllnessProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (provider.episodes.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.medical_information_outlined,
                      size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'No illness episodes recorded',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),
                ],
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: provider.episodes.length,
            itemBuilder: (context, index) {
              final episode = provider.episodes[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          IllnessDetailScreen(episodeId: episode.id!),
                    ),
                  );
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
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
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color:
                                  _statusColor(episode.status).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              episode.status[0].toUpperCase() +
                                  episode.status.substring(1),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _statusColor(episode.status),
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (episode.description != null) ...[
                        const SizedBox(height: 6),
                        Text(
                          episode.description!,
                          style: const TextStyle(
                            fontSize: 13,
                            color: KinsuTheme.textSecondary,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.calendar_today,
                              size: 14, color: Colors.grey.shade500),
                          const SizedBox(width: 4),
                          Text(
                            'Started: ${episode.startDate.day}/${episode.startDate.month}/${episode.startDate.year}',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (episode.endDate != null) ...[
                            const SizedBox(width: 12),
                            Text(
                              'Ended: ${episode.endDate!.day}/${episode.endDate!.month}/${episode.endDate!.year}',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddDialog(BuildContext context) {
    final titleController = TextEditingController();
    final descController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
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
                'New Illness Episode',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'e.g. Flu, Food Poisoning',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () async {
                  if (titleController.text.isEmpty) return;
                  final episode = IllnessEpisode(
                    title: titleController.text,
                    description: descController.text.isNotEmpty
                        ? descController.text
                        : null,
                    startDate: DateTime.now(),
                  );
                  await context.read<IllnessProvider>().createEpisode(episode);
                  if (mounted) Navigator.pop(ctx);
                },
                child: const Text('Create Episode'),
              ),
            ],
          ),
        );
      },
    );
  }
}
