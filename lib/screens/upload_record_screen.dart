import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../core/theme.dart';
import '../providers/vault_provider.dart';

class UploadRecordScreen extends StatefulWidget {
  const UploadRecordScreen({super.key});

  @override
  State<UploadRecordScreen> createState() => _UploadRecordScreenState();
}

class _UploadRecordScreenState extends State<UploadRecordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _notesController = TextEditingController();

  PlatformFile? _selectedFile;
  String _recordType = 'Lab Report';
  DateTime _recordDate = DateTime.now();
  bool _isUploading = false;

  final List<Map<String, dynamic>> _recordTypes = [
    {
      'label': 'Lab Report',
      'icon': Icons.science_outlined,
      'color': const Color(0xFF3B82F6),
    },
    {
      'label': 'Prescription',
      'icon': Icons.medication_outlined,
      'color': const Color(0xFF10B981),
    },
    {
      'label': 'Imaging',
      'icon': Icons.medical_services_outlined,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'label': 'Discharge Summary',
      'icon': Icons.description_outlined,
      'color': const Color(0xFFF59E0B),
    },
    {
      'label': 'Blood Test',
      'icon': Icons.science_outlined,
      'color': const Color(0xFF3B82F6),
    },
    {
      'label': 'CBC',
      'icon': Icons.science_outlined,
      'color': const Color(0xFF3B82F6),
    },
    {
      'label': 'X-ray',
      'icon': Icons.image_outlined,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'label': 'MRI',
      'icon': Icons.image_outlined,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'label': 'CT Scan',
      'icon': Icons.image_outlined,
      'color': const Color(0xFF8B5CF6),
    },
    {
      'label': 'Vaccination',
      'icon': Icons.vaccines_outlined,
      'color': const Color(0xFF10B981),
    },
    {
      'label': 'Other',
      'icon': Icons.insert_drive_file_outlined,
      'color': KinsuTheme.mutedForeground,
    },
  ];

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          _selectedFile = result.files.first;
          // Auto-fill title if empty
          if (_titleController.text.isEmpty) {
            _titleController.text = _selectedFile!.name
                .replaceAll(RegExp(r'\.[^.]+$'), '')
                .replaceAll('_', ' ')
                .replaceAll('-', ' ');
          }
        });
      }
    } catch (e) {
      _showError('Failed to pick file: $e');
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _recordDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
    );

    if (picked != null) {
      setState(() {
        _recordDate = picked;
      });
    }
  }

  Future<void> _uploadRecord() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFile == null) {
      _showError('Please select a file to upload');
      return;
    }

    setState(() => _isUploading = true);

    final provider = context.read<VaultProvider>();

    // Determine content type
    String contentType = 'application/pdf';
    if (_selectedFile!.name.toLowerCase().endsWith('.jpg') ||
        _selectedFile!.name.toLowerCase().endsWith('.jpeg')) {
      contentType = 'image/jpeg';
    } else if (_selectedFile!.name.toLowerCase().endsWith('.png')) {
      contentType = 'image/png';
    }

    // Upload using direct upload method
    final success = await provider.createRecordWithFile(
      recordType: _recordType,
      recordDate: _recordDate,
      title: _titleController.text,
      notes: _notesController.text.isEmpty ? null : _notesController.text,
      file: _selectedFile!,
    );

    setState(() => _isUploading = false);

    if (success && mounted) {
      Navigator.of(context).pop(true);
    } else if (mounted) {
      _showError(provider.error ?? 'Upload failed');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upload Record'),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Record Type Selection
            const Text(
              'Record Type',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KinsuTheme.foreground,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _recordTypes.map((type) {
                final isSelected = _recordType == type['label'];
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      _recordType = type['label'];
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (type['color'] as Color).withOpacity(0.1)
                          : KinsuTheme.muted,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? (type['color'] as Color)
                            : KinsuTheme.border,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type['icon'],
                          size: 18,
                          color: isSelected
                              ? (type['color'] as Color)
                              : KinsuTheme.mutedForeground,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          type['label'],
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected
                                ? (type['color'] as Color)
                                : KinsuTheme.foreground,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Record Date
            const Text(
              'Record Date',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KinsuTheme.foreground,
              ),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KinsuTheme.muted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KinsuTheme.border),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_today_outlined,
                      size: 20,
                      color: KinsuTheme.primary,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMMM d, y').format(_recordDate),
                      style: const TextStyle(
                        fontSize: 14,
                        color: KinsuTheme.foreground,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Title
            const Text(
              'Title',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KinsuTheme.foreground,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                hintText: 'Enter record title',
                filled: true,
                fillColor: KinsuTheme.muted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: KinsuTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: KinsuTheme.border),
                ),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter a title';
                }
                return null;
              },
            ),

            const SizedBox(height: 24),

            // Notes (Optional)
            const Text(
              'Notes (Optional)',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KinsuTheme.foreground,
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notesController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Add any additional notes...',
                filled: true,
                fillColor: KinsuTheme.muted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: KinsuTheme.border),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: KinsuTheme.border),
                ),
              ),
            ),

            const SizedBox(height: 24),

            // File Upload
            const Text(
              'Document',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: KinsuTheme.foreground,
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedFile == null)
              InkWell(
                onTap: _pickFile,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: KinsuTheme.muted,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: KinsuTheme.border,
                      width: 2,
                      strokeAlign: BorderSide.strokeAlignInside,
                    ),
                  ),
                  child: const Column(
                    children: [
                      Icon(
                        Icons.cloud_upload_outlined,
                        size: 48,
                        color: KinsuTheme.primary,
                      ),
                      SizedBox(height: 12),
                      Text(
                        'Tap to select file',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: KinsuTheme.foreground,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'PDF, JPG, PNG (max 10MB)',
                        style: TextStyle(
                          fontSize: 13,
                          color: KinsuTheme.mutedForeground,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: KinsuTheme.muted,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: KinsuTheme.border),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: KinsuTheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.file_present,
                        color: KinsuTheme.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _selectedFile!.name,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: KinsuTheme.foreground,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatFileSize(_selectedFile!.size),
                            style: const TextStyle(
                              fontSize: 12,
                              color: KinsuTheme.mutedForeground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        setState(() {
                          _selectedFile = null;
                        });
                      },
                      color: KinsuTheme.mutedForeground,
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 32),

            // Upload Button
            ElevatedButton(
              onPressed: _isUploading ? null : _uploadRecord,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _isUploading
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Text(
                      'Upload Record',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
