import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/app_config.dart';
import 'package:focus/core/review_prompt.dart';
import 'package:focus/core/session_log.dart';
import 'package:focus/core/support_service.dart';

class _FakeSupport implements SupportService {
  _FakeSupport({this.marketWorks = true, this.webWorks = true});

  final bool marketWorks;
  final bool webWorks;
  final opened = <String>[];

  @override
  Future<bool> openUrl(String url) async {
    opened.add(url);
    if (url == playMarketUri) return marketWorks;
    return webWorks;
  }

  @override
  Future<AppInfo> appInfo() async => const AppInfo(
        versionName: 'x', versionCode: 1, device: 'd', androidVersion: 'a');

  @override
  Future<bool> sendFeedback({
    required String to,
    required String subject,
    required String body,
  }) async =>
      true;
}

SessionRecord done(DateTime start) =>
    SessionRecord(start: start, minutes: 25, completed: true);

void main() {
  final now = DateTime(2026, 10, 30, 12);

  List<SessionRecord> sessions(int count, {int daysAgoFirst = 5}) => [
        for (var i = 0; i < count; i++)
          done(now.subtract(Duration(days: daysAgoFirst - (i % daysAgoFirst)))),
      ];

  group('shouldAskForReview', () {
    test('asks after enough sessions over enough days', () {
      expect(
        shouldAskForReview(
            log: sessions(6), now: now, done: false, snoozedUntil: null),
        isTrue,
      );
    });

    test('does not ask too early', () {
      expect(
        shouldAskForReview(
            log: sessions(3), now: now, done: false, snoozedUntil: null),
        isFalse,
      );
    });

    test('does not ask when the sessions are all brand new', () {
      final fresh = [
        for (var i = 0; i < 6; i++) done(now.subtract(Duration(hours: i + 1))),
      ];
      expect(
        shouldAskForReview(log: fresh, now: now, done: false, snoozedUntil: null),
        isFalse,
      );
    });

    test('ignores sessions that were ended early', () {
      final early = [
        for (var i = 0; i < 8; i++)
          SessionRecord(
            start: now.subtract(Duration(days: 6 - (i % 5))),
            minutes: 3,
            completed: false,
          ),
      ];
      expect(
        shouldAskForReview(log: early, now: now, done: false, snoozedUntil: null),
        isFalse,
      );
    });

    test('does not ask again once done', () {
      expect(
        shouldAskForReview(
            log: sessions(9), now: now, done: true, snoozedUntil: null),
        isFalse,
      );
    });

    test('waits out a snooze, then asks again', () {
      final until = now.add(const Duration(days: 2));
      expect(
        shouldAskForReview(
            log: sessions(9), now: now, done: false, snoozedUntil: until),
        isFalse,
      );
      expect(
        shouldAskForReview(
            log: sessions(9),
            now: until.add(const Duration(minutes: 1)),
            done: false,
            snoozedUntil: until),
        isTrue,
      );
    });
  });

  group('openPlayListing', () {
    test('uses the Play Store app when it opens', () async {
      final support = _FakeSupport();
      expect(await openPlayListing(support), isTrue);
      expect(support.opened, [playMarketUri]);
    });

    test('falls back to the web page', () async {
      final support = _FakeSupport(marketWorks: false);
      expect(await openPlayListing(support), isTrue);
      expect(support.opened, [playMarketUri, storeLink]);
    });

    test('reports failure when neither opens', () async {
      final support = _FakeSupport(marketWorks: false, webWorks: false);
      expect(await openPlayListing(support), isFalse);
    });
  });

  test('the store link points at the app', () {
    expect(storeLink, contains('id=app.stillscreen.focus'));
    expect(storeLink, startsWith('https://play.google.com/'));
  });
}
