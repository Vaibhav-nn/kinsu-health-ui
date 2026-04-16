import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/symptom.dart';
import '../services/symptoms_service.dart';

class SymptomsProvider extends ChangeNotifier {
  final SymptomsService _service;

  SymptomsProvider(this._service);

  List<ChronicSymptom> _symptoms = [];
  List<ChronicSymptom> get symptoms => _symptoms;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  String _formatError(Object error) {
    if (error is DioException) {
      final statusCode = error.response?.statusCode;
      final data = error.response?.data;

      String? detail;
      if (data is Map<String, dynamic>) {
        final rawDetail = data['detail'];
        if (rawDetail is String) {
          detail = rawDetail;
        } else if (rawDetail is List) {
          detail = rawDetail
              .map((item) => item is Map<String, dynamic>
                  ? item['msg']?.toString() ?? item.toString()
                  : item.toString())
              .join(', ');
        }
      } else if (data is String && data.trim().isNotEmpty) {
        detail = data;
      }

      if (statusCode == 401) {
        return 'You are signed out. Please sign in again.';
      }

      if (statusCode == 404 && (detail?.contains('User not found') ?? false)) {
        return 'Your account is being set up. Please tap Save again.';
      }

      if (statusCode == 422) {
        return detail == null || detail.isEmpty
            ? 'Please check your symptom details and try again.'
            : 'Please check your symptom details: $detail';
      }

      if (statusCode != null) {
        return detail == null || detail.isEmpty
            ? 'Request failed with status $statusCode.'
            : 'Request failed ($statusCode): $detail';
      }

      if (error.type == DioExceptionType.connectionError ||
          error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.receiveTimeout ||
          error.type == DioExceptionType.sendTimeout) {
        return 'Cannot reach server at ${ApiConstants.baseUrl}.';
      }
    }

    return 'Something went wrong while saving. Please try again.';
  }

  Future<void> loadSymptoms({bool? isActive}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _symptoms = await _service.listSymptoms(isActive: isActive);
    } catch (error) {
      _error = _formatError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> quickLogSymptom({
    required String symptomName,
    required int severity,
    String? notes,
    Map<String, dynamic>? details,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.quickLogSymptom(
        symptomName: symptomName,
        severity: severity,
        notes: notes,
        details: details,
      );
      return true;
    } catch (error) {
      _error = _formatError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> submitDailyCheckIn({
    String? primaryFeeling,
    List<String> moodTags = const [],
    List<String> digestionTags = const [],
    List<String> painTags = const [],
    List<String> activityTags = const [],
    List<String> cycleTags = const [],
    List<String> otherTags = const [],
    String? notes,
    int severity = 5,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.dailyCheckIn(
        primaryFeeling: primaryFeeling,
        moodTags: moodTags,
        digestionTags: digestionTags,
        painTags: painTags,
        activityTags: activityTags,
        cycleTags: cycleTags,
        otherTags: otherTags,
        notes: notes,
        severity: severity,
      );
      return true;
    } catch (error) {
      _error = _formatError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> addSymptom(ChronicSymptom symptom) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _service.addSymptom(symptom);
      _symptoms.insert(0, created);
      return true;
    } catch (error) {
      _error = _formatError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateSymptom(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.updateSymptom(id, data);
      final index = _symptoms.indexWhere((symptom) => symptom.id == id);
      if (index != -1) {
        _symptoms[index] = updated;
      }
      return true;
    } catch (error) {
      _error = _formatError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteSymptom(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteSymptom(id);
      _symptoms.removeWhere((symptom) => symptom.id == id);
      return true;
    } catch (error) {
      _error = _formatError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
