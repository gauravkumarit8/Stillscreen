import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/battery_guide.dart';
import '../../core/blocking/blocking_engine.dart';
import '../../core/installed_apps.dart';
import '../../core/models.dart';
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
    final stats = FocusStats(ref.read(sessionLogProvider));
    if (stats.todayMinutes >= dailyGoalMinutes) {
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
      if (mounted) setState(() {});
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
    await _beginSession();
  }

  Future<void> _beginSession() async {
    final engine = ref.read(blockingEngineProvider);
    final prefs = ref.read(sharedPrefsProvider);
    final duration = Duration(minutes: _pickedMinutes);
    final now = DateTime.now();

    await engine.setBlockedApps(ref.read(blockedAppsProvider));
    await engine.startSession(duration);
    await prefs.setInt(sessionStartKey, now.millisecondsSinceEpoch);
    await prefs.setInt(sessionEndKey, now.add(duration).millisecondsSinceEpoch);
    await prefs.setBool(sessionStrictKey, ref.read(strictModeProvider));
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

  Future<void> _requestEnd() async {
    final confirmed = await confirmEndSession(context);
    if (confirmed) await _end();
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final mode = ref.watch(userModeProvider);
    final stats = FocusStats(ref.watch(sessionLogProvider));
    final blockedCount = installedCount(
      ref.watch(installedAppsProvider).valueOrNull,
      ref.watch(blockedAppsProvider),
    );

    // Quiet the reminder for the rest of the day once the goal is reached.
    ref.listen<List<SessionRecord>>(sessionLogProvider, (_, next) {
      if (FocusStats(next).todayMinutes >= dailyGoalMinutes) {
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
                strictActive && end != null
                    ? 'Locked until ${TimeOfDay.fromDateTime(end).format(context)}'
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
          border: Border.all(color: context.line),
        ),
        child: Row(
          children: [
            Icon(
              Icons.local_fire_department_outlined,
              color: streak > 0 ? stillTeal : context.line,
            ),
            const SizedBox(width: 8),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
            const Spacer(),
            Text(stats.todayMinutes >= dailyGoalMinutes
                ? 'Goal reached'
                : '${stats.todayMinutes} of $dailyGoalMinutes min today'),
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
