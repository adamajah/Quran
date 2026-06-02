import 'package:flutter/material.dart';

enum MushafFont { hafs, naskh, lpmqIsepMisbah }

enum AppTheme { light, dark, gold, sepia }

class AppSettings {
  // Display
  final double arabicFontSize;
  final MushafFont mushafFont;
  final double lineSpacing;
  final bool showVerseNumbers;
  final bool showPageOrnaments;
  final String displayMode;

  // Theme
  final AppTheme theme;

  // Audio
  final double defaultVolume;
  final bool autoPlay;
  final double playbackSpeed;
  final String defaultReciterId;

  // Notifications
  final bool readReminder;
  final TimeOfDay? reminderTime;
  final bool dailyMotivation;
  final bool showTajwid;

  const AppSettings({
    this.arabicFontSize = 22.0,
    this.mushafFont = MushafFont.hafs,
    this.lineSpacing = 2.2,
    this.showVerseNumbers = true,
    this.showPageOrnaments = true,
    this.displayMode = 'Single Page',
    this.theme = AppTheme.light,
    this.defaultVolume = 0.8,
    this.autoPlay = false,
    this.playbackSpeed = 1.0,
    this.defaultReciterId = 'ar.alafasy',
    this.readReminder = false,
    this.reminderTime = const TimeOfDay(hour: 5, minute: 0),
    this.dailyMotivation = true,
    this.showTajwid = false,
  });

  AppSettings copyWith({
    double? arabicFontSize,
    MushafFont? mushafFont,
    double? lineSpacing,
    bool? showVerseNumbers,
    bool? showPageOrnaments,
    String? displayMode,
    AppTheme? theme,
    double? defaultVolume,
    bool? autoPlay,
    double? playbackSpeed,
    String? defaultReciterId,
    bool? readReminder,
    TimeOfDay? reminderTime,
    bool? dailyMotivation,
    bool? showTajwid,
  }) => AppSettings(
    arabicFontSize: arabicFontSize ?? this.arabicFontSize,
    mushafFont: mushafFont ?? this.mushafFont,
    lineSpacing: lineSpacing ?? this.lineSpacing,
    showVerseNumbers: showVerseNumbers ?? this.showVerseNumbers,
    showPageOrnaments: showPageOrnaments ?? this.showPageOrnaments,
    displayMode: displayMode ?? this.displayMode,
    theme: theme ?? this.theme,
    defaultVolume: defaultVolume ?? this.defaultVolume,
    autoPlay: autoPlay ?? this.autoPlay,
    playbackSpeed: playbackSpeed ?? this.playbackSpeed,
    defaultReciterId: defaultReciterId ?? this.defaultReciterId,
    readReminder: readReminder ?? this.readReminder,
    reminderTime: reminderTime ?? this.reminderTime,
    dailyMotivation: dailyMotivation ?? this.dailyMotivation,
    showTajwid: showTajwid ?? this.showTajwid,
  );

  String get mushafFontName {
    switch (mushafFont) {
      case MushafFont.hafs:
        return 'Hafs Madinah';
      case MushafFont.naskh:
        return 'Naskh Arabic';
      case MushafFont.lpmqIsepMisbah:
        return 'LPMQ Isep Misbah';
    }
  }

  String get lineSpacingName {
    if (lineSpacing < 1.8) return 'Rapat';
    if (lineSpacing < 2.5) return 'Normal';
    return 'Lebar';
  }
}
