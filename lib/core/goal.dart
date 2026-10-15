import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs.dart';

const defaultDailyGoal = 10;
const goalOptions = [10, 20, 30, 45, 60, 90, 120];

String _dayKey(DateTime d) => '${d.year.toString().padLeft(4, '0')}'
    '${d.month.toString().padLeft(2, '0')}'
    '${d.day.toString().padLeft(2, '0')}';

class GoalEntry {
  const GoalEntry(this.day, this.minutes);

  /// "20261014" style local day.
  final String day;
  final int minutes;
}

/// The daily goal over time. A new goal applies from the day it is set, and
/// earlier days keep the goal they had, so raising it never breaks old streaks.
class GoalHistory {
  const GoalHistory([this.entries = const []]);

  /// Oldest first.
  final List<GoalEntry> entries;

  int goalOn(DateTime day) {
    final key = _dayKey(day);
    var goal = defaultDailyGoal;
    for (final e in entries) {
      if (e.day.compareTo(key) <= 0) {
        goal = e.minutes;
      } else {
        break;
      }
    }
    return goal;
  }

  GoalHistory withGoal(DateTime day, int minutes) {
    final key = _dayKey(day);
    final next = <GoalEntry>[
      for (final e in entries)
        if (e.day != key) e,
      GoalEntry(key, minutes),
    ]..sort((a, b) => a.day.compareTo(b.day));
    return GoalHistory(next);
  }

  String encode() =>
      jsonEncode([for (final e in entries) {'d': e.day, 'm': e.minutes}]);

  static GoalHistory decode(String? raw) {
    if (raw == null) return const GoalHistory();
    try {
      final list = (jsonDecode(raw) as List)
          .map((e) => GoalEntry(e['d'] as String, e['m'] as int))
          .toList()
        ..sort((a, b) => a.day.compareTo(b.day));
      return GoalHistory(list);
    } catch (_) {
      return const GoalHistory();
    }
  }
}

class GoalHistoryNotifier extends Notifier<GoalHistory> {
  static const _key = 'goal_history';

  @override
  GoalHistory build() =>
      GoalHistory.decode(ref.read(sharedPrefsProvider).getString(_key));

  Future<void> setGoal(int minutes, {DateTime? today}) async {
    state = state.withGoal(today ?? DateTime.now(), minutes);
    await ref.read(sharedPrefsProvider).setString(_key, state.encode());
  }
}

final goalHistoryProvider =
    NotifierProvider<GoalHistoryNotifier, GoalHistory>(GoalHistoryNotifier.new);
