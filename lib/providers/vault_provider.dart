import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/error_formatter.dart';
import '../models/health_record.dart';
import '../models/vault_models.dart';
import '../services/vault_service.dart';

class VaultProvider extends ChangeNotifier {
  final VaultService _service;

  VaultProvider(this._service);

  List<HealthRecord> _records = [];
  List<HealthRecord> get records => _records;

  List<VaultConnectedService> _connectedServices = [];
  List<VaultConnectedService> get connectedServices => _connectedServices;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingServices = false;
  bool get isLoadingServices => _isLoadingServices;

  String? _error;
  String? get error => _error;

  String? _servicesError;
  String? get servicesError => _servicesError;

  /// Load health records with optional server-side filters.
  Future<void> loadRecords({
    String? recordType,
    String? documentSubtype,
    String? providerName,
    String? tag,
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
        documentSubtype: documentSubtype,
        providerName: providerName,
        tag: tag,
        query: query,
        startDate: startDate,
        endDate: endDate,
        hasFile: hasFile,
        sortBy: sortBy,
        sortOrder: sortOrder,
      );
    } catch (e) {
      _error = formatProviderError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadConnectedServices() async {
    _isLoadingServices = true;
    _servicesError = null;
    notifyListeners();

    try {
      _connectedServices = await _service.fetchConnectedServices();
    } catch (e) {
      _servicesError = formatProviderError(e);
    }

    _isLoadingServices = false;
    notifyListeners();
  }

  Future<VaultLabTrend> fetchLabTrend(String parameterKey) {
    return _service.fetchLabTrend(parameterKey);
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

      final recordId = await _service.createRecord(
        recordType: recordType,
        recordDate: recordDate,
        title: title,
        notes: notes,
      );

      await _service.uploadFile(recordId: recordId, file: file);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatProviderError(e);
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

      final recordId = await _service.createRecord(
        recordType: recordType,
        recordDate: recordDate,
        title: title,
        notes: notes,
      );

      final uploadData = await _service.getPresignedUploadUrl(
        recordId: recordId,
        fileName: file.name,
        contentType: contentType,
      );

      await _service.uploadToS3(
        presignedUrl: uploadData['upload_url'],
        file: file,
        contentType: contentType,
      );

      await _service.confirmUpload(
        recordId: recordId,
        s3Key: uploadData['s3_key'],
        fileName: file.name,
      );

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatProviderError(e);
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
      _error = formatProviderError(e);
      notifyListeners();
      return false;
    }
  }

  /// Clear error message.
  void clearError() {
    _error = null;
    _servicesError = null;
    notifyListeners();
  }
}
