import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/reason.dart';

Future<void> showReasonDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _ReasonDialog());

class _ReasonDialog extends ConsumerStatefulWidget {
  const _ReasonDialog();

  @override
  ConsumerState<_ReasonDialog> createState() => _ReasonDialogState();
}

class _ReasonDialogState extends ConsumerState<_ReasonDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(reasonProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(String value) async {
    await ref.read(reasonProvider.notifier).set(value);
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('My reminder'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'A short note you will see on the pause and block screens, such '
            'as why you are doing this.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            maxLength: maxReasonLength,
            maxLines: 2,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              hintText: 'For example: Exam on 14 November',
            ),
          ),
        ],
      ),
      actions: [
        TextButton(onPressed: () => _save(''), child: const Text('Clear')),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () => _save(_controller.text),
          child: const Text('Save'),
        ),
      ],
    );
  }
}
