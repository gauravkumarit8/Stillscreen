import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InstalledApp {
  const InstalledApp({
    required this.package,
    required this.label,
    this.category = -1,
  });
  final String package;
  final String label;

  /// Android's ApplicationInfo.category, or -1 when unknown.
  final int category;
}

/// Platform-neutral blocking API. The UI only talks to this interface;
/// Android implements it now, Windows can implement it later.
abstract class BlockingEngine {
  Future<bool> isPermissionGranted();
  Future<void> openPermissionSettings();
  Future<List<InstalledApp>> installedApps();
  Future<void> setBlockedApps(Set<String> packages);
  Future<void> startSession(Duration duration);
  Future<void> stopSession();
  Future<void> setWindDown({
    required bool enabled,
    required Set<int> days,
    required int startMinute,
    required int endMinute,
    required Set<String> packages,
  });
  Future<void> setMindfulPause({
    required bool enabled,
    required int seconds,
    required int graceMinutes,
    required Set<String> packages,
  });
  Future<Map<String, int>> getPauseSummary();
  Future<Uint8List?> getAppIcon(String package, int size);

  /// Adds time to the running session. False if none is running.
  Future<bool> extendSession(Duration extra);

  /// The short note shown on the pause and block screens.
  Future<void> setReason(String reason);

  /// When the blocking service last handled a window change, or 0 if never.
  Future<int> lastActiveMillis();
}

class AndroidBlockingEngine implements BlockingEngine {
  static const _channel = MethodChannel('app.stillscreen.focus/blocking');

  @override
  Future<bool> isPermissionGranted() async {
    return (await _channel.invokeMethod<bool>('isAccessibilityEnabled')) ?? false;
  }

  @override
  Future<void> openPermissionSettings() async {
    await _channel.invokeMethod<void>('openAccessibilitySettings');
  }

  @override
  Future<List<InstalledApp>> installedApps() async {
    final raw = await _channel.invokeListMethod<Map>('getInstalledApps') ?? [];
    return raw
        .map((m) => InstalledApp(
              package: m['package'] as String,
              label: m['label'] as String,
              category: (m['category'] as num?)?.toInt() ?? -1,
            ))
        .toList();
  }

  @override
  Future<void> setBlockedApps(Set<String> packages) async {
    await _channel.invokeMethod<void>('setBlockedApps', packages.toList());
  }

  @override
  Future<void> startSession(Duration duration) async {
    await _channel.invokeMethod<void>('startSession', duration.inMilliseconds);
  }

  @override
  Future<void> stopSession() async {
    await _channel.invokeMethod<void>('stopSession');
  }

  @override
  Future<void> setWindDown({
    required bool enabled,
    required Set<int> days,
    required int startMinute,
    required int endMinute,
    required Set<String> packages,
  }) async {
    await _channel.invokeMethod<void>('setWindDown', {
      'enabled': enabled,
      'days': days.toList(),
      'startMinute': startMinute,
      'endMinute': endMinute,
      'packages': packages.toList(),
    });
  }

  @override
  Future<void> setMindfulPause({
    required bool enabled,
    required int seconds,
    required int graceMinutes,
    required Set<String> packages,
  }) async {
    await _channel.invokeMethod<void>('setMindfulPause', {
      'enabled': enabled,
      'seconds': seconds,
      'graceMinutes': graceMinutes,
      'packages': packages.toList(),
    });
  }

  @override
  Future<Map<String, int>> getPauseSummary() async {
    return await _channel.invokeMapMethod<String, int>('getPauseSummary') ?? {};
  }

  @override
  Future<Uint8List?> getAppIcon(String package, int size) {
    return _channel
        .invokeMethod<Uint8List>('getAppIcon', {'package': package, 'size': size});
  }

  @override
  Future<bool> extendSession(Duration extra) async =>
      (await _channel.invokeMethod<bool>('extendSession', extra.inMinutes)) ?? false;

  @override
  Future<void> setReason(String reason) async {
    await _channel.invokeMethod<void>('setReason', reason);
  }

  @override
  Future<int> lastActiveMillis() async =>
      ((await _channel.invokeMethod<num>('lastActive')) ?? 0).toInt();
}

/// Used on web / desktop so the UI can be previewed without real blocking.
class PreviewBlockingEngine implements BlockingEngine {
  @override
  Future<bool> isPermissionGranted() async => true;

  @override
  Future<void> openPermissionSettings() async {}

  @override
  Future<List<InstalledApp>> installedApps() async => const [
        InstalledApp(package: 'com.instagram.android', label: 'Instagram'),
        InstalledApp(package: 'com.google.android.youtube', label: 'YouTube'),
        InstalledApp(package: 'com.zhiliaoapp.musically', label: 'TikTok'),
        InstalledApp(package: 'com.snapchat.android', label: 'Snapchat'),
        InstalledApp(package: 'com.netflix.mediaclient', label: 'Netflix'),
        InstalledApp(package: 'com.whatsapp', label: 'WhatsApp'),
        InstalledApp(package: 'com.Slack', label: 'Slack'),
        InstalledApp(package: 'com.example.arcade', label: 'Arcade Run', category: 0),
        InstalledApp(package: 'com.example.notes', label: 'Notes'),
      ];

  @override
  Future<void> setBlockedApps(Set<String> packages) async {}

  @override
  Future<void> startSession(Duration duration) async {}

  @override
  Future<void> stopSession() async {}

  @override
  Future<void> setWindDown({
    required bool enabled,
    required Set<int> days,
    required int startMinute,
    required int endMinute,
    required Set<String> packages,
  }) async {}

  @override
  Future<void> setMindfulPause({
    required bool enabled,
    required int seconds,
    required int graceMinutes,
    required Set<String> packages,
  }) async {}

  @override
  Future<Map<String, int>> getPauseSummary() async => const {};

  @override
  Future<Uint8List?> getAppIcon(String package, int size) async => null;

  @override
  Future<bool> extendSession(Duration extra) async => true;

  @override
  Future<void> setReason(String reason) async {}

  @override
  Future<int> lastActiveMillis() async => DateTime.now().millisecondsSinceEpoch;
}

final blockingEngineProvider = Provider<BlockingEngine>((ref) {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return AndroidBlockingEngine();
  }
  return PreviewBlockingEngine();
});
