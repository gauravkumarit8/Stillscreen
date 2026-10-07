import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/exam.dart';
import '../../core/session_log.dart';

/// Fills the app with sample data so screenshots look lived-in.
/// Debug builds only: in a release build this widget draws nothing.
class DemoMenu extends ConsumerWidget {
  const DemoMenu({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!kDebugMode) return const SizedBox.shrink();

    return PopupMenuButton<String>(
      tooltip: 'Demo data (debug builds only)',
      icon: const Icon(Icons.science_outlined),
      onSelected: (value) async {
        final log = ref.read(sessionLogProvider.notifier);
        final exam = ref.read(examProvider.notifier);
        if (value == 'load') {
          final now = DateTime.now();
          await log.replaceAll(_demoSessions(now));
          await exam.set(Exam(
            name: 'Board exams',
            date: DateTime(now.year, now.month, now.day + 42),
          ));
        } else {
          await log.replaceAll(const []);
          await exam.clear();
        }
      },
      itemBuilder: (_) => const [
        PopupMenuItem(value: 'load', child: Text('Load demo data')),
        PopupMenuItem(value: 'clear', child: Text('Clear demo data')),
      ],
    );
  }
}

/// Minutes focused, by how many days ago. Day 6 is missing on purpose, so the
/// screen shows a 6-day current streak and a 9-day longest streak.
const _minutesByDaysAgo = {
  0: 50, 1: 25, 2: 75, 3: 25, 4: 50, 5: 25,
  7: 25, 8: 50, 9: 75, 10: 25, 11: 50, 12: 25, 13: 90, 14: 50, 15: 25,
};

List<SessionRecord> _demoSessions(DateTime now) => [
      for (final entry in _minutesByDaysAgo.entries)
        SessionRecord(
          start: DateTime(now.year, now.month, now.day - entry.key, 8, 30),
          minutes: entry.value,
          completed: true,
        ),
    ];
