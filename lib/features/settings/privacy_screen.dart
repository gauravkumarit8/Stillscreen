import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_config.dart';
import '../../core/support_service.dart';

/// Plain-language summary, for people who are wary of an app that asks for
/// accessibility access.
class PrivacyScreen extends ConsumerWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = Theme.of(context).textTheme;

    Widget block(String title, String body) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: text.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(body),
            ],
          ),
        );

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy at a glance')),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text('Your data stays on your phone',
              style: text.headlineSmall?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 20),
          block(
            'No internet',
            'Stillscreen has no permission to use the internet, so it cannot '
                'send anything off your phone. There are no ads, no account '
                'and no tracking.',
          ),
          block(
            'Saved on your phone',
            'The apps you chose, your sessions and streak, your settings and '
                'daily goal, and your short note if you wrote one. Uninstalling '
                'removes all of it.',
          ),
          block(
            'Accessibility permission',
            'Needed to see which app is in front, so Stillscreen can show a '
                'pause or block screen. It does not read what is on your '
                'screen, what you type, or your passwords. It is the only '
                'permission blocking needs.',
          ),
          block(
            'Notifications (optional)',
            'For the daily reminder, and a warning if blocking switches off '
                'during a session.',
          ),
          block(
            'Start after restart',
            'Lets the daily reminder keep working after your phone restarts.',
          ),
          block(
            'List of your apps',
            'Used only to show you which apps you can choose. It stays on '
                'your phone.',
          ),
          block(
            'Check it yourself',
            'Open Stillscreen on Google Play and read its Data safety section.',
          ),
          OutlinedButton(
            onPressed: () => ref.read(supportServiceProvider).openUrl(privacyPolicyUrl),
            child: const Padding(
              padding: EdgeInsets.symmetric(vertical: 14),
              child: Text('Read the full privacy policy'),
            ),
          ),
        ],
      ),
    );
  }
}
