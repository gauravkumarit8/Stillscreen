import 'package:flutter/material.dart';

import '../../core/session_length.dart';

/// Lets the user pick any length from 5 to 120 minutes, in steps of 5.
Future<int?> pickCustomLength(BuildContext context, int initial) {
  return showDialog<int>(
    context: context,
    builder: (_) => _CustomLengthDialog(initial: initial),
  );
}

class _CustomLengthDialog extends StatefulWidget {
  const _CustomLengthDialog({required this.initial});

  final int initial;

  @override
  State<_CustomLengthDialog> createState() => _CustomLengthDialogState();
}

class _CustomLengthDialogState extends State<_CustomLengthDialog> {
  late double _value = normalizeSessionMinutes(widget.initial).toDouble();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Custom length'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${_value.round()} min',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          Slider(
            min: minSessionMinutes.toDouble(),
            max: maxSessionMinutes.toDouble(),
            divisions: (maxSessionMinutes - minSessionMinutes) ~/ 5,
            value: _value,
            onChanged: (v) => setState(() => _value = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_value.round()),
          child: const Text('Set'),
        ),
      ],
    );
  }
}
