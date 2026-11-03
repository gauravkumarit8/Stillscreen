/// A day on which the person tapped "Back to focus" on a block screen.
class FocusChoice {
  const FocusChoice({required this.date, required this.count});

  final DateTime date;
  final int count;

  factory FocusChoice.fromMap(Map<Object?, Object?> map) {
    int number(String key) => (map[key] as num?)?.toInt() ?? 0;
    return FocusChoice(
      date: DateTime(number('y'), number('m'), number('d')),
      count: number('n'),
    );
  }
}

/// How many times focus was chosen in the last [days] days, today included.
int chosenInLastDays(List<FocusChoice> choices, DateTime now, int days) {
  final today = DateTime(now.year, now.month, now.day);
  final first = DateTime(today.year, today.month, today.day - (days - 1));
  var total = 0;
  for (final c in choices) {
    final day = DateTime(c.date.year, c.date.month, c.date.day);
    if (!day.isBefore(first) && !day.isAfter(today)) total += c.count;
  }
  return total;
}
