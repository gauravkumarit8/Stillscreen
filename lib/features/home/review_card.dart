import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/app_config.dart';
import '../../core/review_prompt.dart';
import '../../core/support_service.dart';

/// Asks once in a while for a rating on Google Play. Everyone sees the same
/// three choices, and none of them is a reward or a condition.
class ReviewCard extends ConsumerWidget {
  const ReviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;
    final notifier = ref.read(reviewPromptProvider.notifier);

    Future<void> rate() async {
      final opened = await openPlayListing(ref.read(supportServiceProvider));
      if (opened) {
        await notifier.markDone();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open Google Play.')),
        );
      }
    }

    Future<void> tellMe() async {
      final support = ref.read(supportServiceProvider);
      final AppInfo details;
      try {
        details = await ref.read(appInfoProvider.future);
      } catch (_) {
        return;
      }
      final opened = await support.sendFeedback(
        to: feedbackEmail,
        subject: 'Stillscreen feedback',
        body: feedbackBody(details),
      );
      if (opened) {
        await notifier.snooze();
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No email app found. You can write to $feedbackEmail.'),
          ),
        );
      }
    }

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
            'Help others find Stillscreen',
            style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            'A rating on Google Play helps other people find a focus app. '
            'It takes about ten seconds.',
            style: text.bodyMedium,
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              FilledButton(onPressed: rate, child: const Text('Rate on Play')),
              TextButton(onPressed: notifier.snooze, child: const Text('Not now')),
              TextButton(onPressed: tellMe, child: const Text('Something wrong?')),
            ],
          ),
        ],
      ),
    );
  }
}
