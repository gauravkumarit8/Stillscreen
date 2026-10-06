import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class InstalledApp {
  const InstalledApp({required this.package, required this.label});
  final String package;
  final String label;
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
      ];

  @override
  Future<void> setBlockedApps(Set<String> packages) async {}

  @override
  Future<void> startSession(Duration duration) async {}

  @override
  Future<void> stopSession() async {}
}

final blockingEngineProvider = Provider<BlockingEngine>((ref) {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return AndroidBlockingEngine();
  }
  return PreviewBlockingEngine();
});
