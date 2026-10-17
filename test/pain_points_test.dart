import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/time_ago.dart';

void main() {
  final now = DateTime(2026, 10, 15, 12, 0, 0);

  group('timeAgo', () {
    test('under a minute', () {
      expect(timeAgo(now.subtract(const Duration(seconds: 20)), now), 'just now');
    });
    test('minutes', () {
      expect(timeAgo(now.subtract(const Duration(minutes: 5)), now), '5 min ago');
      expect(timeAgo(now.subtract(const Duration(minutes: 59)), now), '59 min ago');
    });
    test('hours', () {
      expect(timeAgo(now.subtract(const Duration(hours: 1)), now), '1 hour ago');
      expect(timeAgo(now.subtract(const Duration(hours: 5)), now), '5 hours ago');
    });
    test('days', () {
      expect(timeAgo(now.subtract(const Duration(days: 1)), now), '1 day ago');
      expect(timeAgo(now.subtract(const Duration(days: 3)), now), '3 days ago');
    });
    test('a time slightly in the future (clock change) reads as just now', () {
      expect(timeAgo(now.add(const Duration(minutes: 3)), now), 'just now');
    });
  });
}
