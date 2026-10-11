import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'blocking/blocking_engine.dart';

/// Loaded once and kept alive. The home screen reads it early, so by the time
/// the picker opens the list is usually ready.
final installedAppsProvider = FutureProvider<List<InstalledApp>>(
  (ref) => ref.read(blockingEngineProvider).installedApps(),
);

/// How many of the [selected] packages are really installed. A saved list can
/// hold apps that were uninstalled later, so counting it directly overstates.
/// While the app list is still loading, the saved count is the best guess.
int installedCount(List<InstalledApp>? installed, Set<String> selected) {
  if (installed == null) return selected.length;
  return installed.where((a) => selected.contains(a.package)).length;
}
