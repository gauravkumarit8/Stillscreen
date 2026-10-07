import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/models.dart';
import 'package:focus/core/reminder.dart';

void main() {
  group('dayKey', () {
    test('pads month and day', () => expect(dayKey(DateTime(2026, 3, 5)), '20260305'));
    test('two-digit month and day', () => expect(dayKey(DateTime(2026, 10, 17)), '20261017'));
    test('ignores the time of day', () {
      expect(dayKey(DateTime(2026, 10, 7, 0, 1)), dayKey(DateTime(2026, 10, 7, 23, 59)));
    });
  });

  group('reminderTextFor', () {
    test('professional gets the focus-block wording', () {
      expect(reminderTextFor(UserMode.professional).$1, 'Time for a focus block');
    });
    test('student and unset share the default wording', () {
      expect(reminderTextFor(UserMode.student).$1, 'Time to focus');
      expect(reminderTextFor(null).$1, 'Time to focus');
    });
  });
}
