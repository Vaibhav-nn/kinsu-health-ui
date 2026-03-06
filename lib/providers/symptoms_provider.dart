import 'package:flutter/foundation.dart';
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

  Future<void> loadSymptoms({bool? isActive}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _symptoms = await _service.listSymptoms(isActive: isActive);
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> addSymptom(ChronicSymptom symptom) async {
    try {
      final created = await _service.addSymptom(symptom);
      _symptoms.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateSymptom(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _service.updateSymptom(id, data);
      final index = _symptoms.indexWhere((s) => s.id == id);
      if (index != -1) _symptoms[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteSymptom(int id) async {
    try {
      await _service.deleteSymptom(id);
      _symptoms.removeWhere((s) => s.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
