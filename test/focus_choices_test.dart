import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/focus_choices.dart';

FocusChoice choice(int y, int m, int d, int n) =>
    FocusChoice(date: DateTime(y, m, d), count: n);

void main() {
  final now = DateTime(2026, 11, 3, 15);

  test('no choices adds up to zero', () {
    expect(chosenInLastDays(const [], now, 7), 0);
  });

  test('today and the six days before it are counted', () {
    final total = chosenInLastDays([
      choice(2026, 11, 3, 2), // today
      choice(2026, 10, 28, 3), // six days ago, the first day of the window
    ], now, 7);
    expect(total, 5);
  });

  test('older days are left out', () {
    final total = chosenInLastDays([
      choice(2026, 10, 27, 4), // seven days ago
      choice(2026, 11, 2, 1),
    ], now, 7);
    expect(total, 1);
  });

  test('future days are left out', () {
    expect(chosenInLastDays([choice(2026, 11, 4, 9)], now, 7), 0);
  });

  test('the window works across a month change', () {
    final total = chosenInLastDays([
      choice(2026, 10, 31, 2),
      choice(2026, 11, 1, 2),
    ], now, 7);
    expect(total, 4);
  });

  test('fromMap reads the values from the phone side', () {
    final c = FocusChoice.fromMap({'y': 2026, 'm': 11, 'd': 3, 'n': 5});
    expect(c.date, DateTime(2026, 11, 3));
    expect(c.count, 5);
  });

  test('fromMap tolerates missing values', () {
    expect(FocusChoice.fromMap({}).count, 0);
  });
}
