// lib/core/constants.dart
class AppConstants {
  // Notification IDs
  static const int eveningReminderNotificationId = 1;
  static const int recurringReminderNotificationId = 2;
  static const int taskDeadlineNotificationBaseId = 1000;

  // SharedPreferences keys
  static const String keySyncDirectory = 'sync_directory';
  static const String keyThemeMode = 'theme_mode';
  static const String keyEveningReminderEnabled = 'evening_reminder_enabled';
  static const String keyEveningReminderHour = 'evening_reminder_hour';
  static const String keyEveningReminderMinute = 'evening_reminder_minute';
  static const String keyRecurringReminderEnabled = 'recurring_reminder_enabled';
  static const String keyRecurringReminderIntervalMinutes = 'recurring_reminder_interval_minutes';
  static const String keyDeadlineReminderEnabled = 'deadline_reminder_enabled';
  static const String keyShowDeadlineUI = 'show_deadline_ui';

  // Defaults
  static const int defaultEveningReminderHour = 21;
  static const int defaultEveningReminderMinute = 0;
  static const int defaultRecurringIntervalMinutes = 30;
}
