import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'blocking/blocking_engine.dart';

/// App icons, fetched one at a time as rows scroll into view and then kept in
/// memory. Null means "no icon", and the list shows a plain placeholder.
final appIconProvider = FutureProvider.family<Uint8List?, String>((ref, package) async {
  try {
    return await ref.read(blockingEngineProvider).getAppIcon(package, 96);
  } catch (_) {
    return null;
  }
});
