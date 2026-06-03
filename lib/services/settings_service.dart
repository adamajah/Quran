import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/reciter.dart';
import '../models/settings_model.dart';

class SettingsService {
  static const String _keyArabicFontSize = 'arabic_font_size';
  static const String _keyMushafFont = 'mushaf_font_v2';
  static const String _keyLineSpacing = 'line_spacing';
  static const String _keyShowVerseNumbers = 'show_verse_numbers';
  static const String _keyVolume = 'default_volume';
  static const String _keyAutoPlay = 'auto_play';
  static const String _keyPlaybackSpeed = 'playback_speed';
  static const String _keyDefaultReciterId = 'default_reciter_id';
  static const String _keyReadReminder = 'read_reminder';
  static const String _keyReminderTime = 'reminder_time';
  static const String _keyDailyMotivation = 'daily_motivation';
  static const String _keyShowTajwid = 'show_tajwid';

  final SharedPreferences _prefs;

  SettingsService(this._prefs);

  AppSettings loadSettings() {
    return AppSettings(
      arabicFontSize: _prefs.getDouble(_keyArabicFontSize) ?? 22.0,
      mushafFont: _loadMushafFont(),
      lineSpacing: _prefs.getDouble(_keyLineSpacing) ?? 2.2,
      showVerseNumbers: _prefs.getBool(_keyShowVerseNumbers) ?? true,
      defaultVolume: _prefs.getDouble(_keyVolume) ?? 1.0,
      autoPlay: _prefs.getBool(_keyAutoPlay) ?? false,
      playbackSpeed: _prefs.getDouble(_keyPlaybackSpeed) ?? 1.0,
      defaultReciterId: _resolveDefaultReciterId(
        _prefs.getString(_keyDefaultReciterId),
      ),
      readReminder: _prefs.getBool(_keyReadReminder) ?? false,
      reminderTime: _parseTime(_prefs.getString(_keyReminderTime)),
      dailyMotivation: _prefs.getBool(_keyDailyMotivation) ?? true,
      showTajwid: _prefs.getBool(_keyShowTajwid) ?? false,
    );
  }

  Future<void> saveSettings(AppSettings settings) async {
    await _prefs.setDouble(_keyArabicFontSize, settings.arabicFontSize);
    await _prefs.setString(_keyMushafFont, settings.mushafFont.name);
    await _prefs.setDouble(_keyLineSpacing, settings.lineSpacing);
    await _prefs.setBool(_keyShowVerseNumbers, settings.showVerseNumbers);
    await _prefs.setDouble(_keyVolume, settings.defaultVolume);
    await _prefs.setBool(_keyAutoPlay, settings.autoPlay);
    await _prefs.setDouble(_keyPlaybackSpeed, settings.playbackSpeed);
    await _prefs.setString(_keyDefaultReciterId, settings.defaultReciterId);
    await _prefs.setBool(_keyReadReminder, settings.readReminder);
    if (settings.reminderTime != null) {
      await _prefs.setString(
        _keyReminderTime,
        '${settings.reminderTime!.hour}:${settings.reminderTime!.minute}',
      );
    }
    await _prefs.setBool(_keyDailyMotivation, settings.dailyMotivation);
    await _prefs.setBool(_keyShowTajwid, settings.showTajwid);
  }

  TimeOfDay? _parseTime(String? timeStr) {
    if (timeStr == null || !timeStr.contains(':')) {
      return const TimeOfDay(hour: 5, minute: 0);
    }
    final parts = timeStr.split(':');
    return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
  }

  MushafFont _loadMushafFont() {
    final storedFont = _prefs.getString(_keyMushafFont);
    return MushafFont.values.firstWhere(
      (font) => font.name == storedFont,
      orElse: () => MushafFont.hafs,
    );
  }

  String _resolveDefaultReciterId(String? storedId) {
    final fallback = availableReciters.first.id;
    if (storedId == null || storedId.isEmpty) return fallback;
    if (availableReciters.any((reciter) => reciter.id == storedId)) {
      return storedId;
    }

    unawaited(_prefs.setString(_keyDefaultReciterId, fallback));
    return fallback;
  }
}
