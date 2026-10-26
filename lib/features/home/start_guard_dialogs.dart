import 'package:flutter/material.dart';

import '../../core/start_guard.dart';

enum StartChoice { fix, timerOnly, cancel }

/// Shown when Start is tapped but nothing would actually be blocked.
Future<StartChoice> askBeforeStart(BuildContext context, StartCheck check) async {
  final (title, body, fixLabel) = switch (check) {
    StartCheck.needsPermission => (
        'Blocking is off',
        'Stillscreen cannot block apps until you turn blocking on. You can '
            'still run the timer on its own.',
        'Turn on blocking',
      ),
    StartCheck.serviceStopped => (
        'Blocking has stopped',
        'Android has stopped the blocking service in the background, so no '
            'apps would be blocked. Open Accessibility settings, switch '
            'Stillscreen off and on again, then start your session. You can '
            'still run the timer on its own.',
        'Open settings',
      ),
    _ => (
        'No apps chosen',
        'Choose the apps to block during your session, or run the timer on '
            'its own.',
        'Choose apps',
      ),
  };

  final choice = await showDialog<StartChoice>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: Text(body),
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
          child: Text(fixLabel),
        ),
      ],
    ),
  );
  return choice ?? StartChoice.cancel;
}
