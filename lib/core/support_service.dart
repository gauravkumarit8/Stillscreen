import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppInfo {
  const AppInfo({
    required this.versionName,
    required this.versionCode,
    required this.device,
    required this.androidVersion,
  });

  final String versionName;
  final int versionCode;
  final String device;
  final String androidVersion;
}

/// The text that starts a feedback email. The lines under the divider tell me
/// which version and phone the report is about.
String feedbackBody(AppInfo info) => 'What happened?\n\n\n\n'
    '---\n'
    'Please keep the lines below. They help me find the problem.\n'
    'App: ${info.versionName} (${info.versionCode})\n'
    'Phone: ${info.device}\n'
    'Android: ${info.androidVersion}\n';

/// Version info, plus hand-offs to the email app and the browser. Both are
/// started by the user, and neither needs internet access in this app.
abstract class SupportService {
  Future<AppInfo> appInfo();
  Future<bool> sendFeedback({
    required String to,
    required String subject,
    required String body,
  });
  Future<bool> openUrl(String url);
}

class AndroidSupportService implements SupportService {
  static const _channel = MethodChannel('app.stillscreen.focus/blocking');

  @override
  Future<AppInfo> appInfo() async {
    final m = await _channel.invokeMapMethod<String, dynamic>('getAppInfo') ?? {};
    return AppInfo(
      versionName: m['versionName'] as String? ?? '',
      versionCode: (m['versionCode'] as num?)?.toInt() ?? 0,
      device: m['device'] as String? ?? 'unknown',
      androidVersion: m['androidVersion'] as String? ?? 'unknown',
    );
  }

  @override
  Future<bool> sendFeedback({
    required String to,
    required String subject,
    required String body,
  }) async =>
      (await _channel.invokeMethod<bool>(
              'sendFeedback', {'to': to, 'subject': subject, 'body': body})) ??
      false;

  @override
  Future<bool> openUrl(String url) async =>
      (await _channel.invokeMethod<bool>('openUrl', url)) ?? false;
}

class PreviewSupportService implements SupportService {
  @override
  Future<AppInfo> appInfo() async => const AppInfo(
      versionName: 'preview', versionCode: 0, device: 'Browser', androidVersion: 'n/a');

  @override
  Future<bool> sendFeedback({
    required String to,
    required String subject,
    required String body,
  }) async =>
      false;

  @override
  Future<bool> openUrl(String url) async => false;
}

final supportServiceProvider = Provider<SupportService>((ref) {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return AndroidSupportService();
  }
  return PreviewSupportService();
});

final appInfoProvider = FutureProvider<AppInfo>(
  (ref) => ref.read(supportServiceProvider).appInfo(),
);
