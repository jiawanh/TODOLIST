// lib/data/providers/settings_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/app_settings.dart';
import '../repositories/settings_repository.dart';
import '../../services/notification_service.dart';

final settingsProvider = StateNotifierProvider<SettingsNotifier, AppSettings>((ref) {
  return SettingsNotifier();
});

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(const AppSettings()) {
    _load();
  }

  Future<void> _load() async {
    await SettingsRepository.instance.initialize();
    state = SettingsRepository.instance.load();
    await _applyNotifications(state);
  }

  Future<void> update(AppSettings settings) async {
    state = settings;
    await SettingsRepository.instance.save(settings);
    await _applyNotifications(settings);
  }

  Future<void> _applyNotifications(AppSettings s) async {
    final ns = NotificationService.instance;
    if (s.eveningReminderEnabled) {
      await ns.scheduleEveningReminder(
        hour: s.eveningReminderHour,
        minute: s.eveningReminderMinute,
      );
    } else {
      await ns.cancelEveningReminder();
    }

    if (s.recurringReminderEnabled) {
      await ns.scheduleRecurringReminder(s.recurringReminderIntervalMinutes);
    } else {
      await ns.cancelRecurringReminder();
    }
  }
}
