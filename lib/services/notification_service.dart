// lib/services/notification_service.dart
import 'dart:io';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import '../core/constants.dart';

class NotificationService {
  static NotificationService? _instance;
  static NotificationService get instance => _instance ??= NotificationService._();
  NotificationService._();

  final _plugin = FlutterLocalNotificationsPlugin();

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const linuxSettings = LinuxInitializationSettings(defaultActionName: '打开');

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
      linux: linuxSettings,
    );

    await _plugin.initialize(initSettings);

    // Request permissions on macOS/iOS
    if (Platform.isIOS || Platform.isMacOS) {
      await _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }
    if (Platform.isAndroid) {
      final androidImpl = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      await androidImpl?.requestNotificationsPermission();
    }

    // Set timezone
    final tzName = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(tzName));
  }

  // ── Evening reminder ────────────────────────────────────────────────────────

  Future<void> scheduleEveningReminder({
    required int hour,
    required int minute,
  }) async {
    if (Platform.isWindows) return;
    await cancelEveningReminder();

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    await _plugin.zonedSchedule(
      AppConstants.eveningReminderNotificationId,
      '📝 制定明日计划',
      '现在是规划明天的好时机，让明天更有效率！',
      scheduled,
      _notificationDetails('每日提醒'),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> cancelEveningReminder() async {
    if (Platform.isWindows) return;
    await _plugin.cancel(AppConstants.eveningReminderNotificationId);
  }

  // ── Recurring reminder ──────────────────────────────────────────────────────

  Future<void> scheduleRecurringReminder(int intervalMinutes) async {
    if (Platform.isWindows) return;
    await cancelRecurringReminder();

    RepeatInterval interval;
    if (intervalMinutes <= 15) {
      interval = RepeatInterval.everyMinute;
    } else if (intervalMinutes <= 30) {
      interval = RepeatInterval.hourly;
    } else {
      interval = RepeatInterval.hourly;
    }

    await _plugin.periodicallyShow(
      AppConstants.recurringReminderNotificationId,
      '📋 任务提醒',
      '别忘了查看你的任务清单！',
      interval,
      _notificationDetails('循环提醒'),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelRecurringReminder() async {
    if (Platform.isWindows) return;
    await _plugin.cancel(AppConstants.recurringReminderNotificationId);
  }

  // ── Task deadline reminder ──────────────────────────────────────────────────

  Future<void> scheduleDeadlineReminder({
    required String taskId,
    required String taskTitle,
    required DateTime deadline,
  }) async {
    if (Platform.isWindows) return;
    final id = AppConstants.taskDeadlineNotificationBaseId +
        taskId.hashCode.abs() % 8000;

    final scheduledDate = tz.TZDateTime.from(deadline, tz.local);
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) return;

    await _plugin.zonedSchedule(
      id,
      '⏰ 任务截止提醒',
      taskTitle,
      scheduledDate,
      _notificationDetails('任务提醒'),
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  Future<void> cancelDeadlineReminder(String taskId) async {
    if (Platform.isWindows) return;
    final id = AppConstants.taskDeadlineNotificationBaseId +
        taskId.hashCode.abs() % 8000;
    await _plugin.cancel(id);
  }

  Future<void> cancelAllDeadlineReminders() async {
    // Cancel IDs in the deadline range
    for (int i = AppConstants.taskDeadlineNotificationBaseId;
        i < AppConstants.taskDeadlineNotificationBaseId + 8000;
        i++) {
      await _plugin.cancel(i);
    }
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  NotificationDetails _notificationDetails(String channelName) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelName.toLowerCase().replaceAll(' ', '_'),
        channelName,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
      macOS: const DarwinNotificationDetails(),
      linux: const LinuxNotificationDetails(),
    );
  }
}
