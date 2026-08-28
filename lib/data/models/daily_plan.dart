// lib/data/models/daily_plan.dart
import 'package:flutter/foundation.dart';
import 'task.dart';

@immutable
class DailyPlan {
  final DateTime date;
  final List<Task> dayGoals;   // 日目标（置顶独立卡片）
  final List<Task> tasks;      // 普通任务

  const DailyPlan({
    required this.date,
    this.dayGoals = const [],
    this.tasks = const [],
  });

  List<Task> get pendingTasks =>
      tasks.where((t) => !t.isCompleted).toList();

  List<Task> get completedTasks =>
      tasks.where((t) => t.isCompleted).toList();

  DailyPlan copyWith({
    DateTime? date,
    List<Task>? dayGoals,
    List<Task>? tasks,
  }) {
    return DailyPlan(
      date: date ?? this.date,
      dayGoals: dayGoals ?? this.dayGoals,
      tasks: tasks ?? this.tasks,
    );
  }
}
