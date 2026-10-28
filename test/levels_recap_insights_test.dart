import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/insights.dart';
import 'package:focus/core/levels.dart';
import 'package:focus/core/session_log.dart';
import 'package:focus/core/weekly_recap.dart';

SessionRecord rec(DateTime start, int minutes, {bool completed = true}) =>
    SessionRecord(start: start, minutes: minutes, completed: completed);

void main() {
  group('levels', () {
    test('zero minutes is level 1, a Seed', () {
      final l = levelFor(0);
      expect(l.index, 1);
      expect(l.name, 'Seed');
      expect(l.progress, 0);
      expect(l.minutesToNext, 30);
    });

    test('the first level up comes at 30 minutes', () {
      expect(levelFor(29).index, 1);
      expect(levelFor(30).index, 2);
      expect(levelFor(30).name, 'Sprout');
    });

    test('progress runs from 0 to 1 within a level', () {
      final l = levelFor(75); // Sprout runs 30..120
      expect(l.index, 2);
      expect(l.progress, closeTo(0.5, 0.001));
      expect(l.minutesToNext, 45);
      expect(l.nextName, 'Sapling');
    });

    test('the top level stays full with nothing left to reach', () {
      final l = levelFor(100000);
      expect(l.index, focusLevelCount);
      expect(l.isTop, isTrue);
      expect(l.progress, 1);
      expect(l.minutesToNext, isNull);
      expect(l.nextName, isNull);
    });

    test('negative totals are treated as zero', () {
      expect(levelFor(-50).index, 1);
    });

    test('label reads as level and name', () {
      expect(levelFor(120).label, 'Level 3 \u00B7 Sapling');
    });

    test('levels only go up as minutes grow', () {
      var last = 0;
      for (var m = 0; m < 6000; m += 7) {
        final i = levelFor(m).index;
        expect(i >= last, isTrue);
        last = i;
      }
    });

    test('a session that crosses a threshold reports the new level', () {
      final up = levelReachedBy(totalAfter: 35, sessionMinutes: 25);
      expect(up, isNotNull);
      expect(up!.name, 'Sprout');
    });

    test('a session inside a level reports nothing', () {
      expect(levelReachedBy(totalAfter: 60, sessionMinutes: 25), isNull);
    });

    test('a long session can skip a level and reports where it landed', () {
      final up = levelReachedBy(totalAfter: 130, sessionMinutes: 130);
      expect(up!.index, 3);
    });
  });

  group('weekly recap', () {
    final now = DateTime(2026, 10, 30, 12); // a Friday
    FocusStats stats(List<SessionRecord> log) => FocusStats(log, now: now);

    test('an empty history gives zeros and a prompt', () {
      final r = weeklyRecap(stats(const []));
      expect(r.thisWeekMinutes, 0);
      expect(r.sessions, 0);
      expect(bestDayLine(r), isNull);
      expect(recapHeadline(r), contains('No focus time yet'));
    });

    test('this week and last week are kept apart', () {
      final r = weeklyRecap(stats([
        rec(DateTime(2026, 10, 30, 9), 30), // today
        rec(DateTime(2026, 10, 25, 9), 20), // 5 days ago
        rec(DateTime(2026, 10, 20, 9), 40), // 10 days ago = last week
      ]));
      expect(r.thisWeekMinutes, 50);
      expect(r.lastWeekMinutes, 40);
      expect(r.change, 10);
      expect(r.sessions, 2);
    });

    test('the best day is the one with the most minutes', () {
      final r = weeklyRecap(stats([
        rec(DateTime(2026, 10, 28, 9), 25),
        rec(DateTime(2026, 10, 28, 15), 25),
        rec(DateTime(2026, 10, 29, 9), 30),
      ]));
      expect(r.bestDayMinutes, 50);
      expect(bestDayLine(r), 'Best day: Wednesday, 50 min');
    });

    test('headline says more, less or the same', () {
      expect(
        recapHeadline(const WeeklyRecap(
            thisWeekMinutes: 90, lastWeekMinutes: 30, sessions: 3,
            bestDayMinutes: 40, bestDay: null)),
        'You focused for 1 h 30 min this week, 1 h more than last week.',
      );
      expect(
        recapHeadline(const WeeklyRecap(
            thisWeekMinutes: 30, lastWeekMinutes: 90, sessions: 1,
            bestDayMinutes: 30, bestDay: null)),
        contains('less than last week'),
      );
      expect(
        recapHeadline(const WeeklyRecap(
            thisWeekMinutes: 60, lastWeekMinutes: 60, sessions: 2,
            bestDayMinutes: 30, bestDay: null)),
        contains('the same as last week'),
      );
      expect(
        recapHeadline(const WeeklyRecap(
            thisWeekMinutes: 25, lastWeekMinutes: 0, sessions: 1,
            bestDayMinutes: 25, bestDay: null)),
        contains('A great start'),
      );
    });

    test('a session over midnight counts on both days of the window', () {
      final r = weeklyRecap(stats([rec(DateTime(2026, 10, 29, 23, 50), 30)]));
      expect(r.thisWeekMinutes, 30);
      expect(r.sessions, 1);
    });
  });

  group('insights', () {
    test('no sessions gives nothing to say', () {
      final i = focusInsights(const []);
      expect(i.hasEnoughData, isFalse);
      expect(i.bestPart, isNull);
    });

    test('it needs a few sessions before it speaks', () {
      final i = focusInsights([
        rec(DateTime(2026, 10, 1, 9), 25),
        rec(DateTime(2026, 10, 2, 9), 25),
      ]);
      expect(i.hasEnoughData, isFalse);
    });

    test('the best part of day is the one with the most minutes', () {
      final i = focusInsights([
        rec(DateTime(2026, 10, 1, 9), 25),
        rec(DateTime(2026, 10, 2, 20), 50),
        rec(DateTime(2026, 10, 3, 21), 50),
        rec(DateTime(2026, 10, 4, 6), 25),
      ]);
      expect(i.hasEnoughData, isTrue);
      expect(i.bestPart, DayPart.evening);
      expect(i.averageMinutes, 38); // 150 / 4 rounded
    });

    test('early-ended sessions are left out', () {
      final i = focusInsights([
        rec(DateTime(2026, 10, 1, 9), 25),
        rec(DateTime(2026, 10, 2, 9), 25),
        rec(DateTime(2026, 10, 3, 9), 25),
        rec(DateTime(2026, 10, 3, 22), 120, completed: false),
      ]);
      expect(i.sessionCount, 3);
      expect(i.bestPart, DayPart.morning);
    });

    test('day parts cover the clock', () {
      expect(dayPartOf(DateTime(2026, 1, 1, 4, 59)), DayPart.night);
      expect(dayPartOf(DateTime(2026, 1, 1, 5)), DayPart.morning);
      expect(dayPartOf(DateTime(2026, 1, 1, 12)), DayPart.afternoon);
      expect(dayPartOf(DateTime(2026, 1, 1, 17)), DayPart.evening);
      expect(dayPartOf(DateTime(2026, 1, 1, 22)), DayPart.night);
    });
  });
}
