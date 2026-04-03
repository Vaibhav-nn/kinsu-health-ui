import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../models/medication.dart';

/// API service for medications endpoints.
class MedicationsService {
  final Dio _dio;

  MedicationsService(this._dio);

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
    } on DioException catch (error) {
      if (_isUserBootstrapError(error)) {
        await _bootstrapUser();
        return await operation();
      }
      rethrow;
    }
  }

  Future<Medication> addMedication(Medication medication) async {
    return _withBootstrapRetry(() async {
      final response = await _dio.post(
        '${ApiConstants.medications}/',
        data: medication.toJson(),
      );
      return Medication.fromJson(response.data);
    });
  }

  Future<List<Medication>> listMedications({
    bool? isActive,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (isActive != null) {
      params['is_active'] = isActive;
    }

    return _withBootstrapRetry(() async {
      final response = await _dio.get(
        '${ApiConstants.medications}/',
        queryParameters: params,
      );
      return (response.data as List)
          .map((item) => Medication.fromJson(item))
          .toList();
    });
  }

  Future<MedicationDashboard> fetchDashboard({DateTime? targetDate}) async {
    final params = <String, dynamic>{};
    if (targetDate != null) {
      params['target_date'] = _dateOnly(targetDate);
    }

    return _withBootstrapRetry(() async {
      final response = await _dio.get(
        ApiConstants.medicationsDashboard,
        queryParameters: params.isEmpty ? null : params,
      );
      return MedicationDashboard.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<MedicationAdherence> fetchAdherence({
    required String view,
    DateTime? referenceDate,
  }) async {
    final params = <String, dynamic>{'view': view};
    if (referenceDate != null) {
      params['reference_date'] = _dateOnly(referenceDate);
    }

    return _withBootstrapRetry(() async {
      final response = await _dio.get(
        ApiConstants.medicationsAdherence,
        queryParameters: params,
      );
      return MedicationAdherence.fromJson(response.data as Map<String, dynamic>);
    });
  }

  Future<Medication> getMedication(int id) async {
    final response = await _dio.get('${ApiConstants.medications}/$id');
    return Medication.fromJson(response.data);
  }

  Future<Medication> updateMedication(int id, Map<String, dynamic> data) async {
    final response = await _dio.put(
      '${ApiConstants.medications}/$id',
      data: data,
    );
    return Medication.fromJson(response.data);
  }

  Future<void> deleteMedication(int id) async {
    await _dio.delete('${ApiConstants.medications}/$id');
  }

  Future<void> logDose(
    int medicationId, {
    required String status,
    DateTime? scheduledFor,
    DateTime? takenAt,
    String? notes,
  }) async {
    final effectiveDate = scheduledFor ?? DateTime.now();

    await _withBootstrapRetry(() async {
      await _dio.post(
        '${ApiConstants.medications}/$medicationId/doses',
        data: {
          'scheduled_for': _dateOnly(effectiveDate),
          'status': status,
          if (takenAt != null) 'taken_at': takenAt.toUtc().toIso8601String(),
          if (notes != null && notes.trim().isNotEmpty) 'notes': notes.trim(),
        },
      );
    });
  }

  String _dateOnly(DateTime value) {
    final yyyy = value.year.toString().padLeft(4, '0');
    final mm = value.month.toString().padLeft(2, '0');
    final dd = value.day.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd';
  }
}
