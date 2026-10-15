import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/achievements.dart';
import 'package:focus/core/goal.dart';
import 'package:focus/core/session_log.dart';

SessionRecord rec(int day, int minutes, {int hour = 9}) => SessionRecord(
      start: DateTime(2026, 10, day, hour),
      minutes: minutes,
      completed: true,
    );

List<SessionRecord> days(Iterable<int> ns, {int minutes = 20}) =>
    [for (final n in ns) rec(n, minutes)];

Iterable<int> upTo(int n) => [for (var i = 1; i <= n; i++) i];

DateTime at(int day) => DateTime(2026, 10, day, 12);

void main() {
  group('rest days', () {
    test('seven days in a row earn one', () {
      final s = FocusStats(days(upTo(7)), now: at(7));
      expect(s.currentStreak, 7);
      expect(s.freezes, 1);
    });

    test('one missed day is absorbed by it', () {
      final s = FocusStats(days([...upTo(7), 9]), now: at(9));
      expect(s.currentStreak, 8);
      expect(s.freezes, 0);
    });

    test('a second miss ends the streak, and the longest is remembered', () {
      final s = FocusStats(days([...upTo(7), 10]), now: at(10));
      expect(s.currentStreak, 1);
      expect(s.longestStreak, 7);
      expect(s.freezes, 0);
    });

    test('you can hold at most two', () {
      expect(FocusStats(days(upTo(14)), now: at(14)).freezes, 2);
      expect(FocusStats(days(upTo(21)), now: at(21)).freezes, 2);
    });

    test('two misses are covered by two rest days', () {
      final s = FocusStats(days([...upTo(14), 17]), now: at(17));
      expect(s.currentStreak, 15);
      expect(s.freezes, 0);
    });

    test('today still being open does not spend a rest day', () {
      final s = FocusStats(days(upTo(7)), now: at(8));
      expect(s.currentStreak, 7);
      expect(s.freezes, 1);
    });

    test('short streaks behave exactly as before', () {
      expect(FocusStats(days([7, 5]), now: at(7)).currentStreak, 1);
      expect(FocusStats(days([6, 5]), now: at(7)).currentStreak, 2);
    });
  });

  group('daily goal', () {
    test('defaults to 10 minutes', () {
      expect(const GoalHistory().goalOn(at(5)), defaultDailyGoal);
    });

    test('a new goal applies from its day, earlier days keep the old one', () {
      final g = const GoalHistory().withGoal(at(8), 60);
      expect(g.goalOn(at(7)), defaultDailyGoal);
      expect(g.goalOn(at(8)), 60);
      expect(g.goalOn(at(20)), 60);
    });

    test('changing it twice on the same day replaces the first', () {
      final g = const GoalHistory().withGoal(at(8), 60).withGoal(at(8), 20);
      expect(g.goalOn(at(8)), 20);
      expect(g.entries.length, 1);
    });

    test('raising the goal does not break earlier streak days', () {
      final goals = const GoalHistory().withGoal(at(8), 60);
      final s = FocusStats(days(upTo(7), minutes: 15), now: at(7), goals: goals);
      expect(s.currentStreak, 7);
    });

    test('survives being saved and loaded', () {
      final g = const GoalHistory().withGoal(at(3), 30).withGoal(at(9), 45);
      final back = GoalHistory.decode(g.encode());
      expect(back.goalOn(at(2)), defaultDailyGoal);
      expect(back.goalOn(at(5)), 30);
      expect(back.goalOn(at(12)), 45);
    });

    test('unreadable saved data falls back to the default', () {
      expect(GoalHistory.decode('not json').goalOn(at(5)), defaultDailyGoal);
      expect(GoalHistory.decode(null).goalOn(at(5)), defaultDailyGoal);
    });
  });

  group('achievements', () {
    Set<String> unlocked(FocusStats s) =>
        computeAchievements(s).where((a) => a.unlocked).map((a) => a.id).toSet();

    test('nothing unlocked with no history', () {
      expect(unlocked(FocusStats(const [], now: at(5))), isEmpty);
    });

    test('first session', () {
      expect(unlocked(FocusStats([rec(5, 25)], now: at(5))), {'first_session'});
    });

    test('streak badges use the longest streak', () {
      final s = FocusStats(days(upTo(7)), now: at(7));
      expect(unlocked(s), containsAll(['streak_3', 'streak_7']));
      expect(unlocked(s), isNot(contains('streak_30')));
    });

    test('total time badges', () {
      final s = FocusStats([rec(1, 200), rec(2, 120)], now: at(2));
      expect(unlocked(s), contains('hours_5'));
      expect(unlocked(s), isNot(contains('hours_25')));
    });

    test('long session and early bird', () {
      final s = FocusStats([rec(3, 75, hour: 6)], now: at(3));
      expect(unlocked(s), containsAll(['long_session', 'early_bird']));
    });

    test('a 7 AM start is not an early bird', () {
      expect(unlocked(FocusStats([rec(3, 20, hour: 7)], now: at(3))),
          isNot(contains('early_bird')));
    });

    test('newlyUnlocked leaves out what the user has already seen', () {
      final all = computeAchievements(FocusStats(days(upTo(7)), now: at(7)));
      final fresh = newlyUnlocked(all, {'first_session', 'streak_3'});
      // 7 days at 20 minutes: the 7-day badge is new, the 5-hour one is not earned yet.
      expect(fresh.map((a) => a.id).toList(), ['streak_7']);
    });
  });
}
