import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'blocking/blocking_engine.dart';
import 'models.dart';

final sharedPrefsProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override sharedPrefsProvider in main()'),
);

class UserModeNotifier extends Notifier<UserMode?> {
  static const _key = 'user_mode';

  @override
  UserMode? build() {
    final saved = ref.read(sharedPrefsProvider).getString(_key);
    return UserMode.values.where((m) => m.name == saved).firstOrNull;
  }

  Future<void> set(UserMode mode) async {
    state = mode;
    await ref.read(sharedPrefsProvider).setString(_key, mode.name);
  }
}

final userModeProvider =
    NotifierProvider<UserModeNotifier, UserMode?>(UserModeNotifier.new);

class BlockedAppsNotifier extends Notifier<Set<String>> {
  static const _key = 'blocked_apps';

  @override
  Set<String> build() {
    final saved = ref.read(sharedPrefsProvider).getStringList(_key);
    return (saved ?? const <String>[]).toSet();
  }

  Future<void> toggle(String package) async {
    final next = {...state};
    if (!next.remove(package)) next.add(package);
    state = next;
    await ref.read(sharedPrefsProvider).setStringList(_key, next.toList());
    await ref.read(blockingEngineProvider).setBlockedApps(next);
  }

  /// Selects or deselects many apps with a single save and a single native call.
  Future<void> setMany(Iterable<String> packages, {required bool selected}) async {
    final next = {...state};
    if (selected) {
      next.addAll(packages);
    } else {
      next.removeAll(packages);
    }
    state = next;
    await ref.read(sharedPrefsProvider).setStringList(_key, next.toList());
    await ref.read(blockingEngineProvider).setBlockedApps(next);
  }
}

final blockedAppsProvider =
    NotifierProvider<BlockedAppsNotifier, Set<String>>(BlockedAppsNotifier.new);

const sessionEndKey = 'session_end';
