import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/blocking/blocking_engine.dart';
import '../../core/installed_apps.dart';
import '../../core/prefs.dart';
import '../home/accessibility_disclosure.dart';

/// Three short steps after choosing a mode, so a new user is not left on a
/// home screen where Start does nothing. Every step can be skipped.
class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen>
    with WidgetsBindingObserver {
  bool _blockingOn = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refresh();
    Future.microtask(() => ref.read(installedAppsProvider));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Back from Android's Accessibility settings.
    if (state == AppLifecycleState.resumed) _refresh();
  }

  Future<void> _refresh() async {
    final on = await ref.read(blockingEngineProvider).isPermissionGranted();
    if (mounted) setState(() => _blockingOn = on);
  }

  Future<void> _turnOn() async {
    final agreed = await confirmAccessibilityDisclosure(context);
    if (agreed) {
      await ref.read(blockingEngineProvider).openPermissionSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final chosen = installedCount(
      ref.watch(installedAppsProvider).valueOrNull,
      ref.watch(blockedAppsProvider),
    );
    final allDone = _blockingOn && chosen > 0;

    return Scaffold(
      appBar: AppBar(title: const Text('Set up Stillscreen')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Two quick steps, then you are ready.',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          const Text('You can skip any of this and come back from Settings.'),
          const SizedBox(height: 20),
          _Step(
            number: 1,
            title: 'Turn on blocking',
            body: 'Android needs your permission before Stillscreen can see '
                'which app is open. You will see exactly what it does first.',
            done: _blockingOn,
            doneLabel: 'Blocking is on',
            actionLabel: 'Turn on blocking',
            onAction: _turnOn,
          ),
          const SizedBox(height: 12),
          _Step(
            number: 2,
            title: 'Choose apps to block',
            body: 'Pick the apps that pull you away. One tap adds a whole group, '
                'like social media.',
            done: chosen > 0,
            doneLabel: chosen == 1 ? '1 app chosen' : '$chosen apps chosen',
            actionLabel: 'Choose apps',
            onAction: () => context.push('/apps'),
          ),
          const SizedBox(height: 12),
          _Step(
            number: 3,
            title: 'Start your first session',
            body: 'On the home screen, pick a length and tap Start. Open one of '
                'your chosen apps to see the pause screen.',
            done: false,
            doneLabel: '',
            actionLabel: null,
            onAction: null,
          ),
          const SizedBox(height: 28),
          FilledButton(
            onPressed: () => context.go('/home'),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 14),
              child: Text(allDone ? 'Start focusing' : 'Skip for now'),
            ),
          ),
        ],
      ),
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.number,
    required this.title,
    required this.body,
    required this.done,
    required this.doneLabel,
    required this.actionLabel,
    required this.onAction,
  });

  final int number;
  final String title;
  final String body;
  final bool done;
  final String doneLabel;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: done ? stillTeal : pebble, width: done ? 2 : 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: done ? stillTeal : null,
              border: done ? null : Border.all(color: stillTeal),
            ),
            child: done
                ? const Icon(Icons.check, size: 18, color: Colors.white)
                : Text('$number'),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(body),
                if (actionLabel != null) ...[
                  const SizedBox(height: 12),
                  if (done)
                    Text(doneLabel,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, color: stillTeal))
                  else
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
