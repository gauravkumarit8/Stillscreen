import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/exam.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

Future<void> showExamDialog(BuildContext context) =>
    showDialog<void>(context: context, builder: (_) => const _ExamDialog());

class _ExamDialog extends ConsumerStatefulWidget {
  const _ExamDialog();

  @override
  ConsumerState<_ExamDialog> createState() => _ExamDialogState();
}

class _ExamDialogState extends ConsumerState<_ExamDialog> {
  late final TextEditingController _name;
  DateTime? _date;

  @override
  void initState() {
    super.initState();
    final existing = ref.read(examProvider);
    _name = TextEditingController(text: existing?.name ?? '');
    _date = existing?.date;
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _date != null && !_date!.isBefore(today) ? _date! : today,
      firstDate: today,
      lastDate: DateTime(now.year + 5, now.month, now.day),
    );
    if (picked != null) setState(() => _date = picked);
  }

  @override
  Widget build(BuildContext context) {
    final existing = ref.watch(examProvider);
    final canSave = _name.text.trim().isNotEmpty && _date != null;

    return AlertDialog(
      title: const Text('Your exam'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _name,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Exam name',
              hintText: 'For example: Board exams',
            ),
            onChanged: (_) => setState(() {}),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            icon: const Icon(Icons.calendar_today_outlined, size: 18),
            label: Text(_date == null
                ? 'Pick exam date'
                : '${_date!.day} ${_months[_date!.month - 1]} ${_date!.year}'),
            onPressed: _pickDate,
          ),
        ],
      ),
      actions: [
        if (existing != null)
          TextButton(
            onPressed: () async {
              await ref.read(examProvider.notifier).clear();
              if (context.mounted) Navigator.of(context).pop();
            },
            child: const Text('Remove'),
          ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: canSave
              ? () async {
                  await ref.read(examProvider.notifier).set(
                        Exam(name: _name.text.trim(), date: _date!),
                      );
                  if (context.mounted) Navigator.of(context).pop();
                }
              : null,
          child: const Text('Save'),
        ),
      ],
    );
  }
}
