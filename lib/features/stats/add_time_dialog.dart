import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/session_log.dart';

/// For time spent focusing without the phone. It keeps a streak honest to what
/// the person actually did.
Future<void> showAddTimeDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _AddTimeDialog());

class _AddTimeDialog extends ConsumerStatefulWidget {
  const _AddTimeDialog();

  @override
  ConsumerState<_AddTimeDialog> createState() => _AddTimeDialogState();
}

class _AddTimeDialogState extends ConsumerState<_AddTimeDialog> {
  static const _options = [10, 20, 30, 45, 60, 90];

  int _minutes = 30;
  bool _yesterday = false;

  Future<void> _add() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    final now = DateTime.now();
    // Noon on the chosen day: it counts for that day whatever the time is now.
    final day = DateTime(now.year, now.month, now.day - (_yesterday ? 1 : 0), 12);
    await ref.read(sessionLogProvider.notifier).add(
          SessionRecord(start: day, minutes: _minutes, completed: false),
        );
    navigator.pop();
    messenger.showSnackBar(
      SnackBar(content: Text('Added $_minutes minutes.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add offline focus time'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Studied or worked without your phone? Add the time so your streak '
            'reflects it.',
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            children: [
              for (final m in _options)
                ChoiceChip(
                  label: Text('$m min'),
                  selected: _minutes == m,
                  onSelected: (_) => setState(() => _minutes = m),
                ),
            ],
          ),
          const SizedBox(height: 16),
          SegmentedButton<bool>(
            showSelectedIcon: false,
            segments: const [
              ButtonSegment(value: false, label: Text('Today')),
              ButtonSegment(value: true, label: Text('Yesterday')),
            ],
            selected: {_yesterday},
            onSelectionChanged: (s) => setState(() => _yesterday = s.first),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _add, child: const Text('Add')),
      ],
    );
  }
}
