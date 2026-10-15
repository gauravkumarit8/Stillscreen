import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/achievements.dart';
import '../../core/goal.dart';
import '../../core/session_log.dart';

class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = FocusStats(
      ref.watch(sessionLogProvider),
      goals: ref.watch(goalHistoryProvider),
    );
    final all = computeAchievements(stats);
    final unlocked = all.where((a) => a.unlocked).length;
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('$unlocked of ${all.length} unlocked',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 16),
          for (final a in all)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Opacity(
                opacity: a.unlocked ? 1 : 0.55,
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: a.unlocked ? stillTeal : context.line,
                      width: a.unlocked ? 2 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        a.unlocked ? Icons.emoji_events : Icons.lock_outline,
                        color: a.unlocked ? stillTeal : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(a.title,
                                style: text.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            Text(a.description),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
