import 'package:flutter_test/flutter_test.dart';
import 'package:focus/core/exam.dart';

void main() {
  final exam = Exam(name: 'Boards', date: DateTime(2026, 11, 16));

  test('counts whole calendar days regardless of time of day', () {
    expect(exam.daysLeftFrom(DateTime(2026, 10, 7, 0, 1)), 40);
    expect(exam.daysLeftFrom(DateTime(2026, 10, 7, 23, 59)), 40);
  });

  test('is zero on exam day and negative afterwards', () {
    expect(exam.daysLeftFrom(DateTime(2026, 11, 16, 9)), 0);
    expect(exam.daysLeftFrom(DateTime(2026, 11, 18, 9)), -2);
  });

  test('is unaffected by a daylight saving change in between', () {
    final dstExam = Exam(name: 'X', date: DateTime(2026, 11, 3));
    expect(dstExam.daysLeftFrom(DateTime(2026, 10, 30, 12)), 4);
  });
}
