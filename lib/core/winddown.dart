import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'blocking/blocking_engine.dart';
import 'prefs.dart';

/// Days use ISO numbering: Monday = 1 ... Sunday = 7.
const weekdayNames = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String formatMinute(BuildContext context, int minuteOfDay) =>
    TimeOfDay(hour: minuteOfDay ~/ 60, minute: minuteOfDay % 60).format(context);

class WindDownConfig {
  const WindDownConfig({
    this.enabled = false,
    this.days = const {1, 2, 3, 4, 5},
    this.startMinute = 18 * 60 + 30,
    this.endMinute = 8 * 60,
  });

  final bool enabled;
  final Set<int> days;
  final int startMinute;
  final int endMinute;

  WindDownConfig copyWith({
    bool? enabled,
    Set<int>? days,
    int? startMinute,
    int? endMinute,
  }) =>
      WindDownConfig(
        enabled: enabled ?? this.enabled,
        days: days ?? this.days,
        startMinute: startMinute ?? this.startMinute,
        endMinute: endMinute ?? this.endMinute,
      );
}

Future<void> _pushToNative(Ref ref) async {
  final config = ref.read(windDownProvider);
  final apps = ref.read(windDownAppsProvider);
  await ref.read(blockingEngineProvider).setWindDown(
        enabled: config.enabled,
        days: config.days,
        startMinute: config.startMinute,
        endMinute: config.endMinute,
        packages: apps,
      );
}

class WindDownNotifier extends Notifier<WindDownConfig> {
  @override
  WindDownConfig build() {
    final prefs = ref.read(sharedPrefsProvider);
    final days = prefs.getStringList('wd_days')?.map(int.parse).toSet();
    return WindDownConfig(
      enabled: prefs.getBool('wd_enabled') ?? false,
      days: days ?? const {1, 2, 3, 4, 5},
      startMinute: prefs.getInt('wd_start') ?? 18 * 60 + 30,
      endMinute: prefs.getInt('wd_end') ?? 8 * 60,
    );
  }

  Future<void> update(WindDownConfig config) async {
    state = config;
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool('wd_enabled', config.enabled);
    await prefs.setStringList(
        'wd_days', (config.days.toList()..sort()).map((d) => '$d').toList());
    await prefs.setInt('wd_start', config.startMinute);
    await prefs.setInt('wd_end', config.endMinute);
    await _pushToNative(ref);
  }
}

final windDownProvider =
    NotifierProvider<WindDownNotifier, WindDownConfig>(WindDownNotifier.new);

class WindDownAppsNotifier extends Notifier<Set<String>> {
  static const _key = 'wd_apps';

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
}

final windDownAppsProvider =
    NotifierProvider<WindDownAppsNotifier, Set<String>>(WindDownAppsNotifier.new);
