// lib/data/providers/task_provider.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../models/task.dart';
import '../models/daily_plan.dart';
import '../models/app_settings.dart';
import 'settings_provider.dart';
import 'date_provider.dart';
import '../../services/file_service.dart';
import '../../services/notification_service.dart';

// ── Daily plan provider ──────────────────────────────────────────────────────

final dailyPlanProvider =
    StateNotifierProvider<DailyPlanNotifier, AsyncValue<DailyPlan>>((ref) {
  final date = ref.watch(selectedDateProvider);
  final settings = ref.watch(settingsProvider);
  return DailyPlanNotifier(date: date, settings: settings, ref: ref);
});

class DailyPlanNotifier extends StateNotifier<AsyncValue<DailyPlan>> {
  final DateTime date;
  final AppSettings settings;
  final Ref ref;

  DailyPlanNotifier({
    required this.date,
    required this.settings,
    required this.ref,
  }) : super(const AsyncValue.loading()) {
    _init();
  }

  Future<void> _init() async {
    if (settings.syncDirectory.isEmpty) {
      state = AsyncValue.data(DailyPlan(date: date));
      return;
    }

    FileService.instance.setSyncDirectory(settings.syncDirectory);

    try {
      var plan = await FileService.instance.loadDailyPlan(date);

      // Carry-over: only for today
      final today = DateTime.now();
      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      if (isToday && plan.tasks.isEmpty && plan.dayGoals.isEmpty) {
        final yesterday = date.subtract(const Duration(days: 1));
        final carried =
            await FileService.instance.getUncompletedTasksFrom(yesterday);
        if (carried.isNotEmpty) {
          final dayGoalCarried =
              carried.where((t) => t.type == TaskType.dayGoal).toList();
          final taskCarried =
              carried.where((t) => t.type != TaskType.dayGoal).toList();
          plan = plan.copyWith(
            dayGoals: [...plan.dayGoals, ...dayGoalCarried],
            tasks: [...plan.tasks, ...taskCarried],
          );
          await FileService.instance.saveDailyPlan(plan);
        }
      }

      state = AsyncValue.data(plan);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> _save(DailyPlan plan) async {
    await FileService.instance.saveDailyPlan(plan);
    state = AsyncValue.data(plan);
  }

  // ── Task operations ────────────────────────────────────────────────────────

  Future<void> addTask(String title,
      {TaskType type = TaskType.daily, DateTime? deadline}) async {
    final plan = state.valueOrNull;
    if (plan == null) return;

    final task = Task(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      type: type,
      deadline: deadline,
      sortOrder: type == TaskType.dayGoal
          ? plan.dayGoals.length
          : plan.tasks.length,
    );

    if (settings.deadlineReminderEnabled && deadline != null) {
      await NotificationService.instance.scheduleDeadlineReminder(
        taskId: task.id,
        taskTitle: task.title,
        deadline: deadline,
      );
    }

    final updated = type == TaskType.dayGoal
        ? plan.copyWith(dayGoals: [...plan.dayGoals, task])
        : plan.copyWith(tasks: [...plan.tasks, task]);

    await _save(updated);
  }

  Future<void> toggleTask(String taskId, {bool isDayGoal = false}) async {
    final plan = state.valueOrNull;
    if (plan == null) return;

    final fmt = DateFormat('HH:mm');
    final now = DateTime.now();

    DailyPlan updated;

    if (isDayGoal) {
      final goals = plan.dayGoals.map((t) {
        if (t.id != taskId) return t;
        final completing = !t.isCompleted;
        return t.copyWith(
          isCompleted: completing,
          completedAt: completing ? now : null,
          clearCompletedAt: !completing,
        );
      }).toList();
      updated = plan.copyWith(dayGoals: goals);
    } else {
      final tasks = plan.tasks.map((t) {
        if (t.id != taskId) return t;
        final completing = !t.isCompleted;
        return t.copyWith(
          isCompleted: completing,
          completedAt: completing ? now : null,
          clearCompletedAt: !completing,
          sortOrder: completing ? 99999 : t.sortOrder,
        );
      }).toList();

      // Move completed to bottom
      tasks.sort((a, b) {
        if (a.isCompleted == b.isCompleted) {
          return a.sortOrder.compareTo(b.sortOrder);
        }
        return a.isCompleted ? 1 : -1;
      });

      updated = plan.copyWith(tasks: tasks);

      // Cancel deadline notification if task completed
      final completedTask = tasks.firstWhere((t) => t.id == taskId);
      if (completedTask.isCompleted) {
        await NotificationService.instance.cancelDeadlineReminder(taskId);
      }
    }

    await _save(updated);
  }

  Future<void> deleteTask(String taskId, {bool isDayGoal = false}) async {
    final plan = state.valueOrNull;
    if (plan == null) return;

    await NotificationService.instance.cancelDeadlineReminder(taskId);

    final updated = isDayGoal
        ? plan.copyWith(
            dayGoals: plan.dayGoals.where((t) => t.id != taskId).toList())
        : plan.copyWith(
            tasks: plan.tasks.where((t) => t.id != taskId).toList());

    await _save(updated);
  }

  Future<void> editTask(Task updatedTask, {bool isDayGoal = false}) async {
    final plan = state.valueOrNull;
    if (plan == null) return;

    if (settings.deadlineReminderEnabled && updatedTask.deadline != null) {
      await NotificationService.instance.scheduleDeadlineReminder(
        taskId: updatedTask.id,
        taskTitle: updatedTask.title,
        deadline: updatedTask.deadline!,
      );
    }

    final updated = isDayGoal
        ? plan.copyWith(
            dayGoals: plan.dayGoals
                .map((t) => t.id == updatedTask.id ? updatedTask : t)
                .toList())
        : plan.copyWith(
            tasks: plan.tasks
                .map((t) => t.id == updatedTask.id ? updatedTask : t)
                .toList());

    await _save(updated);
  }

  Future<void> reload() => _init();
}

// ── Goals providers ───────────────────────────────────────────────────────────

final yearGoalsProvider =
    StateNotifierProvider<GoalsNotifier, AsyncValue<List<Task>>>((ref) {
  final settings = ref.watch(settingsProvider);
  final year = DateTime.now().year;
  return GoalsNotifier(
    settings: settings,
    loader: () => FileService.instance.loadYearGoals(year),
    saver: (tasks) => FileService.instance.saveYearGoals(year, tasks),
    type: TaskType.yearGoal,
  );
});

final monthGoalsProvider =
    StateNotifierProvider<GoalsNotifier, AsyncValue<List<Task>>>((ref) {
  final settings = ref.watch(settingsProvider);
  final now = DateTime.now();
  return GoalsNotifier(
    settings: settings,
    loader: () => FileService.instance.loadMonthGoals(now.year, now.month),
    saver: (tasks) =>
        FileService.instance.saveMonthGoals(now.year, now.month, tasks),
    type: TaskType.monthGoal,
  );
});

class GoalsNotifier extends StateNotifier<AsyncValue<List<Task>>> {
  final AppSettings settings;
  final Future<List<Task>> Function() loader;
  final Future<void> Function(List<Task>) saver;
  final TaskType type;

  GoalsNotifier({
    required this.settings,
    required this.loader,
    required this.saver,
    required this.type,
  }) : super(const AsyncValue.loading()) {
    _load();
  }

  Future<void> _load() async {
    if (settings.syncDirectory.isEmpty) {
      state = const AsyncValue.data([]);
      return;
    }
    FileService.instance.setSyncDirectory(settings.syncDirectory);
    try {
      state = AsyncValue.data(await loader());
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> addGoal(String title) async {
    final tasks = state.valueOrNull ?? [];
    final task = Task(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      title: title,
      type: type,
      sortOrder: tasks.length,
    );
    final updated = [...tasks, task];
    await saver(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> toggleGoal(String id) async {
    final tasks = state.valueOrNull ?? [];
    final updated = tasks.map((t) {
      if (t.id != id) return t;
      final completing = !t.isCompleted;
      return t.copyWith(
        isCompleted: completing,
        completedAt: completing ? DateTime.now() : null,
        clearCompletedAt: !completing,
      );
    }).toList();
    await saver(updated);
    state = AsyncValue.data(updated);
  }

  Future<void> deleteGoal(String id) async {
    final tasks = (state.valueOrNull ?? []).where((t) => t.id != id).toList();
    await saver(tasks);
    state = AsyncValue.data(tasks);
  }
}
