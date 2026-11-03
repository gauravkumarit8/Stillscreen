import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/pause_suggestion.dart';

void main() {
  test('suggested after enough finished sessions while the pause is off', () {
    expect(
      shouldSuggestPause(completedSessions: 2, pauseEnabled: false, dismissed: false),
      isTrue,
    );
  });

  test('not suggested too early', () {
    expect(
      shouldSuggestPause(completedSessions: 1, pauseEnabled: false, dismissed: false),
      isFalse,
    );
  });

  test('not suggested if the pause is already on', () {
    expect(
      shouldSuggestPause(completedSessions: 9, pauseEnabled: true, dismissed: false),
      isFalse,
    );
  });

  test('not suggested again once answered', () {
    expect(
      shouldSuggestPause(completedSessions: 9, pauseEnabled: false, dismissed: true),
      isFalse,
    );
  });
}
