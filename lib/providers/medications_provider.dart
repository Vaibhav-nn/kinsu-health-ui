import 'package:flutter/foundation.dart';
import '../models/medication.dart';
import '../services/medications_service.dart';

class MedicationsProvider extends ChangeNotifier {
  final MedicationsService _service;

  MedicationsProvider(this._service);

  List<Medication> _medications = [];
  List<Medication> get medications => _medications;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadMedications({bool? isActive}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _medications = await _service.listMedications(isActive: isActive);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addMedication(Medication medication) async {
    try {
      final created = await _service.addMedication(medication);
      _medications.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateMedication(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _service.updateMedication(id, data);
      final index = _medications.indexWhere((m) => m.id == id);
      if (index != -1) _medications[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteMedication(int id) async {
    try {
      await _service.deleteMedication(id);
      _medications.removeWhere((m) => m.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
