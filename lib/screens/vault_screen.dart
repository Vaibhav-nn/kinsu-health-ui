import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:url_launcher/url_launcher.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../models/health_record.dart';
import '../services/api_service.dart';
import '../widgets/record_card.dart';
import '../theme/app_theme.dart';
import '../utils/file_utils.dart';
import 'upload_record_screen.dart';

// Conditional import for web PDF helper
import 'vault_screen_web_helper_stub.dart'
    if (dart.library.html) 'vault_screen_web_helper.dart';

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
    // Show preview modal
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _buildRecordPreview(record),
    );
  }

  Widget _buildRecordPreview(HealthRecord record) {
    final color = AppTheme.getDocumentTypeColor(record.recordType);
    final icon = AppTheme.getDocumentTypeIcon(record.recordType);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            decoration: BoxDecoration(
              color: AppTheme.card,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              border: Border(
                bottom: BorderSide(color: AppTheme.border, width: 1),
              ),
            ),
            child: Column(
              children: [
                // Drag handle
                Container(
                  width: 32,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color.alphaBlend(
                          color.withOpacity(0.1),
                          AppTheme.card,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: AppTheme.muted,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              record.recordType,
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: AppTheme.mutedForeground,
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            record.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, size: 20),
                      onPressed: () => Navigator.pop(context),
                      style: IconButton.styleFrom(
                        backgroundColor: AppTheme.muted,
                        foregroundColor: AppTheme.foreground,
                      ),
                    ),
                  ],
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
                  // Document Preview
                  if (record.fileUrl != null) ...[
                    Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(
                        minHeight: 400,
                        maxHeight: 500,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.card,
                        border: Border.all(color: AppTheme.border),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: _buildDocumentViewer(record),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // Details card
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.card,
                      border: Border.all(color: AppTheme.border),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text(
                              'Details',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.foreground,
                              ),
                            ),
                            const Spacer(),
                            if (record.fileSize != null)
                              Text(
                                FileUtils.formatFileSize(record.fileSize!),
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTheme.mutedForeground,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        _buildDetailRow(
                          Icons.calendar_today,
                          'Date',
                          record.recordDate.toString().split(' ')[0],
                        ),
                        if (record.fileUploadedAt != null) ...[
                          const SizedBox(height: 8),
                          _buildDetailRow(
                            Icons.upload,
                            'Uploaded',
                            record.fileUploadedAt!.toString().split(' ')[0],
                          ),
                        ],
                        if (record.fileName != null) ...[
                const SizedBox(height: 8),
                          _buildDetailRow(
                            Icons.insert_drive_file,
                            'File',
                            record.fileName!,
                          ),
                        ],
                if (record.notes != null && record.notes!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Notes',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.foreground,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            record.notes!,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppTheme.mutedForeground,
                              height: 1.5,
                            ),
                          ),
                ],
              ],
            ),
                  ),
                  const SizedBox(height: 16),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close, size: 16),
                          label: const Text('Close'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.foreground,
                            side: const BorderSide(color: AppTheme.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => _downloadFile(record),
                          icon: const Icon(Icons.download, size: 16),
                          label: const Text('Download'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primary,
                            foregroundColor: AppTheme.primaryForeground,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentViewer(HealthRecord record) {
    if (record.fileUrl == null) {
      return _buildPlaceholder('No file attached', Icons.insert_drive_file);
    }

    // For images, show the actual image
    if (record.isImage) {
      return Image.network(
        record.fileUrl!,
        fit: BoxFit.contain,
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Center(
            child: CircularProgressIndicator(
              value: loadingProgress.expectedTotalBytes != null
                  ? loadingProgress.cumulativeBytesLoaded /
                      loadingProgress.expectedTotalBytes!
                  : null,
              color: AppTheme.primary,
            ),
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return _buildPlaceholder('Failed to load image', Icons.error_outline);
        },
      );
    }

    // For PDFs
    if (record.isPdf) {
      if (kIsWeb) {
        // Web: Use iframe which is more reliable
        final viewId = 'pdf-${record.id}';
        WebPdfViewerHelper.registerPdfViewer(viewId, record.fileUrl!);
        
        return HtmlElementView(
          viewType: viewId,
        );
      } else {
        // iOS/Android: Use Syncfusion PDF Viewer
        return Container(
          color: AppTheme.background,
          child: SfPdfViewer.network(
            record.fileUrl!,
            canShowScrollHead: true,
            canShowScrollStatus: true,
            enableDoubleTapZooming: true,
            enableTextSelection: true,
            onDocumentLoadFailed: (details) {
              print('PDF load failed: ${details.error}');
            },
          ),
        );
      }
    }

    // For other file types
    return _buildPlaceholder(
      'Preview not available for this file type',
      Icons.insert_drive_file,
    );
  }

  Widget _buildPlaceholder(String message, IconData icon) {
    return Container(
      color: AppTheme.background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 64,
            color: AppTheme.mutedForeground.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(
              fontSize: 14,
              color: AppTheme.mutedForeground,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppTheme.mutedForeground),
        const SizedBox(width: 8),
        Text(
          '$label:',
          style: const TextStyle(
            fontSize: 13,
            color: AppTheme.mutedForeground,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.foreground,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _downloadFile(HealthRecord record) async {
    if (record.fileUrl == null) return;

    final url = Uri.parse(record.fileUrl!);
    try {
      // Use externalApplication mode to force download/open in external app
      await launchUrl(url, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Downloading ${record.fileName ?? "file"}...'),
            backgroundColor: AppTheme.primary,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not download file: ${record.fileName ?? "unknown"}'),
            backgroundColor: AppTheme.destructive,
            action: SnackBarAction(
              label: 'OK',
              textColor: AppTheme.destructiveForeground,
              onPressed: () {},
            ),
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
