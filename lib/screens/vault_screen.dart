import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../core/theme.dart';
import '../models/health_record.dart';
import '../providers/vault_provider.dart';
import '../widgets/kinsu_widgets.dart';
import '../widgets/shimmer_placeholders.dart';
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
    final type = _selectedFilter == 'All' ? null : _selectedFilter;
    await context.read<VaultProvider>().loadRecords(
          recordType: type,
          query: _searchController.text.trim().isEmpty
              ? null
              : _searchController.text.trim(),
          sortBy: _sortBy,
          sortOrder: _sortOrder,
        );
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) return;
      _loadRecords();
    });
  }

  Future<void> _navigateToUpload() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(builder: (context) => const UploadRecordScreen()),
    );
    if (result == true && mounted) {
      await _loadRecords();
    }
  }

  void _showFilterSheet() {
    String tempSort = _sortOrder == 'asc' ? 'Oldest' : 'Newest';
    String tempFilter = _selectedFilter;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx2, setLocal) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const KinsuDragHandle(),
              const SizedBox(height: 16),
              const Text(
                'Filter Records',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 12),
              const Text(
                'Category',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: KinsuTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  'All',
                  'Lab Report',
                  'Prescription',
                  'Imaging',
                  'Discharge Summary',
                ].map((f) {
                  final sel = tempFilter == f;
                  return FilterChip(
                    label: Text(f),
                    selected: sel,
                    onSelected: (_) => setLocal(() => tempFilter = f),
                    selectedColor: KinsuTheme.primaryLight,
                    checkmarkColor: KinsuTheme.primary,
                    labelStyle: TextStyle(
                      color: sel ? KinsuTheme.primary : KinsuTheme.textPrimary,
                      fontSize: 13,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              const Text(
                'Sort',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: KinsuTheme.textSecondary,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: ['Newest', 'Oldest', 'Title A-Z'].map((s) {
                  final sel = tempSort == s;
                  return FilterChip(
                    label: Text(s),
                    selected: sel,
                    onSelected: (_) => setLocal(() => tempSort = s),
                    selectedColor: KinsuTheme.primaryLight,
                    checkmarkColor: KinsuTheme.primary,
                    labelStyle: TextStyle(
                      color: sel ? KinsuTheme.primary : KinsuTheme.textPrimary,
                      fontSize: 13,
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setLocal(() {
                          tempFilter = 'All';
                          tempSort = 'Newest';
                        });
                      },
                      child: const Text('Clear all'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _selectedFilter = tempFilter;
                          if (tempSort == 'Oldest') {
                            _sortBy = 'record_date';
                            _sortOrder = 'asc';
                          } else if (tempSort == 'Title A-Z') {
                            _sortBy = 'title';
                            _sortOrder = 'asc';
                          } else {
                            _sortBy = 'record_date';
                            _sortOrder = 'desc';
                          }
                        });
                        Navigator.pop(ctx2);
                        _loadRecords();
                      },
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAbhaSheet() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const KinsuDragHandle(),
            const SizedBox(height: 16),
            const Text(
              'ABHA Linking',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 16, color: Color(0xFFB45309)),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Link your ABHA number to sync your health records from government hospitals. Coming soon.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF92400E)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: KinsuTheme.cardDecoration,
              child: const Row(
                children: [
                  Icon(Icons.account_balance_outlined,
                      color: KinsuTheme.textSecondary),
                  SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Not linked yet',
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: KinsuTheme.textPrimary,
                          ),
                        ),
                        Text(
                          'ABHA (Ayushman Bharat Health Account)',
                          style: TextStyle(
                            fontSize: 12,
                            color: KinsuTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Got it'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _openRecord(HealthRecord record) async {
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
      constraints:
          BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 12),
            child: KinsuDragHandle(),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
              border:
                  Border(bottom: BorderSide(color: KinsuTheme.divider, width: 1)),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(record.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: KinsuTheme.textPrimary,
                          )),
                      const SizedBox(height: 2),
                      Text(record.recordType,
                          style: const TextStyle(
                            fontSize: 13,
                            color: KinsuTheme.textSecondary,
                          )),
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
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (record.notes != null && record.notes!.isNotEmpty) ...[
                    const Text('Notes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: KinsuTheme.textPrimary,
                        )),
                    const SizedBox(height: 8),
                    Text(record.notes!,
                        style: const TextStyle(
                          fontSize: 14,
                          color: KinsuTheme.textSecondary,
                        )),
                    const SizedBox(height: 20),
                  ],
                  if (record.fileUrl != null) ...[
                    const Text('Document',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: KinsuTheme.textPrimary,
                        )),
                    const SizedBox(height: 12),
                    _buildFilePreview(record),
                  ],
                ],
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border:
                  Border(top: BorderSide(color: KinsuTheme.divider, width: 1)),
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
                        padding: const EdgeInsets.symmetric(vertical: 14)),
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
                        padding: const EdgeInsets.symmetric(vertical: 14)),
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
    if (record.fileUrl == null) return const SizedBox.shrink();
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
          child: SfPdfViewer.network(record.fileUrl!,
              enableDoubleTapZooming: false, enableTextSelection: false),
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
          child: Image.network(record.fileUrl!,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline,
                            size: 48, color: KinsuTheme.textSecondary),
                        SizedBox(height: 8),
                        Text('Failed to load image',
                            style:
                                TextStyle(color: KinsuTheme.textSecondary)),
                      ],
                    ),
                  )),
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
      MaterialPageRoute(builder: (_) => _FullScreenViewer(record: record)),
    );
  }

  Color _getDocumentTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'lab':
      case 'lab report':
        return const Color(0xFF3B82F6);
      case 'prescription':
        return const Color(0xFF10B981);
      case 'scan':
      case 'imaging':
        return const Color(0xFF8B5CF6);
      case 'discharge':
      case 'discharge summary':
        return const Color(0xFFF59E0B);
      default:
        return KinsuTheme.primary;
    }
  }

  IconData _getDocumentTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'lab':
      case 'lab report':
        return Icons.science_outlined;
      case 'prescription':
        return Icons.medical_services_outlined;
      case 'scan':
      case 'imaging':
        return Icons.image_outlined;
      case 'discharge':
      case 'discharge summary':
        return Icons.description_outlined;
      default:
        return Icons.folder_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inDays == 0) return 'Today';
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: KinsuTheme.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Health Vault',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: KinsuTheme.textPrimary,
                              ),
                            ),
                            SizedBox(height: 2),
                            Text(
                              'Your medical records, secure & organised',
                              style: TextStyle(
                                fontSize: 12,
                                color: KinsuTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.tune, size: 20),
                        onPressed: _showFilterSheet,
                        color: KinsuTheme.textPrimary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.account_balance, size: 20),
                        onPressed: _showAbhaSheet,
                        color: KinsuTheme.textPrimary,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(
                          minWidth: 36,
                          minHeight: 36,
                        ),
                      ),
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: KinsuTheme.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: IconButton(
                          icon: const Icon(Icons.upload_outlined,
                              size: 18, color: Colors.white),
                          onPressed: _navigateToUpload,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Search bar
                  TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Search records, labs, doctors…',
                      hintStyle: const TextStyle(
                          color: KinsuTheme.textSecondary, fontSize: 14),
                      prefixIcon:
                          const Icon(Icons.search, size: 20, color: KinsuTheme.textSecondary),
                      filled: true,
                      fillColor: KinsuTheme.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  // Category filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        'All',
                        'Lab Reports',
                        'Prescriptions',
                        'Imaging',
                        'Summaries',
                      ].map((f) {
                        final isSelected = _selectedFilter == f ||
                            (_selectedFilter == 'All' && f == 'All') ||
                            (_selectedFilter == 'Lab Report' &&
                                f == 'Lab Reports') ||
                            (_selectedFilter == 'Prescription' &&
                                f == 'Prescriptions') ||
                            (_selectedFilter == 'Imaging' && f == 'Imaging') ||
                            (_selectedFilter == 'Discharge Summary' &&
                                f == 'Summaries');
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                if (f == 'All') {
                                  _selectedFilter = 'All';
                                } else if (f == 'Lab Reports') {
                                  _selectedFilter = 'Lab Report';
                                } else if (f == 'Prescriptions') {
                                  _selectedFilter = 'Prescription';
                                } else if (f == 'Summaries') {
                                  _selectedFilter = 'Discharge Summary';
                                } else {
                                  _selectedFilter = f;
                                }
                              });
                              _loadRecords();
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 7),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? KinsuTheme.primaryLight
                                    : KinsuTheme.background,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: isSelected
                                      ? KinsuTheme.primary
                                      : KinsuTheme.divider,
                                ),
                              ),
                              child: Text(
                                f,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w600
                                      : FontWeight.w400,
                                  color: isSelected
                                      ? KinsuTheme.primary
                                      : KinsuTheme.textPrimary,
                                ),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 1,
                    color: KinsuTheme.divider,
                  ),
                ],
              ),
            ),

            // ── Body ─────────────────────────────────────────────────
            Expanded(
              child: Consumer<VaultProvider>(
                builder: (context, provider, _) {
                  if (provider.isLoading) {
                    return const ShimmerCardList(count: 5);
                  }

                  if (provider.error != null) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                size: 64, color: KinsuTheme.textSecondary),
                            const SizedBox(height: 16),
                            Text(provider.error!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: KinsuTheme.textSecondary)),
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

                  final records = provider.records;

                  return RefreshIndicator(
                    onRefresh: _loadRecords,
                    child: ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        // Quick links row
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const _LabTrendsStub()),
                                  );
                                },
                                icon: const Icon(Icons.show_chart_rounded,
                                    size: 16),
                                label: const Text('Lab Trends'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _showAbhaSheet,
                                icon: const Icon(Icons.account_balance,
                                    size: 16),
                                label: const Text('ABHA'),
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 12),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),

                        // Record count
                        Text(
                          '${records.length} record${records.length == 1 ? '' : 's'}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: KinsuTheme.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Records list or empty state
                        if (records.isEmpty)
                          Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  const Icon(Icons.folder_outlined,
                                      size: 64,
                                      color: KinsuTheme.textSecondary),
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
                                        color: KinsuTheme.textSecondary),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: _navigateToUpload,
                                    icon: const Icon(Icons.upload),
                                    label: const Text('Upload Record'),
                                  ),
                                ],
                              ),
                            ),
                          )
                        else
                          ...records.map((record) => Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: _buildRecordCard(record),
                              )),
                      ],
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
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
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
                          fontWeight: FontWeight.w600,
                          color: KinsuTheme.textPrimary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (record.notes != null &&
                          record.notes!.isNotEmpty) ...[
                        const SizedBox(height: 2),
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
                      const SizedBox(height: 6),
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
                            child: Text('•',
                                style: TextStyle(
                                    fontSize: 11,
                                    color: KinsuTheme.textSecondary)),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: color.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              record.recordType,
                              style: TextStyle(
                                fontSize: 10,
                                color: color,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (record.fileSize != null) ...[
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 6),
                              child: Text('•',
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: KinsuTheme.textSecondary)),
                            ),
                            Text(
                              FileUtils.formatFileSize(record.fileSize!),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: KinsuTheme.textSecondary),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right,
                    size: 16, color: KinsuTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Stub screen for Lab Trends (navigated to from quick link)
class _LabTrendsStub extends StatelessWidget {
  const _LabTrendsStub();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lab Trends')),
      body: const Center(child: Text('Lab Trends coming soon')),
    );
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
              child: Center(child: Image.network(record.fileUrl!))),
    );
  }
}
