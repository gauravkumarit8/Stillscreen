import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'pause.dart';
import 'prefs.dart';
import 'session_log.dart';

/// The suggestion is shown only after the person has really used the app, and
/// only while the mindful pause is still off.
const pauseSuggestionMinSessions = 2;

bool shouldSuggestPause({
  required int completedSessions,
  required bool pauseEnabled,
  required bool dismissed,
}) =>
    !dismissed &&
    !pauseEnabled &&
    completedSessions >= pauseSuggestionMinSessions;

class PauseSuggestionNotifier extends Notifier<bool> {
  static const _key = 'pause_suggestion_done';

  /// True once the person has answered, either way.
  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(_key) ?? false;

  Future<void> dismiss() async {
    state = true;
    await ref.read(sharedPrefsProvider).setBool(_key, true);
  }
}

final pauseSuggestionDismissedProvider =
    NotifierProvider<PauseSuggestionNotifier, bool>(PauseSuggestionNotifier.new);

final pauseSuggestionVisibleProvider = Provider<bool>((ref) {
  final completed = ref.watch(sessionLogProvider).where((r) => r.completed).length;
  return shouldSuggestPause(
    completedSessions: completed,
    pauseEnabled: ref.watch(pauseConfigProvider).enabled,
    dismissed: ref.watch(pauseSuggestionDismissedProvider),
  );
});
