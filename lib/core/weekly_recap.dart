import 'session_log.dart';

/// How this week compares with the one before it. A "week" here is the last
/// seven days, ending today.
class WeeklyRecap {
  const WeeklyRecap({
    required this.thisWeekMinutes,
    required this.lastWeekMinutes,
    required this.sessions,
    required this.bestDayMinutes,
    required this.bestDay,
  });

  final int thisWeekMinutes;
  final int lastWeekMinutes;
  final int sessions;
  final int bestDayMinutes;
  final DateTime? bestDay;

  int get change => thisWeekMinutes - lastWeekMinutes;
}

WeeklyRecap weeklyRecap(FocusStats stats) {
  final today = stats.today;
  var thisWeek = 0;
  var lastWeek = 0;
  var bestMinutes = 0;
  DateTime? bestDay;

  for (var i = 0; i < 7; i++) {
    final day = DateTime(today.year, today.month, today.day - i);
    final minutes = stats.minutesOn(day);
    thisWeek += minutes;
    if (minutes > bestMinutes) {
      bestMinutes = minutes;
      bestDay = day;
    }
    final before = DateTime(today.year, today.month, today.day - i - 7);
    lastWeek += stats.minutesOn(before);
  }

  final windowStart = DateTime(today.year, today.month, today.day - 6);
  final sessions = stats.log
      .where((r) => r.completed && !dayOf(r.start).isBefore(windowStart))
      .length;

  return WeeklyRecap(
    thisWeekMinutes: thisWeek,
    lastWeekMinutes: lastWeek,
    sessions: sessions,
    bestDayMinutes: bestMinutes,
    bestDay: bestDay,
  );
}

String _duration(int minutes) {
  if (minutes < 60) return '$minutes min';
  final rest = minutes % 60;
  return rest == 0 ? '${minutes ~/ 60} h' : '${minutes ~/ 60} h $rest min';
}

const _weekdayNames = [
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
  'Sunday',
];

/// One friendly sentence for the top of the recap card.
String recapHeadline(WeeklyRecap r) {
  if (r.thisWeekMinutes == 0) {
    return 'No focus time yet this week. One short session gets it going.';
  }
  final total = _duration(r.thisWeekMinutes);
  if (r.lastWeekMinutes == 0) {
    return 'You focused for $total this week. A great start.';
  }
  if (r.change > 0) {
    return 'You focused for $total this week, ${_duration(r.change)} more than last week.';
  }
  if (r.change < 0) {
    return 'You focused for $total this week, ${_duration(-r.change)} less than last week.';
  }
  return 'You focused for $total this week, the same as last week.';
}

String? bestDayLine(WeeklyRecap r) {
  final day = r.bestDay;
  if (day == null || r.bestDayMinutes == 0) return null;
  return 'Best day: ${_weekdayNames[day.weekday - 1]}, ${_duration(r.bestDayMinutes)}';
}
