import 'package:flutter/material.dart';

import '../../core/start_guard.dart';

enum StartChoice { fix, timerOnly, cancel }

/// Shown when Start is tapped but nothing would actually be blocked.
Future<StartChoice> askBeforeStart(BuildContext context, StartCheck check) async {
  final needsPermission = check == StartCheck.needsPermission;
  final choice = await showDialog<StartChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(needsPermission ? 'Blocking is off' : 'No apps chosen'),
      content: Text(
        needsPermission
            ? 'Stillscreen cannot block apps until you turn blocking on. You '
                'can still run the timer on its own.'
            : 'Choose the apps to block during your session, or run the timer '
                'on its own.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(StartChoice.cancel),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(StartChoice.timerOnly),
          child: const Text('Timer only'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(ctx).pop(StartChoice.fix),
          child: Text(needsPermission ? 'Turn on blocking' : 'Choose apps'),
        ),
      ],
    ),
  );
  return choice ?? StartChoice.cancel;
}
