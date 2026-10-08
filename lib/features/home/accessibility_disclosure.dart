import 'package:flutter/material.dart';

/// Google Play requires a prominent in-app disclosure, with explicit consent,
/// before sending someone to enable an Accessibility service. Keep this text in
/// sync with docs/ACCESSIBILITY_DECLARATION.md and the Play Console form.
const accessibilityDisclosure =
    'Stillscreen uses Android\'s Accessibility Service to detect which app is '
    'currently in front. This lets it show a pause screen over the apps you '
    'choose to block, during focus sessions and your wind-down hours, and a '
    'short mindful pause before apps you choose for that feature.\n\n'
    'Stillscreen does not read what is on your screen, the text you type, or '
    'your passwords. It does not send this information anywhere.';

Future<bool> confirmAccessibilityDisclosure(BuildContext context) async {
  final agreed = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => AlertDialog(
      title: const Text('Allow Accessibility access?'),
      content: const SingleChildScrollView(child: Text(accessibilityDisclosure)),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Not now'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Agree and continue'),
        ),
      ],
    ),
  );
  return agreed ?? false;
}
