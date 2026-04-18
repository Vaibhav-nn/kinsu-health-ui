import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:kinsu_health/widgets/ios_back_button.dart';
import 'package:provider/provider.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/router.dart';
import '../core/theme.dart';
import '../models/health_record.dart';
import '../models/vault_models.dart';
import '../providers/family_provider.dart';
import '../providers/vault_provider.dart';

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

  String _selectedRecordType = 'all';
  bool? _hasFileFilter;
  DateTimeRange? _dateRange;
  String _sortBy = 'record_date';
  String _sortOrder = 'desc';
  String? _selectedProviderName;
  String? _selectedTag;

  static const List<_RecordTypeFilter> _recordTypes = [
    _RecordTypeFilter('all', 'All'),
    _RecordTypeFilter('lab_report', 'Lab Reports'),
    _RecordTypeFilter('prescription', 'Prescriptions'),
    _RecordTypeFilter('imaging', 'Imaging'),
    _RecordTypeFilter('discharge_summary', 'Discharge Summary'),
  ];

  static const List<_QuickLabParameter> _labParameters = [
    _QuickLabParameter('hemoglobin', 'Hemoglobin'),
    _QuickLabParameter('rbc', 'RBC'),
    _QuickLabParameter('wbc', 'WBC'),
    _QuickLabParameter('hba1c', 'HbA1c'),
    _QuickLabParameter('tsh', 'TSH'),
  ];

  static const List<String> _fallbackHospitals = [
    'Apollo Hospital',
    'Max Diagnostics',
    'Fortis Hospital',
    'SRL Diagnostics',
    'Medanta Hospital',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadVaultData();
    });
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadVaultData() async {
    final provider = context.read<VaultProvider>();
    await Future.wait([
      provider.loadRecords(
        recordType: _selectedRecordType == 'all' ? null : _selectedRecordType,
        providerName: _selectedProviderName,
        tag: _selectedTag,
        query: _trimmedQuery,
        startDate: _dateRange?.start,
        endDate: _dateRange?.end,
        hasFile: _hasFileFilter,
        sortBy: _sortBy,
        sortOrder: _sortOrder,
      ),
      provider.loadConnectedServices(),
    ]);
  }

  Future<void> _loadRecordsOnly() async {
    await context.read<VaultProvider>().loadRecords(
          recordType: _selectedRecordType == 'all' ? null : _selectedRecordType,
          providerName: _selectedProviderName,
          tag: _selectedTag,
          query: _trimmedQuery,
          startDate: _dateRange?.start,
          endDate: _dateRange?.end,
          hasFile: _hasFileFilter,
          sortBy: _sortBy,
          sortOrder: _sortOrder,
        );
  }

  String? get _trimmedQuery {
    final value = _searchController.text.trim();
    return value.isEmpty ? null : value;
  }

  void _onSearchChanged(String _) {
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      if (!mounted) {
        return;
      }
      _loadRecordsOnly();
    });
  }

  Future<void> _navigateToUpload() async {
    final result = await context.push<bool>(KinsuRoutes.vaultUpload);
    if (result == true && mounted) {
      await _loadVaultData();
    }
  }

  Future<void> _openRecord(HealthRecord record) async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRecordPreview(record),
    );
  }

  Future<void> _openLabTrend([String parameterKey = 'hemoglobin']) async {
    await context.push('/vault/lab/$parameterKey');
  }

  Future<void> _showConnectedServicesSheet() async {
    final provider = context.read<VaultProvider>();
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Connected Services',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Hospitals, labs and radiology centers linked via your vault.',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                if (provider.isLoadingServices)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  )
                else if (provider.servicesError != null)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      provider.servicesError!,
                      style: const TextStyle(color: KinsuTheme.textSecondary),
                    ),
                  )
                else if (provider.connectedServices.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: Text(
                      'No connected providers yet.',
                      style: TextStyle(color: KinsuTheme.textSecondary),
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: provider.connectedServices.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final service = provider.connectedServices[index];
                        return _ConnectedServiceTile(service: service);
                      },
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showAdvancedFilters() async {
    final familyProvider = context.read<FamilyProvider>();
    String tempRecordType = _selectedRecordType;
    bool? tempHasFile = _hasFileFilter;
    DateTimeRange? tempDateRange = _dateRange;
    String tempSortBy = _sortBy;
    String tempSortOrder = _sortOrder;
    String? tempProviderName = _selectedProviderName;
    String? tempTag = _selectedTag;
    int? tempProfileId = familyProvider.activeFamilyProfileId;

    DateTimeRange? dateRangeForPreset(String preset) {
      final now = DateTime.now();
      switch (preset) {
        case 'Last 7 days':
          return DateTimeRange(
            start: now.subtract(const Duration(days: 6)),
            end: now,
          );
        case 'Last 30 days':
          return DateTimeRange(
            start: now.subtract(const Duration(days: 29)),
            end: now,
          );
        case 'Last 3 months':
          return DateTimeRange(
            start: now.subtract(const Duration(days: 89)),
            end: now,
          );
        case 'Last year':
          return DateTimeRange(
            start: DateTime(now.year - 1, now.month, now.day),
            end: now,
          );
        default:
          return null;
      }
    }

    final hospitalOptions =
        _hospitalOptions(context.read<VaultProvider>().records);

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            Widget sectionTitle(String title) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              );
            }

            bool presetMatches(String preset) {
              if (preset == 'All time') {
                return tempDateRange == null;
              }
              final range = dateRangeForPreset(preset);
              return range != null &&
                  tempDateRange != null &&
                  range.start.year == tempDateRange!.start.year &&
                  range.start.month == tempDateRange!.start.month &&
                  range.start.day == tempDateRange!.start.day;
            }

            return Container(
              height: MediaQuery.of(context).size.height * 0.82,
              decoration: BoxDecoration(
                color: Theme.of(context).scaffoldBackgroundColor,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Advanced Filters',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 24),
                    Expanded(
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        children: [
                          sectionTitle('Document Type'),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _recordTypes
                                .where((item) => item.value != 'all')
                                .map(
                                  (item) => ChoiceChip(
                                    label: Text(item.label),
                                    selected: tempRecordType == item.value,
                                    onSelected: (_) => setModalState(() {
                                      tempRecordType = item.value;
                                    }),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                          sectionTitle('Patient'),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: familyProvider.profiles
                                .map(
                                  (profile) => ChoiceChip(
                                    label: Text(profile.displayName),
                                    selected: (profile.profileId ?? -1) ==
                                        (tempProfileId ?? -1),
                                    onSelected: (_) => setModalState(() {
                                      tempProfileId = profile.profileId;
                                    }),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                          sectionTitle('Hospital'),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: hospitalOptions
                                .map(
                                  (name) => ChoiceChip(
                                    label: Text(name),
                                    selected: tempProviderName == name,
                                    onSelected: (_) => setModalState(() {
                                      tempProviderName =
                                          tempProviderName == name
                                              ? null
                                              : name;
                                    }),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                          sectionTitle('Timeframe'),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: const [
                              'Last 7 days',
                              'Last 30 days',
                              'Last 3 months',
                              'Last year',
                              'All time',
                            ]
                                .map(
                                  (preset) => ChoiceChip(
                                    label: Text(preset),
                                    selected: presetMatches(preset),
                                    onSelected: (_) => setModalState(() {
                                      tempDateRange = preset == 'All time'
                                          ? null
                                          : dateRangeForPreset(preset);
                                    }),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                          sectionTitle('Lab Parameters'),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: _labParameters
                                .map(
                                  (item) => ChoiceChip(
                                    label: Text(item.label),
                                    selected: tempTag == item.label,
                                    onSelected: (_) => setModalState(() {
                                      tempTag = tempTag == item.label
                                          ? null
                                          : item.label;
                                    }),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 20),
                          sectionTitle('File Availability'),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              ChoiceChip(
                                label: const Text('All files'),
                                selected: tempHasFile == null,
                                onSelected: (_) => setModalState(() {
                                  tempHasFile = null;
                                }),
                              ),
                              ChoiceChip(
                                label: const Text('With file'),
                                selected: tempHasFile == true,
                                onSelected: (_) => setModalState(() {
                                  tempHasFile = true;
                                }),
                              ),
                              ChoiceChip(
                                label: const Text('No file'),
                                selected: tempHasFile == false,
                                onSelected: (_) => setModalState(() {
                                  tempHasFile = false;
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          sectionTitle('Sort'),
                          Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _sortChip(
                                label: 'Latest First',
                                selected: tempSortBy == 'record_date' &&
                                    tempSortOrder == 'desc',
                                onTap: () => setModalState(() {
                                  tempSortBy = 'record_date';
                                  tempSortOrder = 'desc';
                                }),
                              ),
                              _sortChip(
                                label: 'Oldest First',
                                selected: tempSortBy == 'record_date' &&
                                    tempSortOrder == 'asc',
                                onTap: () => setModalState(() {
                                  tempSortBy = 'record_date';
                                  tempSortOrder = 'asc';
                                }),
                              ),
                              _sortChip(
                                label: 'Recent Uploads',
                                selected: tempSortBy == 'file_uploaded_at',
                                onTap: () => setModalState(() {
                                  tempSortBy = 'file_uploaded_at';
                                  tempSortOrder = 'desc';
                                }),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                                setState(() {
                                  _selectedRecordType = 'all';
                                  _hasFileFilter = null;
                                  _dateRange = null;
                                  _sortBy = 'record_date';
                                  _sortOrder = 'desc';
                                  _selectedProviderName = null;
                                  _selectedTag = null;
                                });
                                familyProvider.setActiveProfileId(null);
                                _loadVaultData();
                              },
                              child: const Text('Clear All'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () async {
                                Navigator.of(context).pop();
                                setState(() {
                                  _selectedRecordType = tempRecordType;
                                  _hasFileFilter = tempHasFile;
                                  _dateRange = tempDateRange;
                                  _sortBy = tempSortBy;
                                  _sortOrder = tempSortOrder;
                                  _selectedProviderName = tempProviderName;
                                  _selectedTag = tempTag;
                                });
                                familyProvider
                                    .setActiveProfileId(tempProfileId);
                                await _loadVaultData();
                              },
                              child: const Text('Apply Filters'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _sortChip({
    required String label,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onTap(),
    );
  }

  List<String> _hospitalOptions(List<HealthRecord> records) {
    final fromRecords = records
        .map((item) => item.providerName?.trim())
        .whereType<String>()
        .where((item) => item.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    if (fromRecords.isNotEmpty) {
      return fromRecords;
    }
    return _fallbackHospitals;
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
    if (_sortBy == 'file_uploaded_at') {
      return 'Recent Uploads';
    }
    if (_sortOrder == 'asc') {
      return 'Oldest First';
    }
    return 'Latest First';
  }

  Color _recordColor(HealthRecord record) {
    switch (record.normalizedType) {
      case 'lab_report':
        return KinsuTheme.primary;
      case 'prescription':
        return const Color(0xFF3B82F6);
      case 'imaging':
        return const Color(0xFF8B5CF6);
      case 'discharge_summary':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFEA580C);
    }
  }

  IconData _recordIcon(HealthRecord record) {
    switch (record.normalizedType) {
      case 'lab_report':
        return Icons.science_outlined;
      case 'prescription':
        return Icons.medical_services_outlined;
      case 'imaging':
        return Icons.image_outlined;
      case 'discharge_summary':
        return Icons.description_outlined;
      default:
        return Icons.note_alt_outlined;
    }
  }

  Widget _buildRecordPreview(HealthRecord record) {
    final color = _recordColor(record);
    final icon = _recordIcon(record);

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
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: KinsuTheme.divider,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            decoration: const BoxDecoration(
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
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
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
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        record.providerName ?? record.displayRecordType,
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
                  _PreviewMetaRow(
                    label: 'Type',
                    value: record.displayRecordType,
                  ),
                  if (record.displayDocumentSubtype != null)
                    _PreviewMetaRow(
                      label: 'Subtype',
                      value: record.displayDocumentSubtype!,
                    ),
                  _PreviewMetaRow(
                    label: 'Date',
                    value: MaterialLocalizations.of(context)
                        .formatMediumDate(record.recordDate),
                  ),
                  if (record.providerName != null &&
                      record.providerName!.trim().isNotEmpty)
                    _PreviewMetaRow(
                      label: 'Provider',
                      value: record.providerName!,
                    ),
                  if (record.tags.isNotEmpty) ...[
                    const Text(
                      'Tags',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: record.tags
                          .map((tag) => _MetaChip(label: tag))
                          .toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                  if (record.notes != null &&
                      record.notes!.trim().isNotEmpty) ...[
                    const Text(
                      'Notes',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
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
                  if (record.fileUrl != null) ...[
                    const Text(
                      'Document',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

    if (record.isPdf) {
      return Container(
        height: 400,
        decoration: BoxDecoration(
          color: KinsuTheme.background,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: KinsuTheme.divider),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(14),
          child: SfPdfViewer.network(
            record.fileUrl!,
            enableDoubleTapZooming: false,
            enableTextSelection: false,
          ),
        ),
      );
    }

    return Container(
      height: 300,
      decoration: BoxDecoration(
        color: KinsuTheme.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: KinsuTheme.divider),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          record.fileUrl!,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    size: 48,
                    color: KinsuTheme.textSecondary,
                  ),
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

  Future<void> _downloadFile(HealthRecord record) async {
    if (record.fileUrl == null) {
      return;
    }

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
    if (record.fileUrl == null) {
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => _FullScreenViewer(record: record),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final familyProvider = context.watch<FamilyProvider>();

    return Scaffold(
      backgroundColor: KinsuTheme.background,
      body: SafeArea(
        child: Consumer<VaultProvider>(
          builder: (context, provider, _) {
            final selectedProfile = familyProvider.activeDashboardCard;
            final recordCount = provider.records.length;

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Expanded(
                            child: Text(
                              'Health Vault',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          _VaultCircleButton(
                            icon: Icons.receipt_long_outlined,
                            onTap: _showConnectedServicesSheet,
                          ),
                          const SizedBox(width: 10),
                          _VaultCircleButton(
                            icon: Icons.add,
                            filled: true,
                            onTap: _navigateToUpload,
                          ),
                        ],
                      ),
                      if (selectedProfile != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          selectedProfile.isSelf
                              ? 'Showing your records'
                              : "Showing ${selectedProfile.displayName}'s records",
                          style: const TextStyle(
                            color: KinsuTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              onChanged: _onSearchChanged,
                              decoration: InputDecoration(
                                hintText: 'Search records...',
                                prefixIcon: const Icon(Icons.search, size: 22),
                                suffixIcon: _trimmedQuery == null
                                    ? null
                                    : IconButton(
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {});
                                          _loadRecordsOnly();
                                        },
                                        icon: const Icon(Icons.close),
                                      ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          _VaultCircleButton(
                            icon: Icons.tune,
                            onTap: _showAdvancedFilters,
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        height: 42,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _recordTypes.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 8),
                          itemBuilder: (context, index) {
                            final type = _recordTypes[index];
                            return ChoiceChip(
                              label: Text(type.label),
                              selected: _selectedRecordType == type.value,
                              onSelected: (_) async {
                                setState(() {
                                  _selectedRecordType = type.value;
                                });
                                await _loadRecordsOnly();
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            label: const Text('All files'),
                            selected: _hasFileFilter == null,
                            onSelected: (_) async {
                              setState(() => _hasFileFilter = null);
                              await _loadRecordsOnly();
                            },
                          ),
                          ChoiceChip(
                            label: const Text('With file'),
                            selected: _hasFileFilter == true,
                            onSelected: (_) async {
                              setState(() => _hasFileFilter = true);
                              await _loadRecordsOnly();
                            },
                          ),
                          ChoiceChip(
                            label: const Text('No file'),
                            selected: _hasFileFilter == false,
                            onSelected: (_) async {
                              setState(() => _hasFileFilter = false);
                              await _loadRecordsOnly();
                            },
                          ),
                          Chip(
                            avatar: const Icon(
                              Icons.calendar_today_outlined,
                              size: 16,
                            ),
                            label: Text(_dateRangeLabel()),
                          ),
                          Chip(
                            avatar: const Icon(Icons.sort, size: 16),
                            label: Text(_sortLabel()),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _loadVaultData,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _VaultShortcutCard(
                                icon: Icons.show_chart,
                                title: 'Lab Trends',
                                color: KinsuTheme.primary,
                                onTap: _openLabTrend,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _VaultShortcutCard(
                                icon: Icons.medical_services_outlined,
                                title: 'Prescriptions',
                                color: const Color(0xFF3B82F6),
                                onTap: () async {
                                  setState(() {
                                    _selectedRecordType = 'prescription';
                                  });
                                  await _loadRecordsOnly();
                                },
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          '$recordCount record${recordCount == 1 ? '' : 's'}',
                          style: const TextStyle(
                            color: KinsuTheme.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (provider.isLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 40),
                            child: Center(child: CircularProgressIndicator()),
                          )
                        else if (provider.error != null)
                          _VaultStateCard(
                            icon: Icons.error_outline,
                            title: 'Unable to load vault',
                            message: provider.error!,
                            actionLabel: 'Retry',
                            onTap: _loadVaultData,
                          )
                        else if (provider.records.isEmpty)
                          _VaultStateCard(
                            icon: Icons.folder_open_outlined,
                            title: 'No records match these filters',
                            message:
                                'Try changing filters or upload a new record to populate your vault.',
                            actionLabel: 'Upload Record',
                            onTap: _navigateToUpload,
                          )
                        else
                          ...provider.records.map(
                            (record) => Padding(
                              padding: const EdgeInsets.only(bottom: 14),
                              child: _VaultRecordCard(
                                record: record,
                                color: _recordColor(record),
                                icon: _recordIcon(record),
                                onTap: () => _openRecord(record),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _RecordTypeFilter {
  final String value;
  final String label;

  const _RecordTypeFilter(this.value, this.label);
}

class _QuickLabParameter {
  final String key;
  final String label;

  const _QuickLabParameter(this.key, this.label);
}

class _VaultCircleButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool filled;

  const _VaultCircleButton({
    required this.icon,
    required this.onTap,
    this.filled = false,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: filled ? KinsuTheme.primary : const Color(0xFFF3F4F6),
          shape: BoxShape.circle,
          border: filled ? null : Border.all(color: const Color(0xFFF3F4F6)),
        ),
        child: Icon(
          icon,
          color: filled ? Colors.white : KinsuTheme.textSecondary,
        ),
      ),
    );
  }
}

class _VaultShortcutCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _VaultShortcutCard({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
          decoration: KinsuTheme.cardDecoration,
          child: Row(
            children: [
              Icon(icon, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _VaultStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onTap;

  const _VaultStateCard({
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Icon(icon, size: 54, color: KinsuTheme.textSecondary),
          const SizedBox(height: 14),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: KinsuTheme.textSecondary,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 18),
          ElevatedButton.icon(
            onPressed: onTap,
            icon: const Icon(Icons.refresh),
            label: Text(actionLabel),
          ),
        ],
      ),
    );
  }
}

class _VaultRecordCard extends StatelessWidget {
  final HealthRecord record;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _VaultRecordCard({
    required this.record,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final chips = <String>[
      if (record.displayDocumentSubtype != null) record.displayDocumentSubtype!,
      ...record.tags.take(2),
    ];

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: KinsuTheme.cardDecoration,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      record.providerName ?? record.displayRecordType,
                      style: const TextStyle(
                        color: KinsuTheme.textSecondary,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 10,
                      runSpacing: 10,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          MaterialLocalizations.of(context)
                              .formatMediumDate(record.recordDate),
                          style: const TextStyle(
                            color: KinsuTheme.textSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        ...chips.map((chip) => _MetaChip(label: chip)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              const Icon(
                Icons.chevron_right,
                color: KinsuTheme.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: KinsuTheme.textSecondary,
          fontSize: 13,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PreviewMetaRow extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewMetaRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 72,
            child: Text(
              label,
              style: const TextStyle(
                color: KinsuTheme.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectedServiceTile extends StatelessWidget {
  final VaultConnectedService service;

  const _ConnectedServiceTile({required this.service});

  Color _statusColor() {
    switch (service.status.toLowerCase()) {
      case 'active':
        return KinsuTheme.statusActive;
      case 'pending':
        return const Color(0xFFF59E0B);
      default:
        return KinsuTheme.textSecondary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor();
    final syncedLabel = service.syncedAt == null
        ? 'Synced Never'
        : 'Synced ${MaterialLocalizations.of(context).formatShortDate(service.syncedAt!)}';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: KinsuTheme.cardDecoration,
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(Icons.apartment_outlined, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  service.providerName,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${service.providerType} · ${service.recordCount} records · $syncedLabel',
                  style: const TextStyle(
                    color: KinsuTheme.textSecondary,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              service.status[0].toUpperCase() + service.status.substring(1),
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FullScreenViewer extends StatelessWidget {
  final HealthRecord record;

  const _FullScreenViewer({required this.record});

  @override
  Widget build(BuildContext context) {
    if (record.fileUrl == null) {
      return const Scaffold(
        body: Center(child: Text('No file attached.')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: const IosBackButton(),
        automaticallyImplyLeading: false,
        title: Text(record.title),
      ),
      body: record.isPdf
          ? SfPdfViewer.network(record.fileUrl!)
          : InteractiveViewer(
              child: Center(
                child: Image.network(record.fileUrl!),
              ),
            ),
    );
  }
}
