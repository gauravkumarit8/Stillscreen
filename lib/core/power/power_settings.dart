import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Phone power-management helpers. Some phones stop background apps, which
/// would silently switch blocking off, so we guide users to the right screens.
abstract class PowerSettings {
  Future<String> manufacturer();
  Future<bool> isBatteryOptimizationIgnored();
  Future<void> openBatterySettings();

  /// Returns false when no manufacturer-specific screen could be opened.
  Future<bool> openAutostartSettings();
  Future<void> openAppInfo();
}

class AndroidPowerSettings implements PowerSettings {
  static const _channel = MethodChannel('app.stillscreen.focus/blocking');

  @override
  Future<String> manufacturer() async =>
      (await _channel.invokeMethod<String>('getManufacturer')) ?? '';

  @override
  Future<bool> isBatteryOptimizationIgnored() async =>
      (await _channel.invokeMethod<bool>('isBatteryOptimizationIgnored')) ?? false;

  @override
  Future<void> openBatterySettings() async {
    await _channel.invokeMethod<void>('openBatterySettings');
  }

  @override
  Future<bool> openAutostartSettings() async =>
      (await _channel.invokeMethod<bool>('openAutostartSettings')) ?? false;

  @override
  Future<void> openAppInfo() async {
    await _channel.invokeMethod<void>('openAppInfo');
  }
}

class PreviewPowerSettings implements PowerSettings {
  @override
  Future<String> manufacturer() async => 'preview';

  @override
  Future<bool> isBatteryOptimizationIgnored() async => false;

  @override
  Future<void> openBatterySettings() async {}

  @override
  Future<bool> openAutostartSettings() async => false;

  @override
  Future<void> openAppInfo() async {}
}

final powerSettingsProvider = Provider<PowerSettings>((ref) {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return AndroidPowerSettings();
  }
  return PreviewPowerSettings();
});
