import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/achievements.dart';
import '../../core/app_config.dart';
import '../../core/goal.dart';
import '../../core/installed_apps.dart';
import '../../core/models.dart';
import '../../core/pause.dart';
import '../../core/prefs.dart';
import '../../core/reminder.dart';
import '../../core/session_log.dart';
import '../../core/support_service.dart';
import '../../core/theme_mode.dart';
import '../../core/winddown.dart';
import 'goal_dialog.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode = ref.watch(userModeProvider);
    final pauseConfig = ref.watch(pauseConfigProvider);
    final pauseChosen = installedCount(
      ref.watch(installedAppsProvider).valueOrNull,
      ref.watch(pauseAppsProvider),
    );
    final reminder = ref.watch(reminderProvider);
    final windDown = ref.watch(windDownProvider);
    final info = ref.watch(appInfoProvider).valueOrNull;
    final dailyGoal = ref.watch(goalHistoryProvider).goalOn(DateTime.now());
    final achievements = computeAchievements(FocusStats(
      ref.watch(sessionLogProvider),
      goals: ref.watch(goalHistoryProvider),
    ));
    final unlockedCount = achievements.where((a) => a.unlocked).length;
    final text = Theme.of(context).textTheme;

    Future<void> sendFeedback() async {
      final support = ref.read(supportServiceProvider);
      final AppInfo details;
      try {
        details = await ref.read(appInfoProvider.future);
      } catch (_) {
        return;
      }
      final opened = await support.sendFeedback(
        to: feedbackEmail,
        subject: 'Stillscreen feedback',
        body: feedbackBody(details),
      );
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No email app found. You can write to $feedbackEmail.'),
          ),
        );
      }
    }

    Future<void> openPolicy() async {
      final opened = await ref.read(supportServiceProvider).openUrl(privacyPolicyUrl);
      if (!opened && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open the link.')),
        );
      }
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _Header('I use Stillscreen as'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SegmentedButton<UserMode>(
              showSelectedIcon: false,
              emptySelectionAllowed: true,
              segments: const [
                ButtonSegment(value: UserMode.student, label: Text('Student')),
                ButtonSegment(
                    value: UserMode.professional, label: Text('Professional')),
              ],
              selected: {if (mode != null) mode},
              onSelectionChanged: (s) {
                if (s.isNotEmpty) ref.read(userModeProvider.notifier).set(s.first);
              },
            ),
          ),
          _Header('Appearance'),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: SegmentedButton<ThemeMode>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(value: ThemeMode.system, label: Text('System')),
                ButtonSegment(value: ThemeMode.light, label: Text('Light')),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark')),
              ],
              selected: {ref.watch(themeModeProvider)},
              onSelectionChanged: (s) =>
                  ref.read(themeModeProvider.notifier).set(s.first),
            ),
          ),
          const SizedBox(height: 8),
          _Header('Focus'),
          ListTile(
            title: const Text('Daily goal'),
            subtitle: Text('$dailyGoal min a day'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showGoalDialog(context),
          ),
          ListTile(
            title: const Text('Achievements'),
            subtitle: Text('$unlockedCount of ${achievements.length} unlocked'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/achievements'),
          ),
          ListTile(
            title: const Text('Mindful pause'),
            subtitle: Text(pauseSubtitle(pauseConfig, pauseChosen)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/pause'),
          ),
          ListTile(
            title: const Text('End-of-day wind-down'),
            subtitle: Text(windDown.enabled
                ? '${formatMinute(context, windDown.startMinute)} to '
                    '${formatMinute(context, windDown.endMinute)}'
                : 'Off'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/winddown'),
          ),
          ListTile(
            title: const Text('Daily reminder'),
            subtitle: Text(reminder.enabled
                ? formatMinute(context, reminder.minuteOfDay)
                : 'Off'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/reminder'),
          ),
          _Header('Help'),
          ListTile(
            title: const Text('Set up blocking'),
            subtitle: const Text('Permission, apps and your first session'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/setup'),
          ),
          ListTile(
            title: const Text('Keep blocking reliable'),
            subtitle: const Text('Battery settings for your phone'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/battery'),
          ),
          ListTile(
            title: const Text('Send feedback'),
            subtitle: const Text('Opens your email app'),
            trailing: const Icon(Icons.chevron_right),
            onTap: sendFeedback,
          ),
          _Header('About'),
          ListTile(
            title: const Text('Privacy policy'),
            trailing: const Icon(Icons.chevron_right),
            onTap: openPolicy,
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
            child: Text(
              info == null
                  ? 'Stillscreen'
                  : 'Stillscreen ${info.versionName} (${info.versionCode})',
              style: text.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        label,
        style: Theme.of(context)
            .textTheme
            .titleSmall
            ?.copyWith(fontWeight: FontWeight.w600),
      ),
    );
  }
}
