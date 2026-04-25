import 'package:flutter/foundation.dart';

import '../core/error_formatter.dart';
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

  Future<void> loadMedications({bool? isActive}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _medications = await _service.listMedications(isActive: isActive);
    } catch (error) {
      _error = formatProviderError(error);
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
      _dashboardError = formatProviderError(error);
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
      _adherenceError = formatProviderError(error);
    } finally {
      _isLoadingAdherence = false;
      notifyListeners();
    }
  }

  /// Adds a medication with optimistic UI update.
  ///
  /// The medication is inserted locally at index 0 immediately. If the POST
  /// fails, the placeholder is removed and [error] is set.
  Future<Medication?> addMedication(Medication medication) async {
    // Optimistic insert — user sees the new entry immediately.
    _medications.insert(0, medication);
    _error = null;
    notifyListeners();

    try {
      final created = await _service.addMedication(medication);
      // Replace placeholder with the server-assigned version (real id, etc.).
      final idx = _medications.indexOf(medication);
      if (idx >= 0) _medications[idx] = created;
      notifyListeners();
      return created;
    } catch (error) {
      _medications.remove(medication);
      _error = formatProviderError(error);
      notifyListeners();
      return null;
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
      _error = formatProviderError(error);
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
      _error = formatProviderError(error);
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
      _error = formatProviderError(error);
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    // Cancel any pending operations or timers here if added in future.
    super.dispose();
  }
}
