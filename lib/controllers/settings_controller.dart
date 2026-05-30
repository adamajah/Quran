import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/settings_model.dart';
import '../services/settings_service.dart';
import '../services/notification_service.dart';

class SettingsController extends ChangeNotifier {
  final SettingsService _service;
  AppSettings _settings;

  SettingsController(this._service) : _settings = _service.loadSettings() {
    _initNotifications();
  }

  void _initNotifications() {
    if (_settings.readReminder && _settings.reminderTime != null) {
      NotificationService.scheduleReadingReminder(_settings.reminderTime!);
    }
  }

  AppSettings get settings => _settings;

  // Real-time updates
  void updateArabicFontSize(double size) {
    _settings = _settings.copyWith(arabicFontSize: size);
    _service.saveSettings(_settings);
    _hapticFeedback();
    notifyListeners();
  }

  void updateMushafFont(MushafFont font) {
    _settings = _settings.copyWith(mushafFont: font);
    _service.saveSettings(_settings);
    _hapticFeedback();
    notifyListeners();
  }

  void updateLineSpacing(double spacing) {
    _settings = _settings.copyWith(lineSpacing: spacing);
    _service.saveSettings(_settings);
    _hapticFeedback();
    notifyListeners();
  }

  void toggleVerseNumbers(bool show) {
    _settings = _settings.copyWith(showVerseNumbers: show);
    _service.saveSettings(_settings);
    _hapticFeedback();
    notifyListeners();
  }

  void updateTheme(AppTheme theme) {
    _settings = _settings.copyWith(theme: theme);
    _service.saveSettings(_settings);
    _hapticFeedback();
    notifyListeners();
  }

  void updateVolume(double volume) {
    _settings = _settings.copyWith(defaultVolume: volume);
    _service.saveSettings(_settings);
    notifyListeners();
  }

  void toggleAutoPlay(bool auto) {
    _settings = _settings.copyWith(autoPlay: auto);
    _service.saveSettings(_settings);
    _hapticFeedback();
    notifyListeners();
  }

  void updatePlaybackSpeed(double speed) {
    _settings = _settings.copyWith(playbackSpeed: speed);
    _service.saveSettings(_settings);
    _hapticFeedback();
    notifyListeners();
  }

  void updateDefaultReciter(String reciterId) {
    _settings = _settings.copyWith(defaultReciterId: reciterId);
    _service.saveSettings(_settings);
    _hapticFeedback();
    notifyListeners();
  }

  void toggleReadReminder(bool active) {
    _settings = _settings.copyWith(readReminder: active);
    _service.saveSettings(_settings);

    if (active && _settings.reminderTime != null) {
      NotificationService.scheduleReadingReminder(_settings.reminderTime!);
    } else {
      NotificationService.cancelAll();
    }

    _hapticFeedback();
    notifyListeners();
  }

  void updateReminderTime(TimeOfDay time) {
    _settings = _settings.copyWith(reminderTime: time);
    _service.saveSettings(_settings);

    if (_settings.readReminder) {
      NotificationService.scheduleReadingReminder(time);
    }

    _hapticFeedback();
    notifyListeners();
  }

  void toggleDailyMotivation(bool active) {
    _settings = _settings.copyWith(dailyMotivation: active);
    _service.saveSettings(_settings);
    _hapticFeedback();
    notifyListeners();
  }

  void toggleTajwid(bool active) {
    _settings = _settings.copyWith(showTajwid: active);
    _service.saveSettings(_settings);
    _hapticFeedback();
    notifyListeners();
  }

  void _hapticFeedback() {
    HapticFeedback.lightImpact();
  }

  // Backup & Restore (Mock for now, as requested)
  Future<void> syncData() async {
    await Future.delayed(const Duration(seconds: 2));
    _hapticFeedback();
    notifyListeners();
  }

  Future<void> backupData(bool toCloud) async {
    await Future.delayed(const Duration(seconds: 2));
    _hapticFeedback();
    notifyListeners();
  }
}
