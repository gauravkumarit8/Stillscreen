import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/power/power_settings.dart';
import '../../core/prefs.dart';
import '../../core/reminder.dart';
import '../../core/reminder_service.dart';
import '../../core/winddown.dart';

class ReminderScreen extends ConsumerStatefulWidget {
  const ReminderScreen({super.key});

  @override
  ConsumerState<ReminderScreen> createState() => _ReminderScreenState();
}

class _ReminderScreenState extends ConsumerState<ReminderScreen>
    with WidgetsBindingObserver {
  bool _notificationsAllowed = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user may come back from Android settings.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final allowed = await ref.read(reminderServiceProvider).notificationsAllowed();
    if (mounted) setState(() => _notificationsAllowed = allowed);
  }

  Future<void> _toggle(bool value) async {
    final ok = await ref.read(reminderProvider.notifier).setEnabled(value);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Notifications are blocked, so the reminder stays off.'),
        ),
      );
    }
    _refresh();
  }

  Future<void> _pickTime(ReminderConfig config) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: config.minuteOfDay ~/ 60,
        minute: config.minuteOfDay % 60,
      ),
    );
    if (picked == null) return;
    await ref
        .read(reminderProvider.notifier)
        .setTime(picked.hour * 60 + picked.minute);
  }

  @override
  Widget build(BuildContext context) {
    final config = ref.watch(reminderProvider);
    final (title, body) = reminderTextFor(ref.watch(userModeProvider));

    return Scaffold(
      appBar: AppBar(title: const Text('Daily reminder')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'A gentle nudge at a time you choose. You will not get it on days '
            'when you have already reached your daily goal.',
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Daily reminder'),
            value: config.enabled,
            onChanged: _toggle,
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            enabled: config.enabled,
            title: const Text('Reminder time'),
            trailing: Text(formatMinute(context, config.minuteOfDay)),
            onTap: config.enabled ? () => _pickTime(config) : null,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: pebble),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('What you will see'),
                const SizedBox(height: 6),
                Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
                Text(body),
              ],
            ),
          ),
          if (config.enabled && !_notificationsAllowed) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: stillTeal),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Notifications are off for Stillscreen',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  const Text(
                    'The reminder is set, but Android will not show it. Open '
                    'app info, choose Notifications, and turn them on.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: ref.read(powerSettingsProvider).openAppInfo,
                    child: const Text('Open app info'),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
