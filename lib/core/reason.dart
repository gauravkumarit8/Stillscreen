import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'blocking/blocking_engine.dart';
import 'prefs.dart';

const maxReasonLength = 80;

/// A short personal note ("Exam on 14 November") shown on the pause and block
/// screens. Kept on the phone, and copied to the side that draws those screens.
class ReasonNotifier extends Notifier<String> {
  static const _key = 'my_reason';

  @override
  String build() => ref.read(sharedPrefsProvider).getString(_key) ?? '';

  Future<void> set(String value) async {
    final text = value.trim();
    final clipped =
        text.length > maxReasonLength ? text.substring(0, maxReasonLength) : text;
    state = clipped;
    await ref.read(sharedPrefsProvider).setString(_key, clipped);
    await ref.read(blockingEngineProvider).setReason(clipped);
  }
}

final reasonProvider =
    NotifierProvider<ReasonNotifier, String>(ReasonNotifier.new);
