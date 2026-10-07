import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/exam.dart';
import 'exam_dialog.dart';

class ExamCard extends ConsumerWidget {
  const ExamCard({super.key});

  String _countdown(int days) {
    if (days < 0) return 'This exam has passed';
    if (days == 0) return 'Exam day is today';
    if (days == 1) return 'Tomorrow';
    return '$days days to go';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final exam = ref.watch(examProvider);
    final text = Theme.of(context).textTheme;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => showExamDialog(context),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: exam == null ? stillTeal : pebble),
        ),
        child: exam == null
            ? Row(
                children: [
                  const Icon(Icons.event_outlined, color: stillTeal),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Set your exam date',
                            style: text.titleMedium
                                ?.copyWith(fontWeight: FontWeight.w600)),
                        const Text('See how many days you have left.'),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(exam.name, style: text.bodyMedium),
                  const SizedBox(height: 2),
                  Text(_countdown(exam.daysLeft),
                      style: text.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}
