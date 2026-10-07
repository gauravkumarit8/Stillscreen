import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/share/share_text.dart';

void main() {
  group('formatMinutes', () {
    test('under an hour', () => expect(formatMinutes(45), '45 min'));
    test('whole hours', () => expect(formatMinutes(120), '2 h'));
    test('hours and minutes', () => expect(formatMinutes(125), '2 h 5 min'));
    test('zero', () => expect(formatMinutes(0), '0 min'));
  });

  group('shareCaption', () {
    test('uses the streak when there is one', () {
      expect(shareCaption(streak: 6, totalMinutes: 300),
          "I'm on a 6-day focus streak with Stillscreen.");
    });

    test('falls back to total time with no streak', () {
      expect(shareCaption(streak: 0, totalMinutes: 90),
          "I've focused for 1 h 30 min with Stillscreen.");
    });

    test('appends the store link when one is set', () {
      expect(
        shareCaption(streak: 3, totalMinutes: 100, link: 'https://example.com/x'),
        "I'm on a 3-day focus streak with Stillscreen.\nhttps://example.com/x",
      );
    });
  });
}
