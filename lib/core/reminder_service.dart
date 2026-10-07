import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Daily reminder, scheduled on the phone itself. No network is involved.
abstract class ReminderService {
  /// Asks for the notification permission where Android requires it (13+).
  Future<bool> requestPermission();

  /// False when notifications are switched off for the app.
  Future<bool> notificationsAllowed();

  Future<void> configure({
    required bool enabled,
    required int minuteOfDay,
    required String title,
    required String body,
  });

  /// Tells the reminder that today's goal is done, so it stays quiet today.
  Future<void> markGoalReached(String dayKey);
}

class AndroidReminderService implements ReminderService {
  static const _channel = MethodChannel('app.stillscreen.focus/blocking');

  @override
  Future<bool> requestPermission() async =>
      (await _channel.invokeMethod<bool>('requestNotificationPermission')) ?? false;

  @override
  Future<bool> notificationsAllowed() async =>
      (await _channel.invokeMethod<bool>('notificationsAllowed')) ?? false;

  @override
  Future<void> configure({
    required bool enabled,
    required int minuteOfDay,
    required String title,
    required String body,
  }) async {
    await _channel.invokeMethod<void>('configureReminder', {
      'enabled': enabled,
      'minuteOfDay': minuteOfDay,
      'title': title,
      'body': body,
    });
  }

  @override
  Future<void> markGoalReached(String dayKey) async {
    await _channel.invokeMethod<void>('markGoalReached', dayKey);
  }
}

class PreviewReminderService implements ReminderService {
  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> notificationsAllowed() async => true;

  @override
  Future<void> configure({
    required bool enabled,
    required int minuteOfDay,
    required String title,
    required String body,
  }) async {}

  @override
  Future<void> markGoalReached(String dayKey) async {}
}

final reminderServiceProvider = Provider<ReminderService>((ref) {
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    return AndroidReminderService();
  }
  return PreviewReminderService();
});
