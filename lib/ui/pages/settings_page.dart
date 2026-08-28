// lib/ui/pages/settings_page.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:file_picker/file_picker.dart';
import '../../data/providers/settings_provider.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('设置'),
        elevation: 0,
        backgroundColor: theme.scaffoldBackgroundColor,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [

          // ── 同步目录 ──────────────────────────────────────────────────────
          _SectionHeader('📁 数据同步'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.folder_outlined),
              title: const Text('同步目录'),
              subtitle: Text(
                settings.syncDirectory.isEmpty ? '未设置（点击选择）' : settings.syncDirectory,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12,
                  color: settings.syncDirectory.isEmpty
                      ? theme.colorScheme.error
                      : theme.colorScheme.outline,
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () async {
                final result = await FilePicker.platform.getDirectoryPath(
                  dialogTitle: '选择任务数据同步目录',
                );
                if (result != null) {
                  await notifier.update(settings.copyWith(syncDirectory: result));
                }
              },
            ),
          ),

          const SizedBox(height: 16),

          // ── 外观 ──────────────────────────────────────────────────────────
          _SectionHeader('🎨 外观'),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.palette_outlined),
                  title: const Text('主题'),
                  trailing: DropdownButton<ThemeMode>(
                    value: settings.themeMode,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: ThemeMode.system, child: Text('跟随系统')),
                      DropdownMenuItem(value: ThemeMode.light, child: Text('浅色')),
                      DropdownMenuItem(value: ThemeMode.dark, child: Text('深色')),
                    ],
                    onChanged: (v) {
                      if (v != null) notifier.update(settings.copyWith(themeMode: v));
                    },
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // ── 通知 ──────────────────────────────────────────────────────────
          _SectionHeader('🔔 通知'),
          Card(
            child: Column(
              children: [
                // Evening reminder
                SwitchListTile(
                  secondary: const Icon(Icons.nights_stay_outlined),
                  title: const Text('晚间计划提醒'),
                  subtitle: const Text('每晚提醒制定明日计划'),
                  value: settings.eveningReminderEnabled,
                  onChanged: (v) =>
                      notifier.update(settings.copyWith(eveningReminderEnabled: v)),
                ),
                if (settings.eveningReminderEnabled)
                  ListTile(
                    leading: const SizedBox(width: 24),
                    title: const Text('提醒时间'),
                    trailing: TextButton(
                      onPressed: () async {
                        final t = await showTimePicker(
                          context: context,
                          initialTime: TimeOfDay(
                            hour: settings.eveningReminderHour,
                            minute: settings.eveningReminderMinute,
                          ),
                        );
                        if (t != null) {
                          await notifier.update(settings.copyWith(
                            eveningReminderHour: t.hour,
                            eveningReminderMinute: t.minute,
                          ));
                        }
                      },
                      child: Text(
                        '${settings.eveningReminderHour.toString().padLeft(2, '0')}:'
                        '${settings.eveningReminderMinute.toString().padLeft(2, '0')}',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(color: theme.colorScheme.primary),
                      ),
                    ),
                  ),

                const Divider(height: 1),

                // Recurring reminder
                SwitchListTile(
                  secondary: const Icon(Icons.repeat_outlined),
                  title: const Text('循环消息弹出'),
                  subtitle: const Text('按间隔定时弹出任务提醒'),
                  value: settings.recurringReminderEnabled,
                  onChanged: (v) =>
                      notifier.update(settings.copyWith(recurringReminderEnabled: v)),
                ),
                if (settings.recurringReminderEnabled)
                  ListTile(
                    leading: const SizedBox(width: 24),
                    title: const Text('弹出间隔（分钟）'),
                    trailing: SizedBox(
                      width: 80,
                      child: TextFormField(
                        initialValue:
                            settings.recurringReminderIntervalMinutes.toString(),
                        keyboardType: TextInputType.number,
                        textAlign: TextAlign.center,
                        decoration: const InputDecoration(isDense: true),
                        onFieldSubmitted: (v) {
                          final mins = int.tryParse(v);
                          if (mins != null && mins > 0) {
                            notifier.update(settings.copyWith(
                                recurringReminderIntervalMinutes: mins));
                          }
                        },
                      ),
                    ),
                  ),

                const Divider(height: 1),

                // Deadline reminder
                SwitchListTile(
                  secondary: const Icon(Icons.timer_outlined),
                  title: const Text('任务截止提醒'),
                  subtitle: const Text('到达设定时间时推送通知'),
                  value: settings.deadlineReminderEnabled,
                  onChanged: (v) =>
                      notifier.update(settings.copyWith(deadlineReminderEnabled: v)),
                ),

                const Divider(height: 1),

                // Show deadline UI
                SwitchListTile(
                  secondary: const Icon(Icons.access_time_outlined),
                  title: const Text('显示截止时间字段'),
                  subtitle: const Text('在任务列表中显示截止时间输入与标签'),
                  value: settings.showDeadlineUI,
                  onChanged: (v) =>
                      notifier.update(settings.copyWith(showDeadlineUI: v)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Center(
            child: Text(
              '任务数据以 Markdown 格式保存，可用任意文本编辑器查看',
              style: theme.textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader(this.title);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
      ),
    );
  }
}
