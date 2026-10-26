import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/block_diagnostics.dart';

void main() {
  final now = DateTime(2026, 10, 25, 22, 25);

  test('nothing seen yet reads as a prompt to test', () {
    expect(describeSeen(const BlockDiagnostics(), now), contains('No app seen'));
  });

  test('a seen app shows its package and when', () {
    final d = BlockDiagnostics(
      seenPackage: 'com.google.android.youtube',
      seenAt: now.subtract(const Duration(minutes: 3)).millisecondsSinceEpoch,
    );
    final text = describeSeen(d, now);
    expect(text, contains('com.google.android.youtube'));
    expect(text, contains('3'));
  });

  test('no attempt yet explains when it will fill in', () {
    expect(describeAttempt(const BlockDiagnostics(), now), startsWith('None yet'));
  });

  test('an attempt shows the app and what happened', () {
    final d = BlockDiagnostics(
      attemptPackage: 'com.google.android.youtube',
      attemptAt: now.subtract(const Duration(minutes: 1)).millisecondsSinceEpoch,
      attemptResult: 'block screen did not appear, sent Home instead',
    );
    final text = describeAttempt(d, now);
    expect(text, contains('com.google.android.youtube'));
    expect(text, contains('sent Home instead'));
  });

  test('fromMap reads the values from the native side', () {
    final d = BlockDiagnostics.fromMap({
      'seenPackage': 'a.b',
      'seenAt': 5,
      'attemptPackage': 'c.d',
      'attemptAt': 6,
      'attemptResult': 'opened the screen',
    });
    expect(d.seenPackage, 'a.b');
    expect(d.attemptAt, 6);
    expect(d.attemptResult, 'opened the screen');
  });

  test('fromMap tolerates missing values', () {
    final d = BlockDiagnostics.fromMap({});
    expect(d.seenAt, 0);
    expect(d.attemptResult, '');
  });

  group('describeExits', () {
    test('no stops recorded says so', () {
      expect(describeExits(const [], now), contains('No recent stops'));
    });

    test('lists the reason and when, newest first, with detail', () {
      final exits = [
        ProcessExit(
          reason: 'killed by the system',
          at: now.subtract(const Duration(minutes: 2)).millisecondsSinceEpoch,
          detail: 'freezer',
        ),
        ProcessExit(
          reason: 'crashed',
          at: now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        ),
      ];
      final lines = describeExits(exits, now).split('\n');
      expect(lines.length, 2);
      expect(lines.first, contains('killed by the system'));
      expect(lines.first, contains('(freezer)'));
      expect(lines.last, contains('crashed'));
      expect(lines.last, isNot(contains('(')));
    });

    test('shows at most three stops', () {
      final exits = List.generate(
        5,
        (i) => ProcessExit(
          reason: 'stop $i',
          at: now.subtract(Duration(minutes: i + 1)).millisecondsSinceEpoch,
        ),
      );
      expect(describeExits(exits, now).split('\n').length, 3);
    });

    test('fromMap tolerates missing values', () {
      final e = ProcessExit.fromMap({});
      expect(e.at, 0);
      expect(e.reason, '');
    });
  });
}
