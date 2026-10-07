import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'blocking/blocking_engine.dart';

/// Loaded once and kept alive. The home screen reads it early, so by the time
/// the picker opens the list is usually ready.
final installedAppsProvider = FutureProvider<List<InstalledApp>>(
  (ref) => ref.read(blockingEngineProvider).installedApps(),
);
