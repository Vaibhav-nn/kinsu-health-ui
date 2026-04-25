import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../models/medication.dart';
import '../services/medications_service.dart';

class MedicationsProvider extends ChangeNotifier {
  final MedicationsService _service;

  MedicationsProvider(this._service);

  List<Medication> _medications = [];
  List<Medication> get medications => _medications;

  /// Pre-filtered list of active medications — avoids repeated .where() in build().
  List<Medication> get activeMedications => _medications.where((m) => m.isActive).toList();

  MedicationDashboard? _dashboard;
  MedicationDashboard? get dashboard => _dashboard;

  MedicationAdherence? _adherence;
  MedicationAdherence? get adherence => _adherence;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isLoadingDashboard = false;
  bool get isLoadingDashboard => _isLoadingDashboard;

  bool _isLoadingAdherence = false;
  bool get isLoadingAdherence => _isLoadingAdherence;

  String? _error;
  String? get error => _error;

  String? _dashboardError;
  String? get dashboardError => _dashboardError;

  String? _adherenceError;
  String? get adherenceError => _adherenceError;

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
        return 'Your account is being set up. Please try again.';
      }

      if (statusCode == 422) {
        return detail == null || detail.isEmpty
            ? 'Please check medication details and try again.'
            : 'Please check medication details: $detail';
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

    return 'Something went wrong. Please try again.';
  }

  Future<void> loadMedications({bool? isActive}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _medications = await _service.listMedications(isActive: isActive);
    } catch (error) {
      _error = _formatError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadDashboard({DateTime? targetDate}) async {
    _isLoadingDashboard = true;
    _dashboardError = null;
    notifyListeners();

    try {
      _dashboard = await _service.fetchDashboard(targetDate: targetDate);
    } catch (error) {
      _dashboardError = _formatError(error);
    } finally {
      _isLoadingDashboard = false;
      notifyListeners();
    }
  }

  Future<void> loadAdherence({
    required String view,
    DateTime? referenceDate,
  }) async {
    _isLoadingAdherence = true;
    _adherenceError = null;
    notifyListeners();

    try {
      _adherence = await _service.fetchAdherence(
        view: view,
        referenceDate: referenceDate,
      );
    } catch (error) {
      _adherenceError = _formatError(error);
    } finally {
      _isLoadingAdherence = false;
      notifyListeners();
    }
  }

  Future<Medication?> addMedication(Medication medication) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final created = await _service.addMedication(medication);
      _medications.insert(0, created);
      return created;
    } catch (error) {
      _error = _formatError(error);
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> updateMedication(int id, Map<String, dynamic> data) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = await _service.updateMedication(id, data);
      final index =
          _medications.indexWhere((medication) => medication.id == id);
      if (index != -1) {
        _medications[index] = updated;
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

  Future<bool> deleteMedication(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.deleteMedication(id);
      _medications.removeWhere((medication) => medication.id == id);
      return true;
    } catch (error) {
      _error = _formatError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> logDose(
    int medicationId, {
    required String status,
    DateTime? scheduledFor,
    DateTime? takenAt,
    String? notes,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.logDose(
        medicationId,
        status: status,
        scheduledFor: scheduledFor,
        takenAt: takenAt,
        notes: notes,
      );
      // Refresh all dependent data in parallel rather than sequentially.
      await Future.wait([
        loadMedications(isActive: true),
        loadDashboard(),
        if (_adherence != null) loadAdherence(view: _adherence!.view),
      ]);
      return true;
    } catch (error) {
      _error = _formatError(error);
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    // Cancel any pending operations or timers here if added in future.
    super.dispose();
  }
}
