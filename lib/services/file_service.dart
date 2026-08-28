// lib/services/file_service.dart
import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:intl/intl.dart';
import '../data/models/task.dart';
import '../data/models/daily_plan.dart';

/// Handles all Markdown file I/O for tasks and goals.
class FileService {
  static FileService? _instance;
  static FileService get instance => _instance ??= FileService._();
  FileService._();

  String _syncDir = '';
  final _dateFormat = DateFormat('yyyy-MM-dd');
  final _timeFormat = DateFormat('HH:mm');

  void setSyncDirectory(String path) {
    _syncDir = path;
  }

  String get syncDirectory => _syncDir;

  // ── Directory helpers ──────────────────────────────────────────────────────

  Directory get _dailyDir => Directory(p.join(_syncDir, 'daily'));
  Directory get _goalsDir => Directory(p.join(_syncDir, 'goals'));

  Future<void> ensureDirectories() async {
    await _dailyDir.create(recursive: true);
    await _goalsDir.create(recursive: true);
  }

  // ── Daily plan ─────────────────────────────────────────────────────────────

  String _dailyFilePath(DateTime date) =>
      p.join(_dailyDir.path, '${_dateFormat.format(date)}.md');

  Future<DailyPlan> loadDailyPlan(DateTime date) async {
    final file = File(_dailyFilePath(date));
    if (!await file.exists()) return DailyPlan(date: date);
    final content = await file.readAsString();
    return _parseDailyPlan(date, content);
  }

  Future<void> saveDailyPlan(DailyPlan plan) async {
    await ensureDirectories();
    final file = File(_dailyFilePath(plan.date));
    await file.writeAsString(_serializeDailyPlan(plan));
  }

  // ── Goals ──────────────────────────────────────────────────────────────────

  String _yearGoalPath(int year) =>
      p.join(_goalsDir.path, 'year_$year.md');

  String _monthGoalPath(int year, int month) =>
      p.join(_goalsDir.path, 'month_${year}_${month.toString().padLeft(2, '0')}.md');

  Future<List<Task>> loadYearGoals(int year) async {
    final file = File(_yearGoalPath(year));
    if (!await file.exists()) return [];
    return _parseGoalFile(await file.readAsString(), TaskType.yearGoal);
  }

  Future<void> saveYearGoals(int year, List<Task> goals) async {
    await ensureDirectories();
    final file = File(_yearGoalPath(year));
    await file.writeAsString(_serializeGoals('🏆 ${year}年目标', goals));
  }

  Future<List<Task>> loadMonthGoals(int year, int month) async {
    final file = File(_monthGoalPath(year, month));
    if (!await file.exists()) return [];
    return _parseGoalFile(await file.readAsString(), TaskType.monthGoal);
  }

  Future<void> saveMonthGoals(int year, int month, List<Task> goals) async {
    await ensureDirectories();
    final file = File(_monthGoalPath(year, month));
    await file.writeAsString(_serializeGoals(
        '📅 ${year}年${month}月目标', goals));
  }

  // ── Carry-over logic ───────────────────────────────────────────────────────

  /// Returns uncompleted tasks from [date] to carry into today.
  Future<List<Task>> getUncompletedTasksFrom(DateTime date) async {
    final plan = await loadDailyPlan(date);
    return [
      ...plan.dayGoals.where((t) => !t.isCompleted),
      ...plan.tasks.where((t) => !t.isCompleted),
    ].map((t) => t.copyWith(
          id: '${t.id}_carried_${_dateFormat.format(date)}',
          carriedFromDate: _dateFormat.format(date),
        )).toList();
  }

  // ── Serialization ──────────────────────────────────────────────────────────

  String _serializeDailyPlan(DailyPlan plan) {
    final buf = StringBuffer();
    buf.writeln('# 📅 ${_dateFormat.format(plan.date)}');
    buf.writeln();

    // Day goals section
    buf.writeln('## 🎯 日目标');
    for (final t in plan.dayGoals) {
      buf.writeln(_serializeTask(t));
      for (final s in t.subtasks) {
        buf.writeln('  ${_serializeTask(s)}');
      }
    }
    buf.writeln();

    // Pending tasks
    final pending = plan.tasks.where((t) => !t.isCompleted).toList();
    final completed = plan.tasks.where((t) => t.isCompleted).toList();

    buf.writeln('## 📋 今日任务');
    for (final t in pending) {
      buf.writeln(_serializeTask(t));
      for (final s in t.subtasks) {
        buf.writeln('  ${_serializeTask(s)}');
      }
    }
    buf.writeln();

    // Completed tasks
    if (completed.isNotEmpty) {
      buf.writeln('## ✅ 已完成');
      for (final t in completed) {
        buf.writeln(_serializeTask(t));
      }
    }

    return buf.toString();
  }

