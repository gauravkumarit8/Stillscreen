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
}
