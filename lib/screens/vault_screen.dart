import 'dart:async';

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
  Timer? _searchDebounce;
  String _selectedFilter = 'All';
  bool? _hasFileFilter;
  DateTimeRange? _dateRange;
  String _sortBy = 'record_date';
  String _sortOrder = 'desc';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadRecords();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    await context.read<VaultProvider>().loadRecords(
          recordType: _selectedFilter == 'All' ? null : _selectedFilter,
          query: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          startDate: _dateRange?.start,
          endDate: _dateRange?.end,
          hasFile: _hasFileFilter,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
        );
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      _loadRecords();
    });
  }

  Future<void> _pickDateRange() async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      initialDateRange: _dateRange,
    );
    if (picked == null) {
      return;
    }
    setState(() => _dateRange = picked);
    await _loadRecords();
  }

  String _dateLabel(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/'
        '${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  String _dateRangeLabel() {
    if (_dateRange == null) {
      return 'Any date';
    }
    return '${_dateLabel(_dateRange!.start)} - ${_dateLabel(_dateRange!.end)}';
  }

  String _sortLabel() {
    if (_sortBy == 'title' && _sortOrder == 'asc') {
      return 'Title A-Z';
    }
    if (_sortBy == 'file_uploaded_at') {
      return 'Recent Uploads';
    }
    if (_sortBy == 'record_date' && _sortOrder == 'asc') {
      return 'Oldest First';
    }
    return 'Latest First';
  }

  Future<void> _navigateToUpload() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => const UploadRecordScreen(),
      ),
    );

    // Refresh list if upload was successful
    if (result == true && mounted) {
      await _loadRecords();
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
              color: KinsuTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: KinsuTheme.divider, width: 1),
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
                          color: KinsuTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.recordType,
                        style: const TextStyle(
                          fontSize: 13,
                          color: KinsuTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(context),
                  color: KinsuTheme.textSecondary,
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
                        color: KinsuTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      record.notes!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: KinsuTheme.textSecondary,
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
                        color: KinsuTheme.textPrimary,
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
                top: BorderSide(color: KinsuTheme.divider, width: 1),
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
          color: KinsuTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KinsuTheme.divider),
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
          color: KinsuTheme.background,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: KinsuTheme.divider),
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
                    Icon(Icons.error_outline,
                        size: 48, color: KinsuTheme.textSecondary),
                    SizedBox(height: 8),
                    Text(
                      'Failed to load image',
                      style: TextStyle(color: KinsuTheme.textSecondary),
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
                  bottom: BorderSide(color: KinsuTheme.divider, width: 1),
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
                          color: KinsuTheme.textPrimary,
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
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search records...',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      filled: true,
                      fillColor: KinsuTheme.background,
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
                        'Discharge Summary',
                      ].map((filter) {
                        final isSelected = _selectedFilter == filter;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: FilterChip(
                            label: Text(filter),
                            selected: isSelected,
                            onSelected: (_) async {
                              setState(() {
                                _selectedFilter = filter;
                              });
                              await _loadRecords();
                            },
                            backgroundColor: KinsuTheme.background,
                            selectedColor:
                                KinsuTheme.primary.withValues(alpha: 0.1),
                            checkmarkColor: KinsuTheme.primary,
                            labelStyle: TextStyle(
                              color: isSelected
                                  ? KinsuTheme.primary
                                  : KinsuTheme.textPrimary,
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
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      ChoiceChip(
                        label: const Text('All files'),
                        selected: _hasFileFilter == null,
                        onSelected: (_) async {
                          setState(() => _hasFileFilter = null);
                          await _loadRecords();
                        },
                      ),
                      ChoiceChip(
                        label: const Text('With file'),
                        selected: _hasFileFilter == true,
                        onSelected: (_) async {
                          setState(() => _hasFileFilter = true);
                          await _loadRecords();
                        },
                      ),
                      ChoiceChip(
                        label: const Text('No file'),
                        selected: _hasFileFilter == false,
                        onSelected: (_) async {
                          setState(() => _hasFileFilter = false);
                          await _loadRecords();
                        },
                      ),
                      OutlinedButton.icon(
                        onPressed: _pickDateRange,
                        icon:
                            const Icon(Icons.calendar_today_outlined, size: 16),
                        label: Text(_dateRangeLabel()),
                      ),
                      if (_dateRange != null)
                        TextButton(
                          onPressed: () async {
                            setState(() => _dateRange = null);
                            await _loadRecords();
                          },
                          child: const Text('Clear Date'),
                        ),
                      PopupMenuButton<String>(
                        tooltip: 'Sort',
                        onSelected: (value) async {
                          setState(() {
                            if (value == 'latest') {
                              _sortBy = 'record_date';
                              _sortOrder = 'desc';
                            } else if (value == 'oldest') {
                              _sortBy = 'record_date';
                              _sortOrder = 'asc';
                            } else if (value == 'title_az') {
                              _sortBy = 'title';
                              _sortOrder = 'asc';
                            } else if (value == 'recent_uploads') {
                              _sortBy = 'file_uploaded_at';
                              _sortOrder = 'desc';
                            }
                          });
                          await _loadRecords();
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: 'latest',
                            child: Text('Latest First'),
                          ),
                          PopupMenuItem(
                            value: 'oldest',
                            child: Text('Oldest First'),
                          ),
                          PopupMenuItem(
                            value: 'title_az',
                            child: Text('Title A-Z'),
                          ),
                          PopupMenuItem(
                            value: 'recent_uploads',
                            child: Text('Recent Uploads'),
                          ),
                        ],
                        child: Chip(
                          avatar: const Icon(Icons.sort, size: 16),
                          label: Text(_sortLabel()),
                        ),
                      ),
                    ],
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
                              color: KinsuTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              provider.error!,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: KinsuTheme.textSecondary,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: _loadRecords,
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
                              color: KinsuTheme.textSecondary,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No records yet',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: KinsuTheme.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Upload your first health record to get started',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: KinsuTheme.textSecondary,
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

                  return RefreshIndicator(
                    onRefresh: _loadRecords,
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: provider.records.length,
                      itemBuilder: (context, index) {
                        final record = provider.records[index];
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
        border: Border.all(color: KinsuTheme.divider),
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
                          color: KinsuTheme.textPrimary,
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
                            color: KinsuTheme.textSecondary,
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
                              color: KinsuTheme.textSecondary,
                            ),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6),
                            child: Text(
                              '•',
                              style: TextStyle(
                                fontSize: 11,
                                color: KinsuTheme.textSecondary,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: KinsuTheme.background,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              record.recordType,
                              style: const TextStyle(
                                fontSize: 10,
                                color: KinsuTheme.textSecondary,
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
                                  color: KinsuTheme.textSecondary,
                                ),
                              ),
                            ),
                            Text(
                              FileUtils.formatFileSize(record.fileSize!),
                              style: const TextStyle(
                                fontSize: 11,
                                color: KinsuTheme.textSecondary,
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
                  color: KinsuTheme.textSecondary,
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
                downloadFileOnWeb(
                    record.fileUrl!, record.fileName ?? 'download');
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
