import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/illness.dart';

/// API service for illness episodes endpoints.
class IllnessService {
  final Dio _dio;

  IllnessService(this._dio);

  Future<IllnessEpisode> createEpisode(IllnessEpisode episode) async {
    final response = await _dio.post(
      ApiConstants.illness,
      data: episode.toJson(),
    );
    return IllnessEpisode.fromJson(response.data);
  }

  Future<List<IllnessEpisode>> listEpisodes({
    String? status,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (status != null) params['status'] = status;

    final response = await _dio.get(
      ApiConstants.illness,
      queryParameters: params,
    );
    return (response.data as List)
        .map((e) => IllnessEpisode.fromJson(e))
        .toList();
  }

  Future<IllnessEpisode> getEpisodeDetailed(int id) async {
    final response = await _dio.get('${ApiConstants.illness}/$id');
    return IllnessEpisode.fromJson(response.data);
  }

  Future<IllnessEpisode> updateEpisode(int id, Map<String, dynamic> data) async {
    final response = await _dio.put(
      '${ApiConstants.illness}/$id',
      data: data,
    );
    return IllnessEpisode.fromJson(response.data);
  }

  Future<IllnessDetail> addEpisodeDetail(int episodeId, IllnessDetail detail) async {
    final response = await _dio.post(
      '${ApiConstants.illness}/$episodeId/details',
      data: detail.toJson(),
    );
    return IllnessDetail.fromJson(response.data);
  }

  Future<void> deleteEpisode(int id) async {
    await _dio.delete('${ApiConstants.illness}/$id');
  }
}
