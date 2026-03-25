import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/health_record.dart';
import '../services/vault_service.dart';

class VaultProvider extends ChangeNotifier {
  final VaultService _service;

  VaultProvider(this._service);

  List<HealthRecord> _records = [];
  List<HealthRecord> get records => _records;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  /// Load health records with optional server-side filters.
  Future<void> loadRecords({
    String? recordType,
    String? query,
    DateTime? startDate,
    DateTime? endDate,
    bool? hasFile,
    String sortBy = 'record_date',
    String sortOrder = 'desc',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _records = await _service.fetchRecords(
        recordType: recordType,
        query: query,
        startDate: startDate,
        endDate: endDate,
        hasFile: hasFile,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } catch (e) {
      _error = _parseError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Create a new record with file upload.
  Future<bool> createRecordWithFile({
    required String recordType,
    required DateTime recordDate,
    required String title,
    String? notes,
    required PlatformFile file,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Create record
      final recordId = await _service.createRecord(
        recordType: recordType,
        recordDate: recordDate,
        title: title,
        notes: notes,
      );

      // Upload file
      await _service.uploadFile(recordId: recordId, file: file);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Create a new record with S3 presigned URL upload.
  Future<bool> createRecordWithS3Upload({
    required String recordType,
    required DateTime recordDate,
    required String title,
    String? notes,
    required PlatformFile file,
    required String contentType,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      // Create record
      final recordId = await _service.createRecord(
        recordType: recordType,
        recordDate: recordDate,
        title: title,
        notes: notes,
      );

      // Get presigned URL
      final uploadData = await _service.getPresignedUploadUrl(
        recordId: recordId,
        fileName: file.name,
        contentType: contentType,
      );

      // Upload to S3
      await _service.uploadToS3(
        presignedUrl: uploadData['upload_url'],
        file: file,
        contentType: contentType,
      );

      // Confirm upload
      await _service.confirmUpload(
        recordId: recordId,
        s3Key: uploadData['s3_key'],
        fileName: file.name,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete a record.
  Future<bool> deleteRecord(String id) async {
    try {
      await _service.deleteRecord(id);
      _records.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = _parseError(e);
      notifyListeners();
      return false;
    }
  }

  /// Clear error message.
  void clearError() {
    _error = null;
    notifyListeners();
  }

  String _parseError(dynamic error) {
    final message = error.toString();

    if (message.contains('connection error') ||
        message.contains('XMLHttpRequest onError') ||
        message.contains('Connection refused') ||
        message.contains('Failed host lookup')) {
      return 'Cannot reach backend at ${ApiConstants.baseUrl}. '
          'Please ensure API server is running and reachable.';
    }
    if (error.toString().contains('404')) {
      return 'Records not found. Please create your first record.';
    }
    return 'An error occurred: $message';
  }
}
