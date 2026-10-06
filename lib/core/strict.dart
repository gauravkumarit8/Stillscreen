import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs.dart';

/// Whether the running session was started in strict mode. Stored per session,
/// so flipping the switch mid-session cannot unlock it.
const sessionStrictKey = 'session_strict';

class StrictModeNotifier extends Notifier<bool> {
  static const _key = 'strict_mode';

  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(_key) ?? false;

  Future<void> set(bool value) async {
    state = value;
    await ref.read(sharedPrefsProvider).setBool(_key, value);
  }
}

final strictModeProvider =
    NotifierProvider<StrictModeNotifier, bool>(StrictModeNotifier.new);
