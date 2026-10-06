import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/blocking/blocking_engine.dart';
import '../../core/prefs.dart';

final installedAppsProvider = FutureProvider<List<InstalledApp>>(
  (ref) => ref.read(blockingEngineProvider).installedApps(),
);

class AppsScreen extends ConsumerWidget {
  const AppsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final apps = ref.watch(installedAppsProvider);
    final blocked = ref.watch(blockedAppsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Apps to block')),
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
              value: blocked.contains(app.package),
              onChanged: (_) =>
                  ref.read(blockedAppsProvider.notifier).toggle(app.package),
            );
          },
        ),
      ),
    );
  }
}
