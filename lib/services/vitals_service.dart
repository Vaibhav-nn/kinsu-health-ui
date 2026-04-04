import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/vital.dart';

/// API service for vitals endpoints.
class VitalsService {
  final Dio _dio;

  VitalsService(this._dio);

  Future<VitalLog> logVital(VitalLog vital) async {
    final response = await _dio.post(
      ApiConstants.vitals,
      data: vital.toJson(),
    );
    return VitalLog.fromJson(response.data);
  }

  Future<List<VitalLog>> logSnapshot(VitalSnapshot snapshot) async {
    final response = await _dio.post(
      ApiConstants.vitalSnapshot,
      data: snapshot.toJson(),
    );
    return (response.data as List<dynamic>)
        .map((item) => VitalLog.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<VitalLog>> listVitals({
    String? vitalType,
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (vitalType != null) params['vital_type'] = vitalType;
    if (startDate != null) params['start_date'] = startDate.toIso8601String();
    if (endDate != null) params['end_date'] = endDate.toIso8601String();

    final response = await _dio.get(
      ApiConstants.vitals,
      queryParameters: params,
    );
    return (response.data as List).map((e) => VitalLog.fromJson(e)).toList();
  }

  Future<VitalTrendResponse> getVitalTrends({
    required String vitalType,
    DateTime? startDate,
    DateTime? endDate,
  }) async {
    final params = <String, dynamic>{
      'vital_type': vitalType,
    };
    if (startDate != null) params['start_date'] = startDate.toIso8601String();
    if (endDate != null) params['end_date'] = endDate.toIso8601String();

    final response = await _dio.get(
      ApiConstants.vitalTrends,
      queryParameters: params,
    );
    return VitalTrendResponse.fromJson(response.data);
  }

  Future<VitalLog> getVital(int id) async {
    final response = await _dio.get('${ApiConstants.vitals}/$id');
    return VitalLog.fromJson(response.data);
  }

  Future<void> deleteVital(int id) async {
    await _dio.delete('${ApiConstants.vitals}/$id');
  }
}
