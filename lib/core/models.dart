enum UserMode {
  student(
    'Student',
    'Study without the scroll.',
    [
      'Exam countdown and daily streaks',
      'Focus sessions with strict mode',
      'Mindful pause before distracting apps',
    ],
  ),
  professional(
    'Working professional',
    'Protect your deep work.',
    [
      'End-of-day wind-down for work apps',
      'Focus sessions and daily streaks',
      'Mindful pause before distracting apps',
    ],
  );

  const UserMode(this.title, this.tagline, this.benefits);

  final String title;
  final String tagline;
  final List<String> benefits;
}
