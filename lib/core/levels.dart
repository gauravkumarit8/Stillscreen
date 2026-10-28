/// Focus levels: a slow, visible sense of progress that grows with total
/// focus time. The first step comes quickly, so a new person sees it early.
///
/// Everything here is worked out from the total minutes. Nothing is stored.
const _steps = <(String, int)>[
  ('Seed', 0),
  ('Sprout', 30),
  ('Sapling', 120),
  ('Bloom', 300),
  ('Tree', 600),
  ('Grove', 1200),
  ('Forest', 2400),
  ('Summit', 4800),
];

class FocusLevel {
  const FocusLevel({
    required this.index,
    required this.name,
    required this.startMinutes,
    required this.totalMinutes,
    this.nextName,
    this.nextMinutes,
  });

  /// 1 for the first level.
  final int index;
  final String name;
  final int startMinutes;
  final int totalMinutes;
  final String? nextName;
  final int? nextMinutes;

  bool get isTop => nextMinutes == null;

  String get label => 'Level $index \u00B7 $name';

  /// How far through this level, from 0 to 1. The top level is always full.
  double get progress {
    final next = nextMinutes;
    if (next == null) return 1;
    final span = next - startMinutes;
    if (span <= 0) return 1;
    return ((totalMinutes - startMinutes) / span).clamp(0.0, 1.0);
  }

  /// Minutes still needed for the next level, or null at the top.
  int? get minutesToNext {
    final next = nextMinutes;
    if (next == null) return null;
    final left = next - totalMinutes;
    return left < 0 ? 0 : left;
  }
}

int get focusLevelCount => _steps.length;

FocusLevel levelFor(int totalMinutes) {
  final total = totalMinutes < 0 ? 0 : totalMinutes;
  var current = 0;
  for (var i = 0; i < _steps.length; i++) {
    if (total >= _steps[i].$2) current = i;
  }
  final hasNext = current + 1 < _steps.length;
  return FocusLevel(
    index: current + 1,
    name: _steps[current].$1,
    startMinutes: _steps[current].$2,
    totalMinutes: total,
    nextName: hasNext ? _steps[current + 1].$1 : null,
    nextMinutes: hasNext ? _steps[current + 1].$2 : null,
  );
}

/// The level a session reached, if it took the person up at least one level.
FocusLevel? levelReachedBy({required int totalAfter, required int sessionMinutes}) {
  final before = levelFor(totalAfter - sessionMinutes);
  final after = levelFor(totalAfter);
  return after.index > before.index ? after : null;
}
