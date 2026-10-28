import 'package:flutter/material.dart';

import '../../app/theme.dart';
import '../../core/insights.dart';
import '../../core/levels.dart';
import '../../core/weekly_recap.dart';

String _minutesText(int minutes) {
  if (minutes < 60) return '$minutes min';
  final rest = minutes % 60;
  return rest == 0 ? '${minutes ~/ 60} h' : '${minutes ~/ 60} h $rest min';
}

String _toNext(FocusLevel level) => level.isTop
    ? 'Top level reached'
    : '${_minutesText(level.minutesToNext ?? 0)} to ${level.nextName}';

BoxDecoration _frame(BuildContext context, {bool highlight = false}) =>
    BoxDecoration(
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: highlight ? stillTeal : context.line),
    );

/// A compact level line for the home screen.
class LevelRow extends StatelessWidget {
  const LevelRow({super.key, required this.level, required this.onTap});

  final FocusLevel level;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
        decoration: _frame(context),
        child: Column(
          children: [
            Row(
              children: [
                const Icon(Icons.spa_outlined, color: stillTeal, size: 20),
                const SizedBox(width: 8),
                Text(level.label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                const Spacer(),
                Text(_toNext(level), style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: level.progress,
              minHeight: 5,
              color: stillTeal,
              backgroundColor: context.line,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    );
  }
}

/// The fuller level card for the stats screen, with a dot for every level.
class LevelCard extends StatelessWidget {
  const LevelCard({super.key, required this.level});

  final FocusLevel level;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _frame(context, highlight: true),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.spa_outlined, color: stillTeal),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Focus level',
                        style: text.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(level.label),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: level.progress,
            minHeight: 8,
            color: stillTeal,
            backgroundColor: context.line,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: 6),
          Text(_toNext(level), style: text.bodySmall),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              for (var i = 1; i <= focusLevelCount; i++)
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= level.index ? stillTeal : Colors.transparent,
                    border: Border.all(
                      color: i <= level.index ? stillTeal : context.line,
                      width: 2,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// This week against last week.
class RecapCard extends StatelessWidget {
  const RecapCard({super.key, required this.recap});

  final WeeklyRecap recap;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final bestDay = bestDayLine(recap);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _frame(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calendar_view_week_outlined, color: stillTeal),
              const SizedBox(width: 12),
              Text('This week',
                  style:
                      text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
            ],
          ),
          const SizedBox(height: 8),
          Text(recapHeadline(recap)),
          if (recap.sessions > 0 || bestDay != null) ...[
            const SizedBox(height: 8),
            Text(
              [
                if (recap.sessions > 0)
                  recap.sessions == 1
                      ? '1 session'
                      : '${recap.sessions} sessions',
                if (bestDay != null) bestDay,
              ].join('  \u00B7  '),
              style: text.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// A pattern spotted in the person's own history.
class InsightsCard extends StatelessWidget {
  const InsightsCard({super.key, required this.insights});

  final FocusInsights insights;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final part = insights.bestPart;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _frame(context),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.lightbulb_outline, color: stillTeal),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Your pattern',
                    style:
                        text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                if (part != null)
                  Text('You focus most in the ${dayPartName(part)}.'),
                Text('Your average session is '
                    '${_minutesText(insights.averageMinutes)}.'),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
