import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';

class BatteryGuideCard extends StatelessWidget {
  const BatteryGuideCard({super.key});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => context.push('/battery'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: stillTeal),
        ),
        child: Row(
          children: [
            const Icon(Icons.battery_charging_full_outlined, color: stillTeal),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Keep blocking reliable',
                      style: text.titleMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const Text(
                    'Some phones stop background apps. A couple of quick '
                    'settings prevent that.',
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
