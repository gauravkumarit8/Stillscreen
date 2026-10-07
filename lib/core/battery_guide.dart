import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs.dart';

class BatteryGuideDoneNotifier extends Notifier<bool> {
  static const _key = 'battery_guide_done';

  @override
  bool build() => ref.read(sharedPrefsProvider).getBool(_key) ?? false;

  Future<void> markDone() async {
    state = true;
    await ref.read(sharedPrefsProvider).setBool(_key, true);
  }
}

final batteryGuideDoneProvider =
    NotifierProvider<BatteryGuideDoneNotifier, bool>(BatteryGuideDoneNotifier.new);

bool _matches(String manufacturer, List<String> names) {
  final m = manufacturer.toLowerCase();
  return names.any((n) => m.contains(n));
}

/// Brands that usually have a separate "autostart" or "startup" screen.
bool hasAutostartScreen(String manufacturer) => _matches(manufacturer, [
      'xiaomi', 'redmi', 'poco', 'oppo', 'realme', 'oneplus',
      'vivo', 'iqoo', 'huawei', 'honor',
    ]);

/// Short steps per brand. Menu names differ by phone model and Android
/// version, so the screen tells users to expect small differences.
List<String> stepsFor(String manufacturer) {
  if (_matches(manufacturer, ['xiaomi', 'redmi', 'poco'])) {
    return [
      'Turn on Autostart for Stillscreen.',
      'In battery settings for Stillscreen, choose No restrictions.',
      'Open recent apps, long-press the Stillscreen card, and tap the lock icon.',
    ];
  }
  if (_matches(manufacturer, ['oppo', 'realme', 'oneplus'])) {
    return [
      'Allow Stillscreen to start automatically (Auto-launch or Startup manager).',
      'In battery settings for Stillscreen, allow background activity and turn off battery optimization.',
      'Open recent apps and lock Stillscreen.',
    ];
  }
  if (_matches(manufacturer, ['vivo', 'iqoo'])) {
    return [
      'Turn on Autostart for Stillscreen.',
      'Allow high background power use for Stillscreen.',
      'Open recent apps and lock Stillscreen.',
    ];
  }
  if (_matches(manufacturer, ['samsung'])) {
    return [
      'Open Settings, then Battery, then Background usage limits.',
      'Make sure Stillscreen is not in Sleeping apps or Deep sleeping apps, and add it to Never sleeping apps.',
      'Set Stillscreen battery usage to Unrestricted.',
    ];
  }
  if (_matches(manufacturer, ['huawei', 'honor'])) {
    return [
      'Open App launch, find Stillscreen, and switch it to Manage manually.',
      'Turn on Auto-launch, Secondary launch, and Run in background.',
    ];
  }
  return [
    'Set Stillscreen battery usage to Unrestricted (or Do not optimize).',
    'If your phone has a lock option in recent apps, lock Stillscreen there.',
  ];
}
