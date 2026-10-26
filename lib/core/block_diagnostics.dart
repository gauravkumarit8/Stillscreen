import 'time_ago.dart';

/// What the blocking service last noticed and last tried to do. Shown in the
/// health check so a problem report says what actually happened.
class BlockDiagnostics {
  const BlockDiagnostics({
    this.seenPackage = '',
    this.seenAt = 0,
    this.attemptPackage = '',
    this.attemptAt = 0,
    this.attemptResult = '',
  });

  final String seenPackage;
  final int seenAt;
  final String attemptPackage;
  final int attemptAt;
  final String attemptResult;

  factory BlockDiagnostics.fromMap(Map<Object?, Object?> map) {
    String text(String key) => (map[key] as String?) ?? '';
    int number(String key) => (map[key] as num?)?.toInt() ?? 0;
    return BlockDiagnostics(
      seenPackage: text('seenPackage'),
      seenAt: number('seenAt'),
      attemptPackage: text('attemptPackage'),
      attemptAt: number('attemptAt'),
      attemptResult: text('attemptResult'),
    );
  }
}

String describeSeen(BlockDiagnostics d, DateTime now) {
  if (d.seenAt == 0 || d.seenPackage.isEmpty) {
    return 'No app seen yet. Open any other app to test.';
  }
  final when = timeAgo(DateTime.fromMillisecondsSinceEpoch(d.seenAt), now);
  return '${d.seenPackage}, $when.';
}

String describeAttempt(BlockDiagnostics d, DateTime now) {
  if (d.attemptAt == 0 || d.attemptResult.isEmpty) {
    return 'None yet. This fills in the first time Stillscreen tries to '
        'block an app.';
  }
  final when = timeAgo(DateTime.fromMillisecondsSinceEpoch(d.attemptAt), now);
  return '${d.attemptPackage}: ${d.attemptResult}, $when.';
}
