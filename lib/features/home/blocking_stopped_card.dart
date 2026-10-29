import 'package:flutter/material.dart';

/// Shown during a session when the phone has stopped the blocking service, so
/// nothing is being blocked. It says what happened and how to fix it.
class BlockingStoppedCard extends StatelessWidget {
  const BlockingStoppedCard({super.key, required this.onFix});

  final VoidCallback onFix;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.errorContainer.withValues(alpha: 0.4),
        border: Border.all(color: scheme.error),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: scheme.error),
              const SizedBox(width: 8),
              Text(
                'Blocking has stopped',
                style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'Your phone stopped Stillscreen, often because it was swiped away '
            'from recent apps. No apps are being blocked right now. Switch '
            'Stillscreen off and on in Accessibility settings, then lock it in '
            'recent apps.',
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: onFix,
            child: const Text('Open Accessibility settings'),
          ),
        ],
      ),
    );
  }
}
