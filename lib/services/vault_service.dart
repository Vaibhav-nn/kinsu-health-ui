import 'dart:io';
import 'package:dio/dio.dart';
import 'package:file_picker/file_picker.dart';
import '../core/constants.dart';
import '../models/health_record.dart';

/// API service for vault endpoints using Dio.
class VaultService {
  final Dio _dio;

  VaultService(this._dio);

  /// Fetch health records with optional filters
  Future<List<HealthRecord>> fetchRecords({
    String? recordType,
    int page = 1,
    int limit = 50,
  }) async {
    final params = <String, dynamic>{
      'page': page,
      'limit': limit,
    };
    if (recordType != null) params['record_type'] = recordType;

    final response = await _dio.get(
      ApiConstants.vaultRecords,
      queryParameters: params,
    );

    final records = (response.data['records'] as List)
        .map((json) => HealthRecord.fromJson(json))
        .toList();
    return records;
  }

  /// Create a new health record
  Future<String> createRecord({
    required String recordType,
    required DateTime recordDate,
    required String title,
    String? notes,
  }) async {
    final response = await _dio.post(
      ApiConstants.vaultRecords,
      data: {
        'records': [
          {
            'record_type': recordType,
            'record_date': recordDate.toIso8601String().split('T')[0],
            'title': title,
            if (notes != null) 'notes': notes,
          }
        ]
      },
    );

    return response.data['record_ids'][0].toString();
  }

  /// Upload file directly (for mobile/desktop with multipart)
  Future<void> uploadFile({
    required String recordId,
    required PlatformFile file,
  }) async {
    FormData formData;

    if (file.bytes != null) {
      // Web: use bytes directly
      formData = FormData.fromMap({
        'file': MultipartFile.fromBytes(
          file.bytes!,
          filename: file.name,
        ),
      });
    } else if (file.path != null) {
      // Mobile/Desktop: read from path
      formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          file.path!,
          filename: file.name,
        ),
      });
    } else {
      throw Exception('File has no bytes or path');
    }

    await _dio.post(
      '${ApiConstants.vaultRecords}/$recordId/upload',
      data: formData,
    );
  }

  /// Get presigned URL for direct S3 upload
  Future<Map<String, dynamic>> getPresignedUploadUrl({
    required String recordId,
    required String fileName,
    required String contentType,
  }) async {
    final response = await _dio.post(
      ApiConstants.vaultUploadUrl,
      data: {
        'record_id': recordId,
        'file_name': fileName,
        'content_type': contentType,
      },
    );

    return response.data as Map<String, dynamic>;
  }

  /// Upload file to S3 using presigned URL
  Future<void> uploadToS3({
    required String presignedUrl,
    required PlatformFile file,
    required String contentType,
  }) async {
    List<int> fileBytes;
    if (file.bytes != null) {
      fileBytes = file.bytes!;
    } else if (file.path != null) {
      fileBytes = await File(file.path!).readAsBytes();
    } else {
      throw Exception('File has no bytes or path');
    }

    // Use a separate Dio instance for S3 upload (no auth headers)
    final s3Dio = Dio();
    await s3Dio.put(
      presignedUrl,
      data: fileBytes,
      options: Options(
        headers: {'Content-Type': contentType},
      ),
    );
  }

  /// Confirm upload completion
  Future<void> confirmUpload({
    required String recordId,
    required String s3Key,
    required String fileName,
  }) async {
    await _dio.post(
      ApiConstants.vaultConfirmUpload,
      data: {
        'record_id': recordId,
        's3_key': s3Key,
        'file_name': fileName,
      },
    );
  }

  /// Get a specific record by ID
  Future<HealthRecord> getRecord(String id) async {
    final response = await _dio.get('${ApiConstants.vaultRecords}/$id');
    return HealthRecord.fromJson(response.data);
  }

  /// Delete a record
  Future<void> deleteRecord(String id) async {
    await _dio.delete('${ApiConstants.vaultRecords}/$id');
  }
}
