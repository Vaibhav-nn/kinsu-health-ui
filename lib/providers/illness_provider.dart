import 'package:flutter/foundation.dart';
import '../core/error_formatter.dart';
import '../models/illness.dart';
import '../services/illness_service.dart';

class IllnessProvider extends ChangeNotifier {
  final IllnessService _service;

  IllnessProvider(this._service);

  List<IllnessEpisode> _episodes = [];
  List<IllnessEpisode> get episodes => _episodes;

  IllnessEpisode? _selectedEpisode;
  IllnessEpisode? get selectedEpisode => _selectedEpisode;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadEpisodes({String? status}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _episodes = await _service.listEpisodes(status: status);
    } catch (e) {
      _error = formatProviderError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadEpisodeDetails(int id) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _selectedEpisode = await _service.getEpisodeDetailed(id);
    } catch (e) {
      _error = formatProviderError(e);
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createEpisode(IllnessEpisode episode) async {
    try {
      final created = await _service.createEpisode(episode);
      _episodes.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatProviderError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> addDetail(int episodeId, IllnessDetail detail) async {
    try {
      await _service.addEpisodeDetail(episodeId, detail);
      // Reload the episode to get updated details
      await loadEpisodeDetails(episodeId);
      return true;
    } catch (e) {
      _error = formatProviderError(e);
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteEpisode(int id) async {
    try {
      await _service.deleteEpisode(id);
      _episodes.removeWhere((e) => e.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = formatProviderError(e);
      notifyListeners();
      return false;
    }
  }
}
