// lib/data/repositories/settings_repository.dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_settings.dart';
import '../../core/constants.dart';

class SettingsRepository {
  static SettingsRepository? _instance;
  static SettingsRepository get instance => _instance ??= SettingsRepository._();
  SettingsRepository._();

  late SharedPreferences _prefs;

  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
  }

  AppSettings load() {
    return AppSettings(
      syncDirectory: _prefs.getString(AppConstants.keySyncDirectory) ?? '',
      themeMode: ThemeMode.values[_prefs.getInt(AppConstants.keyThemeMode) ?? 0],
      eveningReminderEnabled:
          _prefs.getBool(AppConstants.keyEveningReminderEnabled) ?? true,
      eveningReminderHour:
          _prefs.getInt(AppConstants.keyEveningReminderHour) ?? AppConstants.defaultEveningReminderHour,
      eveningReminderMinute:
          _prefs.getInt(AppConstants.keyEveningReminderMinute) ?? AppConstants.defaultEveningReminderMinute,
      recurringReminderEnabled:
          _prefs.getBool(AppConstants.keyRecurringReminderEnabled) ?? false,
      recurringReminderIntervalMinutes:
          _prefs.getInt(AppConstants.keyRecurringReminderIntervalMinutes) ??
              AppConstants.defaultRecurringIntervalMinutes,
      deadlineReminderEnabled:
          _prefs.getBool(AppConstants.keyDeadlineReminderEnabled) ?? true,
      showDeadlineUI: _prefs.getBool(AppConstants.keyShowDeadlineUI) ?? true,
    );
  }

  Future<void> save(AppSettings settings) async {
    await Future.wait([
      _prefs.setString(AppConstants.keySyncDirectory, settings.syncDirectory),
      _prefs.setInt(AppConstants.keyThemeMode, settings.themeMode.index),
      _prefs.setBool(AppConstants.keyEveningReminderEnabled, settings.eveningReminderEnabled),
      _prefs.setInt(AppConstants.keyEveningReminderHour, settings.eveningReminderHour),
      _prefs.setInt(AppConstants.keyEveningReminderMinute, settings.eveningReminderMinute),
      _prefs.setBool(AppConstants.keyRecurringReminderEnabled, settings.recurringReminderEnabled),
      _prefs.setInt(AppConstants.keyRecurringReminderIntervalMinutes,
          settings.recurringReminderIntervalMinutes),
      _prefs.setBool(AppConstants.keyDeadlineReminderEnabled, settings.deadlineReminderEnabled),
      _prefs.setBool(AppConstants.keyShowDeadlineUI, settings.showDeadlineUI),
    ]);
  }
}
