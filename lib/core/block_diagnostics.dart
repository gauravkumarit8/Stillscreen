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

/// One time Android stopped the app, as recorded by the phone.
class ProcessExit {
  const ProcessExit({required this.reason, required this.at, this.detail = ''});

  final String reason;
  final int at;
  final String detail;

  factory ProcessExit.fromMap(Map<Object?, Object?> map) => ProcessExit(
        reason: (map['reason'] as String?) ?? '',
        at: (map['at'] as num?)?.toInt() ?? 0,
        detail: (map['detail'] as String?) ?? '',
      );
}

/// Up to three recent stops, one per line, newest first.
String describeExits(List<ProcessExit> exits, DateTime now) {
  if (exits.isEmpty) return 'No recent stops recorded on this phone.';
  return exits.take(3).map((e) {
    final when = timeAgo(DateTime.fromMillisecondsSinceEpoch(e.at), now);
    final base = '${e.reason}, $when';
    return e.detail.isEmpty ? base : '$base (${e.detail})';
  }).join('\n');
}
