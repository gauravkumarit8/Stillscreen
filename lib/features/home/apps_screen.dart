import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/blocking/blocking_engine.dart';
import '../../core/prefs.dart';
import '../../core/winddown.dart';

final installedAppsProvider = FutureProvider<List<InstalledApp>>(
  (ref) => ref.read(blockingEngineProvider).installedApps(),
);

/// Picker for installed apps. With [windDown] it edits the work-apps list used
/// by the end-of-day wind-down instead of the focus-session list.
class AppsScreen extends ConsumerWidget {
  const AppsScreen({super.key, this.windDown = false});

  final bool windDown;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(installedAppsProvider);
    final selected = windDown
        ? ref.watch(windDownAppsProvider)
        : ref.watch(blockedAppsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(windDown ? 'Work apps to pause' : 'Apps to block'),
      ),
      body: apps.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Could not load your apps. Go back and try again.'),
          ),
        ),
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final app = list[i];
            return CheckboxListTile(
              title: Text(app.label),
              value: selected.contains(app.package),
              onChanged: (_) => windDown
                  ? ref.read(windDownAppsProvider.notifier).toggle(app.package)
                  : ref.read(blockedAppsProvider.notifier).toggle(app.package),
            );
          },
        ),
      ),
    );
  }
}
