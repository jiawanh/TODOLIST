// lib/ui/widgets/goals_sidebar.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/models/task.dart';
import '../../data/providers/task_provider.dart';

class GoalsSidebar extends ConsumerWidget {
  const GoalsSidebar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final yearGoals = ref.watch(yearGoalsProvider);
    final monthGoals = ref.watch(monthGoalsProvider);

    return Container(
      width: 240,
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            color: theme.dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Year goals
          _GoalSection(
            title: '🏆 年目标',
            goalsAsync: yearGoals,
            onToggle: (id) =>
                ref.read(yearGoalsProvider.notifier).toggleGoal(id),
            onDelete: (id) =>
                ref.read(yearGoalsProvider.notifier).deleteGoal(id),
            onAdd: (title) =>
                ref.read(yearGoalsProvider.notifier).addGoal(title),
          ),
          Divider(height: 1, color: theme.dividerColor),
          // Month goals
          _GoalSection(
            title: '📅 月目标',
            goalsAsync: monthGoals,
            onToggle: (id) =>
                ref.read(monthGoalsProvider.notifier).toggleGoal(id),
            onDelete: (id) =>
                ref.read(monthGoalsProvider.notifier).deleteGoal(id),
            onAdd: (title) =>
                ref.read(monthGoalsProvider.notifier).addGoal(title),
          ),
        ],
      ),
    );
  }
}

class _GoalSection extends StatefulWidget {
  final String title;
  final AsyncValue<List<Task>> goalsAsync;
  final void Function(String id) onToggle;
  final void Function(String id) onDelete;
  final void Function(String title) onAdd;

  const _GoalSection({
    required this.title,
    required this.goalsAsync,
    required this.onToggle,
    required this.onDelete,
    required this.onAdd,
  });

  @override
  State<_GoalSection> createState() => _GoalSectionState();
}

class _GoalSectionState extends State<_GoalSection> {
  bool _expanded = true;
  final _ctrl = TextEditingController();
  bool _adding = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Expanded(
      child: Column(
        children: [
          // Section header
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  Text(widget.title,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Icon(
                    _expanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    size: 18,
                    color: theme.colorScheme.outline,
                  ),
                  IconButton(
                    icon: const Icon(Icons.add, size: 18),
                    visualDensity: VisualDensity.compact,
                    tooltip: '添加目标',
                    onPressed: () => setState(() => _adding = true),
                  ),
                ],
              ),
            ),
          ),

          // Add input
          if (_adding)
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: '输入目标…',
                        isDense: true,
                      ),
                      onSubmitted: (v) {
                        if (v.trim().isNotEmpty) widget.onAdd(v.trim());
                        _ctrl.clear();
                        setState(() => _adding = false);
                      },
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: () {
                      _ctrl.clear();
                      setState(() => _adding = false);
                    },
                  ),
                ],
              ),
            ),

          // Goal list
          if (_expanded)
            Expanded(
              child: widget.goalsAsync.when(
                loading: () =>
                    const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(child: Text('$e')),
                data: (goals) => goals.isEmpty
                    ? Center(
                        child: Text('暂无目标',
                            style: TextStyle(
                                color: theme.colorScheme.outline,
                                fontSize: 12)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 4),
                        itemCount: goals.length,
                        itemBuilder: (_, i) {
                          final g = goals[i];
                          return _GoalItem(
                            task: g,
                            onToggle: () => widget.onToggle(g.id),
                            onDelete: () => widget.onDelete(g.id),
                          );
                        },
                      ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GoalItem extends StatelessWidget {
  final Task task;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _GoalItem({
    required this.task,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 18,
              height: 18,
              margin: const EdgeInsets.only(right: 8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: task.isCompleted
                      ? theme.colorScheme.primary
                      : theme.colorScheme.outline,
                  width: 1.5,
                ),
                color: task.isCompleted
                    ? theme.colorScheme.primary
                    : Colors.transparent,
              ),
              child: task.isCompleted
                  ? Icon(Icons.check,
                      size: 11, color: theme.colorScheme.onPrimary)
                  : null,
            ),
          ),
          Expanded(
            child: Text(
              task.title,
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 13,
                decoration:
                    task.isCompleted ? TextDecoration.lineThrough : null,
                color: task.isCompleted
                    ? theme.colorScheme.outline
                    : theme.colorScheme.onSurface,
              ),
            ),
          ),
          GestureDetector(
            onTap: onDelete,
            child: Icon(Icons.close,
                size: 14, color: theme.colorScheme.outline),
          ),
        ],
      ),
    );
  }
}
