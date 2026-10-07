import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs.dart';

/// A day counts toward the streak once you focus at least this many minutes.
const dailyGoalMinutes = 10;

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

/// Streak and totals, derived from the session log.
class FocusStats {
  FocusStats(this.log, {DateTime? now}) : today = dayOf(now ?? DateTime.now()) {
    for (final r in log) {
      final d = dayOf(r.start);
      _minutesByDay[d] = (_minutesByDay[d] ?? 0) + r.minutes;
    }
  }

  final List<SessionRecord> log;
  final DateTime today;
  final Map<DateTime, int> _minutesByDay = {};

  int minutesOn(DateTime d) => _minutesByDay[dayOf(d)] ?? 0;
  int get todayMinutes => minutesOn(today);
  int get totalMinutes => log.fold(0, (sum, r) => sum + r.minutes);

  bool _hitGoal(DateTime d) => minutesOn(d) >= dailyGoalMinutes;

  /// Consecutive goal days ending today. If today has not hit the goal yet,
  /// the streak still counts through yesterday, so it only breaks once a
  /// full day has passed.
  int get currentStreak {
    var day = _hitGoal(today) ? today : _previousDay(today);
    var count = 0;
    while (_hitGoal(day)) {
      count++;
      day = _previousDay(day);
    }
    return count;
  }

  int get longestStreak {
    final days = _minutesByDay.keys.where(_hitGoal).toList()..sort();
    var longest = 0;
    var run = 0;
    DateTime? prev;
    for (final d in days) {
      run = (prev != null && _previousDay(d) == prev) ? run + 1 : 1;
      if (run > longest) longest = run;
      prev = d;
    }
    return longest;
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
