import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'models.dart';
import 'prefs.dart';
import 'reminder_service.dart';

/// "20261007" style key for a local calendar day. The Android side builds the
/// same format, so both agree on what "today" means.
String dayKey(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}'
    '${d.month.toString().padLeft(2, '0')}'
    '${d.day.toString().padLeft(2, '0')}';

/// Notification wording for each mode.
(String, String) reminderTextFor(UserMode? mode) => switch (mode) {
      UserMode.professional => (
          'Time for a focus block',
          'Protect your deep work with a short session.',
        ),
      _ => (
          'Time to focus',
          'A short session keeps your streak going.',
        ),
    };

class ReminderConfig {
  const ReminderConfig({this.enabled = false, this.minuteOfDay = 18 * 60});

  final bool enabled;
  final int minuteOfDay;

  ReminderConfig copyWith({bool? enabled, int? minuteOfDay}) => ReminderConfig(
        enabled: enabled ?? this.enabled,
        minuteOfDay: minuteOfDay ?? this.minuteOfDay,
      );
}

class ReminderNotifier extends Notifier<ReminderConfig> {
  static const _enabledKey = 'rem_enabled';
  static const _minuteKey = 'rem_minute';

  @override
  ReminderConfig build() {
    final prefs = ref.read(sharedPrefsProvider);
    return ReminderConfig(
      enabled: prefs.getBool(_enabledKey) ?? false,
      minuteOfDay: prefs.getInt(_minuteKey) ?? 18 * 60,
    );
  }

  /// Turning it on asks for the notification permission first. Returns false
  /// if the user said no, in which case the reminder stays off.
  Future<bool> setEnabled(bool value) async {
    if (value) {
      final granted = await ref.read(reminderServiceProvider).requestPermission();
      if (!granted) return false;
    }
    await _save(state.copyWith(enabled: value));
    return true;
  }

  Future<void> setTime(int minuteOfDay) =>
      _save(state.copyWith(minuteOfDay: minuteOfDay));

  /// Re-sends the schedule. Safe to call often; the phone forgets alarms after
  /// the app is force-stopped, so the app calls this each time it opens.
  Future<void> resync() => _push();

  Future<void> _save(ReminderConfig config) async {
    state = config;
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setBool(_enabledKey, config.enabled);
    await prefs.setInt(_minuteKey, config.minuteOfDay);
    await _push();
  }

  Future<void> _push() async {
    final (title, body) = reminderTextFor(ref.read(userModeProvider));
    await ref.read(reminderServiceProvider).configure(
          enabled: state.enabled,
          minuteOfDay: state.minuteOfDay,
          title: title,
          body: body,
        );
  }
}

final reminderProvider =
    NotifierProvider<ReminderNotifier, ReminderConfig>(ReminderNotifier.new);
