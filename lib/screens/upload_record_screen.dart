import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
import '../theme/app_theme.dart';

class UploadRecordScreen extends StatefulWidget {
  final ApiService apiService;

  const UploadRecordScreen({
    super.key,
    required this.apiService,
  });

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
      'color': AppTheme.labReportColor,
    },
    {
      'label': 'Prescription',
      'icon': Icons.medical_services_outlined,
      'color': AppTheme.prescriptionColor,
    },
    {
      'label': 'Imaging (X-Ray/CT)',
      'icon': Icons.image_outlined,
      'color': AppTheme.imagingColor,
    },
    {
      'label': 'Discharge Summary',
      'icon': Icons.description_outlined,
      'color': AppTheme.dischargeSummaryColor,
    },
    {
      'label': 'Blood Test',
      'icon': Icons.science_outlined,
      'color': AppTheme.labReportColor,
    },
    {
      'label': 'CBC',
      'icon': Icons.science_outlined,
      'color': AppTheme.labReportColor,
    },
    {
      'label': 'X-ray',
      'icon': Icons.image_outlined,
      'color': AppTheme.imagingColor,
    },
    {
      'label': 'MRI',
      'icon': Icons.image_outlined,
      'color': AppTheme.imagingColor,
    },
    {
      'label': 'CT Scan',
      'icon': Icons.image_outlined,
      'color': AppTheme.imagingColor,
    },
    {
      'label': 'Vaccination',
      'icon': Icons.vaccines_outlined,
      'color': AppTheme.prescriptionColor,
    },
    {
      'label': 'Other',
      'icon': Icons.insert_drive_file_outlined,
      'color': AppTheme.handwrittenColor,
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
        final file = result.files.first;

        // Validate file size (10MB limit)
        if (file.size > 10 * 1024 * 1024) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('File size must be less than 10MB'),
                backgroundColor: Colors.red,
              ),
            );
          }
          return;
        }

        setState(() {
          _selectedFile = file;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
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
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a file to upload'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      // Step 1: Create record
      final recordId = await widget.apiService.createRecord(
        recordType: _recordType,
        recordDate: _recordDate,
        title: _titleController.text.trim(),
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
      );

      // Step 2: Upload file
      await widget.apiService.uploadFile(
        recordId: recordId,
        file: _selectedFile!,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop(true); // Return true to indicate success
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error uploading record: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, size: 16),
          onPressed: () => Navigator.of(context).pop(),
          style: IconButton.styleFrom(
            backgroundColor: AppTheme.muted,
            foregroundColor: AppTheme.foreground,
          ),
        ),
        title: const Text(
          'Upload Record',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppTheme.foreground,
          ),
        ),
        backgroundColor: AppTheme.card,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            color: AppTheme.border,
            height: 1,
          ),
        ),
      ),
      body: _buildUploadForm(dateFormat),
    );
  }

  Widget _buildUploadForm(DateFormat dateFormat) {
    return Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
          // Document Type Selection
          const Text(
            'Document Type',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: AppTheme.foreground,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _recordTypes.map((type) {
              final isSelected = _recordType == type['label'];
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _isUploading ? null : () {
                    setState(() {
                      _recordType = type['label'] as String;
                    });
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: isSelected 
                          ? Color.alphaBlend(
                              (type['color'] as Color).withOpacity(0.1),
                              AppTheme.card,
                            )
                          : AppTheme.card,
                      border: Border.all(
                        color: isSelected 
                            ? type['color'] as Color
                            : AppTheme.border,
                        width: isSelected ? 2 : 1,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          type['icon'] as IconData,
                          size: 16,
                          color: isSelected 
                              ? type['color'] as Color
                              : AppTheme.mutedForeground,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          type['label'] as String,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                            color: isSelected 
                                ? AppTheme.foreground
                                : AppTheme.mutedForeground,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          
            // File picker with modern design
            Container(
              decoration: BoxDecoration(
                color: AppTheme.card,
                border: Border.all(
                  color: AppTheme.border,
                  width: 2,
                  style: BorderStyle.solid,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
            child: Column(
              children: [
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
                    child: Column(
                      children: [
                        Container(
                          width: 64,
                          height: 64,
                          decoration: BoxDecoration(
                            color: _selectedFile != null 
                                ? const Color.fromRGBO(10, 155, 143, 0.1)
                                : AppTheme.muted,
                            borderRadius: BorderRadius.circular(32),
                          ),
                          child: Icon(
                            _selectedFile != null 
                                ? Icons.check_circle 
                                : Icons.upload_file,
                            size: 28,
                            color: _selectedFile != null
                                ? AppTheme.primary
                                : AppTheme.mutedForeground,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _selectedFile != null
                              ? _selectedFile!.name
                              : 'Tap to upload or take a photo',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          color: AppTheme.foreground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _selectedFile != null
                              ? _formatFileSize(_selectedFile!.size)
                              : 'Supports PDF, JPG, PNG (max 10MB)',
                          style: const TextStyle(
                            fontSize: 13,
                            color: AppTheme.mutedForeground,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                // Buttons row
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: _isUploading ? null : _pickFile,
                            icon: const Icon(Icons.folder_open, size: 16),
                            label: const Text('Choose File'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primary,
                              foregroundColor: AppTheme.primaryForeground,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _isUploading ? null : _pickFile, // Camera would go here
                            icon: const Icon(Icons.camera_alt, size: 16),
                            label: const Text('Camera'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.foreground,
                              side: const BorderSide(color: AppTheme.border),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Title field
            TextFormField(
              controller: _titleController,
              decoration: InputDecoration(
                labelText: 'Title',
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.foreground,
                ),
                hintText: 'e.g., Annual Checkup Blood Test',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.mutedForeground,
                ),
                filled: true,
                fillColor: AppTheme.muted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 2,
                  ),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.destructive,
                    width: 1,
                  ),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.destructive,
                    width: 2,
                  ),
                ),
              ),
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.foreground,
              ),
              enabled: !_isUploading,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Please enter a title';
                }
                return null;
                    },
            ),
            const SizedBox(height: 16),
            
            // Date picker
            InkWell(
              onTap: _isUploading ? null : _selectDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                decoration: BoxDecoration(
                  color: AppTheme.muted,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Record Date',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: AppTheme.mutedForeground,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dateFormat.format(_recordDate),
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.foreground,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.calendar_today,
                      size: 18,
                      color: AppTheme.mutedForeground,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Notes field
            TextFormField(
              controller: _notesController,
              decoration: InputDecoration(
                labelText: 'Notes (optional)',
                labelStyle: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.foreground,
                ),
                hintText: 'Add any additional notes...',
                hintStyle: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.mutedForeground,
                ),
                filled: true,
                fillColor: AppTheme.muted,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: AppTheme.primary,
                    width: 2,
                  ),
                ),
                alignLabelWithHint: true,
              ),
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.foreground,
              ),
              maxLines: 4,
              enabled: !_isUploading,
            ),
            const SizedBox(height: 32),
            
            // Upload button
            SizedBox(
              height: 48,
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadRecord,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: AppTheme.primaryForeground,
                  disabledBackgroundColor: AppTheme.muted,
                  disabledForegroundColor: AppTheme.mutedForeground,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            AppTheme.primaryForeground,
                          ),
                        ),
                      )
                    : const Text(
                        'Upload Record',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
      ),
    );
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) {
      return '$bytes B';
    } else if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
  }
}
