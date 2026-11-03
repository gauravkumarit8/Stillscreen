import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/theme.dart';
import '../../core/pause_suggestion.dart';

/// Suggests the mindful pause once. It is a short breathing pause before the
/// apps the person picks, and it works outside focus sessions too.
class PauseSuggestionCard extends ConsumerWidget {
  const PauseSuggestionCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final notifier = ref.read(pauseSuggestionDismissedProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: stillTeal),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Try a mindful pause',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          const Text(
            'Before an app you choose opens, Stillscreen can add a short '
            'breathing pause, even outside focus sessions. In one field study '
            'of a similar pause, daily social media use fell by more than a '
            'third.',
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton(
                onPressed: () async {
                  await notifier.dismiss();
                  if (context.mounted) context.push('/pause');
                },
                child: const Text('Set it up'),
              ),
              TextButton(
                onPressed: notifier.dismiss,
                child: const Text('Not now'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
