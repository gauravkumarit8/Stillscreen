import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/block_diagnostics.dart';
import '../../core/app_config.dart';
import '../../core/battery_guide.dart';
import '../../core/blocking/blocking_engine.dart';
import '../../core/power/power_settings.dart';
import '../../core/reminder_service.dart';
import '../../core/support_service.dart';
import '../../core/time_ago.dart';
import '../home/accessibility_disclosure.dart';

/// One place to see whether blocking can work, and how to fix it if not.
/// On Android, blocking can quietly stop after a restart, an update or a
/// battery saver, and people only notice when it has already failed.
class HealthScreen extends ConsumerStatefulWidget {
  const HealthScreen({super.key});

  @override
  ConsumerState<HealthScreen> createState() => _HealthScreenState();
}

class _HealthScreenState extends ConsumerState<HealthScreen>
    with WidgetsBindingObserver {
  bool? _blockingOn;
  bool? _serviceRunning;
  bool? _batteryOff;
  bool? _notificationsOn;
  int _lastActive = 0;
  BlockDiagnostics _diag = const BlockDiagnostics();
  List<ProcessExit> _exits = const [];
  String _maker = '';
  String _build = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from Android settings: look again.
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final engine = ref.read(blockingEngineProvider);
    final blocking = await engine.isPermissionGranted();
    final running = blocking ? await engine.isServiceConnected() : null;
    final battery = await ref.read(powerSettingsProvider).isBatteryOptimizationIgnored();
    final notifications = await ref.read(reminderServiceProvider).notificationsAllowed();
    final last = await engine.lastActiveMillis();
    final diag = await engine.blockDiagnostics();
    var build = '';
    try {
      final info = await ref.read(appInfoProvider.future);
      build = '${info.versionName} (${info.versionCode}), build $buildNumber';
    } catch (_) {
      build = 'build $buildNumber';
    }
    final exits = await engine.recentExits();
    final maker = await ref.read(powerSettingsProvider).manufacturer();
    if (!mounted) return;
    setState(() {
      _blockingOn = blocking;
      _serviceRunning = running;
      _batteryOff = battery;
      _notificationsOn = notifications;
      _lastActive = last;
      _diag = diag;
      _exits = exits;
      _maker = maker;
      _build = build;
    });
  }

  Future<void> _turnOn() async {
    final agreed = await confirmAccessibilityDisclosure(context);
    if (agreed) {
      await ref.read(blockingEngineProvider).openPermissionSettings();
    }
  }

  Future<void> _sendReport() async {
    final support = ref.read(supportServiceProvider);
    final AppInfo info;
    try {
      info = await ref.read(appInfoProvider.future);
    } catch (_) {
      return;
    }
    final body = '${feedbackBody(info)}'
        'Blocking permission: ${_blockingOn == true ? 'on' : 'off'}\n'
        'Blocking service running: ${_serviceRunning == true ? 'yes' : 'no'}\n'
        'Last app seen: ${describeSeen(_diag, DateTime.now())}\n'
        'Last block attempt: ${describeAttempt(_diag, DateTime.now())}\n'
        'Blocking state: ${describeState(_diag)}\n'
        'App: $_build\n'
        'Phone: $_maker\n'
        'Recent activity:\n${describeLog(_diag)}\n'
        'Why the app last stopped: '
        '${describeExits(_exits, DateTime.now()).replaceAll('\n', '; ')}\n'
        'Battery optimization off: ${_batteryOff == true ? 'yes' : 'no'}\n'
        'Notifications: ${_notificationsOn == true ? 'on' : 'off'}\n'
        'Last seen working: ${_lastActive == 0 ? 'never' : timeAgo(DateTime.fromMillisecondsSinceEpoch(_lastActive), DateTime.now())}\n';
    await support.sendFeedback(
      to: feedbackEmail,
      subject: 'Stillscreen: blocking problem',
      body: body,
    );
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final power = ref.read(powerSettingsProvider);
    final lastSeen = _lastActive == 0
        ? 'Not noticed yet. Open any app to test.'
        : 'Noticed an app change ${timeAgo(DateTime.fromMillisecondsSinceEpoch(_lastActive), DateTime.now())}. '
            'If that is old and you have been switching apps, switch '
            'Stillscreen off and on in Accessibility settings.';

    return Scaffold(
      appBar: AppBar(title: const Text('Blocking health check')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            _blockingOn == null
                ? 'Checking...'
                : _blockingOn == false
                    ? 'Blocking is off.'
                    : _serviceRunning == false
                        ? 'Blocking has stopped.'
                        : 'Blocking is on.',
            style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text('If blocking ever stops working, start here.'),
          const SizedBox(height: 20),
          _CheckRow(
            title: 'Blocking permission',
            ok: _blockingOn,
            detail: _blockingOn == true
                ? 'Stillscreen can see which app is open.'
                : 'Turn it on so Stillscreen can block or pause apps.',
            actionLabel: _blockingOn == true ? null : 'Turn on',
            onAction: _turnOn,
          ),
          const SizedBox(height: 12),
          _CheckRow(
            title: 'Blocking service',
            ok: _blockingOn == true ? _serviceRunning : null,
            detail: _serviceRunning == false
                ? 'Android has stopped it in the background, so apps are not '
                    'being blocked. Switch Stillscreen off and on again in '
                    'Accessibility settings.'
                : _serviceRunning == true
                    ? 'Running.'
                    : 'Turn on blocking first.',
            actionLabel:
                _serviceRunning == false ? 'Open Accessibility settings' : null,
            onAction: ref.read(blockingEngineProvider).openPermissionSettings,
          ),
          const SizedBox(height: 12),
          _CheckRow(
            title: 'App build',
            ok: null,
            detail: _build.isEmpty ? 'Reading...' : _build,
          ),
          const SizedBox(height: 12),
          _CheckRow(
            title: 'Blocking state',
            ok: null,
            detail: describeState(_diag),
          ),
          const SizedBox(height: 12),
          _CheckRow(
            title: 'Last app change noticed',
            ok: _blockingOn == true && _serviceRunning == true && _lastActive > 0
                ? true
                : null,
            detail: lastSeen,
          ),
          const SizedBox(height: 12),
          _CheckRow(
            title: 'Last app seen',
            ok: null,
            detail: describeSeen(_diag, DateTime.now()),
          ),
          const SizedBox(height: 12),
          _CheckRow(
            title: 'Last block attempt',
            ok: null,
            detail: describeAttempt(_diag, DateTime.now()),
          ),
          const SizedBox(height: 12),
          _CheckRow(
            title: 'Recent activity (newest first)',
            ok: null,
            detail: describeLog(_diag),
          ),
          const SizedBox(height: 12),
          _CheckRow(
            title: 'Why the app last stopped',
            ok: null,
            detail: describeExits(_exits, DateTime.now()),
          ),
          if (needsPopupPermission(_maker)) ...[
            const SizedBox(height: 12),
            _CheckRow(
              title: 'Allow pop-ups (Xiaomi)',
              ok: null,
              detail: 'Recommended. Xiaomi phones only open the full block screen '
                  'if Stillscreen may display pop-up windows while running in '
                  'the background. Without it, Stillscreen covers the app with '
                  'a simpler block screen instead. In Other permissions, allow it.',
              actionLabel: 'Open permissions',
              onAction: () async {
                final opened = await power.openAppPermissions();
                if (!opened) await power.openAppInfo();
              },
            ),
          ],
          const SizedBox(height: 12),
          _CheckRow(
            title: 'Battery optimization',
            ok: _batteryOff,
            detail: _batteryOff == true
                ? 'Off for Stillscreen.'
                : 'On. Some phones may switch blocking off in the background.',
            actionLabel: _batteryOff == true ? null : 'Open battery settings',
            onAction: power.openBatterySettings,
          ),
          const SizedBox(height: 12),
          _CheckRow(
            title: 'Notifications (optional)',
            ok: _notificationsOn,
            detail: _notificationsOn == true
                ? 'On. You get reminders, and a warning if blocking switches off.'
                : 'Off. You will not get reminders or a warning if blocking switches off.',
            actionLabel: _notificationsOn == true ? null : 'Open app info',
            onAction: power.openAppInfo,
          ),
          const SizedBox(height: 12),
          _CheckRow(
            title: 'Picture-in-picture',
            ok: null,
            detail: 'Video apps can keep playing in a small window after you '
                'leave them, and a blocker may not catch that. Turn it off for '
                'apps you block, so they stop when you leave.',
            actionLabel: 'Open picture-in-picture settings',
            onAction: power.openPictureInPictureSettings,
          ),
          const SizedBox(height: 28),
          Text('Good to know',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          const _Tip('Some phones switch accessibility off after a restart, an '
              'update or when the battery saver starts. If blocking stops, '
              'check this screen first.'),
          const _Tip('On some phones, locking Stillscreen in the recent apps '
              'screen stops it being closed.'),
          const _Tip('Blocked apps opened in a floating window or pop-up may '
              'not be caught on some phones.'),
          const _Tip('On Android 17 and newer, Advanced Protection can restrict '
              'accessibility access for apps. If blocking will not stay on, '
              'try turning off Device protection (the path can differ by phone, '
              'often Settings, Google, Personal and device safety, Advanced '
              'Protection), restart if asked, then switch Stillscreen\'s '
              'blocking back on here.'),
          const _Tip('If you installed Stillscreen from a file and the switch '
              'is greyed out, open the app info, tap the three-dot menu and '
              'choose Allow restricted settings.'),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: _sendReport,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Still stuck? Send a report'),
            ),
          ),
        ],
      ),
    );
  }
}

class _CheckRow extends StatelessWidget {
  const _CheckRow({
    required this.title,
    required this.ok,
    required this.detail,
    this.actionLabel,
    this.onAction,
  });

  final String title;

  /// True: fine. False: needs attention. Null: unknown or just information.
  final bool? ok;
  final String detail;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final icon = ok == true
        ? Icons.check_circle_outline
        : ok == false
            ? Icons.error_outline
            : Icons.info_outline;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: ok == true ? stillTeal : context.line,
          width: ok == true ? 2 : 1,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ok == true ? stillTeal : null),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Text(detail),
                if (actionLabel != null) ...[
                  const SizedBox(height: 10),
                  OutlinedButton(onPressed: onAction, child: Text(actionLabel!)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  const _Tip(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.lightbulb_outline, size: 18, color: stillTeal),
          ),
          const SizedBox(width: 10),
          Expanded(child: Text(message)),
        ],
      ),
    );
  }
}
