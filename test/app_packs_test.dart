import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/app_packs.dart';
import 'package:focus/core/blocking/blocking_engine.dart';

InstalledApp app(String package, {int category = -1}) =>
    InstalledApp(package: package, label: package, category: category);

void main() {
  test('known package names match their pack', () {
    expect(socialPack.matches(app('com.instagram.android')), isTrue);
    expect(videoPack.matches(app('com.netflix.mediaclient')), isTrue);
    expect(workPack.matches(app('com.Slack')), isTrue);
    expect(messagingPack.matches(app('com.whatsapp')), isTrue);
  });

  test('Android category is used when the package is not listed', () {
    expect(gamesPack.matches(app('com.unknown.game', category: 0)), isTrue);
    expect(socialPack.matches(app('com.unknown.chatter', category: 4)), isTrue);
    expect(videoPack.matches(app('com.unknown.player', category: 2)), isTrue);
  });

  test('unrelated apps and unknown categories do not match', () {
    expect(socialPack.matches(app('com.example.notes')), isFalse);
    expect(gamesPack.matches(app('com.example.notes')), isFalse);
    expect(workPack.matches(app('com.instagram.android')), isFalse);
  });

  test('the dialer and settings are never part of any pack', () {
    const all = [...focusPacks, ...windDownPacks];
    for (final pack in all) {
      expect(pack.packages.contains('com.android.settings'), isFalse);
      expect(pack.packages.contains('com.google.android.dialer'), isFalse);
    }
  });
}
