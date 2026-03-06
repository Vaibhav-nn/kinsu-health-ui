import 'package:dio/dio.dart';
import '../core/constants.dart';
import '../models/reminder.dart';

/// API service for reminders endpoints.
class RemindersService {
  final Dio _dio;

  RemindersService(this._dio);

  Future<Reminder> createReminder(Reminder reminder) async {
    final response = await _dio.post(
      ApiConstants.reminders,
      data: reminder.toJson(),
    );
    return Reminder.fromJson(response.data);
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
    if (reminderType != null) params['reminder_type'] = reminderType;
    if (isEnabled != null) params['is_enabled'] = isEnabled;

    final response = await _dio.get(
      ApiConstants.reminders,
      queryParameters: params,
    );
    return (response.data as List)
        .map((e) => Reminder.fromJson(e))
        .toList();
  }

  Future<List<Reminder>> getTimeline() async {
    final response = await _dio.get(ApiConstants.reminderTimeline);
    return (response.data as List)
        .map((e) => Reminder.fromJson(e))
        .toList();
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
