import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/symptom.dart';

/// API service for chronic symptoms endpoints.
class SymptomsService {
  final Dio _dio;

  SymptomsService(this._dio);

  bool _isUserBootstrapError(DioException error) {
    final statusCode = error.response?.statusCode;
    final data = error.response?.data;
    final detail =
        data is Map<String, dynamic> ? data['detail']?.toString() ?? '' : '';
    return statusCode == 404 && detail.contains('User not found');
  }

  Future<void> _bootstrapUser() async {
    await _dio.post(ApiConstants.authLogin);
  }

  Future<T> _withBootstrapRetry<T>(Future<T> Function() operation) async {
    try {
      return await operation();
    } on DioException catch (e) {
      if (_isUserBootstrapError(e)) {
        await _bootstrapUser();
        return await operation();
      }
      rethrow;
    }
  }

  Future<ChronicSymptom> addSymptom(ChronicSymptom symptom) async {
    return _withBootstrapRetry(() async {
      final response = await _dio.post(
        '${ApiConstants.symptoms}/',
        data: symptom.toJson(),
      );
      return ChronicSymptom.fromJson(response.data);
    });
  }

  Future<List<ChronicSymptom>> listSymptoms({
    bool? isActive,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (isActive != null) params['is_active'] = isActive;

    return _withBootstrapRetry(() async {
      final response = await _dio.get(
        '${ApiConstants.symptoms}/',
        queryParameters: params,
      );
      return (response.data as List)
          .map((e) => ChronicSymptom.fromJson(e))
          .toList();
    });
  }

  Future<ChronicSymptom> getSymptom(int id) async {
    final response = await _dio.get('${ApiConstants.symptoms}/$id');
    return ChronicSymptom.fromJson(response.data);
  }

  Future<ChronicSymptom> updateSymptom(
      int id, Map<String, dynamic> data) async {
    final response = await _dio.put(
      '${ApiConstants.symptoms}/$id',
      data: data,
    );
    return ChronicSymptom.fromJson(response.data);
  }

  Future<void> deleteSymptom(int id) async {
    await _dio.delete('${ApiConstants.symptoms}/$id');
  }
}