  String _serializeTask(Task t) {
    final check = t.isCompleted ? 'x' : ' ';
    final title = t.isCompleted ? '~~${t.title}~~' : t.title;
    var line = '- [$check] $title';

    if (t.carriedFromDate != null) {
      line += ' 📌来自${t.carriedFromDate}';
    }
    if (t.deadline != null) {
      line += ' ⏰${_timeFormat.format(t.deadline!)}';
    }
    if (t.isCompleted && t.completedAt != null) {
      line += ' — 完成于${_timeFormat.format(t.completedAt!)}';
    }
    if (t.id.isNotEmpty) {
      line += ' <!-- id:${t.id} -->';
    }
    return line;
  }

  String _serializeGoals(String heading, List<Task> goals) {
    final buf = StringBuffer();
    buf.writeln('# $heading');
    buf.writeln();
    for (final t in goals) {
      buf.writeln(_serializeTask(t));
    }
    return buf.toString();
  }

  // ── Parsing ────────────────────────────────────────────────────────────────

  DailyPlan _parseDailyPlan(DateTime date, String content) {
    final lines = content.split('\n');
    final dayGoals = <Task>[];
    final tasks = <Task>[];

    String? currentSection;
    int sortIndex = 0;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('## 🎯')) {
        currentSection = 'dayGoal';
      } else if (trimmed.startsWith('## 📋')) {
        currentSection = 'task';
      } else if (trimmed.startsWith('## ✅')) {
        currentSection = 'completed';
      } else if (trimmed.startsWith('- [')) {
        final task = _parseTaskLine(trimmed, sortIndex++,
            type: currentSection == 'dayGoal' ? TaskType.dayGoal : TaskType.daily);
        if (task != null) {
          if (currentSection == 'dayGoal') {
            dayGoals.add(task);
          } else {
            tasks.add(task);
          }
        }
      }
    }

    return DailyPlan(date: date, dayGoals: dayGoals, tasks: tasks);
  }

  List<Task> _parseGoalFile(String content, TaskType type) {
    final lines = content.split('\n');
    final tasks = <Task>[];
    int sortIndex = 0;
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.startsWith('- [')) {
        final task = _parseTaskLine(trimmed, sortIndex++, type: type);
        if (task != null) tasks.add(task);
      }
    }
    return tasks;
  }

  Task? _parseTaskLine(String line, int sortOrder, {TaskType type = TaskType.daily}) {
    final checkMatch = RegExp(r'- \[( |x)\] (.+)').firstMatch(line);
    if (checkMatch == null) return null;

    final isCompleted = checkMatch.group(1) == 'x';
    var title = checkMatch.group(2) ?? '';

    // Extract ID
    String id = DateTime.now().microsecondsSinceEpoch.toString();
    final idMatch = RegExp(r'<!-- id:([^>]+) -->').firstMatch(title);
    if (idMatch != null) {
      id = idMatch.group(1)!;
      title = title.replaceAll(idMatch.group(0)!, '').trim();
    }

    // Strip strikethrough
    title = title.replaceAllMapped(RegExp(r'~~(.+?)~~'), (m) {
      return m.group(1) ?? '';
    });

    // Extract carried from
    String? carriedFrom;
    final carriedMatch = RegExp(r'📌来自(\d{4}-\d{2}-\d{2})').firstMatch(title);
    if (carriedMatch != null) {
      carriedFrom = carriedMatch.group(1);
      title = title.replaceAll(carriedMatch.group(0)!, '').trim();
    }

    // Extract deadline
    DateTime? deadline;
    final deadlineMatch = RegExp(r'⏰(\d{2}:\d{2})').firstMatch(title);
    if (deadlineMatch != null) {
      final parts = deadlineMatch.group(1)!.split(':');
      final now = DateTime.now();
      deadline = DateTime(now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]));
      title = title.replaceAll(deadlineMatch.group(0)!, '').trim();
    }

    // Extract completed time
    DateTime? completedAt;
    final completedMatch = RegExp(r'— 完成于(\d{2}:\d{2})').firstMatch(title);
    if (completedMatch != null) {
      final parts = completedMatch.group(1)!.split(':');
      final now = DateTime.now();
      completedAt = DateTime(now.year, now.month, now.day,
          int.parse(parts[0]), int.parse(parts[1]));
      title = title.replaceAll(completedMatch.group(0)!, '').trim();
    }

    title = title.trim();

    return Task(
      id: id,
      title: title,
      isCompleted: isCompleted,
      completedAt: completedAt,
      deadline: deadline,
      carriedFromDate: carriedFrom,
      type: type,
      sortOrder: sortOrder,
    );
  }
}
