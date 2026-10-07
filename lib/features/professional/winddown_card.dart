import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/winddown.dart';

class WindDownCard extends ConsumerWidget {
  const WindDownCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(windDownProvider);
    final apps = ref.watch(windDownAppsProvider);
    final text = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/winddown'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: config.enabled ? pebble : stillTeal),
        ),
        child: Row(
          children: [
            Icon(Icons.nightlight_outlined,
                color: config.enabled ? deepWater : stillTeal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    config.enabled
                        ? 'Wind-down is on'
                        : 'Set up end-of-day wind-down',
                    style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    config.enabled
                        ? '${formatMinute(context, config.startMinute)} to '
                            '${formatMinute(context, config.endMinute)}, '
                            '${apps.length} work apps paused'
                        : 'Pause work apps after hours so you can switch off.',
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}
