import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/session_length.dart';

void main() {
  group('normalizeSessionMinutes', () {
    test('nothing saved gives the default', () {
      expect(normalizeSessionMinutes(null), defaultSessionMinutes);
    });
    test('presets are kept as they are', () {
      for (final m in sessionPresets) {
        expect(normalizeSessionMinutes(m), m);
      }
    });
    test('rounds to the nearest five', () {
      expect(normalizeSessionMinutes(37), 35);
      expect(normalizeSessionMinutes(38), 40);
    });
    test('stays inside the allowed range', () {
      expect(normalizeSessionMinutes(1), minSessionMinutes);
      expect(normalizeSessionMinutes(0), minSessionMinutes);
      expect(normalizeSessionMinutes(500), maxSessionMinutes);
      expect(normalizeSessionMinutes(-20), minSessionMinutes);
    });
  });

  test('presets are recognised, other lengths are custom', () {
    expect(isPresetLength(50), isTrue);
    expect(isPresetLength(45), isFalse);
  });

  test('every preset fits the allowed range', () {
    for (final m in sessionPresets) {
      expect(m, inInclusiveRange(minSessionMinutes, maxSessionMinutes));
    }
  });
}
