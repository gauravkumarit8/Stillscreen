import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/pause.dart';

class PauseScreen extends ConsumerWidget {
  const PauseScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(pauseConfigProvider);
    final apps = ref.watch(pauseAppsProvider);
    final notifier = ref.read(pauseConfigProvider.notifier);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Mindful pause')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Instead of blocking, Mindful pause asks you to stop for a few '
            'seconds before you open the apps you choose. Then you decide. It '
            'works at any time, not only during focus sessions.',
          ),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Mindful pause'),
            value: config.enabled,
            onChanged: (v) => notifier.update(config.copyWith(enabled: v)),
          ),
          const SizedBox(height: 16),
          Text('Pause length',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final s in pauseSecondsOptions)
                ChoiceChip(
                  label: Text('$s s'),
                  selected: config.seconds == s,
                  onSelected: (_) => notifier.update(config.copyWith(seconds: s)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text('After you continue',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('That app will not pause you again for:'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final m in graceMinutesOptions)
                ChoiceChip(
                  label: Text('$m min'),
                  selected: config.graceMinutes == m,
                  onSelected: (_) =>
                      notifier.update(config.copyWith(graceMinutes: m)),
                ),
            ],
          ),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Apps to pause'),
            subtitle: Text(apps.isEmpty
                ? 'None chosen yet'
                : apps.length == 1
                    ? '1 chosen'
                    : '${apps.length} chosen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/pause-apps'),
          ),
          if (config.enabled && apps.isEmpty) ...[
            const SizedBox(height: 8),
            const Text('Choose at least one app, or nothing will be paused.'),
          ],
          const SizedBox(height: 16),
          const Text(
            'Mindful pause uses the same Accessibility permission as blocking. '
            'Focus sessions and wind-down always take priority over it.',
          ),
        ],
      ),
    );
  }
}
