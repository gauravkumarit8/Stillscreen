import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/winddown.dart';

class WindDownScreen extends ConsumerWidget {
  const WindDownScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(windDownProvider);
    final apps = ref.watch(windDownAppsProvider);
    final notifier = ref.read(windDownProvider.notifier);

    Future<void> pickTime({required bool isStart}) async {
      final current = isStart ? config.startMinute : config.endMinute;
      final picked = await showTimePicker(
        context: context,
        initialTime: TimeOfDay(hour: current ~/ 60, minute: current % 60),
      );
      if (picked == null || !context.mounted) return;

      final minute = picked.hour * 60 + picked.minute;
      final other = isStart ? config.endMinute : config.startMinute;
      if (minute == other) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Start and end times cannot be the same.')),
        );
        return;
      }
      await notifier.update(isStart
          ? config.copyWith(startMinute: minute)
          : config.copyWith(endMinute: minute));
    }

    final sortedDays = config.days.toList()..sort();
    final summary = sortedDays.isEmpty
        ? 'Pick at least one day.'
        : 'Work apps are paused from ${formatMinute(context, config.startMinute)} '
            'to ${formatMinute(context, config.endMinute)}, starting on '
            '${sortedDays.map((d) => weekdayNames[d - 1]).join(', ')}.';

    return Scaffold(
      appBar: AppBar(title: const Text('End-of-day wind-down')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Switch off after work. During these hours, the work apps you '
            'choose are paused, with no focus session needed.',
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Wind-down'),
            value: config.enabled,
            onChanged: (v) => notifier.update(config.copyWith(enabled: v)),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Starts'),
            trailing: Text(formatMinute(context, config.startMinute)),
            onTap: () => pickTime(isStart: true),
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Ends'),
            trailing: Text(formatMinute(context, config.endMinute)),
            onTap: () => pickTime(isStart: false),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (var d = 1; d <= 7; d++)
                FilterChip(
                  label: Text(weekdayNames[d - 1]),
                  selected: config.days.contains(d),
                  onSelected: (on) {
                    final next = {...config.days};
                    on ? next.add(d) : next.remove(d);
                    notifier.update(config.copyWith(days: next));
                  },
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(summary),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Work apps to pause'),
            subtitle: Text(apps.isEmpty
                ? 'None chosen yet. Pick apps like email and chat.'
                : '${apps.length} chosen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/winddown-apps'),
          ),
        ],
      ),
    );
  }
}
