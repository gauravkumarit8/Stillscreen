import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/battery_guide.dart';

void main() {
  const makers = [
    'Xiaomi', 'OPPO', 'realme', 'OnePlus', 'vivo', 'samsung',
    'HUAWEI', 'HONOR', 'Google', 'motorola', 'TECNO', '',
  ];

  test('every manufacturer gets at least one step', () {
    for (final m in makers) {
      expect(stepsFor(m), isNotEmpty, reason: 'no steps for "$m"');
    }
  });

  test('brand matching ignores case', () {
    expect(stepsFor('XIAOMI').first, contains('Autostart'));
    expect(stepsFor('Samsung').first, contains('Background usage limits'));
  });

  test('autostart screen is offered only for brands that have one', () {
    expect(hasAutostartScreen('Xiaomi'), isTrue);
    expect(hasAutostartScreen('vivo'), isTrue);
    expect(hasAutostartScreen('samsung'), isFalse);
    expect(hasAutostartScreen('Google'), isFalse);
  });
}
