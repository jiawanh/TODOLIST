// lib/ui/pages/home_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/providers/task_provider.dart';
import '../../data/providers/settings_provider.dart';
import '../widgets/date_navigator.dart';
import '../widgets/task_item.dart';
import '../widgets/add_task_bar.dart';
import '../widgets/goals_sidebar.dart';
import 'settings_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final theme = Theme.of(context);

    // If no sync directory is set, show setup screen
    if (settings.syncDirectory.isEmpty) {
      return _SetupScreen();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('任务清单'),
        centerTitle: false,
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: '设置',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SettingsPage()),
            ),
          ),
        ],
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(48),
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 8),
            child: DateNavigator(),
          ),
        ),
      ),
      body: Row(
        children: [
          // Main content
          Expanded(child: _MainContent()),
          // Goals sidebar
          const GoalsSidebar(),
        ],
      ),
    );
  }
}

// ── Main content area ─────────────────────────────────────────────────────────

class _MainContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(dailyPlanProvider);
    final theme = Theme.of(context);

    return planAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(
        child: Text('加载失败：$e',
            style: TextStyle(color: theme.colorScheme.error)),
      ),
      data: (plan) => CustomScrollView(
        slivers: [
          // 🎯 Day goals card (pinned at top)
          SliverToBoxAdapter(
            child: Card(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Text('🎯', style: TextStyle(fontSize: 18)),
                        const SizedBox(width: 8),
                        Text('日目标',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            )),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (plan.dayGoals.isEmpty && false) ...[],
                    ...plan.dayGoals.map((t) => TaskItem(
                          key: ValueKey(t.id),
                          task: t,
                          isDayGoal: true,
                        )),
                    const SizedBox(height: 8),
                    const AddTaskBar(
                      isDayGoal: true,
                      hint: '添加日目标…',
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Spacer
          const SliverToBoxAdapter(child: SizedBox(height: 12)),

          // 📋 Tasks section header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: [
                  const Text('📋', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 6),
                  Text('今日任务',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Spacer(),
                  if (plan.completedTasks.isNotEmpty)
                    Text(
                      '${plan.completedTasks.length}/${plan.tasks.length} 完成',
                      style: theme.textTheme.bodySmall,
                    ),
                ],
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 8)),

          // Task list (pending first, then completed at bottom)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) {
                final task = plan.tasks[i];
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TaskItem(
                    key: ValueKey(task.id),
                    task: task,
                    isDayGoal: false,
                  ),
                );
              },
              childCount: plan.tasks.length,
            ),
          ),

          // Add task bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              child: const AddTaskBar(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Setup screen ──────────────────────────────────────────────────────────────

class _SetupScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('📝', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 24),
              Text('欢迎使用任务清单',
                  style: theme.textTheme.headlineSmall
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                '请先选择一个同步目录（如 OneDrive / iCloud Drive 的本地文件夹），\n任务数据将以 Markdown 格式存储在该目录下，可跨设备共享。',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.outline),
              ),
              const SizedBox(height: 32),
              FilledButton.icon(
                icon: const Icon(Icons.folder_open),
                label: const Text('选择同步目录'),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SettingsPage()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
