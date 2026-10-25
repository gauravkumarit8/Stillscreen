import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/pomodoro.dart';

void main() {
  final t0 = DateTime(2026, 10, 7, 9, 0);

  test('the first session is round 1 with a short break', () {
    final r = nextPomodoroRound(
      previousRound: 0,
      lastEnd: null,
      sessionStart: t0,
    );
    expect(r.round, 1);
    expect(r.isLastOfCycle, isFalse);
    expect(r.breakMinutes, shortBreakMinutes);
    expect(r.label, 'Round 1 of 4');
  });

  test('a session soon after the last one is the next round', () {
    final r = nextPomodoroRound(
      previousRound: 1,
      lastEnd: t0,
      sessionStart: t0.add(const Duration(minutes: 5)),
    );
    expect(r.round, 2);
  });

  test('the fourth round earns the long break', () {
    final r = nextPomodoroRound(
      previousRound: 3,
      lastEnd: t0,
      sessionStart: t0.add(const Duration(minutes: 5)),
    );
    expect(r.round, 4);
    expect(r.isLastOfCycle, isTrue);
    expect(r.breakMinutes, longBreakMinutes);
  });

  test('a new cycle starts after the long break', () {
    final r = nextPomodoroRound(
      previousRound: 4,
      lastEnd: t0,
      sessionStart: t0.add(const Duration(minutes: 15)),
    );
    expect(r.round, 1);
  });

  test('a long gap starts the cycle again', () {
    final r = nextPomodoroRound(
      previousRound: 2,
      lastEnd: t0,
      sessionStart: t0.add(const Duration(hours: 3)),
    );
    expect(r.round, 1);
  });

  test('a gap exactly at the limit still continues the cycle', () {
    final r = nextPomodoroRound(
      previousRound: 2,
      lastEnd: t0,
      sessionStart: t0.add(pomodoroResetGap),
    );
    expect(r.round, 3);
  });
}
