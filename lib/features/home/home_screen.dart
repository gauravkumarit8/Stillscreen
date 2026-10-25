import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/achievements.dart';
import '../../core/battery_guide.dart';
import '../../core/blocking/blocking_engine.dart';
import '../../core/goal.dart';
import '../../core/installed_apps.dart';
import '../../core/models.dart';
import '../../core/pomodoro.dart';
import '../../core/prefs.dart';
import '../../core/reminder.dart';
import '../../core/reminder_service.dart';
import '../../core/session_length.dart';
import '../../core/session_log.dart';
import '../../core/start_guard.dart';
import '../../core/strict.dart';
import '../battery/battery_guide_card.dart';
import '../professional/winddown_card.dart';
import '../student/exam_card.dart';
import 'accessibility_disclosure.dart';
import 'custom_length_dialog.dart';
import 'demo_menu.dart';
import 'end_session_dialog.dart';
import 'session_complete_dialog.dart';
import 'session_ring.dart';
import 'start_guard_dialogs.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen>
    with WidgetsBindingObserver {
  static const _lengthKey = 'picked_minutes';
  static const _maxSessionMinutes = 180;

  bool _permissionGranted = true;
  bool _settling = false;
  late int _pickedMinutes;

  @override
  void initState() {
    super.initState();
    _pickedMinutes =
        normalizeSessionMinutes(ref.read(sharedPrefsProvider).getInt(_lengthKey));
    WidgetsBinding.instance.addObserver(this);
    _refreshPermission();
    // Start loading the app list now so the picker opens instantly.
    Future.microtask(() => ref.read(installedAppsProvider));
    Future.microtask(_syncReminder);
    // A session may have ended while the app was closed.
    Future.microtask(_settleIfFinished);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from system settings, or from a long time away.
    if (state == AppLifecycleState.resumed) {
      _refreshPermission();
      _settleIfFinished();
    }
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

  /// Re-arms the daily reminder (phones forget alarms after a force-stop) and
  /// tells it if today's goal is already done.
  Future<void> _syncReminder() async {
    await ref.read(reminderProvider.notifier).resync();
    final stats = FocusStats(
      ref.read(sessionLogProvider),
      goals: ref.read(goalHistoryProvider),
    );
    if (stats.todayMinutes >= stats.todayGoal) {
      await ref
          .read(reminderServiceProvider)
          .markGoalReached(dayKey(DateTime.now()));
    }
  }

  Future<void> _clearSession() async {
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.remove(sessionEndKey);
    await prefs.remove(sessionStartKey);
    await prefs.remove(sessionStrictKey);
    await ref.read(blockingEngineProvider).stopSession();
  }

  /// Logs a session that ran to its end, including ones that finished while
  /// the app was closed, then shows the "session complete" moment.
  Future<void> _settleIfFinished() async {
    if (_settling) return;
    final end = _sessionEnd;
    if (end == null || DateTime.now().isBefore(end)) return;

    _settling = true;
    int? finishedMinutes;
    DateTime? finishedStart;
    try {
      final start = _sessionStart;
      await _clearSession();
      if (start != null) {
        final minutes = end.difference(start).inMinutes;
        await ref.read(sessionLogProvider.notifier).add(
              SessionRecord(start: start, minutes: minutes, completed: true),
            );
        finishedMinutes = minutes;
        finishedStart = start;
      }
    } finally {
      _settling = false;
      if (mounted) setState(() {});
    }

    final minutes = finishedMinutes;
    final started = finishedStart;
    if (minutes != null && started != null && minutes > 0 && mounted) {
      await _celebrate(minutes, started: started, ended: end);
    }
  }

  Future<void> _celebrate(
    int minutes, {
    required DateTime started,
    required DateTime ended,
  }) async {
    HapticFeedback.mediumImpact();
    PomodoroRound? round;
    if (ref.read(pomodoroEnabledProvider)) {
      round = await ref
          .read(pomodoroTrackerProvider)
          .completeRound(sessionStart: started, sessionEnd: ended);
    }
    final stats = FocusStats(
      ref.read(sessionLogProvider),
      goals: ref.read(goalHistoryProvider),
    );
    final all = computeAchievements(stats);
    final fresh = newlyUnlocked(all, ref.read(seenAchievementsProvider));
    await ref
        .read(seenAchievementsProvider.notifier)
        .markSeen(all.where((a) => a.unlocked).map((a) => a.id));
    if (!mounted) return;

    final choice = await showSessionComplete(
      context,
      minutes: minutes,
      streak: stats.currentStreak,
      todayMinutes: stats.todayMinutes,
      goal: stats.todayGoal,
      badges: fresh,
      round: round,
    );
    if (!mounted) return;
    switch (choice) {
      case CompleteChoice.again:
        await _start();
      case CompleteChoice.breakTime:
        context.push('/break?m=${round?.breakMinutes ?? shortBreakMinutes}');
      case CompleteChoice.done:
        break;
    }
  }

  Future<void> _pick(int minutes) async {
    setState(() => _pickedMinutes = minutes);
    await ref.read(sharedPrefsProvider).setInt(_lengthKey, minutes);
  }

  Future<void> _pickCustom() async {
    final minutes = await pickCustomLength(context, _pickedMinutes);
    if (minutes != null) await _pick(minutes);
  }

  Future<void> _turnOnBlocking() async {
    final agreed = await confirmAccessibilityDisclosure(context);
    if (agreed) {
      await ref.read(blockingEngineProvider).openPermissionSettings();
    }
  }

  /// Start, unless nothing would be blocked. In that case, ask first, so a
  /// session never silently does nothing.
  Future<void> _start() async {
    final engine = ref.read(blockingEngineProvider);
    final granted = await engine.isPermissionGranted();
    if (mounted) setState(() => _permissionGranted = granted);

    final chosen = installedCount(
      ref.read(installedAppsProvider).valueOrNull,
      ref.read(blockedAppsProvider),
    );
    final check =
        evaluateStart(permissionGranted: granted, chosenInstalledApps: chosen);

    if (check != StartCheck.ready) {
      if (!mounted) return;
      final choice = await askBeforeStart(context, check);
      if (choice == StartChoice.cancel) return;
      if (choice == StartChoice.fix) {
        if (!mounted) return;
        if (check == StartCheck.needsPermission) {
          await _turnOnBlocking();
        } else {
          context.push('/apps');
        }
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Timer only: no apps will be blocked.')),
        );
      }
    }
    await _beginSession(willBlock: check == StartCheck.ready);
  }

  Future<void> _beginSession({required bool willBlock}) async {
    final engine = ref.read(blockingEngineProvider);
    final prefs = ref.read(sharedPrefsProvider);
    final duration = Duration(minutes: _pickedMinutes);
    final now = DateTime.now();

    await engine.setBlockedApps(ref.read(blockedAppsProvider));
    await engine.startSession(duration);
    await prefs.setInt(sessionStartKey, now.millisecondsSinceEpoch);
    await prefs.setInt(sessionEndKey, now.add(duration).millisecondsSinceEpoch);
    await prefs.setBool(sessionStrictKey, ref.read(strictModeProvider));
    if (!mounted) return;
    setState(() {});
    if (willBlock) {
      // Blocking reacts when an app opens, so one that is already on screen
      // needs to be left and reopened first.
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Session started. If a chosen app is already open, switch away '
            'from it and it will be blocked when you return.',
          ),
        ),
      );
    }
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

  /// For interruptions: add a few minutes to the running session. Not offered
  /// in strict mode, where the point is to stay with the plan you made.
  Future<void> _extend(int minutes) async {
    final start = _sessionStart;
    final end = _sessionEnd;
    if (start == null || end == null || !end.isAfter(DateTime.now())) return;

    final newEnd = end.add(Duration(minutes: minutes));
    if (newEnd.difference(start) > const Duration(minutes: _maxSessionMinutes)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sessions can be up to 3 hours.')),
      );
      return;
    }
    final extended = await ref
        .read(blockingEngineProvider)
        .extendSession(Duration(minutes: minutes));
    if (!extended) return;
    await ref
        .read(sharedPrefsProvider)
        .setInt(sessionEndKey, newEnd.millisecondsSinceEpoch);
    if (mounted) setState(() {});
  }

  Future<void> _requestEnd() async {
    final confirmed = await confirmEndSession(context);
    if (confirmed) await _end();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final mode = ref.watch(userModeProvider);
    final stats = FocusStats(
      ref.watch(sessionLogProvider),
      goals: ref.watch(goalHistoryProvider),
    );
    final blockedCount = installedCount(
      ref.watch(installedAppsProvider).valueOrNull,
      ref.watch(blockedAppsProvider),
    );

    // Quiet the reminder for the rest of the day once the goal is reached.
    ref.listen<List<SessionRecord>>(sessionLogProvider, (_, next) {
      final latest = FocusStats(next, goals: ref.read(goalHistoryProvider));
      if (latest.todayMinutes >= latest.todayGoal) {
        ref.read(reminderServiceProvider).markGoalReached(dayKey(DateTime.now()));
      }
    });
    // New mode means new reminder wording.
    ref.listen<UserMode?>(userModeProvider, (_, __) {
      ref.read(reminderProvider.notifier).resync();
    });

    final end = _sessionEnd;
    final start = _sessionStart;
    final active = end != null && end.isAfter(DateTime.now());
    final strictOn = ref.watch(strictModeProvider);
    final strictActive = active &&
        (ref.read(sharedPrefsProvider).getBool(sessionStrictKey) ?? false);
    final lockedUntil = strictActive ? end : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stillscreen'),
        actions: [
          const DemoMenu(),
          IconButton(
            tooltip: 'Your focus',
            icon: const Icon(Icons.bar_chart),
            onPressed: () => context.push('/stats'),
          ),
          IconButton(
            tooltip: 'Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
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
          const SizedBox(height: 12),
          if (mode == UserMode.student) ...[
            const ExamCard(),
            const SizedBox(height: 16),
          ],
          if (mode == UserMode.professional) ...[
            const WindDownCard(),
            const SizedBox(height: 16),
          ],
          if (!_permissionGranted) ...[
            _PermissionNotice(onTap: _turnOnBlocking),
            const SizedBox(height: 24),
          ],
          if (_permissionGranted && !ref.watch(batteryGuideDoneProvider)) ...[
            const BatteryGuideCard(),
            const SizedBox(height: 16),
          ],
          SessionRing(
            start: start,
            end: end,
            idle: Duration(minutes: _pickedMinutes),
            onFinished: _settleIfFinished,
          ),
          const SizedBox(height: 24),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            children: [
              for (final m in sessionPresets)
                ChoiceChip(
                  label: Text('$m min'),
                  selected: _pickedMinutes == m,
                  onSelected: active ? null : (_) => _pick(m),
                ),
              ChoiceChip(
                label: Text(
                    isPresetLength(_pickedMinutes) ? 'Custom' : '$_pickedMinutes min'),
                selected: !isPresetLength(_pickedMinutes),
                onSelected: active ? null : (_) => _pickCustom(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: active ? (strictActive ? null : _requestEnd) : _start,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(
                lockedUntil != null
                    ? 'Locked until ${TimeOfDay.fromDateTime(lockedUntil).format(context)}'
                    : active
                        ? 'End session'
                        : 'Start focus session',
              ),
            ),
          ),
          if (strictActive) ...[
            const SizedBox(height: 8),
            const Text(
              'Strict mode is on. Blocking stays on until the timer ends.',
              textAlign: TextAlign.center,
            ),
          ],
          if (active && !strictActive) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                TextButton(
                  onPressed: () => _extend(5),
                  child: const Text('+5 min'),
                ),
                TextButton(
                  onPressed: () => _extend(10),
                  child: const Text('+10 min'),
                ),
              ],
            ),
          ],
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
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Strict mode'),
            subtitle: const Text(
              'Lock each session so it cannot be ended early. '
              'Sessions are capped at 2 hours.',
            ),
            value: strictOn,
            onChanged: active
                ? null
                : (v) => ref.read(strictModeProvider.notifier).set(v),
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
    final goal = stats.todayGoal;
    final reached = stats.todayMinutes >= goal;
    final label = streak == 0
        ? 'Start your streak'
        : streak == 1
            ? '1 day streak'
            : '$streak day streak';

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: context.line),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.local_fire_department_outlined,
                  color: streak > 0 ? stillTeal : context.line,
                ),
                const SizedBox(width: 8),
                Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
                if (stats.freezes > 0) ...[
                  const SizedBox(width: 10),
                  Tooltip(
                    message: 'Rest days saved: ${stats.freezes}',
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.ac_unit, size: 16, color: stillTeal),
                        const SizedBox(width: 2),
                        Text('${stats.freezes}'),
                      ],
                    ),
                  ),
                ],
                const Spacer(),
                Text(reached
                    ? 'Goal reached'
                    : '${stats.todayMinutes} of $goal min today'),
              ],
            ),
            const SizedBox(height: 10),
            LinearProgressIndicator(
              value: (stats.todayMinutes / goal).clamp(0.0, 1.0),
              minHeight: 6,
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
