import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/blocking/blocking_engine.dart';
import '../../core/models.dart';
import '../../core/prefs.dart';
import '../../core/session_log.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  static const _durations = [25, 50, 90];

  Timer? _ticker;
  bool _permissionGranted = true;
  bool _settling = false;
  int _pickedMinutes = 25;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermission();
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      _settleIfFinished();
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _ticker?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // The user comes back from system settings after enabling the permission.
    if (state == AppLifecycleState.resumed) _refreshPermission();
  }

  Future<void> _refreshPermission() async {
    final granted = await ref.read(blockingEngineProvider).isPermissionGranted();
    if (mounted) setState(() => _permissionGranted = granted);
  }

  DateTime? get _sessionEnd {
    final ms = ref.read(sharedPrefsProvider).getInt(sessionEndKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  DateTime? get _sessionStart {
    final ms = ref.read(sharedPrefsProvider).getInt(sessionStartKey);
    return ms == null ? null : DateTime.fromMillisecondsSinceEpoch(ms);
  }

  Duration get _remaining {
    final end = _sessionEnd;
    if (end == null) return Duration.zero;
    final left = end.difference(DateTime.now());
    return left.isNegative ? Duration.zero : left;
  }

  Future<void> _clearSession() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.remove(sessionEndKey);
    await prefs.remove(sessionStartKey);
    await ref.read(blockingEngineProvider).stopSession();
  }

  /// Logs a session that ran to its end, including ones that finished while
  /// the app was closed.
  Future<void> _settleIfFinished() async {
    if (_settling) return;
    final end = _sessionEnd;
    if (end == null || DateTime.now().isBefore(end)) return;

    _settling = true;
    try {
      final start = _sessionStart;
      await _clearSession();
      if (start != null) {
        final minutes = end.difference(start).inMinutes;
        await ref.read(sessionLogProvider.notifier).add(
              SessionRecord(start: start, minutes: minutes, completed: true),
            );
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Session complete. $minutes minutes focused.')),
          );
        }
      }
    } finally {
      _settling = false;
    }
  }

  Future<void> _start() async {
    final engine = ref.read(blockingEngineProvider);
    final prefs = ref.read(sharedPrefsProvider);
    final duration = Duration(minutes: _pickedMinutes);
    final now = DateTime.now();

    await engine.setBlockedApps(ref.read(blockedAppsProvider));
    await engine.startSession(duration);
    await prefs.setInt(sessionStartKey, now.millisecondsSinceEpoch);
    await prefs.setInt(sessionEndKey, now.add(duration).millisecondsSinceEpoch);
    if (mounted) setState(() {});
  }

  Future<void> _end() async {
    final start = _sessionStart;
    await _clearSession();
    if (start != null) {
      final minutes = DateTime.now().difference(start).inMinutes;
      await ref.read(sessionLogProvider.notifier).add(
            SessionRecord(start: start, minutes: minutes, completed: false),
          );
    }
    if (mounted) setState(() {});
  }

  String _format(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0 ? '${d.inHours}:$m:$s' : '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final mode = ref.watch(userModeProvider);
    final blockedCount = ref.watch(blockedAppsProvider).length;
    final stats = FocusStats(ref.watch(sessionLogProvider));
    final remaining = _remaining;
    final active = remaining > Duration.zero;
    final total = Duration(minutes: _pickedMinutes);
    final progress = active
        ? (remaining.inSeconds / total.inSeconds).clamp(0.0, 1.0)
        : 1.0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stillscreen'),
        actions: [
          IconButton(
            tooltip: 'Your focus',
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/stats'),
          ),
          PopupMenuButton<UserMode>(
            tooltip: 'Switch mode',
            icon: const Icon(Icons.swap_horiz),
            onSelected: (m) => ref.read(userModeProvider.notifier).set(m),
            itemBuilder: (_) => [
              for (final m in UserMode.values)
                PopupMenuItem(value: m, child: Text(m.title)),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(mode?.tagline ?? '',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          _StreakRow(stats: stats, onTap: () => context.push('/stats')),
          const SizedBox(height: 16),
          if (!_permissionGranted) ...[
            _PermissionNotice(
              onTap: () =>
                  ref.read(blockingEngineProvider).openPermissionSettings(),
            ),
            const SizedBox(height: 24),
          ],
          Center(
            child: SizedBox(
              width: 240,
              height: 240,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: progress,
                      strokeWidth: 10,
                      color: stillTeal,
                      backgroundColor: pebble,
                    ),
                  ),
                  Text(
                    _format(active ? remaining : total),
                    style: text.displayMedium?.copyWith(fontWeight: FontWeight.w300),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              for (final m in _durations)
                ChoiceChip(
                  label: Text('$m min'),
                  selected: _pickedMinutes == m,
                  onSelected:
                      active ? null : (_) => setState(() => _pickedMinutes = m),
                ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: active ? _end : _start,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(active ? 'End session' : 'Start focus session'),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Apps to block'),
            subtitle: Text(blockedCount == 0
                ? 'None chosen yet'
                : '$blockedCount chosen'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.push('/apps'),
          ),
        ],
      ),
    );
  }
}

class _StreakRow extends StatelessWidget {
  const _StreakRow({required this.stats, required this.onTap});
  final FocusStats stats;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final streak = stats.currentStreak;
    final label = streak == 0
        ? 'Start your streak'
        : streak == 1
            ? '1 day streak'
            : '$streak day streak';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: pebble),
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department_outlined,
              color: streak > 0 ? stillTeal : pebble,
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text('${stats.todayMinutes} of $dailyGoalMinutes min today'),
          ],
        ),
      ),
    );
  }
}

class _PermissionNotice extends StatelessWidget {
  const _PermissionNotice({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: stillTeal),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Blocking is off',
              style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text(
            'Stillscreen uses the Accessibility permission only to see which '
            'app is open, so it can show a pause screen for the apps you '
            'chose. It does not read what is on your screen.',
          ),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onTap, child: const Text('Turn on blocking')),
        ],
      ),
    );
  }
}
