import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/goal.dart';
import 'package:focus/core/session_log.dart';
import 'package:focus/core/streak_sync.dart';

SessionRecord rec(DateTime start, int minutes) =>
    SessionRecord(start: start, minutes: minutes, completed: true);

void main() {
  final now = DateTime(2026, 11, 3, 12);

  StreakSnapshot snap(List<SessionRecord> log) =>
      streakSnapshot(FocusStats(log, now: now));

  test('no history: no streak, goal not reached, the full goal to go', () {
    final s = snap(const []);
    expect(s.days, 0);
    expect(s.goalDone, isFalse);
    expect(s.minutesToGoal, defaultDailyGoal);
  });

  test('goal reached today: streak of one, nothing left to do', () {
    final s = snap([rec(DateTime(2026, 11, 3, 9), defaultDailyGoal + 5)]);
    expect(s.days, 1);
    expect(s.goalDone, isTrue);
    expect(s.minutesToGoal, 0);
  });

  test('yesterday counts while today is still open', () {
    final s = snap([
      rec(DateTime(2026, 11, 2, 9), defaultDailyGoal + 5),
      rec(DateTime(2026, 11, 3, 9), 3),
    ]);
    expect(s.days, 1);
    expect(s.goalDone, isFalse);
    expect(s.minutesToGoal, defaultDailyGoal - 3);
  });

  test('a run of goal days is counted', () {
    final s = snap([
      for (var d = 1; d <= 3; d++)
        rec(DateTime(2026, 11, d, 9), defaultDailyGoal),
    ]);
    expect(s.days, 3);
    expect(s.goalDone, isTrue);
  });

  test('a missed full day breaks the streak', () {
    final s = snap([rec(DateTime(2026, 10, 30, 9), defaultDailyGoal)]);
    expect(s.days, 0);
    expect(s.goalDone, isFalse);
  });

  test('minutes to goal never goes below zero', () {
    final s = snap([rec(DateTime(2026, 11, 3, 9), defaultDailyGoal * 4)]);
    expect(s.minutesToGoal, 0);
  });
}
