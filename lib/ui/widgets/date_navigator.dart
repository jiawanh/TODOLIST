// lib/ui/widgets/date_navigator.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../data/providers/date_provider.dart';

class DateNavigator extends ConsumerWidget {
  const DateNavigator({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedDateProvider);
    final today = DateTime.now();
    final isToday = selected.year == today.year &&
        selected.month == today.month &&
        selected.day == today.day;

    final fmt = DateFormat('yyyy年MM月dd日 EEEE', 'zh_CN');

    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          tooltip: '前一天',
          onPressed: () {
            ref.read(selectedDateProvider.notifier).state =
                selected.subtract(const Duration(days: 1));
          },
        ),
        Expanded(
          child: Center(
            child: Text(
              fmt.format(selected),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ),
        if (!isToday)
          TextButton(
            onPressed: () {
              final now = DateTime.now();
              ref.read(selectedDateProvider.notifier).state =
                  DateTime(now.year, now.month, now.day);
            },
            child: const Text('今天'),
          ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          tooltip: '后一天',
          onPressed: isToday
              ? null
              : () {
                  ref.read(selectedDateProvider.notifier).state =
                      selected.add(const Duration(days: 1));
                },
        ),
        IconButton(
          icon: const Icon(Icons.calendar_month_outlined),
          tooltip: '选择日期',
          onPressed: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: selected,
              firstDate: DateTime(2020),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              ref.read(selectedDateProvider.notifier).state = picked;
            }
          },
        ),
      ],
    );
  }
}
