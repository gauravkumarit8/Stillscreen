import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/session_log.dart';

Map<String, dynamic> entry(int day, int minutes) => {
      's': DateTime(2026, 10, day, 9).millisecondsSinceEpoch,
      'm': minutes,
      'c': true,
    };

void main() {
  test('no saved log gives an empty list', () {
    expect(decodeSessionLog(null), isEmpty);
  });

  test('a valid log is read in full', () {
    final raw = jsonEncode([entry(5, 20), entry(6, 25)]);
    final log = decodeSessionLog(raw);
    expect(log.length, 2);
    expect(log.first.minutes, 20);
  });

  test('one damaged entry is skipped and the rest are kept', () {
    final raw = jsonEncode([
      entry(5, 20),
      {'s': 'oops', 'm': null},
      entry(7, 30),
    ]);
    final log = decodeSessionLog(raw);
    expect(log.length, 2);
    expect(log.map((r) => r.minutes), [20, 30]);
  });

  test('text that is not a list gives an empty list', () {
    expect(decodeSessionLog('{"a": 1}'), isEmpty);
    expect(decodeSessionLog('not json at all'), isEmpty);
  });
}
