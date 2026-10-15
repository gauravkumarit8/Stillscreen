import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/achievements.dart';

enum CompleteChoice { done, again, breakTime }

/// Shown when a focus session ends: a small moment of "well done", with what
/// the session added up to and any badges it unlocked.
Future<CompleteChoice> showSessionComplete(
  BuildContext context, {
  required int minutes,
  required int streak,
  required int todayMinutes,
  required int goal,
  required List<Achievement> badges,
}) async {
  final choice = await showDialog<CompleteChoice>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) {
      final text = Theme.of(ctx).textTheme;
      final progress = (todayMinutes / goal).clamp(0.0, 1.0);
      final streakText = streak == 0
          ? 'A good start'
          : streak == 1
              ? '1 day streak'
              : '$streak day streak';

      return AlertDialog(
        title: const Text('Session complete'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$minutes minutes focused',
                style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 4),
              Text(streakText),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                color: stillTeal,
                backgroundColor: ctx.line,
                borderRadius: BorderRadius.circular(4),
              ),
              const SizedBox(height: 6),
              Text(todayMinutes >= goal
                  ? 'Daily goal reached'
                  : '$todayMinutes of $goal min today'),
              if (badges.isNotEmpty) ...[
                const SizedBox(height: 16),
                Text(
                  badges.length == 1 ? 'New badge' : 'New badges',
                  style: text.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                for (final b in badges)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.emoji_events_outlined,
                            size: 20, color: stillTeal),
                        const SizedBox(width: 8),
                        Expanded(child: Text('${b.title}: ${b.description}')),
                      ],
                    ),
                  ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(CompleteChoice.done),
            child: const Text('Done'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(CompleteChoice.breakTime),
            child: const Text('5 min break'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(CompleteChoice.again),
            child: const Text('Another session'),
          ),
        ],
      );
    },
  );
  return choice ?? CompleteChoice.done;
}
