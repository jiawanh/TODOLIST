// lib/ui/widgets/day_goal_card.dart
// 日目标卡片独立组件（供将来抽取到 CustomScrollView 的 SliverPersistentHeader 中使用）
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/task_provider.dart';
import 'task_item.dart';
import 'add_task_bar.dart';

class DayGoalCard extends ConsumerWidget {
  const DayGoalCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(dailyPlanProvider);
    final theme = Theme.of(context);

    return planAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (plan) => Card(
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  const Text('🎯', style: TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(
                    '日目标',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  if (plan.dayGoals.isNotEmpty)
                    Text(
                      '${plan.dayGoals.where((t) => t.isCompleted).length}/${plan.dayGoals.length}',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              if (plan.dayGoals.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text(
                    '今日尚无日目标，添加一项重要任务作为今日重心',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.outline),
                  ),
                ),
              ...plan.dayGoals.map((t) => TaskItem(
                    key: ValueKey('goal_${t.id}'),
                    task: t,
                    isDayGoal: true,
                  )),
              const SizedBox(height: 8),
              const AddTaskBar(
                isDayGoal: true,
                hint: '添加日目标… (Enter 确认)',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
