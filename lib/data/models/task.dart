// lib/data/models/task.dart
import 'package:flutter/foundation.dart';

enum TaskType { daily, dayGoal, monthGoal, yearGoal }

@immutable
class Task {
  final String id;
  final String title;
  final bool isCompleted;
  final DateTime? completedAt;
  final DateTime? deadline;
  final String? note;
  final String? carriedFromDate; // 来自哪天的未完成任务
  final TaskType type;
  final List<Task> subtasks;
  final int sortOrder;

  const Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
    this.completedAt,
    this.deadline,
    this.note,
    this.carriedFromDate,
    this.type = TaskType.daily,
    this.subtasks = const [],
    this.sortOrder = 0,
  });

  Task copyWith({
    String? id,
    String? title,
    bool? isCompleted,
    DateTime? completedAt,
    DateTime? deadline,
    String? note,
    String? carriedFromDate,
    TaskType? type,
    List<Task>? subtasks,
    int? sortOrder,
    bool clearDeadline = false,
    bool clearCompletedAt = false,
    bool clearCarriedFrom = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      isCompleted: isCompleted ?? this.isCompleted,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      deadline: clearDeadline ? null : (deadline ?? this.deadline),
      note: note ?? this.note,
      carriedFromDate: clearCarriedFrom ? null : (carriedFromDate ?? this.carriedFromDate),
      type: type ?? this.type,
      subtasks: subtasks ?? this.subtasks,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Task && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
