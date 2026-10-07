import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/battery_guide.dart';
import '../../core/power/power_settings.dart';

class BatteryGuideScreen extends ConsumerStatefulWidget {
  const BatteryGuideScreen({super.key});

  @override
  ConsumerState<BatteryGuideScreen> createState() => _BatteryGuideScreenState();
}

class _BatteryGuideScreenState extends ConsumerState<BatteryGuideScreen>
    with WidgetsBindingObserver {
  String _maker = '';
  bool _optimizationIgnored = false;

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
    // Refresh the status when the user comes back from system settings.
    if (state == AppLifecycleState.resumed) _load();
  }

  Future<void> _load() async {
    final power = ref.read(powerSettingsProvider);
    final maker = await power.manufacturer();
    final ignored = await power.isBatteryOptimizationIgnored();
    if (!mounted) return;
    setState(() {
      _maker = maker;
      _optimizationIgnored = ignored;
    });
  }

  Future<void> _openAutostart() async {
    final power = ref.read(powerSettingsProvider);
    final opened = await power.openAutostartSettings();
    if (opened) return;
    await power.openAppInfo();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Could not find the autostart screen on this phone, so app info '
          'opened instead.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final power = ref.read(powerSettingsProvider);
    final steps = stepsFor(_maker);
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Keep blocking reliable')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const Text(
            'Some phones stop apps running in the background to save battery. '
            'If that happens, blocking can switch off without warning. '
            'These steps stop it.',
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                _optimizationIgnored ? Icons.check_circle_outline : Icons.info_outline,
                color: _optimizationIgnored ? stillTeal : deepWater,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _optimizationIgnored
                      ? 'Battery optimization is off for Stillscreen.'
                      : 'Battery optimization is on. Some phones may stop '
                          'blocking in the background.',
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text('What to do on your phone',
              style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          for (var i = 0; i < steps.length; i++)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: stillTeal),
                    ),
                    child: Text('${i + 1}'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(steps[i])),
                ],
              ),
            ),
          const Text(
            'Menu names differ between phone models and Android versions.',
          ),
          const SizedBox(height: 24),
          FilledButton(
            onPressed: power.openBatterySettings,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Open battery settings'),
            ),
          ),
          if (hasAutostartScreen(_maker)) ...[
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: _openAutostart,
              child: const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text('Open autostart settings'),
              ),
            ),
          ],
          const SizedBox(height: 12),
          OutlinedButton(
            onPressed: power.openAppInfo,
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Open app info'),
            ),
          ),
          const SizedBox(height: 24),
          TextButton(
            onPressed: () async {
              await ref.read(batteryGuideDoneProvider.notifier).markDone();
              if (context.mounted) context.pop();
            },
            child: const Text('I have done this'),
          ),
        ],
      ),
    );
  }
}
