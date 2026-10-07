String formatMinutes(int minutes) {
  if (minutes < 60) return '$minutes min';
  final hours = minutes ~/ 60;
  final rest = minutes % 60;
  return rest == 0 ? '$hours h' : '$hours h $rest min';
}

/// The text that travels with the shared image.
String shareCaption({
  required int streak,
  required int totalMinutes,
  String link = '',
}) {
  final base = streak > 0
      ? "I'm on a $streak-day focus streak with Stillscreen."
      : "I've focused for ${formatMinutes(totalMinutes)} with Stillscreen.";
  return link.isEmpty ? base : '$base\n$link';
}
