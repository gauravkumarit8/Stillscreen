import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'prefs.dart';

/// Pomodoro rounds: focus sessions in a row, with a short break after each and
/// a longer one after the last round of a cycle. It only suggests breaks. It
/// never starts or blocks anything by itself.
const pomodoroRoundsPerCycle = 4;
const shortBreakMinutes = 5;
const longBreakMinutes = 15;

/// If the next session starts later than this after the last one ended, the
/// cycle starts again at round one. This leaves room for the longest break.
const pomodoroResetGap = Duration(minutes: 30);

class PomodoroRound {
  const PomodoroRound({required this.round, required this.isLastOfCycle});

  /// 1 to [pomodoroRoundsPerCycle].
  final int round;
  final bool isLastOfCycle;

  int get breakMinutes => isLastOfCycle ? longBreakMinutes : shortBreakMinutes;

  String get label => 'Round $round of $pomodoroRoundsPerCycle';
}

/// Works out which round a session that just finished made.
///
/// [previousRound] is the round the last finished session made (0 if none) and
/// [lastEnd] is when it ended. A new cycle starts after the last round of a
/// cycle, or when the gap since [lastEnd] was longer than [pomodoroResetGap].
PomodoroRound nextPomodoroRound({
  required int previousRound,
  required DateTime? lastEnd,
  required DateTime sessionStart,
}) {
  final startsFresh = previousRound <= 0 ||
      previousRound >= pomodoroRoundsPerCycle ||
      lastEnd == null ||
      sessionStart.difference(lastEnd) > pomodoroResetGap;
  final round = startsFresh ? 1 : previousRound + 1;
  return PomodoroRound(
    round: round,
    isLastOfCycle: round == pomodoroRoundsPerCycle,
  );
}

class PomodoroEnabledNotifier extends Notifier<bool> {
  static const _key = 'pomodoro_enabled';

  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(_key) ?? false;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPrefsProvider).setBool(_key, value);
  }
}

final pomodoroEnabledProvider =
    NotifierProvider<PomodoroEnabledNotifier, bool>(PomodoroEnabledNotifier.new);

/// Remembers which round the last finished session made.
class PomodoroTracker {
  PomodoroTracker(this._prefs);

  static const _roundKey = 'pomodoro_round';
  static const _endKey = 'pomodoro_last_end';

  final SharedPreferences _prefs;

  Future<PomodoroRound> completeRound({
    required DateTime sessionStart,
    required DateTime sessionEnd,
  }) async {
    final lastEndMs = _prefs.getInt(_endKey);
    final round = nextPomodoroRound(
      previousRound: _prefs.getInt(_roundKey) ?? 0,
      lastEnd: lastEndMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(lastEndMs),
      sessionStart: sessionStart,
    );
    await _prefs.setInt(_roundKey, round.round);
    await _prefs.setInt(_endKey, sessionEnd.millisecondsSinceEpoch);
    return round;
  }
}

final pomodoroTrackerProvider = Provider<PomodoroTracker>(
  (ref) => PomodoroTracker(ref.read(sharedPrefsProvider)),
);
