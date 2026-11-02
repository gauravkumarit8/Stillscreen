import 'dart:math';

import 'session_log.dart';

/// What the block screen needs to know about the streak.
class StreakSnapshot {
  const StreakSnapshot({
    required this.days,
    required this.goalDone,
    required this.minutesToGoal,
  });

  /// The current streak. If today is still open, it counts through yesterday.
  final int days;

  /// Whether today's goal has already been reached.
  final bool goalDone;

  /// Minutes of focus still missing from today's goal (0 once it is reached).
  final int minutesToGoal;
}

/// Uses the same rules as the home and stats screens, including rest days and
/// the goal that applied on each day.
StreakSnapshot streakSnapshot(FocusStats stats) => StreakSnapshot(
      days: stats.currentStreak,
      goalDone: stats.hitGoal(stats.today),
      minutesToGoal: max(0, stats.todayGoal - stats.todayMinutes),
    );
