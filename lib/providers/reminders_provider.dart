import 'package:flutter/foundation.dart';
import '../models/reminder.dart';
import '../services/reminders_service.dart';

class RemindersProvider extends ChangeNotifier {
  final RemindersService _service;

  RemindersProvider(this._service);

  List<Reminder> _reminders = [];
  List<Reminder> get reminders => _reminders;

  List<Reminder> _timeline = [];
  List<Reminder> get timeline => _timeline;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Future<void> loadReminders({String? reminderType, bool? isEnabled}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _reminders = await _service.listReminders(
        reminderType: reminderType,
        isEnabled: isEnabled,
      );
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadTimeline() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _timeline = await _service.getTimeline();
    } catch (e) {
      _error = e.toString();
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> createReminder(Reminder reminder) async {
    try {
      final created = await _service.createReminder(reminder);
      _reminders.insert(0, created);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> updateReminder(int id, Map<String, dynamic> data) async {
    try {
      final updated = await _service.updateReminder(id, data);
      final index = _reminders.indexWhere((r) => r.id == id);
      if (index != -1) _reminders[index] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteReminder(int id) async {
    try {
      await _service.deleteReminder(id);
      _reminders.removeWhere((r) => r.id == id);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      notifyListeners();
      return false;
    }
  }
}
