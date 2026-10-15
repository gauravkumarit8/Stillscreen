import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/goal.dart';
import '../../core/reminder.dart';

Future<void> showGoalDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _GoalDialog());

class _GoalDialog extends ConsumerWidget {
  const _GoalDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final current = ref.watch(goalHistoryProvider).goalOn(DateTime.now());

    return AlertDialog(
      title: const Text('Daily goal'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'How long do you want to focus each day? Your streak counts the '
            'days that reach this goal. A new goal applies from today, so '
            'earlier days keep theirs.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final m in goalOptions)
                ChoiceChip(
                  label: Text('$m min'),
                  selected: current == m,
                  onSelected: (_) async {
                    await ref.read(goalHistoryProvider.notifier).setGoal(m);
                    await ref.read(reminderProvider.notifier).resync();
                    if (context.mounted) Navigator.of(context).pop();
                  },
                ),
            ],
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}
