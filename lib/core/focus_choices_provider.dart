import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'blocking/blocking_engine.dart';
import 'focus_choices.dart';

/// The recent days on which focus was chosen. Read fresh each time the stats
/// screen opens.
final focusChosenProvider = FutureProvider.autoDispose<List<FocusChoice>>(
  (ref) => ref.read(blockingEngineProvider).focusChosenHistory(),
);
