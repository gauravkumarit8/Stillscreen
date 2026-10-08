import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'blocking/blocking_engine.dart';
import 'prefs.dart';

const pauseSecondsOptions = [5, 10, 15];
const graceMinutesOptions = [2, 5, 15];

class PauseConfig {
  const PauseConfig({
    this.enabled = false,
    this.seconds = 10,
    this.graceMinutes = 5,
  });

  final bool enabled;

  /// How long the breathing screen lasts before "Continue" unlocks.
  final int seconds;

  /// After you continue, the same app is not paused again for this long.
  final int graceMinutes;

  PauseConfig copyWith({bool? enabled, int? seconds, int? graceMinutes}) =>
      PauseConfig(
        enabled: enabled ?? this.enabled,
        seconds: seconds ?? this.seconds,
        graceMinutes: graceMinutes ?? this.graceMinutes,
      );
}

String pauseSubtitle(PauseConfig config, int appCount) {
  if (!config.enabled) return 'Off';
  final apps = appCount == 1 ? '1 app' : '$appCount apps';
  return '$apps, ${config.seconds} s pause';
}

Future<void> _pushToNative(Ref ref) async {
  final config = ref.read(pauseConfigProvider);
  final apps = ref.read(pauseAppsProvider);
  await ref.read(blockingEngineProvider).setMindfulPause(
        enabled: config.enabled,
        seconds: config.seconds,
        graceMinutes: config.graceMinutes,
        packages: apps,
      );
}

class PauseConfigNotifier extends Notifier<PauseConfig> {
  @override
  PauseConfig build() {
    final prefs = ref.read(sharedPrefsProvider);
    return PauseConfig(
      enabled: prefs.getBool('mp_enabled') ?? false,
      seconds: prefs.getInt('mp_seconds') ?? 10,
      graceMinutes: prefs.getInt('mp_grace') ?? 5,
    );
  }

  Future<void> update(PauseConfig config) async {
    state = config;
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool('mp_enabled', config.enabled);
    await prefs.setInt('mp_seconds', config.seconds);
    await prefs.setInt('mp_grace', config.graceMinutes);
    await _pushToNative(ref);
  }
}

final pauseConfigProvider =
    NotifierProvider<PauseConfigNotifier, PauseConfig>(PauseConfigNotifier.new);

class PauseAppsNotifier extends Notifier<Set<String>> {
  static const _key = 'mp_apps';

  @override
  Set<String> build() =>
      (ref.read(sharedPrefsProvider).getStringList(_key) ?? const <String>[])
          .toSet();

  Future<void> toggle(String package) async {
    final next = {...state};
    if (!next.remove(package)) next.add(package);
    state = next;
    await ref.read(sharedPrefsProvider).setStringList(_key, next.toList());
    await _pushToNative(ref);
  }

  Future<void> setMany(Iterable<String> packages, {required bool selected}) async {
    final next = {...state};
    if (selected) {
      next.addAll(packages);
    } else {
      next.removeAll(packages);
    }
    state = next;
    await ref.read(sharedPrefsProvider).setStringList(_key, next.toList());
    await _pushToNative(ref);
  }
}

final pauseAppsProvider =
    NotifierProvider<PauseAppsNotifier, Set<String>>(PauseAppsNotifier.new);

/// How often the pause screen appeared, and how often you walked away.
class PauseSummary {
  const PauseSummary({
    this.shownToday = 0,
    this.resistedToday = 0,
    this.shownWeek = 0,
    this.resistedWeek = 0,
  });

  final int shownToday;
  final int resistedToday;
  final int shownWeek;
  final int resistedWeek;
}

final pauseSummaryProvider = FutureProvider.autoDispose<PauseSummary>((ref) async {
  final m = await ref.read(blockingEngineProvider).getPauseSummary();
  return PauseSummary(
    shownToday: m['shownToday'] ?? 0,
    resistedToday: m['resistedToday'] ?? 0,
    shownWeek: m['shownWeek'] ?? 0,
    resistedWeek: m['resistedWeek'] ?? 0,
  );
});
