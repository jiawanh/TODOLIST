// lib/data/models/app_settings.dart
import 'package:flutter/material.dart';

class AppSettings {
  final String syncDirectory;
  final ThemeMode themeMode;
  final bool eveningReminderEnabled;
  final int eveningReminderHour;
  final int eveningReminderMinute;
  final bool recurringReminderEnabled;
  final int recurringReminderIntervalMinutes;
  final bool deadlineReminderEnabled;
  final bool showDeadlineUI;

  const AppSettings({
    this.syncDirectory = '',
    this.themeMode = ThemeMode.system,
    this.eveningReminderEnabled = true,
    this.eveningReminderHour = 21,
    this.eveningReminderMinute = 0,
    this.recurringReminderEnabled = false,
    this.recurringReminderIntervalMinutes = 30,
    this.deadlineReminderEnabled = true,
    this.showDeadlineUI = true,
  });

  AppSettings copyWith({
    String? syncDirectory,
    ThemeMode? themeMode,
    bool? eveningReminderEnabled,
    int? eveningReminderHour,
    int? eveningReminderMinute,
    bool? recurringReminderEnabled,
    int? recurringReminderIntervalMinutes,
    bool? deadlineReminderEnabled,
    bool? showDeadlineUI,
  }) {
    return AppSettings(
      syncDirectory: syncDirectory ?? this.syncDirectory,
      themeMode: themeMode ?? this.themeMode,
      eveningReminderEnabled: eveningReminderEnabled ?? this.eveningReminderEnabled,
      eveningReminderHour: eveningReminderHour ?? this.eveningReminderHour,
      eveningReminderMinute: eveningReminderMinute ?? this.eveningReminderMinute,
      recurringReminderEnabled: recurringReminderEnabled ?? this.recurringReminderEnabled,
      recurringReminderIntervalMinutes:
          recurringReminderIntervalMinutes ?? this.recurringReminderIntervalMinutes,
      deadlineReminderEnabled: deadlineReminderEnabled ?? this.deadlineReminderEnabled,
      showDeadlineUI: showDeadlineUI ?? this.showDeadlineUI,
    );
  }
}
