import 'dart:async';

import 'package:flutter/material.dart';

/// Soft strict mode: ending early needs a short wait and a confirmation.
/// Returns true only if the user waited and chose to end the session.
Future<bool> confirmEndSession(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _EndSessionDialog(),
  );
  return result ?? false;
}

class _EndSessionDialog extends StatefulWidget {
  const _EndSessionDialog();

  @override
  State<_EndSessionDialog> createState() => _EndSessionDialogState();
}

class _EndSessionDialogState extends State<_EndSessionDialog> {
  static const _waitSeconds = 10;

  int _left = _waitSeconds;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _left = _left > 0 ? _left - 1 : 0);
      if (_left == 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('End this session early?'),
      content: const Text(
        'Take a breath first. You can still keep going, and minutes you have '
        'already focused still count toward your streak.',
      ),
      actions: [
        TextButton(
          onPressed: _left == 0 ? () => Navigator.of(context).pop(true) : null,
          child: Text(_left == 0 ? 'End session' : 'End session ($_left)'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Keep going'),
        ),
      ],
    );
  }
}
