import 'package:dio/dio.dart';

import '../core/constants.dart';
import '../models/reminder.dart';

/// API service for reminders endpoints.
class RemindersService {
  final Dio _dio;

  RemindersService(this._dio);

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

  Future<Reminder> createReminder(Reminder reminder) async {
    return _withBootstrapRetry(() async {
      final response = await _dio.post(
        '${ApiConstants.reminders}/',
        data: reminder.toJson(),
      );
      return Reminder.fromJson(response.data);
    });
  }

  Future<List<Reminder>> listReminders({
    String? reminderType,
    bool? isEnabled,
    int limit = 50,
    int offset = 0,
  }) async {
    final params = <String, dynamic>{
      'limit': limit,
      'offset': offset,
    };
    if (reminderType != null) {
      params['reminder_type'] = reminderType;
    }
    if (isEnabled != null) {
      params['is_enabled'] = isEnabled;
    }

    return _withBootstrapRetry(() async {
      final response = await _dio.get(
        '${ApiConstants.reminders}/',
        queryParameters: params,
      );
      return (response.data as List)
          .map((item) => Reminder.fromJson(item))
          .toList();
    });
  }

  Future<List<Reminder>> getTimeline() async {
    return _withBootstrapRetry(() async {
      final response = await _dio.get(ApiConstants.reminderTimeline);
      return (response.data as List)
          .map((item) => Reminder.fromJson(item))
          .toList();
    });
  }

  Future<Reminder> getReminder(int id) async {
    final response = await _dio.get('${ApiConstants.reminders}/$id');
    return Reminder.fromJson(response.data);
  }

  Future<Reminder> updateReminder(int id, Map<String, dynamic> data) async {
    final response = await _dio.put(
      '${ApiConstants.reminders}/$id',
      data: data,
    );
    return Reminder.fromJson(response.data);
  }

  Future<void> deleteReminder(int id) async {
    await _dio.delete('${ApiConstants.reminders}/$id');
  }
}
