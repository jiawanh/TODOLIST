// lib/ui/widgets/task_item.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/models/task.dart';
import '../../data/providers/task_provider.dart';
import '../../data/providers/settings_provider.dart';

class TaskItem extends ConsumerStatefulWidget {
  final Task task;
  final bool isDayGoal;

  const TaskItem({super.key, required this.task, this.isDayGoal = false});

  @override
  ConsumerState<TaskItem> createState() => _TaskItemState();
}

class _TaskItemState extends ConsumerState<TaskItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  bool _isToggling = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_isToggling) return;
    setState(() => _isToggling = true);
    await _controller.forward();
    await ref.read(dailyPlanProvider.notifier).toggleTask(
          widget.task.id,
          isDayGoal: widget.isDayGoal,
        );
    _controller.reset();
    if (mounted) setState(() => _isToggling = false);
  }

  void _showEditDialog() {
    showDialog(
      context: context,
      builder: (_) => _EditTaskDialog(
        task: widget.task,
        isDayGoal: widget.isDayGoal,
      ),
    );
  }

  void _delete() {
    ref.read(dailyPlanProvider.notifier).deleteTask(
          widget.task.id,
          isDayGoal: widget.isDayGoal,
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);
    final task = widget.task;
    final timeFmt = DateFormat('HH:mm');

    return FadeTransition(
      opacity: Tween<double>(begin: 1.0, end: 0.3).animate(_fadeAnim),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Circle toggle button
            GestureDetector(
              onTap: _toggle,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 22,
                height: 22,
                margin: const EdgeInsets.only(top: 2, right: 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: task.isCompleted
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                    width: 2,
                  ),
                  color: task.isCompleted
                      ? theme.colorScheme.primary
                      : Colors.transparent,
                ),
                child: task.isCompleted
                    ? Icon(Icons.check,
                        size: 14, color: theme.colorScheme.onPrimary)
                    : null,
              ),
            ),

            // Task content
            Expanded(
              child: GestureDetector(
                onDoubleTap: task.isCompleted ? null : _showEditDialog,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title with optional strikethrough
                    Text(
                      task.title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        decoration: task.isCompleted
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isCompleted
                            ? theme.colorScheme.outline
                            : null,
                      ),
                    ),

                    // Metadata row
                    if (task.carriedFromDate != null ||
                        (settings.showDeadlineUI && task.deadline != null) ||
                        task.completedAt != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Wrap(
                          spacing: 8,
                          children: [
                            if (task.carriedFromDate != null)
                              _chip(
                                context,
                                '📌 来自 ${task.carriedFromDate}',
                                theme.colorScheme.tertiary.withOpacity(0.15),
                                theme.colorScheme.tertiary,
                              ),
                            if (settings.showDeadlineUI &&
                                task.deadline != null &&
                                !task.isCompleted)
                              _chip(
                                context,
                                '⏰ ${timeFmt.format(task.deadline!)}',
                                _deadlineColor(task.deadline!, context)
                                    .withOpacity(0.15),
                                _deadlineColor(task.deadline!, context),
                              ),
                            if (task.isCompleted && task.completedAt != null)
                              _chip(
                                context,
                                '✅ ${timeFmt.format(task.completedAt!)}',
                                theme.colorScheme.primary.withOpacity(0.1),
                                theme.colorScheme.primary,
                              ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Delete button (visible on hover / long press)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.close, size: 16),
              visualDensity: VisualDensity.compact,
              color: theme.colorScheme.outline,
              tooltip: '删除',
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(
      BuildContext context, String label, Color bg, Color fg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: fg, fontWeight: FontWeight.w500),
      ),
    );
  }

  Color _deadlineColor(DateTime deadline, BuildContext context) {
    final diff = deadline.difference(DateTime.now());
    if (diff.isNegative) return Colors.red;
    if (diff.inMinutes < 30) return Colors.orange;
    return Theme.of(context).colorScheme.secondary;
  }
}

// ── Edit dialog ───────────────────────────────────────────────────────────────

class _EditTaskDialog extends ConsumerStatefulWidget {
  final Task task;
  final bool isDayGoal;
  const _EditTaskDialog({required this.task, required this.isDayGoal});

  @override
  ConsumerState<_EditTaskDialog> createState() => _EditTaskDialogState();
}

class _EditTaskDialogState extends ConsumerState<_EditTaskDialog> {
  late TextEditingController _titleCtrl;
  TimeOfDay? _deadline;
  bool _hasDeadline = false;

  @override
  void initState() {
    super.initState();
    _titleCtrl = TextEditingController(text: widget.task.title);
    if (widget.task.deadline != null) {
      _hasDeadline = true;
      _deadline = TimeOfDay.fromDateTime(widget.task.deadline!);
    }
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    return AlertDialog(
      title: const Text('编辑任务'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(labelText: '任务内容'),
            autofocus: true,
            maxLines: 2,
          ),
          if (settings.showDeadlineUI) ...[
            const SizedBox(height: 12),
            SwitchListTile(
              title: const Text('设置截止时间'),
              value: _hasDeadline,
              onChanged: (v) => setState(() {
                _hasDeadline = v;
                if (!v) _deadline = null;
              }),
              contentPadding: EdgeInsets.zero,
              dense: true,
            ),
            if (_hasDeadline)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.access_time),
                title: Text(_deadline == null
                    ? '选择时间'
                    : _deadline!.format(context)),
                onTap: () async {
                  final t = await showTimePicker(
                    context: context,
                    initialTime: _deadline ?? TimeOfDay.now(),
                  );
                  if (t != null) setState(() => _deadline = t);
                },
              ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('取消'),
        ),
        FilledButton(
          onPressed: () {
            final title = _titleCtrl.text.trim();
            if (title.isEmpty) return;

            DateTime? deadline;
            if (_hasDeadline && _deadline != null) {
              final now = DateTime.now();
              deadline = DateTime(
                  now.year, now.month, now.day, _deadline!.hour, _deadline!.minute);
            }

            ref.read(dailyPlanProvider.notifier).editTask(
                  widget.task.copyWith(
                    title: title,
                    deadline: deadline,
                    clearDeadline: !_hasDeadline,
                  ),
                  isDayGoal: widget.isDayGoal,
                );
            Navigator.pop(context);
          },
          child: const Text('保存'),
        ),
      ],
    );
  }
}
