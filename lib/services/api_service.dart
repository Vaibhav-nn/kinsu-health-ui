import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:file_picker/file_picker.dart';
import '../models/health_record.dart';

class ApiService {
  final String baseUrl;

  ApiService({required this.baseUrl});

  Future<List<HealthRecord>> fetchRecords({
    String? recordType,
    int page = 1,
    int limit = 50,
  }) async {
    final uri = Uri.parse('$baseUrl/vault/records').replace(
      queryParameters: {
        if (recordType != null) 'record_type': recordType,
        'page': page.toString(),
        'limit': limit.toString(),
      },
    );

    final response = await http.get(uri);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final records = (data['records'] as List)
          .map((json) => HealthRecord.fromJson(json))
          .toList();
      return records;
    } else {
      throw Exception('Failed to load records: ${response.statusCode}');
    }
  }

  Future<String> createRecord({
    required String recordType,
    required DateTime recordDate,
    required String title,
    String? notes,
  }) async {
    final uri = Uri.parse('$baseUrl/vault/records');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'records': [
          {
            'record_type': recordType,
            'record_date': recordDate.toIso8601String().split('T')[0],
            'title': title,
            'notes': notes,
          }
        ]
      }),
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['record_ids'][0] as String;
    } else {
      throw Exception('Failed to create record: ${response.statusCode}');
    }
  }

  Future<void> uploadFile({
    required String recordId,
    required PlatformFile file,
  }) async {
    final uri = Uri.parse('$baseUrl/vault/records/$recordId/upload');

    var request = http.MultipartRequest('POST', uri);

    // Add file to request
    if (file.bytes != null) {
      // Web: use bytes directly
      request.files.add(
        http.MultipartFile.fromBytes(
          'file',
          file.bytes!,
          filename: file.name,
        ),
      );
    } else if (file.path != null) {
      // Mobile/Desktop: read from path
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          file.path!,
          filename: file.name,
        ),
      );
    } else {
      throw Exception('File has no bytes or path');
    }

    final response = await request.send();

    if (response.statusCode != 200) {
      final responseBody = await response.stream.bytesToString();
      throw Exception('Failed to upload file: ${response.statusCode} - $responseBody');
    }
  }

  Future<Map<String, dynamic>> getPresignedUploadUrl({
    required String recordId,
    required String fileName,
    required String contentType,
  }) async {
    final uri = Uri.parse('$baseUrl/vault/records/upload-url');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'record_id': recordId,
        'file_name': fileName,
        'content_type': contentType,
      }),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to get presigned URL: ${response.statusCode}');
    }
  }

  Future<void> uploadToS3({
    required String presignedUrl,
    required PlatformFile file,
    required String contentType,
  }) async {
    final uri = Uri.parse(presignedUrl);

    List<int> fileBytes;
    if (file.bytes != null) {
      fileBytes = file.bytes!;
    } else if (file.path != null) {
      fileBytes = await File(file.path!).readAsBytes();
    } else {
      throw Exception('File has no bytes or path');
    }

    final response = await http.put(
      uri,
      headers: {'Content-Type': contentType},
      body: fileBytes,
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to upload to S3: ${response.statusCode}');
    }
  }

  Future<void> confirmUpload({
    required String recordId,
    required String s3Key,
    required String fileName,
  }) async {
    final uri = Uri.parse('$baseUrl/vault/records/confirm-upload');

    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'record_id': recordId,
        's3_key': s3Key,
        'file_name': fileName,
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to confirm upload: ${response.statusCode}');
    }
  }
}
