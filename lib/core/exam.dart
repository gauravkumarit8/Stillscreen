import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'prefs.dart';

class Exam {
  const Exam({required this.name, required this.date});

  final String name;
  final DateTime date;

  /// Whole calendar days from [now] to the exam. Uses UTC dates so daylight
  /// saving changes and the time of day never shift the count.
  int daysLeftFrom(DateTime now) {
    final exam = DateTime.utc(date.year, date.month, date.day);
    final today = DateTime.utc(now.year, now.month, now.day);
    return exam.difference(today).inDays;
  }

  int get daysLeft => daysLeftFrom(DateTime.now());
}

class ExamNotifier extends Notifier<Exam?> {
  static const _nameKey = 'exam_name';
  static const _dateKey = 'exam_date';

  @override
  Exam? build() {
    final prefs = ref.read(sharedPrefsProvider);
    final name = prefs.getString(_nameKey);
    final ms = prefs.getInt(_dateKey);
    if (name == null || ms == null) return null;
    return Exam(name: name, date: DateTime.fromMillisecondsSinceEpoch(ms));
  }

  Future<void> set(Exam exam) async {
    state = exam;
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.setString(_nameKey, exam.name);
    await prefs.setInt(_dateKey, exam.date.millisecondsSinceEpoch);
  }

  Future<void> clear() async {
    state = null;
    final prefs = ref.read(sharedPrefsProvider);
    await prefs.remove(_nameKey);
    await prefs.remove(_dateKey);
  }
}

final examProvider = NotifierProvider<ExamNotifier, Exam?>(ExamNotifier.new);
