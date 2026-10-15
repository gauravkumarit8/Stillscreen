import 'dart:convert';
import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'goal.dart';
import 'prefs.dart';

/// A day counts toward the streak once you focus at least this many minutes.
const dailyGoalMinutes = defaultDailyGoal;

/// Start time of the running session (ms since epoch). Paired with sessionEndKey.
const sessionStartKey = 'session_start';

class SessionRecord {
  const SessionRecord({
    required this.start,
    required this.minutes,
    required this.completed,
  });

  final DateTime start;
  final int minutes;
  final bool completed;

  Map<String, dynamic> toJson() => {
        's': start.millisecondsSinceEpoch,
        'm': minutes,
        'c': completed,
      };

  factory SessionRecord.fromJson(Map<String, dynamic> j) => SessionRecord(
        start: DateTime.fromMillisecondsSinceEpoch(j['s'] as int),
        minutes: j['m'] as int,
        completed: j['c'] as bool,
      );
}

DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);
DateTime _previousDay(DateTime d) => DateTime(d.year, d.month, d.day - 1);
DateTime _nextDay(DateTime d) => DateTime(d.year, d.month, d.day + 1);

class SessionLogNotifier extends Notifier<List<SessionRecord>> {
  static const _key = 'session_log';

  @override
  List<SessionRecord> build() {
    final raw = ref.read(sharedPrefsProvider).getString(_key);
    if (raw == null) return const [];
    try {
      return (jsonDecode(raw) as List)
          .map((e) => SessionRecord.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> add(SessionRecord record) async {
    if (record.minutes < 1) return;
    state = [...state, record];
    await ref
        .read(sharedPrefsProvider)
        .setString(_key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }

  /// Replaces the whole history. Used by the debug-only demo data menu.
  Future<void> replaceAll(List<SessionRecord> records) async {
    state = List.of(records);
    await ref
        .read(sharedPrefsProvider)
        .setString(_key, jsonEncode(state.map((e) => e.toJson()).toList()));
  }
}

final sessionLogProvider =
    NotifierProvider<SessionLogNotifier, List<SessionRecord>>(
        SessionLogNotifier.new);

/// Days in a row that earn a rest day, and the most you can hold at once.
const freezeEveryDays = 7;
const maxFreezes = 2;

/// Streak and totals, derived from the session log.
///
/// A streak counts days that reached the goal. Every [freezeEveryDays] such
/// days earns a rest day (up to [maxFreezes]). A missed day uses one instead of
/// ending the streak, so a single slip does not wipe out weeks of effort.
class FocusStats {
  FocusStats(this.log, {DateTime? now, GoalHistory? goals})
      : today = dayOf(now ?? DateTime.now()),
        _goals = goals ?? const GoalHistory() {
    for (final r in log) {
      final d = dayOf(r.start);
      _minutesByDay[d] = (_minutesByDay[d] ?? 0) + r.minutes;
    }
    _walk();
  }

  final List<SessionRecord> log;
  final DateTime today;
  final GoalHistory _goals;
  final Map<DateTime, int> _minutesByDay = {};

  int _current = 0;
  int _longest = 0;
  int _freezes = 0;

  int minutesOn(DateTime d) => _minutesByDay[dayOf(d)] ?? 0;
  int get todayMinutes => minutesOn(today);
  int get totalMinutes => log.fold(0, (sum, r) => sum + r.minutes);

  int goalOn(DateTime d) => _goals.goalOn(d);
  int get todayGoal => goalOn(today);
  bool hitGoal(DateTime d) => minutesOn(d) >= goalOn(d);

  /// Consecutive goal days ending today. If today has not reached the goal yet,
  /// the streak still counts through yesterday, so it only breaks once a full
  /// day has passed.
  int get currentStreak => _current;
  int get longestStreak => _longest;

  /// Rest days you are holding right now.
  int get freezes => _freezes;

  void _walk() {
    if (_minutesByDay.isEmpty) return;
    var day = _minutesByDay.keys.reduce((a, b) => a.isBefore(b) ? a : b);
    var streak = 0;
    var longest = 0;
    var freezes = 0;
    var runSinceAward = 0;

    while (!day.isAfter(today)) {
      if (hitGoal(day)) {
        streak++;
        runSinceAward++;
        if (runSinceAward == freezeEveryDays) {
          freezes = min(freezes + 1, maxFreezes);
          runSinceAward = 0;
        }
        if (streak > longest) longest = streak;
      } else if (day == today) {
        // Today is still open: it neither counts nor breaks anything yet.
      } else if (streak > 0 && freezes > 0) {
        freezes--; // a rest day absorbs the miss
      } else {
        streak = 0;
        runSinceAward = 0;
      }
      day = _nextDay(day);
    }

    _current = streak;
    _longest = longest;
    _freezes = freezes;
  }

  /// Oldest first, ending today.
  List<DateTime> lastDays(int n) {
    final days = <DateTime>[];
    var d = today;
    for (var i = 0; i < n; i++) {
      days.add(d);
      d = _previousDay(d);
    }
    return days.reversed.toList();
  }
}
