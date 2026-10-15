import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs.dart';
import 'session_log.dart';

class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.unlocked,
  });

  final String id;
  final String title;
  final String description;
  final bool unlocked;
}

/// Badges, worked out from the session history alone. Nothing is stored except
/// which ones the user has already been told about.
List<Achievement> computeAchievements(FocusStats s) {
  final longestSession =
      s.log.fold<int>(0, (best, r) => r.minutes > best ? r.minutes : best);
  final earlyBird = s.log.any((r) => r.start.hour >= 5 && r.start.hour < 7);

  return [
    Achievement(
      id: 'first_session',
      title: 'First step',
      description: 'Finish your first focus session',
      unlocked: s.totalMinutes > 0,
    ),
    Achievement(
      id: 'streak_3',
      title: 'Warming up',
      description: 'Reach a 3-day streak',
      unlocked: s.longestStreak >= 3,
    ),
    Achievement(
      id: 'streak_7',
      title: 'On a roll',
      description: 'Reach a 7-day streak',
      unlocked: s.longestStreak >= 7,
    ),
    Achievement(
      id: 'streak_30',
      title: 'Habit formed',
      description: 'Reach a 30-day streak',
      unlocked: s.longestStreak >= 30,
    ),
    Achievement(
      id: 'hours_5',
      title: 'Five hours in',
      description: 'Focus for 5 hours in total',
      unlocked: s.totalMinutes >= 300,
    ),
    Achievement(
      id: 'hours_25',
      title: 'Deep diver',
      description: 'Focus for 25 hours in total',
      unlocked: s.totalMinutes >= 1500,
    ),
    Achievement(
      id: 'hours_100',
      title: 'Centurion',
      description: 'Focus for 100 hours in total',
      unlocked: s.totalMinutes >= 6000,
    ),
    Achievement(
      id: 'long_session',
      title: 'Long haul',
      description: 'Focus for 60 minutes in one session',
      unlocked: longestSession >= 60,
    ),
    Achievement(
      id: 'early_bird',
      title: 'Early bird',
      description: 'Start a session between 5 and 7 AM',
      unlocked: earlyBird,
    ),
  ];
}

/// Badges that are unlocked but not yet shown to the user.
List<Achievement> newlyUnlocked(List<Achievement> all, Set<String> seen) =>
    all.where((a) => a.unlocked && !seen.contains(a.id)).toList();

class SeenAchievementsNotifier extends Notifier<Set<String>> {
  static const _key = 'ach_seen';

  @override
  Set<String> build() =>
      (ref.read(sharedPrefsProvider).getStringList(_key) ?? const <String>[])
          .toSet();

  Future<void> markSeen(Iterable<String> ids) async {
    final next = {...state, ...ids};
    if (next.length == state.length) return;
    state = next;
    await ref.read(sharedPrefsProvider).setStringList(_key, next.toList());
  }
}

final seenAchievementsProvider =
    NotifierProvider<SeenAchievementsNotifier, Set<String>>(
        SeenAchievementsNotifier.new);
