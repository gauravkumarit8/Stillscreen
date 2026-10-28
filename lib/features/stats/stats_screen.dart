import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/achievements.dart';
import '../../core/goal.dart';
import '../../core/insights.dart';
import '../../core/levels.dart';
import '../../core/pause.dart';
import '../../core/session_log.dart';
import '../../core/weekly_recap.dart';
import 'add_time_dialog.dart';
import 'insight_cards.dart';
import 'streak_share_dialog.dart';

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

String _days(int n) => n == 1 ? '1 day' : '$n days';

String _duration(int minutes) {
  if (minutes < 60) return '$minutes min';
  return '${minutes ~/ 60} h ${minutes % 60} min';
}

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = FocusStats(
      ref.watch(sessionLogProvider),
      goals: ref.watch(goalHistoryProvider),
    );
    final text = Theme.of(context).textTheme;
    final goal = stats.todayGoal;
    final todayProgress = (stats.todayMinutes / goal).clamp(0.0, 1.0);
    final badges = computeAchievements(stats);
    final unlocked = badges.where((a) => a.unlocked).length;
    final insights = focusInsights(stats.log);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your focus'),
        actions: [
          IconButton(
            tooltip: 'Add offline focus time',
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () => showAddTimeDialog(context),
          ),
          IconButton(
            tooltip: 'Share your streak',
            icon: const Icon(Icons.ios_share),
            onPressed: () {
              if (stats.totalMinutes == 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Complete a focus session first, then share.'),
                  ),
                );
                return;
              }
              showStreakShareDialog(context, stats);
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            children: [
              Expanded(
                  child: _StatTile(
                      label: 'Current streak', value: _days(stats.currentStreak))),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatTile(
                      label: 'Longest streak', value: _days(stats.longestStreak))),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _StatTile(
                      label: 'Total focus time',
                      value: _duration(stats.totalMinutes))),
              const SizedBox(width: 12),
              Expanded(
                  child: _StatTile(
                      label: 'Rest days saved', value: '${stats.freezes}')),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Every 7 days in a row earns a rest day, up to 2. If you miss a '
            'day, a rest day keeps your streak going.',
            style: text.bodySmall,
          ),
          const SizedBox(height: 16),
          LevelCard(level: levelFor(stats.totalMinutes)),
          const SizedBox(height: 16),
          InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/achievements'),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.line),
              ),
              child: Row(
                children: [
                  const Icon(Icons.emoji_events_outlined, color: stillTeal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Achievements',
                            style: text.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        Text('$unlocked of ${badges.length} unlocked'),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
            ),
          ),
          const SizedBox(height: 28),
          Text('Today',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: todayProgress,
            minHeight: 10,
            color: stillTeal,
            backgroundColor: context.line,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 8),
          Text(stats.todayMinutes >= goal
              ? 'Goal reached. ${stats.todayMinutes} minutes focused today.'
              : '${stats.todayMinutes} of $goal minutes to keep your streak'),
          const SizedBox(height: 28),
          RecapCard(recap: weeklyRecap(stats)),
          const SizedBox(height: 16),
          if (insights.hasEnoughData) ...[
            InsightsCard(insights: insights),
            const SizedBox(height: 16),
          ],
          const SizedBox(height: 12),
          ref.watch(pauseSummaryProvider).maybeWhen(
                data: (s) => s.shownWeek == 0
                    ? const SizedBox.shrink()
                    : Padding(
                        padding: const EdgeInsets.only(bottom: 28),
                        child: _PauseCard(summary: s),
                      ),
                orElse: () => const SizedBox.shrink(),
              ),
          Text('Last 7 days',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _WeekBars(stats: stats),
          const SizedBox(height: 28),
          Text('Last 5 weeks',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _Heatmap(stats: stats),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: text.bodyMedium),
          const SizedBox(height: 4),
          Text(value,
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}

class _WeekBars extends StatelessWidget {
  const _WeekBars({required this.stats});
  final FocusStats stats;

  @override
  Widget build(BuildContext context) {
    final days = stats.lastDays(7);
    final maxMinutes = days.map(stats.minutesOn).fold<int>(stats.todayGoal, max);

    return SizedBox(
      height: 140,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final d in days)
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    stats.minutesOn(d) > 0 ? '${stats.minutesOn(d)}' : '',
                    style: const TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    height: max(4.0, 90 * stats.minutesOn(d) / maxMinutes),
                    margin: const EdgeInsets.symmetric(horizontal: 6),
                    decoration: BoxDecoration(
                      color: stats.hitGoal(d) ? stillTeal : context.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(_weekdays[d.weekday - 1],
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Five weeks as a calendar: darker means closer to (or past) that day's goal.
class _Heatmap extends StatelessWidget {
  const _Heatmap({required this.stats});
  final FocusStats stats;

  @override
  Widget build(BuildContext context) {
    final today = stats.today;
    final monday = DateTime(today.year, today.month, today.day - (today.weekday - 1));
    final first = DateTime(monday.year, monday.month, monday.day - 7 * 4);

    return Column(
      children: [
        Row(
          children: [
            for (final name in _weekdays)
              Expanded(
                child: Center(
                  child: Text(name.substring(0, 1),
                      style: const TextStyle(fontSize: 12)),
                ),
              ),
          ],
        ),
        const SizedBox(height: 4),
        for (var week = 0; week < 5; week++)
          Row(
            children: [
              for (var d = 0; d < 7; d++)
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(2),
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: _cell(
                        context,
                        DateTime(first.year, first.month, first.day + week * 7 + d),
                      ),
                    ),
                  ),
                ),
            ],
          ),
      ],
    );
  }

  Widget _cell(BuildContext context, DateTime day) {
    if (day.isAfter(stats.today)) return const SizedBox.shrink();
    final minutes = stats.minutesOn(day);
    final goal = stats.goalOn(day);
    final strength = minutes == 0 ? 0.0 : (minutes / goal).clamp(0.3, 1.0);
    final color = minutes == 0
        ? context.line
        : Color.lerp(context.line, stillTeal, strength)!;
    final isToday = day == stats.today;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
        border: isToday
            ? Border.all(color: Theme.of(context).colorScheme.onSurface, width: 1.5)
            : null,
      ),
    );
  }
}

class _PauseCard extends StatelessWidget {
  const _PauseCard({required this.summary});

  final PauseSummary summary;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final times = summary.resistedWeek == 1 ? '1 time' : '${summary.resistedWeek} times';
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mindful pauses', style: text.bodyMedium),
          const SizedBox(height: 4),
          Text(
            'You chose not to open an app $times this week',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'Paused ${summary.shownWeek} times this week, '
            '${summary.resistedToday} walked away today.',
          ),
        ],
      ),
    );
  }
}
