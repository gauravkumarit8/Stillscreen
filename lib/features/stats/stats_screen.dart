import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/session_log.dart';
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
    final stats = FocusStats(ref.watch(sessionLogProvider));
    final text = Theme.of(context).textTheme;
    final todayProgress =
        (stats.todayMinutes / dailyGoalMinutes).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Your focus'),
        actions: [
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
          _StatTile(label: 'Total focus time', value: _duration(stats.totalMinutes)),
          const SizedBox(height: 28),
          Text('Today',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: todayProgress,
            minHeight: 10,
            color: stillTeal,
            backgroundColor: pebble,
            borderRadius: BorderRadius.circular(5),
          ),
          const SizedBox(height: 8),
          Text('${stats.todayMinutes} of $dailyGoalMinutes minutes to keep your streak'),
          const SizedBox(height: 28),
          Text('Last 7 days',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _WeekBars(stats: stats),
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
        border: Border.all(color: pebble),
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
    final maxMinutes =
        days.map(stats.minutesOn).fold<int>(dailyGoalMinutes, max);

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
                      color: stats.minutesOn(d) >= dailyGoalMinutes
                          ? stillTeal
                          : pebble,
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
