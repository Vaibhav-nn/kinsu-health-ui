import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../models/health_record.dart';
import '../services/api_service.dart';
import '../widgets/record_card.dart';
import '../theme/app_theme.dart';
import 'upload_record_screen.dart';

class VaultScreen extends StatefulWidget {
  final ApiService apiService;

  const VaultScreen({
    super.key,
    required this.apiService,
  });

  @override
  State<VaultScreen> createState() => _VaultScreenState();
}

class _VaultScreenState extends State<VaultScreen> {
  List<HealthRecord> _records = [];
  bool _isLoading = false;
  String? _errorMessage;
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadRecords();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadRecords() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final records = await widget.apiService.fetchRecords();
      if (mounted) {
        setState(() {
          _records = records;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load records: $e';
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _navigateToUpload() async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => UploadRecordScreen(
          apiService: widget.apiService,
        ),
      ),
    );

    // Refresh list if upload was successful
    if (result == true) {
      _loadRecords();
    }
  }

  Future<void> _openRecord(HealthRecord record) async {
    // If record has a file, open it in browser/download
    if (record.fileUrl != null) {
      final url = Uri.parse(record.fileUrl!);
      try {
        // For web, this will open in a new tab
        // For mobile, this will download or open with default app
        await launchUrl(url, mode: LaunchMode.platformDefault);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Could not open file: ${record.fileName ?? "unknown"}'),
              action: SnackBarAction(
                label: 'Copy URL',
                onPressed: () {
                  // Could implement clipboard copy here
                },
              ),
            ),
          );
        }
      }
    } else {
      // If no file, show a dialog with record details
      if (mounted) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(record.title),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Type: ${record.recordType}'),
                const SizedBox(height: 8),
                Text('Date: ${record.recordDate.toString().split(' ')[0]}'),
                if (record.notes != null && record.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Notes: ${record.notes}'),
                ],
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header with modern design
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.card,
                  border: Border(
                    bottom: BorderSide(
                      color: AppTheme.border,
                      width: 1,
                    ),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 48, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and action buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Health Vault',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.foreground,
                              ),
                            ),
                            if (!_isLoading && _errorMessage == null) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.muted,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '${_records.length}',
                                  style: const TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.mutedForeground,
                                  ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        SizedBox(
                          width: 36,
                          height: 36,
                          child: IconButton(
                            onPressed: _navigateToUpload,
                            icon: const Icon(Icons.add, size: 16),
                            padding: EdgeInsets.zero,
                            style: IconButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: AppTheme.primaryForeground,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(100),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Search bar
                    Container(
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppTheme.muted,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextField(
                        controller: _searchController,
                        enabled: false, // Non-functional in this iteration
                        decoration: InputDecoration(
                          hintText: 'Search records...',
                          hintStyle: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.mutedForeground,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            size: 15,
                            color: AppTheme.mutedForeground,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppTheme.foreground,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            
            // Content
            if (_isLoading)
              const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: AppTheme.primary,
                  ),
                ),
              )
            else if (_errorMessage != null)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(220, 38, 38, 0.1),
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: const Icon(
                            Icons.error_outline,
                            size: 32,
                            color: AppTheme.destructive,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _errorMessage!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: AppTheme.mutedForeground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _loadRecords,
                          icon: const Icon(Icons.refresh, size: 16),
                          label: const Text('Retry'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.primaryForeground,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else if (_records.isEmpty)
              SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            color: AppTheme.muted,
                            borderRadius: BorderRadius.circular(40),
                          ),
                          child: const Icon(
                            Icons.folder_open_outlined,
                            size: 40,
                            color: AppTheme.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 24),
                        const Text(
                          'No Records Yet',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.foreground,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Upload your first health record to get started',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppTheme.mutedForeground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: _navigateToUpload,
                          icon: const Icon(Icons.add, size: 16),
                          label: const Text('Upload Record'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.primaryForeground,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      if (index < _records.length) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: RecordCard(
                            record: _records[index],
                            onTap: () => _openRecord(_records[index]),
                          ),
                        );
                      }
                      return null;
                    },
                    childCount: _records.length,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
