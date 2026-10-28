import 'session_log.dart';

enum DayPart { morning, afternoon, evening, night }

DayPart dayPartOf(DateTime t) {
  final h = t.hour;
  if (h >= 5 && h < 12) return DayPart.morning;
  if (h >= 12 && h < 17) return DayPart.afternoon;
  if (h >= 17 && h < 22) return DayPart.evening;
  return DayPart.night;
}

String dayPartName(DayPart p) => switch (p) {
      DayPart.morning => 'morning',
      DayPart.afternoon => 'afternoon',
      DayPart.evening => 'evening',
      DayPart.night => 'late night',
    };

/// Patterns in how the person focuses. Shown only once there is enough
/// history for them to mean something.
const insightsMinSessions = 3;

class FocusInsights {
  const FocusInsights({
    required this.sessionCount,
    required this.averageMinutes,
    required this.bestPart,
  });

  final int sessionCount;
  final int averageMinutes;
  final DayPart? bestPart;

  bool get hasEnoughData => sessionCount >= insightsMinSessions;
}

FocusInsights focusInsights(List<SessionRecord> log) {
  final done = log.where((r) => r.completed).toList();
  if (done.isEmpty) {
    return const FocusInsights(sessionCount: 0, averageMinutes: 0, bestPart: null);
  }

  final byPart = <DayPart, int>{};
  var total = 0;
  for (final r in done) {
    total += r.minutes;
    final part = dayPartOf(r.start);
    byPart[part] = (byPart[part] ?? 0) + r.minutes;
  }

  DayPart? best;
  var bestMinutes = 0;
  for (final part in DayPart.values) {
    final m = byPart[part] ?? 0;
    if (m > bestMinutes) {
      bestMinutes = m;
      best = part;
    }
  }

  return FocusInsights(
    sessionCount: done.length,
    averageMinutes: (total / done.length).round(),
    bestPart: best,
  );
}
