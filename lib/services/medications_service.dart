import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/medication.dart';

/// API service for medications endpoints.
class MedicationsService {
  final Dio _dio;

  MedicationsService(this._dio);

  Future<Medication> addMedication(Medication medication) async {
    final response = await _dio.post(
      ApiConstants.medications,
      data: medication.toJson(),
    );
    return Medication.fromJson(response.data);
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
    if (isActive != null) params['is_active'] = isActive;

    final response = await _dio.get(
      ApiConstants.medications,
      queryParameters: params,
    );
    return (response.data as List)
        .map((e) => Medication.fromJson(e))
        .toList();
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
}
