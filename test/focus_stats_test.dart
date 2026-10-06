import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/session_log.dart';

SessionRecord rec(DateTime start, int minutes) =>
    SessionRecord(start: start, minutes: minutes, completed: true);

void main() {
  final now = DateTime(2026, 10, 7, 12);

  test('streak counts consecutive days that hit the goal', () {
    final stats = FocusStats([
      rec(DateTime(2026, 10, 7, 9), 10),
      rec(DateTime(2026, 10, 6, 9), 25),
      rec(DateTime(2026, 10, 5, 9), 12),
    ], now: now);
    expect(stats.currentStreak, 3);
  });

  test('streak survives until today ends', () {
    final stats = FocusStats([
      rec(DateTime(2026, 10, 6, 9), 20),
      rec(DateTime(2026, 10, 5, 9), 20),
    ], now: now);
    expect(stats.currentStreak, 2);
  });

  test('a missed day resets the streak', () {
    final stats = FocusStats([
      rec(DateTime(2026, 10, 7, 9), 20),
      rec(DateTime(2026, 10, 5, 9), 20),
    ], now: now);
    expect(stats.currentStreak, 1);
  });

  test('a day below the goal does not count', () {
    final stats = FocusStats([rec(DateTime(2026, 10, 7, 9), 5)], now: now);
    expect(stats.currentStreak, 0);
    expect(stats.todayMinutes, 5);
  });

  test('several short sessions on one day add up', () {
    final stats = FocusStats([
      rec(DateTime(2026, 10, 7, 8), 4),
      rec(DateTime(2026, 10, 7, 15), 6),
    ], now: now);
    expect(stats.currentStreak, 1);
  });

  test('longest streak is found across gaps', () {
    final stats = FocusStats([
      rec(DateTime(2026, 9, 28, 9), 15),
      rec(DateTime(2026, 9, 29, 9), 15),
      rec(DateTime(2026, 9, 30, 9), 15),
      rec(DateTime(2026, 10, 2, 9), 15),
      rec(DateTime(2026, 10, 7, 9), 15),
    ], now: now);
    expect(stats.longestStreak, 3);
    expect(stats.currentStreak, 1);
  });

  test('lastDays returns seven days ending today', () {
    final days = FocusStats(const [], now: now).lastDays(7);
    expect(days.length, 7);
    expect(days.first, DateTime(2026, 10, 1));
    expect(days.last, DateTime(2026, 10, 7));
  });
}
