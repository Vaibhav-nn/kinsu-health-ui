import 'package:flutter/foundation.dart';

import '../core/constants.dart';
import '../core/error_formatter.dart';
import '../models/vital.dart';
import '../services/health_connect_service.dart';
import '../services/vitals_service.dart';

class VitalsProvider extends ChangeNotifier {
  final VitalsService _service;

  VitalsProvider(this._service);

  // ── Health Connect write-back ─────────────────────────────────────────────

  HealthConnectService? _hcService;
  bool _hcWriteBack = false;

  /// Called by [HealthSyncProvider] to wire up (or disconnect) HC write-back.
  void configureHealthConnect(HealthConnectService hc, {required bool writeBack}) {
    _hcService = hc;
    _hcWriteBack = writeBack;
  }

  List<VitalLog> _vitals = [];
  List<VitalLog> get vitals => _vitals;

  VitalTrendResponse? _trendData;
  VitalTrendResponse? get trendData => _trendData;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadVitals({String? vitalType}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _vitals = await _service.listVitals(vitalType: vitalType);
    } catch (e) {
      _error = formatProviderError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTrends(String vitalType) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _trendData = await _service.getVitalTrends(vitalType: vitalType);
    } catch (e) {
      _error = formatProviderError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Logs a vital to the backend.
  ///
  /// Set [skipHCWrite] to true when the vital was imported *from* Health
  /// Connect — prevents an echo loop where we'd write it straight back.
  Future<bool> logVital(VitalLog vital, {bool skipHCWrite = false}) async {
    try {
      final created = await _service.logVital(vital);
      _vitals.insert(0, created);
      notifyListeners();
      if (!skipHCWrite && _hcWriteBack && _hcService != null) {
        _hcService!.writeVitalFromLog(created);
      }
      return true;
    } catch (e) {
      _error = formatProviderError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> logSnapshot(VitalSnapshot snapshot) async {
    try {
      final created = await _service.logSnapshot(snapshot);
      _vitals = [...created, ..._vitals];
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatProviderError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteVital(int id) async {
    try {
      await _service.deleteVital(id);
      _vitals.removeWhere((v) => v.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatProviderError(e);
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }
}
