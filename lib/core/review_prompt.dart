import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app_config.dart';
import 'prefs.dart';
import 'session_log.dart';
import 'support_service.dart';

/// A rating is only asked for after the person has really used the app, and
/// never more than once in a while.
const reviewMinCompletedSessions = 5;
const reviewMinDaysSinceFirstSession = 3;
const reviewSnoozeDays = 14;

/// Whether the rating card should be on the home screen.
bool shouldAskForReview({
  required List<SessionRecord> log,
  required DateTime now,
  required bool done,
  required DateTime? snoozedUntil,
}) {
  if (done) return false;
  if (snoozedUntil != null && now.isBefore(snoozedUntil)) return false;

  final completed = log.where((r) => r.completed).toList();
  if (completed.length < reviewMinCompletedSessions) return false;

  final first = completed
      .map((r) => r.start)
      .reduce((a, b) => a.isBefore(b) ? a : b);
  return now.difference(first) >= const Duration(days: reviewMinDaysSinceFirstSession);
}

/// Opens the Play Store on the app's page. Tries the Play Store app first and
/// the web page if that is not available. Returns false if neither opened.
Future<bool> openPlayListing(SupportService support) async {
  if (await support.openUrl(playMarketUri)) return true;
  return support.openUrl(storeLink);
}

class ReviewPromptState {
  const ReviewPromptState({this.done = false, this.snoozedUntil});

  final bool done;
  final DateTime? snoozedUntil;
}

class ReviewPromptNotifier extends Notifier<ReviewPromptState> {
  static const _doneKey = 'review_done';
  static const _snoozeKey = 'review_snooze_until';

  @override
  ReviewPromptState build() {
    final prefs = ref.read(sharedPrefsProvider);
    final until = prefs.getInt(_snoozeKey);
    return ReviewPromptState(
      done: prefs.getBool(_doneKey) ?? false,
      snoozedUntil:
          until == null ? null : DateTime.fromMillisecondsSinceEpoch(until),
    );
  }

  /// "Not now": ask again in a couple of weeks.
  Future<void> snooze() async {
    final until = DateTime.now().add(const Duration(days: reviewSnoozeDays));
    state = ReviewPromptState(done: state.done, snoozedUntil: until);
    await ref
        .read(sharedPrefsProvider)
        .setInt(_snoozeKey, until.millisecondsSinceEpoch);
  }

  /// The person went to rate, so do not ask again.
  Future<void> markDone() async {
    state = ReviewPromptState(done: true, snoozedUntil: state.snoozedUntil);
    await ref.read(sharedPrefsProvider).setBool(_doneKey, true);
  }
}

final reviewPromptProvider =
    NotifierProvider<ReviewPromptNotifier, ReviewPromptState>(
  ReviewPromptNotifier.new,
);

final reviewCardVisibleProvider = Provider<bool>((ref) {
  final state = ref.watch(reviewPromptProvider);
  return shouldAskForReview(
    log: ref.watch(sessionLogProvider),
    now: DateTime.now(),
    done: state.done,
    snoozedUntil: state.snoozedUntil,
  );
});
