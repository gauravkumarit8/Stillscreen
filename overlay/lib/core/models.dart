enum UserMode {
  student(
    'Student',
    'Study without the scroll.',
    [
      'Exam countdown and study streaks',
      'Focus groups and friend leaderboards',
      'Study-only YouTube and websites',
    ],
  ),
  professional(
    'Working professional',
    'Protect your deep work.',
    [
      'Focus blocks around your calendar',
      'Work hours with an end-of-day wind-down',
      'Private weekly focus reports',
    ],
  );

  const UserMode(this.title, this.tagline, this.benefits);

  final String title;
  final String tagline;
  final List<String> benefits;
}
