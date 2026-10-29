import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/session_tip.dart';

void main() {
  test('shown once on Xiaomi-family phones', () {
    expect(shouldShowSessionTip(manufacturer: 'Xiaomi', alreadyShown: false), isTrue);
    expect(shouldShowSessionTip(manufacturer: 'POCO', alreadyShown: false), isTrue);
    expect(shouldShowSessionTip(manufacturer: 'Redmi', alreadyShown: false), isTrue);
  });

  test('not shown again once it has been shown', () {
    expect(shouldShowSessionTip(manufacturer: 'Xiaomi', alreadyShown: true), isFalse);
  });

  test('not shown on other brands', () {
    expect(shouldShowSessionTip(manufacturer: 'samsung', alreadyShown: false), isFalse);
    expect(shouldShowSessionTip(manufacturer: '', alreadyShown: false), isFalse);
  });

  test('the tip names the lock and the swipe', () {
    expect(sessionTipText, contains('lock'));
    expect(sessionTipText, contains('swiping'));
  });
}
