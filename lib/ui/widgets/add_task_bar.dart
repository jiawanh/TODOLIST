// lib/ui/widgets/add_task_bar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import '../../data/providers/task_provider.dart';
import '../../data/providers/settings_provider.dart';

class AddTaskBar extends ConsumerStatefulWidget {
  final bool isDayGoal;
  final String hint;

  const AddTaskBar({
    super.key,
    this.isDayGoal = false,
    this.hint = '添加任务… (按 Enter 确认)',
  });

  @override
  ConsumerState<AddTaskBar> createState() => _AddTaskBarState();
}

class _AddTaskBarState extends ConsumerState<AddTaskBar> {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  TimeOfDay? _deadline;
  bool _showDeadlinePicker = false;

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final title = _ctrl.text.trim();
    if (title.isEmpty) return;

    DateTime? deadline;
    if (_deadline != null) {
      final now = DateTime.now();
      deadline = DateTime(now.year, now.month, now.day, _deadline!.hour, _deadline!.minute);
    }

    await ref.read(dailyPlanProvider.notifier).addTask(
          title,
          type: widget.isDayGoal ? TaskType.dayGoal : TaskType.daily,
          deadline: deadline,
        );

    _ctrl.clear();
    _deadline = null;
    setState(() => _showDeadlinePicker = false);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final settings = ref.watch(settingsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _ctrl,
                focusNode: _focus,
                decoration: InputDecoration(
                  hintText: widget.hint,
                  prefixIcon: const Icon(Icons.add, size: 18),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: theme.colorScheme.surface,
                ),
                onSubmitted: (_) => _submit(),
                textInputAction: TextInputAction.done,
              ),
            ),
            if (settings.showDeadlineUI) ...[
              const SizedBox(width: 6),
              Tooltip(
                message: '设置截止时间',
                child: IconButton(
                  icon: Icon(
                    Icons.access_time,
                    color: _deadline != null
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outline,
                  ),
                  onPressed: () async {
                    final t = await showTimePicker(
                      context: context,
                      initialTime: _deadline ?? TimeOfDay.now(),
                    );
                    setState(() => _deadline = t);
                  },
                ),
              ),
            ],
            const SizedBox(width: 4),
            FilledButton(
              onPressed: _submit,
              style: FilledButton.styleFrom(
                minimumSize: const Size(56, 40),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.send, size: 18),
            ),
          ],
        ),
        if (_deadline != null)
          Padding(
            padding: const EdgeInsets.only(top: 4, left: 4),
            child: GestureDetector(
              onTap: () => setState(() => _deadline = null),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '⏰ ${_deadline!.format(context)}',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.close,
                        size: 12,
                        color: theme.colorScheme.onPrimaryContainer),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}
