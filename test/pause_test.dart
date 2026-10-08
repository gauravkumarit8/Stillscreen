import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/app_packs.dart';
import 'package:focus/core/blocking/blocking_engine.dart';
import 'package:focus/core/pause.dart';

void main() {
  group('pauseSubtitle', () {
    test('off', () => expect(pauseSubtitle(const PauseConfig(), 3), 'Off'));
    test('one app', () {
      expect(pauseSubtitle(const PauseConfig(enabled: true, seconds: 10), 1),
          '1 app, 10 s pause');
    });
    test('several apps', () {
      expect(pauseSubtitle(const PauseConfig(enabled: true, seconds: 5), 4),
          '4 apps, 5 s pause');
    });
  });

  test('defaults are offered as options', () {
    const c = PauseConfig();
    expect(pauseSecondsOptions, contains(c.seconds));
    expect(graceMinutesOptions, contains(c.graceMinutes));
  });

  test('copyWith changes only what it is given', () {
    const c = PauseConfig(enabled: true, seconds: 10, graceMinutes: 5);
    final d = c.copyWith(seconds: 15);
    expect(d.seconds, 15);
    expect(d.enabled, isTrue);
    expect(d.graceMinutes, 5);
  });

  test('pause packs cover social and video apps but not work apps', () {
    const insta = InstalledApp(package: 'com.instagram.android', label: 'Instagram');
    const slack = InstalledApp(package: 'com.Slack', label: 'Slack');
    expect(pausePacks.any((p) => p.matches(insta)), isTrue);
    expect(pausePacks.any((p) => p.matches(slack)), isFalse);
  });
}
