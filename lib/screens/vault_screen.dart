import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../core/theme.dart';
import '../models/health_record.dart';
import '../providers/vault_provider.dart';
import '../utils/file_utils.dart';
import 'upload_record_screen.dart';

// Conditional import for web PDF helper
import 'vault_screen_web_helper_stub.dart'
    if (dart.library.html) 'vault_screen_web_helper.dart';

class VaultScreen extends StatefulWidget {
  const VaultScreen({super.key});

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  final _searchController = TextEditingController();
  String _selectedFilter = 'All';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<VaultProvider>().loadRecords();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _navigateToUpload() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const UploadRecordScreen(),
      ),
    );

    // Refresh list if upload was successful
    if (result == true && mounted) {
      context.read<VaultProvider>().loadRecords();
    }
  }

  Future<void> _openRecord(HealthRecord record) async {
    // Show preview modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRecordPreview(record),
    );
  }

  Widget _buildRecordPreview(HealthRecord record) {
    final color = _getDocumentTypeColor(record.recordType);
    final icon = _getDocumentTypeIcon(record.recordType);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle bar
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: KinsuTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: KinsuTheme.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: KinsuTheme.foreground,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.recordType,
                        style: const TextStyle(
                          fontSize: 13,
                          color: KinsuTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: KinsuTheme.mutedForeground,
                ),
              ],
            ),
          ),

          // Content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (record.notes != null && record.notes!.isNotEmpty) ...[
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: KinsuTheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      record.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: KinsuTheme.mutedForeground,
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // File preview
                  if (record.fileUrl != null) ...[
                    const Text(
                      'Document',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: KinsuTheme.foreground,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _buildFilePreview(record),
                  ],
                ],
              ),
            ),
          ),

          // Actions
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: KinsuTheme.border, width: 1),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _downloadFile(record);
                    },
                    icon: const Icon(Icons.download_outlined, size: 18),
                    label: const Text('Download'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      _viewFullScreen(record);
                    },
                    icon: const Icon(Icons.open_in_full, size: 18),
                    label: const Text('View Full'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilePreview(HealthRecord record) {
    if (record.fileUrl == null) {
      return const SizedBox.shrink();
    }

    final isPdf = record.fileName?.toLowerCase().endsWith('.pdf') ?? false;

    if (isPdf) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: KinsuTheme.muted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KinsuTheme.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SfPdfViewer.network(
            record.fileUrl!,
            enableDoubleTapZooming: false,
            enableTextSelection: false,
          ),
        ),
      );
    } else {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: KinsuTheme.muted,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KinsuTheme.border),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: Image.network(
            record.fileUrl!,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: KinsuTheme.mutedForeground),
                    SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: KinsuTheme.mutedForeground),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    }
  }

  Future<void> _downloadFile(HealthRecord record) async {
    if (record.fileUrl == null) return;

    if (kIsWeb) {
      downloadFileOnWeb(record.fileUrl!, record.fileName ?? 'download');
    } else {
      final uri = Uri.parse(record.fileUrl!);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    }
  }

  Future<void> _viewFullScreen(HealthRecord record) async {
    if (record.fileUrl == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenViewer(record: record),
      ),
    );
  }

  Color _getDocumentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'lab report':
        return const Color(0xFF3B82F6);
      case 'prescription':
        return const Color(0xFF10B981);
      case 'imaging':
        return const Color(0xFF8B5CF6);
      case 'discharge summary':
        return const Color(0xFFF59E0B);
      default:
        return KinsuTheme.primary;
    }
  }

  IconData _getDocumentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'lab report':
        return Icons.science_outlined;
      case 'prescription':
        return Icons.medication_outlined;
      case 'imaging':
        return Icons.medical_services_outlined;
      case 'discharge summary':
        return Icons.description_outlined;
      default:
        return Icons.file_present_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KinsuTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                border: Border(
                  bottom: BorderSide(color: KinsuTheme.border, width: 1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Health Vault',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: KinsuTheme.foreground,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.add_circle_outline),
                        onPressed: _navigateToUpload,
                        color: KinsuTheme.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: (value) => setState(() {}),
                    decoration: InputDecoration(
                      hintText: 'Search records...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: KinsuTheme.muted,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'All',
                        'Lab Report',
                        'Prescription',
                        'Imaging',
                        'Discharge Summary'
                      ].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (selected) {
                              setState(() {
                                _selectedFilter = selected ? filter : 'All';
                              });
                            },
                            backgroundColor: KinsuTheme.muted,
                            selectedColor: KinsuTheme.primary.withOpacity(0.1),
                            checkmarkColor: KinsuTheme.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? KinsuTheme.primary
                                  : KinsuTheme.foreground,
                              fontSize: 13,
                            ),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 8,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // Records list
            Expanded(
              child: Consumer<VaultProvider>(
                builder: (context, provider, child) {
                  if (provider.isLoading) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: KinsuTheme.mutedForeground,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              provider.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: KinsuTheme.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: () => provider.loadRecords(),
                              icon: const Icon(Icons.refresh),
                              label: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  if (provider.records.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 64,
                              color: KinsuTheme.mutedForeground,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No records yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: KinsuTheme.foreground,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Upload your first health record to get started',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: KinsuTheme.mutedForeground,
                              ),
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton.icon(
                              onPressed: _navigateToUpload,
                              icon: const Icon(Icons.add),
                              label: const Text('Upload Record'),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  // Filter records
                  var filteredRecords = provider.records;
                  final searchQuery = _searchController.text.toLowerCase();

                  if (searchQuery.isNotEmpty) {
                    filteredRecords = filteredRecords.where((record) {
                      return record.title.toLowerCase().contains(searchQuery) ||
                          record.recordType.toLowerCase().contains(searchQuery) ||
                          (record.notes?.toLowerCase().contains(searchQuery) ?? false);
                    }).toList();
                  }

                  if (_selectedFilter != 'All') {
                    filteredRecords = filteredRecords
                        .where((record) => record.recordType == _selectedFilter)
                        .toList();
                  }

                  if (filteredRecords.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.all(24),
                        child: Text(
                          'No matching records found',
                          style: TextStyle(
                            color: KinsuTheme.mutedForeground,
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => provider.loadRecords(),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredRecords.length,
                      itemBuilder: (context, index) {
                        final record = filteredRecords[index];
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _buildRecordCard(record),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordCard(HealthRecord record) {
    final color = _getDocumentTypeColor(record.recordType);
    final icon = _getDocumentTypeIcon(record.recordType);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: KinsuTheme.border),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _openRecord(record),
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 18),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        record.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: KinsuTheme.foreground,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (record.notes != null && record.notes!.isNotEmpty) ...[
                        const SizedBox(height: 4),
                        Text(
                          record.notes!,
                          style: const TextStyle(
                            fontSize: 12,
                            color: KinsuTheme.mutedForeground,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Text(
                            _formatDate(record.recordDate),
                            style: const TextStyle(
                              fontSize: 11,
                              color: KinsuTheme.mutedForeground,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: TextStyle(
                                fontSize: 11,
                                color: KinsuTheme.mutedForeground,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: KinsuTheme.muted,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              record.recordType,
                              style: const TextStyle(
                                fontSize: 10,
                                color: KinsuTheme.mutedForeground,
                              ),
                            ),
                          ),
                          if (record.fileSize != null) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Text(
                                '•',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: KinsuTheme.mutedForeground,
                                ),
                              ),
                            ),
                            Text(
                              FileUtils.formatFileSize(record.fileSize!),
                              style: const TextStyle(
                                fontSize: 11,
                                color: KinsuTheme.mutedForeground,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  size: 16,
                  color: KinsuTheme.mutedForeground,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class _FullScreenViewer extends StatelessWidget {
  final HealthRecord record;

  const _FullScreenViewer({required this.record});

  @override
  Widget build(BuildContext context) {
    final isPdf = record.fileName?.toLowerCase().endsWith('.pdf') ?? false;

    return Scaffold(
      appBar: AppBar(
        title: Text(record.title),
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () async {
              if (record.fileUrl == null) return;

              if (kIsWeb) {
                downloadFileOnWeb(record.fileUrl!, record.fileName ?? 'download');
              } else {
                final uri = Uri.parse(record.fileUrl!);
                if (await canLaunchUrl(uri)) {
                  await launchUrl(uri, mode: LaunchMode.externalApplication);
                }
              }
            },
          ),
        ],
      ),
      body: isPdf
          ? SfPdfViewer.network(record.fileUrl!)
          : InteractiveViewer(
              child: Center(
                child: Image.network(record.fileUrl!),
              ),
            ),
    );
  }
}
